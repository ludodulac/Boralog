-- BORALOG-169B: canonical Person <-> Boralog account link through organization membership.
-- Identity link only: no direct Auth/Profile FK and no new self-access policy.

alter table public.people
  add column organization_membership_id uuid
    references public.organization_memberships(id)
    on delete set null;

create unique index people_organization_membership_uidx
  on public.people(organization_membership_id)
  where organization_membership_id is not null;

create or replace function private.boralog_people_membership_consistency()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_membership_organization_id uuid;
begin
  if new.organization_membership_id is null then
    return new;
  end if;

  select m.organization_id
    into v_membership_organization_id
  from public.organization_memberships as m
  where m.id = new.organization_membership_id;

  if v_membership_organization_id is null
     or v_membership_organization_id <> new.organization_id then
    raise exception 'person and organization membership must belong to same organization'
      using errcode = '23514';
  end if;

  return new;
end
$$;

alter function private.boralog_people_membership_consistency() owner to postgres;
revoke all on function private.boralog_people_membership_consistency()
  from public, anon, authenticated, service_role;

create trigger boralog_people_membership_consistency
before insert or update of organization_id, organization_membership_id
on public.people
for each row
execute function private.boralog_people_membership_consistency();
