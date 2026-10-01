-- BORALOG-161: atomic minimal INTERNAL Message creation.
-- Content -> visibility -> save. No Project/Date/Groups/Read UI in this contract.

create or replace function private.boralog_message_access_allowed(
  p_message_id uuid,
  p_organization_id uuid,
  p_project_id uuid,
  p_event_id uuid,
  p_visibility text,
  p_created_by uuid,
  p_author_user_id uuid
)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid;
  v_access public.organization_access_level;
  v_is_recipient boolean := false;
  v_business_eligible boolean := false;
  v_event_project_id uuid;
begin
  v_actor := auth.uid();
  if v_actor is null then
    return false;
  end if;

  select m.access_level
    into v_access
  from public.organization_memberships as m
  where m.organization_id = p_organization_id
    and m.user_id = v_actor
    and m.status = 'active'::public.membership_status
  limit 1;

  if v_access is null then
    return false;
  end if;

  select exists (
    select 1
    from public.message_recipients as mr
    where mr.message_id = p_message_id
      and mr.user_id = v_actor
  )
  into v_is_recipient;

  if v_access in (
    'owner'::public.organization_access_level,
    'full'::public.organization_access_level
  ) then
    v_business_eligible := true;
  elsif v_access = 'limited'::public.organization_access_level then
    if p_project_id is not null then
      v_business_eligible := private.boralog_can_access_project(p_project_id);
    elsif p_event_id is not null then
      select e.project_id
        into v_event_project_id
      from public.events as e
      where e.id = p_event_id;

      v_business_eligible :=
        v_event_project_id is not null
        and private.boralog_can_access_project(v_event_project_id);
    elsif p_visibility = 'RESTRICTED' then
      -- No Project/Date is allowed for LIMITED only when confidentiality itself
      -- establishes the narrow audience. Creator/author access stays explicit
      -- and does not grant organization-wide visibility.
      v_business_eligible :=
        v_actor = p_created_by
        or v_actor = p_author_user_id
        or v_is_recipient;
    end if;
  end if;

  if not v_business_eligible then
    return false;
  end if;

  if p_visibility = 'ORGANIZATION' then
    return true;
  end if;

  if p_visibility = 'RESTRICTED' then
    return v_actor = p_created_by
      or v_actor = p_author_user_id
      or v_is_recipient;
  end if;

  return false;
end
$$;

alter function private.boralog_message_access_allowed(
  uuid, uuid, uuid, uuid, text, uuid, uuid
) owner to postgres;

revoke all on function private.boralog_message_access_allowed(
  uuid, uuid, uuid, uuid, text, uuid, uuid
) from public, anon, service_role;

grant execute on function private.boralog_message_access_allowed(
  uuid, uuid, uuid, uuid, text, uuid, uuid
) to authenticated;

create or replace function private.boralog_restricted_message_requires_recipient()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_message_id uuid;
  v_visibility text;
begin
  if tg_table_name = 'messages' then
    v_message_id := new.id;
    v_visibility := new.visibility;
  else
    -- This trigger is attached only to DELETE/UPDATE on message_recipients.
    -- Always validate the message losing (or changing) the recipient row.
    v_message_id := old.message_id;

    select m.visibility
      into v_visibility
    from public.messages as m
    where m.id = v_message_id;

    if not found then
      if tg_op = 'DELETE' then
        return old;
      end if;
      return new;
    end if;
  end if;

  if v_visibility = 'RESTRICTED'
     and not exists (
       select 1
       from public.message_recipients as mr
       where mr.message_id = v_message_id
     ) then
    raise exception 'restricted message requires at least one recipient'
      using errcode = '23514';
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end
$$;

alter function private.boralog_restricted_message_requires_recipient() owner to postgres;
revoke all on function private.boralog_restricted_message_requires_recipient()
  from public, anon, authenticated, service_role;

create constraint trigger boralog_restricted_message_recipient_required
after insert or update of visibility
on public.messages
deferrable initially deferred
for each row
execute function private.boralog_restricted_message_requires_recipient();

create constraint trigger boralog_restricted_message_recipient_delete_guard
after delete or update of message_id, user_id
on public.message_recipients
deferrable initially deferred
for each row
execute function private.boralog_restricted_message_requires_recipient();

create or replace function public.boralog_create_internal_message(
  p_organization_id uuid,
  p_content text,
  p_visibility text,
  p_recipient_user_ids uuid[] default '{}'::uuid[]
)
returns public.messages
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid;
  v_access public.organization_access_level;
  v_recipient_ids uuid[] := coalesce(p_recipient_user_ids, '{}'::uuid[]);
  v_recipient_count integer := 0;
  v_valid_recipient_count integer := 0;
  v_message public.messages%rowtype;
begin
  v_actor := auth.uid();
  if v_actor is null then
    raise exception 'authenticated actor required to create message'
      using errcode = '42501';
  end if;

  if nullif(btrim(p_content), '') is null then
    raise exception 'message content is required'
      using errcode = '23514';
  end if;

  if p_visibility is null
     or p_visibility not in ('ORGANIZATION', 'RESTRICTED') then
    raise exception 'invalid message visibility'
      using errcode = '23514';
  end if;

  select membership.access_level
    into v_access
  from public.organization_memberships as membership
  where membership.organization_id = p_organization_id
    and membership.user_id = v_actor
    and membership.status = 'active'::public.membership_status
  limit 1;

  if v_access is null then
    raise exception 'active organization membership required'
      using errcode = '42501';
  end if;

  if exists (
    select 1
    from unnest(v_recipient_ids) as supplied(user_id)
    where supplied.user_id is null
  ) then
    raise exception 'recipient ids cannot contain null'
      using errcode = '23514';
  end if;

  select count(distinct supplied.user_id)
    into v_recipient_count
  from unnest(v_recipient_ids) as supplied(user_id);

  if p_visibility = 'ORGANIZATION' then
    if v_access = 'limited'::public.organization_access_level then
      raise exception 'limited member cannot create organization-wide message without context'
        using errcode = '42501';
    end if;

    if v_recipient_count <> 0 then
      raise exception 'organization message does not accept selected recipients'
        using errcode = '23514';
    end if;
  else
    if v_recipient_count = 0 then
      raise exception 'restricted message requires at least one selected recipient'
        using errcode = '23514';
    end if;

    select count(*)
      into v_valid_recipient_count
    from public.organization_memberships as membership
    where membership.organization_id = p_organization_id
      and membership.status = 'active'::public.membership_status
      and membership.user_id in (
        select distinct supplied.user_id
        from unnest(v_recipient_ids) as supplied(user_id)
      );

    if v_valid_recipient_count <> v_recipient_count then
      raise exception 'all recipients must be active members of the message organization'
        using errcode = '23514';
    end if;
  end if;

  insert into public.messages(
    organization_id,
    project_id,
    event_id,
    content,
    created_by,
    origin_type,
    author_user_id,
    external_author_label,
    source_kind,
    source_occurred_at,
    visibility
  ) values (
    p_organization_id,
    null,
    null,
    btrim(p_content),
    v_actor,
    'INTERNAL',
    v_actor,
    null,
    null,
    null,
    p_visibility
  )
  returning * into v_message;

  if p_visibility = 'RESTRICTED' then
    insert into public.message_recipients(message_id, user_id)
    select
      v_message.id,
      supplied.user_id
    from (
      select distinct recipient.user_id
      from unnest(v_recipient_ids) as recipient(user_id)
    ) as supplied;
  end if;

  return v_message;
end
$$;

alter function public.boralog_create_internal_message(uuid, text, text, uuid[]) owner to postgres;

revoke all on function public.boralog_create_internal_message(uuid, text, text, uuid[])
  from public, anon, service_role;

grant execute on function public.boralog_create_internal_message(uuid, text, text, uuid[])
  to authenticated;
