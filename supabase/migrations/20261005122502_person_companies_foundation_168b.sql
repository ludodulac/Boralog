-- BORALOG-168B: canonical Person <-> Company relationship foundation.
-- This is a business relation only: no Auth account, invitation, permission, or access role.

create table public.person_companies (
  person_id uuid not null
    references public.people(id) on delete cascade,
  company_id uuid not null
    references public.companies(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (person_id, company_id)
);

create index person_companies_company_person_idx
  on public.person_companies(company_id, person_id);

create or replace function private.boralog_person_company_consistency()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_person_organization_id uuid;
  v_company_organization_id uuid;
begin
  select p.organization_id
    into v_person_organization_id
  from public.people as p
  where p.id = new.person_id;

  select c.organization_id
    into v_company_organization_id
  from public.companies as c
  where c.id = new.company_id;

  if v_person_organization_id is null
     or v_company_organization_id is null
     or v_person_organization_id <> v_company_organization_id then
    raise exception 'person and company must belong to same organization'
      using errcode = '23514';
  end if;

  return new;
end
$$;

alter function private.boralog_person_company_consistency() owner to postgres;
revoke all on function private.boralog_person_company_consistency()
  from public, anon, authenticated, service_role;

create trigger boralog_person_company_consistency
before insert or update of person_id, company_id
on public.person_companies
for each row
execute function private.boralog_person_company_consistency();

alter table public.person_companies enable row level security;

revoke all on table public.person_companies from anon, authenticated;
grant select, insert, delete on table public.person_companies to authenticated;

create policy "person company owner full select"
on public.person_companies
for select
to authenticated
using (
  exists (
    select 1
    from public.people as p
    where p.id = person_id
      and private.boralog_org_access(p.organization_id) in (
        'owner'::public.organization_access_level,
        'full'::public.organization_access_level
      )
  )
);

create policy "person company owner full insert"
on public.person_companies
for insert
to authenticated
with check (
  exists (
    select 1
    from public.people as p
    where p.id = person_id
      and private.boralog_org_access(p.organization_id) in (
        'owner'::public.organization_access_level,
        'full'::public.organization_access_level
      )
  )
);

create policy "person company owner full delete"
on public.person_companies
for delete
to authenticated
using (
  exists (
    select 1
    from public.people as p
    where p.id = person_id
      and private.boralog_org_access(p.organization_id) in (
        'owner'::public.organization_access_level,
        'full'::public.organization_access_level
      )
  )
);
