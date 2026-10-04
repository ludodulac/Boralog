-- BORALOG-166B Companies foundation tests.
-- Self-contained fixtures; every write is rolled back.

begin;

create temporary table _boralog_166b_results (
  test text primary key,
  pass boolean not null,
  detail text
) on commit drop;
grant select, insert on _boralog_166b_results to authenticated;

insert into auth.users (
  id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('166b0000-0000-4000-8000-000000000001','authenticated','authenticated','owner-a-166b@example.invalid','{}','{}',now(),now()),
  ('166b0000-0000-4000-8000-000000000002','authenticated','authenticated','full-a-166b@example.invalid','{}','{}',now(),now()),
  ('166b0000-0000-4000-8000-000000000003','authenticated','authenticated','limited-a-166b@example.invalid','{}','{}',now(),now()),
  ('166b0000-0000-4000-8000-000000000004','authenticated','authenticated','owner-b-166b@example.invalid','{}','{}',now(),now());

-- OWNER A creates two Structures so organization_id immutability can be tested
-- even when the actor is authorized in both source and target Structures.
set local role authenticated;
select set_config('request.jwt.claim.sub','166b0000-0000-4000-8000-000000000001',true);

insert into public.organizations(id,name,slug,created_by) values
  ('166b1000-0000-4000-8000-000000000001','Structure A 166B','structure-a-166b','166b0000-0000-4000-8000-000000000001'),
  ('166b1000-0000-4000-8000-000000000002','Structure A2 166B','structure-a2-166b','166b0000-0000-4000-8000-000000000001');

insert into public.organization_memberships(
  organization_id,user_id,status,access_level
) values
  ('166b1000-0000-4000-8000-000000000001','166b0000-0000-4000-8000-000000000002','active','full'),
  ('166b1000-0000-4000-8000-000000000001','166b0000-0000-4000-8000-000000000003','active','limited');

-- OWNER B creates an independent Structure.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','166b0000-0000-4000-8000-000000000004',true);

insert into public.organizations(id,name,slug,created_by) values (
  '166b1000-0000-4000-8000-000000000003',
  'Structure B 166B',
  'structure-b-166b',
  '166b0000-0000-4000-8000-000000000004'
);

-- 1. OWNER can create a Company in own Structure.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','166b0000-0000-4000-8000-000000000001',true);

insert into public.companies(id,organization_id,name,created_by) values (
  '166b2000-0000-4000-8000-000000000001',
  '166b1000-0000-4000-8000-000000000001',
  'Compagnie Alpha',
  auth.uid()
);

insert into _boralog_166b_results
select
  'OWNER_CREATE',
  exists(
    select 1 from public.companies
    where id='166b2000-0000-4000-8000-000000000001'
      and created_by=auth.uid()
  ),
  '';

-- 2. FULL can create a Company in own Structure.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','166b0000-0000-4000-8000-000000000002',true);

insert into public.companies(id,organization_id,name,created_by) values (
  '166b2000-0000-4000-8000-000000000002',
  '166b1000-0000-4000-8000-000000000001',
  'Compagnie Beta',
  auth.uid()
);

insert into _boralog_166b_results
select
  'FULL_CREATE',
  exists(
    select 1 from public.companies
    where id='166b2000-0000-4000-8000-000000000002'
      and created_by=auth.uid()
  ),
  '';

-- 3. OWNER/FULL can read Companies in their Structure.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','166b0000-0000-4000-8000-000000000001',true);

insert into _boralog_166b_results
select 'OWNER_READ', count(*)=2, 'count='||count(*)
from public.companies
where organization_id='166b1000-0000-4000-8000-000000000001';

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','166b0000-0000-4000-8000-000000000002',true);

insert into _boralog_166b_results
select 'FULL_READ', count(*)=2, 'count='||count(*)
from public.companies
where organization_id='166b1000-0000-4000-8000-000000000001';

-- 4. OWNER/FULL can modify Company names.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','166b0000-0000-4000-8000-000000000001',true);

update public.companies
set name='Compagnie Alpha Owner'
where id='166b2000-0000-4000-8000-000000000001';

insert into _boralog_166b_results
select
  'OWNER_UPDATE_NAME',
  name='Compagnie Alpha Owner',
  name
from public.companies
where id='166b2000-0000-4000-8000-000000000001';

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','166b0000-0000-4000-8000-000000000002',true);

update public.companies
set name='Compagnie Beta Full'
where id='166b2000-0000-4000-8000-000000000002';

insert into _boralog_166b_results
select
  'FULL_UPDATE_NAME',
  name='Compagnie Beta Full',
  name
from public.companies
where id='166b2000-0000-4000-8000-000000000002';

-- 5. LIMITED cannot browse the general Company directory.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','166b0000-0000-4000-8000-000000000003',true);

insert into _boralog_166b_results
select 'LIMITED_READ_DENIED', count(*)=0, 'count='||count(*)
from public.companies
where organization_id='166b1000-0000-4000-8000-000000000001';

-- 6. LIMITED cannot create a Company.
do $$
declare
  denied boolean := false;
begin
  begin
    insert into public.companies(id,organization_id,name,created_by) values (
      '166b2000-0000-4000-8000-000000000003',
      '166b1000-0000-4000-8000-000000000001',
      'Forbidden Limited Company',
      auth.uid()
    );
  exception when insufficient_privilege then
    denied := true;
  end;

  insert into _boralog_166b_results values ('LIMITED_CREATE_DENIED', denied, '');
end $$;

-- 7. Another Structure member cannot read or modify Company A.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','166b0000-0000-4000-8000-000000000004',true);

do $$
declare
  seen bigint;
  changed bigint;
begin
  select count(*) into seen
  from public.companies
  where id='166b2000-0000-4000-8000-000000000001';

  update public.companies
  set name='FORBIDDEN CROSS ORG'
  where id='166b2000-0000-4000-8000-000000000001';
  get diagnostics changed = row_count;

  insert into _boralog_166b_results values (
    'CROSS_ORG_ISOLATION',
    seen=0 and changed=0,
    'seen='||seen||', changed='||changed
  );
end $$;

-- 8. created_by must equal the authenticated actor at creation.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','166b0000-0000-4000-8000-000000000001',true);

do $$
declare
  denied boolean := false;
begin
  begin
    insert into public.companies(id,organization_id,name,created_by) values (
      '166b2000-0000-4000-8000-000000000004',
      '166b1000-0000-4000-8000-000000000001',
      'Wrong Creator',
      '166b0000-0000-4000-8000-000000000002'
    );
  exception when insufficient_privilege then
    denied := true;
  end;

  insert into _boralog_166b_results values ('CREATED_BY_ACTOR_ENFORCED', denied, '');
end $$;

-- 9-11. Canonical identity/provenance fields are immutable.
do $$
declare
  denied boolean;
begin
  denied := false;
  begin
    update public.companies
    set organization_id='166b1000-0000-4000-8000-000000000002'
    where id='166b2000-0000-4000-8000-000000000001';
  exception when others then
    if sqlerrm = 'immutable company identity/provenance' then denied := true; else raise; end if;
  end;
  insert into _boralog_166b_results values ('ORGANIZATION_ID_IMMUTABLE', denied, '');

  denied := false;
  begin
    update public.companies
    set created_by='166b0000-0000-4000-8000-000000000002'
    where id='166b2000-0000-4000-8000-000000000001';
  exception when others then
    if sqlerrm = 'immutable company identity/provenance' then denied := true; else raise; end if;
  end;
  insert into _boralog_166b_results values ('CREATED_BY_IMMUTABLE', denied, '');

  denied := false;
  begin
    update public.companies
    set id='166b2000-0000-4000-8000-000000000099'
    where id='166b2000-0000-4000-8000-000000000001';
  exception when others then
    if sqlerrm = 'immutable company identity/provenance' then denied := true; else raise; end if;
  end;
  insert into _boralog_166b_results values ('ID_IMMUTABLE', denied, '');

  denied := false;
  begin
    update public.companies
    set created_at=created_at + interval '1 second'
    where id='166b2000-0000-4000-8000-000000000001';
  exception when others then
    if sqlerrm = 'immutable company identity/provenance' then denied := true; else raise; end if;
  end;
  insert into _boralog_166b_results values ('CREATED_AT_IMMUTABLE', denied, '');
end $$;

-- 12. Blank/whitespace-only names are rejected.
do $$
declare
  denied boolean := false;
begin
  begin
    insert into public.companies(id,organization_id,name,created_by) values (
      '166b2000-0000-4000-8000-000000000005',
      '166b1000-0000-4000-8000-000000000001',
      '   ',
      auth.uid()
    );
  exception when check_violation then
    denied := true;
  end;

  insert into _boralog_166b_results values ('BLANK_NAME_DENIED', denied, '');
end $$;

-- 13. Case/whitespace-equivalent duplicates are rejected in one Structure.
do $$
declare
  denied boolean := false;
begin
  begin
    insert into public.companies(id,organization_id,name,created_by) values (
      '166b2000-0000-4000-8000-000000000006',
      '166b1000-0000-4000-8000-000000000001',
      '  compagnie    alpha owner  ',
      auth.uid()
    );
  exception when unique_violation then
    denied := true;
  end;

  insert into _boralog_166b_results values ('NORMALIZED_DUPLICATE_DENIED', denied, '');
end $$;

-- 14. The same normalized name is allowed in a different Structure.
insert into public.companies(id,organization_id,name,created_by) values (
  '166b2000-0000-4000-8000-000000000007',
  '166b1000-0000-4000-8000-000000000002',
  'Compagnie Alpha Owner',
  auth.uid()
);

insert into _boralog_166b_results
select
  'SAME_NAME_OTHER_ORG_ALLOWED',
  exists(
    select 1 from public.companies
    where id='166b2000-0000-4000-8000-000000000007'
      and organization_id='166b1000-0000-4000-8000-000000000002'
  ),
  '';

reset role;

do $$
begin
  if exists(select 1 from _boralog_166b_results where not pass) then
    raise exception 'BORALOG-166B Companies foundation test failed';
  end if;
end $$;

select test,pass,detail
from _boralog_166b_results
order by test;

rollback;
