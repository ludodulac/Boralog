-- BORALOG-ACCESS-MODEL-IMPLEMENTATION-CANDIDATE-027
-- Candidate only. Do not apply to remote Supabase without explicit approval.

create type public.organization_access_level as enum ('owner', 'full', 'limited');

alter table public.organization_memberships
  add column access_level public.organization_access_level not null;

alter table public.organization_memberships
  alter column role drop not null;

alter table public.project_memberships
  alter column role drop not null;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to authenticated;

-- Read-only authorization helpers. SECURITY DEFINER avoids recursive RLS on memberships.
create or replace function private.boralog_org_access(p_organization_id uuid)
returns public.organization_access_level
language sql
stable
security definer
set search_path = ''
as $$
  select m.access_level
  from public.organization_memberships as m
  where m.organization_id = p_organization_id
    and m.user_id = auth.uid()
    and m.status = 'active'::public.membership_status
  limit 1
$$;

create or replace function private.boralog_can_access_project(p_project_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.projects as p
    join public.organization_memberships as m
      on m.organization_id = p.organization_id
     and m.user_id = auth.uid()
     and m.status = 'active'::public.membership_status
    where p.id = p_project_id
      and (
        m.access_level in ('owner'::public.organization_access_level, 'full'::public.organization_access_level)
        or (
          m.access_level = 'limited'::public.organization_access_level
          and exists (
            select 1
            from public.project_memberships as pm
            where pm.project_id = p.id
              and pm.user_id = auth.uid()
          )
        )
      )
  )
$$;

create or replace function private.boralog_can_manage_membership(
  p_organization_id uuid,
  p_target_access public.organization_access_level
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case private.boralog_org_access(p_organization_id)
    when 'owner'::public.organization_access_level then true
    when 'full'::public.organization_access_level then
      p_target_access in ('full'::public.organization_access_level, 'limited'::public.organization_access_level)
    else false
  end
$$;

create or replace function private.boralog_can_manage_project_memberships(p_project_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.projects as p
    join public.organization_memberships as actor
      on actor.organization_id = p.organization_id
     and actor.user_id = auth.uid()
     and actor.status = 'active'::public.membership_status
     and actor.access_level in ('owner'::public.organization_access_level, 'full'::public.organization_access_level)
    where p.id = p_project_id
  )
$$;

create or replace function private.boralog_valid_project_assignment(
  p_project_id uuid,
  p_target_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.projects as p
    join public.organization_memberships as target
      on target.organization_id = p.organization_id
     and target.user_id = p_target_user_id
     and target.status = 'active'::public.membership_status
     and target.access_level = 'limited'::public.organization_access_level
    where p.id = p_project_id
  )
$$;

alter function private.boralog_org_access(uuid) owner to postgres;
alter function private.boralog_can_access_project(uuid) owner to postgres;
alter function private.boralog_can_manage_membership(uuid, public.organization_access_level) owner to postgres;
alter function private.boralog_can_manage_project_memberships(uuid) owner to postgres;
alter function private.boralog_valid_project_assignment(uuid, uuid) owner to postgres;

revoke execute on function private.boralog_org_access(uuid) from public, anon;
revoke execute on function private.boralog_can_access_project(uuid) from public, anon;
revoke execute on function private.boralog_can_manage_membership(uuid, public.organization_access_level) from public, anon;
revoke execute on function private.boralog_can_manage_project_memberships(uuid) from public, anon;
revoke execute on function private.boralog_valid_project_assignment(uuid, uuid) from public, anon;
grant execute on function private.boralog_org_access(uuid) to authenticated;
grant execute on function private.boralog_can_access_project(uuid) to authenticated;
grant execute on function private.boralog_can_manage_membership(uuid, public.organization_access_level) to authenticated;
grant execute on function private.boralog_can_manage_project_memberships(uuid) to authenticated;
grant execute on function private.boralog_valid_project_assignment(uuid, uuid) to authenticated;

-- Trigger-only privileged bootstrap. No client may execute it directly.
create or replace function private.boralog_bootstrap_organization_owner()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.created_by is null or new.created_by <> auth.uid() then
    raise exception 'organization creator must match authenticated user';
  end if;

  insert into public.organization_memberships (
    organization_id,
    user_id,
    role,
    status,
    access_level
  ) values (
    new.id,
    new.created_by,
    'owner'::public.membership_role,
    'active'::public.membership_status,
    'owner'::public.organization_access_level
  );

  return new;
end
$$;

alter function private.boralog_bootstrap_organization_owner() owner to postgres;
revoke execute on function private.boralog_bootstrap_organization_owner() from public, anon, authenticated, service_role;

drop trigger if exists boralog_bootstrap_organization_owner on public.organizations;
create trigger boralog_bootstrap_organization_owner
after insert on public.organizations
for each row
execute function private.boralog_bootstrap_organization_owner();

-- Immutable identity/provenance fields.
create or replace function private.boralog_guard_immutable_fields()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_table_schema = 'public' and tg_table_name = 'organization_memberships' then
    if new.id is distinct from old.id
       or new.organization_id is distinct from old.organization_id
       or new.user_id is distinct from old.user_id
       or new.created_at is distinct from old.created_at then
      raise exception 'immutable organization membership identity/provenance';
    end if;
  elsif tg_table_schema = 'public' and tg_table_name = 'project_memberships' then
    if new.project_id is distinct from old.project_id
       or new.user_id is distinct from old.user_id
       or new.created_at is distinct from old.created_at then
      raise exception 'immutable project membership identity/provenance';
    end if;
  elsif tg_table_schema = 'public' and tg_table_name = 'organizations' then
    if new.id is distinct from old.id
       or new.created_by is distinct from old.created_by
       or new.created_at is distinct from old.created_at then
      raise exception 'immutable organization identity/provenance';
    end if;
  elsif tg_table_schema = 'public' and tg_table_name = 'projects' then
    if new.id is distinct from old.id
       or new.organization_id is distinct from old.organization_id
       or new.created_by is distinct from old.created_by
       or new.created_at is distinct from old.created_at then
      raise exception 'immutable project identity/provenance';
    end if;
  elsif tg_table_schema = 'public' and tg_table_name = 'events' then
    if new.id is distinct from old.id
       or new.project_id is distinct from old.project_id
       or new.created_by is distinct from old.created_by
       or new.created_at is distinct from old.created_at then
      raise exception 'immutable event identity/provenance';
    end if;
  end if;
  return new;
end
$$;

alter function private.boralog_guard_immutable_fields() owner to postgres;
revoke execute on function private.boralog_guard_immutable_fields() from public, anon, authenticated, service_role;

create trigger boralog_organization_membership_immutable
before update on public.organization_memberships
for each row execute function private.boralog_guard_immutable_fields();
create trigger boralog_project_membership_immutable
before update on public.project_memberships
for each row execute function private.boralog_guard_immutable_fields();
create trigger boralog_organization_immutable
before update on public.organizations
for each row execute function private.boralog_guard_immutable_fields();
create trigger boralog_project_immutable
before update on public.projects
for each row execute function private.boralog_guard_immutable_fields();
create trigger boralog_event_immutable
before update on public.events
for each row execute function private.boralog_guard_immutable_fields();

-- Serialize owner-removal transitions on the parent organization row.
create or replace function private.boralog_guard_last_active_owner()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_organization_id uuid;
  v_other_active_owners bigint;
  v_old_is_active_owner boolean;
  v_new_is_active_owner boolean;
begin
  v_organization_id := old.organization_id;
  v_old_is_active_owner := old.access_level = 'owner'::public.organization_access_level
                           and old.status = 'active'::public.membership_status;
  v_new_is_active_owner := case when tg_op = 'DELETE' then false else
    new.access_level = 'owner'::public.organization_access_level
    and new.status = 'active'::public.membership_status end;

  if v_old_is_active_owner and not v_new_is_active_owner then
    perform 1
    from public.organizations as o
    where o.id = v_organization_id
    for update;

    select count(*)
      into v_other_active_owners
    from public.organization_memberships as m
    where m.organization_id = v_organization_id
      and m.id <> old.id
      and m.access_level = 'owner'::public.organization_access_level
      and m.status = 'active'::public.membership_status;

    if v_other_active_owners = 0 then
      raise exception 'an active organization must retain at least one active owner';
    end if;
  end if;

  if tg_op = 'DELETE' then return old; end if;
  return new;
end
$$;

alter function private.boralog_guard_last_active_owner() owner to postgres;
revoke execute on function private.boralog_guard_last_active_owner() from public, anon, authenticated, service_role;

create trigger boralog_last_active_owner_guard
before update or delete on public.organization_memberships
for each row execute function private.boralog_guard_last_active_owner();

-- Replace foundation policies with owner/full/limited authorization.
drop policy if exists "organization creator insert" on public.organizations;
drop policy if exists "organization creator select" on public.organizations;
drop policy if exists "member organization select" on public.organizations;
drop policy if exists "creator membership access" on public.organization_memberships;
drop policy if exists "member project select" on public.projects;
drop policy if exists "organization creator project insert" on public.projects;
drop policy if exists "project member rows select" on public.project_memberships;
drop policy if exists "org admin project member manage" on public.project_memberships;
drop policy if exists "project event select" on public.events;
drop policy if exists "org staff event insert" on public.events;

-- Organizations.
create policy "organization member select"
on public.organizations for select to authenticated
using (private.boralog_org_access(id) is not null);

create policy "organization authenticated create"
on public.organizations for insert to authenticated
with check (auth.uid() is not null and created_by = auth.uid());

create policy "organization owner update"
on public.organizations for update to authenticated
using (private.boralog_org_access(id) = 'owner'::public.organization_access_level)
with check (private.boralog_org_access(id) = 'owner'::public.organization_access_level);

-- Organization memberships. LIMITED sees only itself; OWNER/FULL see the organization roster.
create policy "organization membership select"
on public.organization_memberships for select to authenticated
using (
  user_id = auth.uid()
  or private.boralog_org_access(organization_id) in (
    'owner'::public.organization_access_level,
    'full'::public.organization_access_level
  )
);

create policy "organization membership insert"
on public.organization_memberships for insert to authenticated
with check (
  private.boralog_can_manage_membership(organization_id, access_level)
);

create policy "organization membership update"
on public.organization_memberships for update to authenticated
using (
  private.boralog_can_manage_membership(organization_id, access_level)
)
with check (
  private.boralog_can_manage_membership(organization_id, access_level)
);

create policy "organization membership delete"
on public.organization_memberships for delete to authenticated
using (
  private.boralog_can_manage_membership(organization_id, access_level)
);

-- Projects.
create policy "project access select"
on public.projects for select to authenticated
using (private.boralog_can_access_project(id));

create policy "project owner full insert"
on public.projects for insert to authenticated
with check (
  created_by = auth.uid()
  and private.boralog_org_access(organization_id) in (
    'owner'::public.organization_access_level,
    'full'::public.organization_access_level
  )
);

create policy "project accessible update"
on public.projects for update to authenticated
using (private.boralog_can_access_project(id))
with check (private.boralog_can_access_project(id));

create policy "project owner full delete"
on public.projects for delete to authenticated
using (
  private.boralog_org_access(organization_id) in (
    'owner'::public.organization_access_level,
    'full'::public.organization_access_level
  )
);

-- Project memberships: only active LIMITED members receive explicit project assignments.
create policy "project membership select"
on public.project_memberships for select to authenticated
using (
  user_id = auth.uid()
  or private.boralog_can_manage_project_memberships(project_id)
);

create policy "project membership insert"
on public.project_memberships for insert to authenticated
with check (
  private.boralog_can_manage_project_memberships(project_id)
  and private.boralog_valid_project_assignment(project_id, user_id)
);

create policy "project membership delete"
on public.project_memberships for delete to authenticated
using (private.boralog_can_manage_project_memberships(project_id));

-- Events inherit project access. LIMITED has normal event work inside assigned projects.
create policy "event accessible select"
on public.events for select to authenticated
using (private.boralog_can_access_project(project_id));

create policy "event accessible insert"
on public.events for insert to authenticated
with check (
  created_by = auth.uid()
  and private.boralog_can_access_project(project_id)
);

create policy "event accessible update"
on public.events for update to authenticated
using (private.boralog_can_access_project(project_id))
with check (private.boralog_can_access_project(project_id));

create policy "event accessible delete"
on public.events for delete to authenticated
using (private.boralog_can_access_project(project_id));

-- The foundation previously omitted DELETE grants for projects/events.
grant delete on public.projects to authenticated;
grant delete on public.events to authenticated;

-- No authorization policy below this point may depend on legacy role/can_manage_* columns.
