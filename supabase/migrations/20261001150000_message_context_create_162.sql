-- BORALOG-162: optional business context (none / project / date) for atomic INTERNAL Message creation.

drop function if exists public.boralog_create_internal_message(
  uuid, text, text, uuid[]
);

create or replace function public.boralog_create_internal_message(
  p_organization_id uuid,
  p_content text,
  p_visibility text,
  p_recipient_user_ids uuid[] default '{}'::uuid[],
  p_project_id uuid default null,
  p_event_id uuid default null
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
  v_context_project_id uuid := null;
  v_context_event_id uuid := null;
  v_context_organization_id uuid := null;
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

  if p_project_id is not null and p_event_id is not null then
    raise exception 'message context must be a project or a date, not both'
      using errcode = '23514';
  end if;

  if p_project_id is not null then
    select project.organization_id
      into v_context_organization_id
    from public.projects as project
    where project.id = p_project_id;

    if v_context_organization_id is null
       or v_context_organization_id <> p_organization_id then
      raise exception 'message project must belong to message organization'
        using errcode = '23514';
    end if;

    if not private.boralog_can_access_project(p_project_id) then
      raise exception 'message project is not accessible to actor'
        using errcode = '42501';
    end if;

    v_context_project_id := p_project_id;
  elsif p_event_id is not null then
    select event.project_id, project.organization_id
      into v_context_project_id, v_context_organization_id
    from public.events as event
    join public.projects as project on project.id = event.project_id
    where event.id = p_event_id;

    if v_context_project_id is null
       or v_context_organization_id <> p_organization_id then
      raise exception 'message date must belong to message organization'
        using errcode = '23514';
    end if;

    if not private.boralog_can_access_project(v_context_project_id) then
      raise exception 'message date is not accessible to actor'
        using errcode = '42501';
    end if;

    v_context_event_id := p_event_id;
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
    if v_access = 'limited'::public.organization_access_level
       and v_context_project_id is null then
      raise exception 'limited member cannot create organization-wide message without accessible context'
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
    v_context_project_id,
    v_context_event_id,
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

alter function public.boralog_create_internal_message(
  uuid, text, text, uuid[], uuid, uuid
) owner to postgres;

revoke all on function public.boralog_create_internal_message(
  uuid, text, text, uuid[], uuid, uuid
) from public, anon, service_role;

grant execute on function public.boralog_create_internal_message(
  uuid, text, text, uuid[], uuid, uuid
) to authenticated;
