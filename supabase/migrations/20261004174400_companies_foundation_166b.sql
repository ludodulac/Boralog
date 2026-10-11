-- BORALOG-166B: canonical Companies foundation.
-- Structure organisatrice -> Compagnies only. No People, invitations, or Message changes.

create table public.companies (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null
    check (char_length(btrim(name)) between 1 and 160),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create index companies_organization_idx
  on public.companies(organization_id);

-- Human-facing names remain free text, but casing and whitespace differences
-- must not create duplicate Companies inside the same Structure.
create unique index companies_organization_normalized_name_uidx
  on public.companies (
    organization_id,
    lower(regexp_replace(btrim(name), '[[:space:]]+', ' ', 'g'))
  );

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

create trigger boralog_company_immutable
before update on public.companies
for each row execute function private.boralog_guard_immutable_fields();

alter table public.companies enable row level security;

revoke all on table public.companies from anon, authenticated;
grant select, insert, update on table public.companies to authenticated;

create policy "company owner full select"
on public.companies
for select
to authenticated
using (
  private.boralog_org_access(organization_id) in (
    'owner'::public.organization_access_level,
    'full'::public.organization_access_level
  )
);

create policy "company owner full insert"
on public.companies
for insert
to authenticated
with check (
  created_by = auth.uid()
  and private.boralog_org_access(organization_id) in (
    'owner'::public.organization_access_level,
    'full'::public.organization_access_level
  )
);

create policy "company owner full update"
on public.companies
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
