-- BORALOG-167A: canonical business People foundation.
-- Personne is a business identity and is deliberately distinct from Auth profiles/accounts.

create table public.people (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null
    check (char_length(btrim(name)) between 1 and 160),
  role_label text,
  professional_email text,
  professional_phone text,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create index people_organization_idx
  on public.people(organization_id);

create index people_created_by_idx
  on public.people(created_by);

-- Extend the canonical immutable identity/provenance guard append-only.
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
  elsif tg_table_schema = 'public' and tg_table_name = 'companies' then
    if new.id is distinct from old.id
       or new.organization_id is distinct from old.organization_id
       or new.created_by is distinct from old.created_by
       or new.created_at is distinct from old.created_at then
      raise exception 'immutable company identity/provenance';
    end if;
  elsif tg_table_schema = 'public' and tg_table_name = 'people' then
    if new.id is distinct from old.id
       or new.organization_id is distinct from old.organization_id
       or new.created_by is distinct from old.created_by
       or new.created_at is distinct from old.created_at then
      raise exception 'immutable person identity/provenance';
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
revoke execute on function private.boralog_guard_immutable_fields()
  from public, anon, authenticated, service_role;

create trigger boralog_person_immutable
before update on public.people
for each row execute function private.boralog_guard_immutable_fields();

alter table public.people enable row level security;

revoke all on table public.people from anon, authenticated;
grant select, insert, update on table public.people to authenticated;

create policy "people owner full select"
on public.people
for select
to authenticated
using (
  private.boralog_org_access(organization_id) in (
    'owner'::public.organization_access_level,
    'full'::public.organization_access_level
  )
);

create policy "people owner full insert"
on public.people
for insert
to authenticated
with check (
  created_by = (select auth.uid())
  and private.boralog_org_access(organization_id) in (
    'owner'::public.organization_access_level,
    'full'::public.organization_access_level
  )
);

create policy "people owner full update"
on public.people
for update
to authenticated
using (
  private.boralog_org_access(organization_id) in (
    'owner'::public.organization_access_level,
    'full'::public.organization_access_level
  )
)
with check (
  private.boralog_org_access(organization_id) in (
    'owner'::public.organization_access_level,
    'full'::public.organization_access_level
  )
);
