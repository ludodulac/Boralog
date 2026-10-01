-- BORALOG-157: second Message access barrier (business eligibility + confidentiality).

alter table public.messages
  add column visibility text not null default 'ORGANIZATION';

alter table public.messages
  add constraint messages_visibility_check
    check (visibility in ('ORGANIZATION', 'RESTRICTED'));

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
    else
      v_business_eligible := v_is_recipient;
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

drop policy if exists "message accessible select" on public.messages;
drop policy if exists "message accessible insert" on public.messages;
drop policy if exists "message accessible update" on public.messages;

create policy "message accessible select"
on public.messages
for select
to authenticated
using (
  private.boralog_message_access_allowed(
    id,
    organization_id,
    project_id,
    event_id,
    visibility,
    created_by,
    author_user_id
  )
);

create policy "message accessible insert"
on public.messages
for insert
to authenticated
with check (
  created_by = (select auth.uid())
  and private.boralog_message_access_allowed(
    id,
    organization_id,
    project_id,
    event_id,
    visibility,
    created_by,
    author_user_id
  )
);

create policy "message accessible update"
on public.messages
for update
to authenticated
using (
  private.boralog_message_access_allowed(
    id,
    organization_id,
    project_id,
    event_id,
    visibility,
    created_by,
    author_user_id
  )
)
with check (
  private.boralog_message_access_allowed(
    id,
    organization_id,
    project_id,
    event_id,
    visibility,
    created_by,
    author_user_id
  )
);
