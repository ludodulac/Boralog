-- BORALOG-167A People foundation tests.
-- Self-contained fixtures; every write is rolled back.

begin;

create temporary table _boralog_167a_results (
  test text primary key,
  pass boolean not null,
  detail text
) on commit drop;
grant select, insert on _boralog_167a_results to authenticated;

insert into auth.users (
  id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('167a0000-0000-4000-8000-000000000001','authenticated','authenticated','owner-a-167a@example.invalid','{}','{}',now(),now()),
  ('167a0000-0000-4000-8000-000000000002','authenticated','authenticated','full-a-167a@example.invalid','{}','{}',now(),now()),
  ('167a0000-0000-4000-8000-000000000003','authenticated','authenticated','limited-a-167a@example.invalid','{}','{}',now(),now()),
  ('167a0000-0000-4000-8000-000000000004','authenticated','authenticated','owner-b-167a@example.invalid','{}','{}',now(),now());

-- OWNER A creates two Structures so immutable organization_id can be tested
-- even when the actor has access to source and target Structures.
set local role authenticated;
select set_config('request.jwt.claim.sub','167a0000-0000-4000-8000-000000000001',true);

insert into public.organizations(id,name,slug,created_by) values
  ('167a1000-0000-4000-8000-000000000001','Structure A 167A','structure-a-167a','167a0000-0000-4000-8000-000000000001'),
  ('167a1000-0000-4000-8000-000000000002','Structure A2 167A','structure-a2-167a','167a0000-0000-4000-8000-000000000001');

insert into public.organization_memberships(
  organization_id,user_id,status,access_level
) values
  ('167a1000-0000-4000-8000-000000000001','167a0000-0000-4000-8000-000000000002','active','full'),
  ('167a1000-0000-4000-8000-000000000001','167a0000-0000-4000-8000-000000000003','active','limited');

-- OWNER B creates an independent Structure.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','167a0000-0000-4000-8000-000000000004',true);

insert into public.organizations(id,name,slug,created_by) values (
  '167a1000-0000-4000-8000-000000000003',
  'Structure B 167A',
  'structure-b-167a',
  '167a0000-0000-4000-8000-000000000004'
);

-- 1. OWNER creates a Person.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','167a0000-0000-4000-8000-000000000001',true);

insert into public.people(
  id, organization_id, name, role_label, professional_email, professional_phone, created_by
) values (
  '167a2000-0000-4000-8000-000000000001',
  '167a1000-0000-4000-8000-000000000001',
  'Alex Martin',
  'Architecte',
  'alex.martin@example.invalid',
  '+33 1 23 45 67 89',
  (select auth.uid())
);

insert into _boralog_167a_results
select
  'OWNER_CREATE',
  exists(
    select 1
    from public.people
    where id='167a2000-0000-4000-8000-000000000001'
      and created_by=(select auth.uid())
  ),
  '';

-- 2. FULL creates a Person.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','167a0000-0000-4000-8000-000000000002',true);

insert into public.people(
  id, organization_id, name, role_label, professional_email, professional_phone, created_by
) values (
  '167a2000-0000-4000-8000-000000000002',
  '167a1000-0000-4000-8000-000000000001',
  'Camille Durand',
  'Conductrice de travaux',
  'camille.durand@example.invalid',
  null,
  (select auth.uid())
);

insert into _boralog_167a_results
select
  'FULL_CREATE',
  exists(
    select 1
    from public.people
    where id='167a2000-0000-4000-8000-000000000002'
      and created_by=(select auth.uid())
  ),
  '';

-- 3-4. OWNER/FULL can read the People directory of their Structure.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','167a0000-0000-4000-8000-000000000001',true);

insert into _boralog_167a_results
select 'OWNER_READ', count(*)=2, 'count='||count(*)
from public.people
where organization_id='167a1000-0000-4000-8000-000000000001';

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','167a0000-0000-4000-8000-000000000002',true);

insert into _boralog_167a_results
select 'FULL_READ', count(*)=2, 'count='||count(*)
from public.people
where organization_id='167a1000-0000-4000-8000-000000000001';

-- 5. OWNER can modify all mutable business fields.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','167a0000-0000-4000-8000-000000000001',true);

update public.people
set
  name='Alex Martin Updated',
  role_label='Architecte associé',
  professional_email='alex.updated@example.invalid',
  professional_phone='+33 2 98 00 00 00'
where id='167a2000-0000-4000-8000-000000000001';

insert into _boralog_167a_results
select
  'OWNER_UPDATE_BUSINESS_FIELDS',
  name='Alex Martin Updated'
    and role_label='Architecte associé'
    and professional_email='alex.updated@example.invalid'
    and professional_phone='+33 2 98 00 00 00',
  ''
from public.people
where id='167a2000-0000-4000-8000-000000000001';

-- 6. FULL can modify mutable business fields.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','167a0000-0000-4000-8000-000000000002',true);

update public.people
set
  name='Camille Durand Updated',
  role_label='Cheffe de projet',
  professional_email='camille.updated@example.invalid',
  professional_phone='+33 2 98 11 11 11'
where id='167a2000-0000-4000-8000-000000000002';

insert into _boralog_167a_results
select
  'FULL_UPDATE_BUSINESS_FIELDS',
  name='Camille Durand Updated'
    and role_label='Cheffe de projet'
    and professional_email='camille.updated@example.invalid'
    and professional_phone='+33 2 98 11 11 11',
  ''
from public.people
where id='167a2000-0000-4000-8000-000000000002';

-- 7. LIMITED cannot browse the general People directory.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','167a0000-0000-4000-8000-000000000003',true);

insert into _boralog_167a_results
select 'LIMITED_READ_DENIED', count(*)=0, 'count='||count(*)
from public.people
where organization_id='167a1000-0000-4000-8000-000000000001';

-- 8. LIMITED cannot create a Person.
do $$
declare
  denied boolean := false;
begin
  begin
    insert into public.people(id,organization_id,name,created_by) values (
      '167a2000-0000-4000-8000-000000000003',
      '167a1000-0000-4000-8000-000000000001',
      'Forbidden Limited Person',
      (select auth.uid())
    );
  exception when insufficient_privilege then
    denied := true;
  end;

  insert into _boralog_167a_results values ('LIMITED_CREATE_DENIED', denied, '');
end $$;

-- 9. A member of another Structure cannot read or modify Person A.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','167a0000-0000-4000-8000-000000000004',true);

do $$
declare
  seen bigint;
  changed bigint;
begin
  select count(*) into seen
  from public.people
  where id='167a2000-0000-4000-8000-000000000001';

  update public.people
  set name='FORBIDDEN CROSS ORG'
  where id='167a2000-0000-4000-8000-000000000001';
  get diagnostics changed = row_count;

  insert into _boralog_167a_results values (
    'CROSS_ORG_ISOLATION',
    seen=0 and changed=0,
    'seen='||seen||', changed='||changed
  );
end $$;

-- 10. created_by must match the authenticated actor on INSERT.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','167a0000-0000-4000-8000-000000000001',true);

do $$
declare
  denied boolean := false;
begin
  begin
    insert into public.people(id,organization_id,name,created_by) values (
      '167a2000-0000-4000-8000-000000000004',
      '167a1000-0000-4000-8000-000000000001',
      'Wrong Creator',
      '167a0000-0000-4000-8000-000000000002'
    );
  exception when insufficient_privilege then
    denied := true;
  end;

  insert into _boralog_167a_results values ('CREATED_BY_ACTOR_ENFORCED', denied, '');
end $$;

-- 11-14. Canonical identity/provenance fields are immutable.
do $$
declare
  denied boolean;
begin
  denied := false;
  begin
    update public.people
    set organization_id='167a1000-0000-4000-8000-000000000002'
    where id='167a2000-0000-4000-8000-000000000001';
  exception when others then
    if sqlerrm = 'immutable person identity/provenance' then denied := true; else raise; end if;
  end;
  insert into _boralog_167a_results values ('ORGANIZATION_ID_IMMUTABLE', denied, '');

  denied := false;
  begin
    update public.people
    set created_by='167a0000-0000-4000-8000-000000000002'
    where id='167a2000-0000-4000-8000-000000000001';
  exception when others then
    if sqlerrm = 'immutable person identity/provenance' then denied := true; else raise; end if;
  end;
  insert into _boralog_167a_results values ('CREATED_BY_IMMUTABLE', denied, '');

  denied := false;
  begin
    update public.people
    set id='167a2000-0000-4000-8000-000000000099'
    where id='167a2000-0000-4000-8000-000000000001';
  exception when others then
    if sqlerrm = 'immutable person identity/provenance' then denied := true; else raise; end if;
  end;
  insert into _boralog_167a_results values ('ID_IMMUTABLE', denied, '');

  denied := false;
  begin
    update public.people
    set created_at=created_at + interval '1 second'
    where id='167a2000-0000-4000-8000-000000000001';
  exception when others then
    if sqlerrm = 'immutable person identity/provenance' then denied := true; else raise; end if;
  end;
  insert into _boralog_167a_results values ('CREATED_AT_IMMUTABLE', denied, '');
end $$;

-- 15. Blank/whitespace-only names are rejected.
do $$
declare
  denied boolean := false;
begin
  begin
    insert into public.people(id,organization_id,name,created_by) values (
      '167a2000-0000-4000-8000-000000000005',
      '167a1000-0000-4000-8000-000000000001',
      '   ',
      (select auth.uid())
    );
  exception when check_violation then
    denied := true;
  end;

  insert into _boralog_167a_results values ('BLANK_NAME_DENIED', denied, '');
end $$;

-- 16. Duplicate names in the same Structure are deliberately allowed.
insert into public.people(id,organization_id,name,created_by) values
  (
    '167a2000-0000-4000-8000-000000000006',
    '167a1000-0000-4000-8000-000000000001',
    'Nom Identique',
    (select auth.uid())
  ),
  (
    '167a2000-0000-4000-8000-000000000007',
    '167a1000-0000-4000-8000-000000000001',
    'Nom Identique',
    (select auth.uid())
  );

insert into _boralog_167a_results
select
  'DUPLICATE_NAMES_ALLOWED',
  count(*)=2,
  'count='||count(*)
from public.people
where organization_id='167a1000-0000-4000-8000-000000000001'
  and name='Nom Identique';

-- 17-19. Coordinates are independently optional, including both absent.
insert into public.people(
  id,organization_id,name,professional_email,professional_phone,created_by
) values
  (
    '167a2000-0000-4000-8000-000000000008',
    '167a1000-0000-4000-8000-000000000001',
    'Sans Email',
    null,
    '+33 2 98 22 22 22',
    (select auth.uid())
  ),
  (
    '167a2000-0000-4000-8000-000000000009',
    '167a1000-0000-4000-8000-000000000001',
    'Sans Téléphone',
    'sans.telephone@example.invalid',
    null,
    (select auth.uid())
  ),
  (
    '167a2000-0000-4000-8000-000000000010',
    '167a1000-0000-4000-8000-000000000001',
    'Sans Coordonnées',
    null,
    null,
    (select auth.uid())
  );

insert into _boralog_167a_results
select
  'OPTIONAL_COORDINATES',
  count(*) filter (
    where id='167a2000-0000-4000-8000-000000000008'
      and professional_email is null
      and professional_phone is not null
  )=1
  and count(*) filter (
    where id='167a2000-0000-4000-8000-000000000009'
      and professional_email is not null
      and professional_phone is null
  )=1
  and count(*) filter (
    where id='167a2000-0000-4000-8000-000000000010'
      and professional_email is null
      and professional_phone is null
  )=1,
  ''
from public.people
where id in (
  '167a2000-0000-4000-8000-000000000008',
  '167a2000-0000-4000-8000-000000000009',
  '167a2000-0000-4000-8000-000000000010'
);

-- 20. No account-link field exists on public.people.
reset role;

insert into _boralog_167a_results
select
  'NO_ACCOUNT_LINK_FIELDS',
  count(*)=0,
  'count='||count(*)
from information_schema.columns
where table_schema='public'
  and table_name='people'
  and column_name in ('user_id','auth_user_id','profile_id','account_id');

-- 21. The only FK from people to auth.users is created_by.
insert into _boralog_167a_results
select
  'ONLY_CREATED_BY_REFERENCES_AUTH_USERS',
  count(*)=1 and bool_and(kcu.column_name='created_by'),
  string_agg(kcu.column_name, ',' order by kcu.column_name)
from information_schema.table_constraints tc
join information_schema.key_column_usage kcu
  on kcu.constraint_catalog=tc.constraint_catalog
 and kcu.constraint_schema=tc.constraint_schema
 and kcu.constraint_name=tc.constraint_name
join information_schema.constraint_column_usage ccu
  on ccu.constraint_catalog=tc.constraint_catalog
 and ccu.constraint_schema=tc.constraint_schema
 and ccu.constraint_name=tc.constraint_name
where tc.constraint_type='FOREIGN KEY'
  and tc.table_schema='public'
  and tc.table_name='people'
  and ccu.table_schema='auth'
  and ccu.table_name='users';

-- Structural indexes required by 167A.
insert into _boralog_167a_results
select
  'ORGANIZATION_ID_INDEX_PRESENT',
  exists(
    select 1
    from pg_indexes
    where schemaname='public'
      and tablename='people'
      and indexname='people_organization_idx'
  ),
  '';

insert into _boralog_167a_results
select
  'CREATED_BY_INDEX_PRESENT',
  exists(
    select 1
    from pg_indexes
    where schemaname='public'
      and tablename='people'
      and indexname='people_created_by_idx'
  ),
  '';

-- A Person can exist with no account representing that Person.
insert into _boralog_167a_results
select
  'PERSON_WITHOUT_ACCOUNT',
  exists(
    select 1
    from public.people
    where id='167a2000-0000-4000-8000-000000000010'
      and professional_email is null
      and professional_phone is null
  )
  and not exists(
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='people'
      and column_name in ('user_id','auth_user_id','profile_id','account_id')
  ),
  '';

do $$
begin
  if exists(select 1 from _boralog_167a_results where not pass) then
    raise exception 'BORALOG-167A People foundation test failed';
  end if;
end $$;

select test,pass,detail
from _boralog_167a_results
order by test;

rollback;
