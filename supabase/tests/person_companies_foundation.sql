-- BORALOG-168B Person <-> Company foundation tests.
-- Self-contained fixtures; every write is rolled back.

begin;

create temporary table _boralog_168b_results (
  test text primary key,
  pass boolean not null,
  detail text
) on commit drop;
grant select, insert on _boralog_168b_results to authenticated;

insert into auth.users (
  id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('168b0000-0000-4000-8000-000000000001','authenticated','authenticated','owner-a-168b@example.invalid','{}','{}',now(),now()),
  ('168b0000-0000-4000-8000-000000000002','authenticated','authenticated','full-a-168b@example.invalid','{}','{}',now(),now()),
  ('168b0000-0000-4000-8000-000000000003','authenticated','authenticated','limited-a-168b@example.invalid','{}','{}',now(),now()),
  ('168b0000-0000-4000-8000-000000000004','authenticated','authenticated','owner-b-168b@example.invalid','{}','{}',now(),now());

-- Structure A and memberships.
set local role authenticated;
select set_config('request.jwt.claim.sub','168b0000-0000-4000-8000-000000000001',true);

insert into public.organizations(id,name,slug,created_by) values (
  '168b1000-0000-4000-8000-000000000001',
  'Structure A 168B',
  'structure-a-168b',
  '168b0000-0000-4000-8000-000000000001'
);

insert into public.organization_memberships(
  organization_id,user_id,status,access_level
) values
  ('168b1000-0000-4000-8000-000000000001','168b0000-0000-4000-8000-000000000002','active','full'),
  ('168b1000-0000-4000-8000-000000000001','168b0000-0000-4000-8000-000000000003','active','limited');

-- Structure B.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','168b0000-0000-4000-8000-000000000004',true);

insert into public.organizations(id,name,slug,created_by) values (
  '168b1000-0000-4000-8000-000000000002',
  'Structure B 168B',
  'structure-b-168b',
  '168b0000-0000-4000-8000-000000000004'
);

-- Parent fixtures in Structure A.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','168b0000-0000-4000-8000-000000000001',true);

insert into public.people(id,organization_id,name,created_by) values
  ('168b2000-0000-4000-8000-000000000001','168b1000-0000-4000-8000-000000000001','Person A1',(select auth.uid())),
  ('168b2000-0000-4000-8000-000000000002','168b1000-0000-4000-8000-000000000001','Person A2',(select auth.uid())),
  ('168b2000-0000-4000-8000-000000000003','168b1000-0000-4000-8000-000000000001','Person A3',(select auth.uid())),
  ('168b2000-0000-4000-8000-000000000004','168b1000-0000-4000-8000-000000000001','Person A4',(select auth.uid())),
  ('168b2000-0000-4000-8000-000000000005','168b1000-0000-4000-8000-000000000001','Person Cascade',(select auth.uid())),
  ('168b2000-0000-4000-8000-000000000006','168b1000-0000-4000-8000-000000000001','Person Company Cascade',(select auth.uid()));

insert into public.companies(id,organization_id,name,created_by) values
  ('168b3000-0000-4000-8000-000000000001','168b1000-0000-4000-8000-000000000001','Company A1',auth.uid()),
  ('168b3000-0000-4000-8000-000000000002','168b1000-0000-4000-8000-000000000001','Company A2',auth.uid()),
  ('168b3000-0000-4000-8000-000000000003','168b1000-0000-4000-8000-000000000001','Company Cascade Person',auth.uid()),
  ('168b3000-0000-4000-8000-000000000004','168b1000-0000-4000-8000-000000000001','Company Cascade',auth.uid());

-- Parent fixtures in Structure B.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','168b0000-0000-4000-8000-000000000004',true);

insert into public.people(id,organization_id,name,created_by) values (
  '168b2000-0000-4000-8000-000000000101',
  '168b1000-0000-4000-8000-000000000002',
  'Person B1',
  (select auth.uid())
);

insert into public.companies(id,organization_id,name,created_by) values (
  '168b3000-0000-4000-8000-000000000101',
  '168b1000-0000-4000-8000-000000000002',
  'Company B1',
  auth.uid()
);

-- 1. OWNER associates a Person and Company in own Structure.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','168b0000-0000-4000-8000-000000000001',true);

insert into public.person_companies(person_id,company_id) values (
  '168b2000-0000-4000-8000-000000000001',
  '168b3000-0000-4000-8000-000000000001'
);

insert into _boralog_168b_results
select
  'OWNER_CREATE_LINK',
  exists(
    select 1 from public.person_companies
    where person_id='168b2000-0000-4000-8000-000000000001'
      and company_id='168b3000-0000-4000-8000-000000000001'
  ),
  '';

-- 2. FULL associates a Person and Company in own Structure.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','168b0000-0000-4000-8000-000000000002',true);

insert into public.person_companies(person_id,company_id) values (
  '168b2000-0000-4000-8000-000000000002',
  '168b3000-0000-4000-8000-000000000001'
);

insert into _boralog_168b_results
select
  'FULL_CREATE_LINK',
  exists(
    select 1 from public.person_companies
    where person_id='168b2000-0000-4000-8000-000000000002'
      and company_id='168b3000-0000-4000-8000-000000000001'
  ),
  '';

-- 3. OWNER reads associations of own Structure.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','168b0000-0000-4000-8000-000000000001',true);

insert into _boralog_168b_results
select
  'OWNER_READ_LINKS',
  count(*)=2,
  'count='||count(*)
from public.person_companies;

-- 4. FULL reads associations of own Structure.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','168b0000-0000-4000-8000-000000000002',true);

insert into _boralog_168b_results
select
  'FULL_READ_LINKS',
  count(*)=2,
  'count='||count(*)
from public.person_companies;

-- 5. LIMITED sees no general association directory.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','168b0000-0000-4000-8000-000000000003',true);

insert into _boralog_168b_results
select
  'LIMITED_READ_DENIED',
  count(*)=0,
  'count='||count(*)
from public.person_companies;

-- 6. LIMITED cannot create an association.
do $$
declare
  denied boolean := false;
begin
  begin
    insert into public.person_companies(person_id,company_id) values (
      '168b2000-0000-4000-8000-000000000003',
      '168b3000-0000-4000-8000-000000000002'
    );
  exception when insufficient_privilege then
    denied := true;
  end;

  insert into _boralog_168b_results values ('LIMITED_CREATE_DENIED', denied, '');
end $$;

-- 7. LIMITED cannot delete an association.
do $$
declare
  changed bigint;
begin
  delete from public.person_companies
  where person_id='168b2000-0000-4000-8000-000000000001'
    and company_id='168b3000-0000-4000-8000-000000000001';
  get diagnostics changed = row_count;

  insert into _boralog_168b_results values (
    'LIMITED_DELETE_DENIED',
    changed=0,
    'changed='||changed
  );
end $$;

-- 8-10. Another Structure cannot read/create/delete Structure A associations.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','168b0000-0000-4000-8000-000000000004',true);

insert into _boralog_168b_results
select
  'CROSS_ORG_READ_DENIED',
  count(*)=0,
  'count='||count(*)
from public.person_companies
where person_id='168b2000-0000-4000-8000-000000000001'
  and company_id='168b3000-0000-4000-8000-000000000001';

do $$
declare
  denied boolean := false;
  changed bigint;
begin
  begin
    insert into public.person_companies(person_id,company_id) values (
      '168b2000-0000-4000-8000-000000000003',
      '168b3000-0000-4000-8000-000000000002'
    );
  exception when insufficient_privilege then
    denied := true;
  end;
  insert into _boralog_168b_results values ('CROSS_ORG_CREATE_DENIED', denied, '');

  delete from public.person_companies
  where person_id='168b2000-0000-4000-8000-000000000001'
    and company_id='168b3000-0000-4000-8000-000000000001';
  get diagnostics changed = row_count;
  insert into _boralog_168b_results values (
    'CROSS_ORG_DELETE_DENIED',
    changed=0,
    'changed='||changed
  );
end $$;

-- 11. Person A + Company B is structurally rejected with 23514.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','168b0000-0000-4000-8000-000000000001',true);

do $$
declare
  denied boolean := false;
begin
  begin
    insert into public.person_companies(person_id,company_id) values (
      '168b2000-0000-4000-8000-000000000001',
      '168b3000-0000-4000-8000-000000000101'
    );
  exception when check_violation then
    denied := true;
  end;

  insert into _boralog_168b_results values ('SAME_ORGANIZATION_ENFORCED', denied, '');
end $$;

-- 12. Duplicate association is rejected by the composite PK.
do $$
declare
  denied boolean := false;
begin
  begin
    insert into public.person_companies(person_id,company_id) values (
      '168b2000-0000-4000-8000-000000000001',
      '168b3000-0000-4000-8000-000000000001'
    );
  exception when unique_violation then
    denied := true;
  end;

  insert into _boralog_168b_results values ('DUPLICATE_LINK_DENIED', denied, '');
end $$;

-- 13. One Person can belong to multiple Companies.
insert into public.person_companies(person_id,company_id) values (
  '168b2000-0000-4000-8000-000000000001',
  '168b3000-0000-4000-8000-000000000002'
);

insert into _boralog_168b_results
select
  'MULTI_COMPANY_PERSON',
  count(*)=2,
  'count='||count(*)
from public.person_companies
where person_id='168b2000-0000-4000-8000-000000000001';

-- 14. One Company can contain multiple People.
insert into public.person_companies(person_id,company_id) values (
  '168b2000-0000-4000-8000-000000000003',
  '168b3000-0000-4000-8000-000000000001'
);

insert into _boralog_168b_results
select
  'MULTI_PERSON_COMPANY',
  count(*)=3,
  'count='||count(*)
from public.person_companies
where company_id='168b3000-0000-4000-8000-000000000001';

-- 15,17,18. OWNER deletes only a link; both parents remain.
delete from public.person_companies
where person_id='168b2000-0000-4000-8000-000000000003'
  and company_id='168b3000-0000-4000-8000-000000000001';

insert into _boralog_168b_results
select
  'OWNER_DELETE_LINK_ONLY',
  not exists(
    select 1 from public.person_companies
    where person_id='168b2000-0000-4000-8000-000000000003'
      and company_id='168b3000-0000-4000-8000-000000000001'
  ),
  '';

insert into _boralog_168b_results
select
  'PERSON_SURVIVES_LINK_DELETE',
  exists(
    select 1 from public.people
    where id='168b2000-0000-4000-8000-000000000003'
  ),
  '';

insert into _boralog_168b_results
select
  'COMPANY_SURVIVES_LINK_DELETE',
  exists(
    select 1 from public.companies
    where id='168b3000-0000-4000-8000-000000000001'
  ),
  '';

-- 16. FULL can delete only a link.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','168b0000-0000-4000-8000-000000000002',true);

insert into public.person_companies(person_id,company_id) values (
  '168b2000-0000-4000-8000-000000000004',
  '168b3000-0000-4000-8000-000000000002'
);

delete from public.person_companies
where person_id='168b2000-0000-4000-8000-000000000004'
  and company_id='168b3000-0000-4000-8000-000000000002';

insert into _boralog_168b_results
select
  'FULL_DELETE_LINK_ONLY',
  not exists(
    select 1 from public.person_companies
    where person_id='168b2000-0000-4000-8000-000000000004'
      and company_id='168b3000-0000-4000-8000-000000000002'
  )
  and exists(
    select 1 from public.people
    where id='168b2000-0000-4000-8000-000000000004'
  )
  and exists(
    select 1 from public.companies
    where id='168b3000-0000-4000-8000-000000000002'
  ),
  '';

-- Prepare technical cascade fixtures as OWNER.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','168b0000-0000-4000-8000-000000000001',true);

insert into public.person_companies(person_id,company_id) values
  (
    '168b2000-0000-4000-8000-000000000005',
    '168b3000-0000-4000-8000-000000000003'
  ),
  (
    '168b2000-0000-4000-8000-000000000006',
    '168b3000-0000-4000-8000-000000000004'
  );

-- 19-29. Structural checks and privileged cascade checks.
reset role;

-- 19. Privileged technical deletion of a Person cascades only its links.
delete from public.people
where id='168b2000-0000-4000-8000-000000000005';

insert into _boralog_168b_results
select
  'CASCADE_FROM_PERSON',
  not exists(
    select 1 from public.person_companies
    where person_id='168b2000-0000-4000-8000-000000000005'
  )
  and exists(
    select 1 from public.companies
    where id='168b3000-0000-4000-8000-000000000003'
  ),
  '';

-- 20. Privileged technical deletion of a Company cascades only its links.
delete from public.companies
where id='168b3000-0000-4000-8000-000000000004';

insert into _boralog_168b_results
select
  'CASCADE_FROM_COMPANY',
  not exists(
    select 1 from public.person_companies
    where company_id='168b3000-0000-4000-8000-000000000004'
  )
  and exists(
    select 1 from public.people
    where id='168b2000-0000-4000-8000-000000000006'
  ),
  '';

-- 21-23. Parent DELETE remains denied; relation UPDATE is not granted.
insert into _boralog_168b_results values (
  'PEOPLE_DELETE_STILL_DENIED',
  not has_table_privilege('authenticated','public.people','DELETE'),
  ''
);

insert into _boralog_168b_results values (
  'COMPANIES_DELETE_STILL_DENIED',
  not has_table_privilege('authenticated','public.companies','DELETE'),
  ''
);

insert into _boralog_168b_results
select
  'PERSON_COMPANIES_UPDATE_DENIED',
  not has_table_privilege('authenticated','public.person_companies','UPDATE')
    and not exists(
      select 1
      from pg_policies
      where schemaname='public'
        and tablename='person_companies'
        and cmd='UPDATE'
    ),
  '';

-- 24. Exact three-column structure.
insert into _boralog_168b_results
select
  'COLUMNS_EXACT',
  count(*)=3
    and array_agg(column_name::text order by ordinal_position)
        = array['person_id','company_id','created_at']::text[],
  coalesce(string_agg(column_name, ',' order by ordinal_position),'')
from information_schema.columns
where table_schema='public'
  and table_name='person_companies';

-- 25. No speculative or account/access fields.
insert into _boralog_168b_results
select
  'FORBIDDEN_COLUMNS_ABSENT',
  count(*)=0,
  'count='||count(*)
from information_schema.columns
where table_schema='public'
  and table_name='person_companies'
  and column_name in (
    'id','organization_id','created_by','role','role_label','function','status',
    'is_primary','user_id','auth_user_id','profile_id','account_id','invitation_id'
  );

-- 26. Exact composite primary key (person_id, company_id).
insert into _boralog_168b_results
select
  'COMPOSITE_PRIMARY_KEY',
  exists(
    select 1
    from (
      select
        con.oid,
        array_agg(att.attname::text order by key.ordinality) as columns
      from pg_constraint as con
      cross join lateral unnest(con.conkey) with ordinality as key(attnum, ordinality)
      join pg_attribute as att
        on att.attrelid=con.conrelid
       and att.attnum=key.attnum
      where con.contype='p'
        and con.conrelid='public.person_companies'::regclass
      group by con.oid
    ) as pk
    where pk.columns=array['person_id','company_id']::text[]
  ),
  '';

-- 27. Reverse index (company_id, person_id) is present.
insert into _boralog_168b_results
select
  'REVERSE_INDEX_PRESENT',
  exists(
    select 1
    from pg_indexes
    where schemaname='public'
      and tablename='person_companies'
      and indexname='person_companies_company_person_idx'
      and indexdef like '%(company_id, person_id)%'
  ),
  '';

-- 28. Coherence trigger is present.
insert into _boralog_168b_results
select
  'CONSISTENCY_TRIGGER_PRESENT',
  exists(
    select 1
    from pg_trigger
    where tgrelid='public.person_companies'::regclass
      and tgname='boralog_person_company_consistency'
      and not tgisinternal
  ),
  '';

-- 29. RLS is enabled.
insert into _boralog_168b_results
select
  'RLS_ENABLED',
  relrowsecurity,
  ''
from pg_class
where oid='public.person_companies'::regclass;

do $$
begin
  if exists(select 1 from _boralog_168b_results where not pass) then
    raise exception 'BORALOG-168B Person-Company foundation test failed';
  end if;
end $$;

select test,pass,detail
from _boralog_168b_results
order by test;

rollback;
