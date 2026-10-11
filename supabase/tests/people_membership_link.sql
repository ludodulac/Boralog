-- BORALOG-169B People <-> Boralog account link tests.
-- Self-contained fixtures; every write is rolled back.

begin;

create temporary table _boralog_169b_results (
  test text primary key,
  pass boolean not null,
  detail text
) on commit drop;
grant select, insert on _boralog_169b_results to authenticated;

insert into auth.users (
  id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('169b0000-0000-4000-8000-000000000001','authenticated','authenticated','owner-a-169b@example.invalid','{}','{}',now(),now()),
  ('169b0000-0000-4000-8000-000000000002','authenticated','authenticated','full-a-169b@example.invalid','{}','{}',now(),now()),
  ('169b0000-0000-4000-8000-000000000003','authenticated','authenticated','limited-a-169b@example.invalid','{}','{}',now(),now()),
  ('169b0000-0000-4000-8000-000000000004','authenticated','authenticated','owner-b-169b@example.invalid','{}','{}',now(),now()),
  ('169b0000-0000-4000-8000-000000000005','authenticated','authenticated','common-169b@example.invalid','{}','{}',now(),now()),
  ('169b0000-0000-4000-8000-000000000006','authenticated','authenticated','invited-169b@example.invalid','{}','{}',now(),now()),
  ('169b0000-0000-4000-8000-000000000007','authenticated','authenticated','suspended-169b@example.invalid','{}','{}',now(),now()),
  ('169b0000-0000-4000-8000-000000000008','authenticated','authenticated','membership-delete-169b@example.invalid','{}','{}',now(),now()),
  ('169b0000-0000-4000-8000-000000000009','authenticated','authenticated','created-by-lock-169b@example.invalid','{}','{}',now(),now()),
  ('169b0000-0000-4000-8000-000000000010','authenticated','authenticated','auth-delete-169b@example.invalid','{}','{}',now(),now());

-- Structure A.
set local role authenticated;
select set_config('request.jwt.claim.sub','169b0000-0000-4000-8000-000000000001',true);

insert into public.organizations(id,name,slug,created_by) values (
  '169b1000-0000-4000-8000-000000000001',
  'Structure A 169B',
  'structure-a-169b',
  '169b0000-0000-4000-8000-000000000001'
);

insert into public.organization_memberships(
  id, organization_id, user_id, status, access_level
) values
  ('169b1100-0000-4000-8000-000000000002','169b1000-0000-4000-8000-000000000001','169b0000-0000-4000-8000-000000000002','active','full'),
  ('169b1100-0000-4000-8000-000000000003','169b1000-0000-4000-8000-000000000001','169b0000-0000-4000-8000-000000000003','active','limited'),
  ('169b1100-0000-4000-8000-000000000005','169b1000-0000-4000-8000-000000000001','169b0000-0000-4000-8000-000000000005','active','limited'),
  ('169b1100-0000-4000-8000-000000000006','169b1000-0000-4000-8000-000000000001','169b0000-0000-4000-8000-000000000006','invited','limited'),
  ('169b1100-0000-4000-8000-000000000007','169b1000-0000-4000-8000-000000000001','169b0000-0000-4000-8000-000000000007','suspended','limited'),
  ('169b1100-0000-4000-8000-000000000008','169b1000-0000-4000-8000-000000000001','169b0000-0000-4000-8000-000000000008','active','limited'),
  ('169b1100-0000-4000-8000-000000000010','169b1000-0000-4000-8000-000000000001','169b0000-0000-4000-8000-000000000010','active','limited');

-- Structure B and the same account's second membership.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','169b0000-0000-4000-8000-000000000004',true);

insert into public.organizations(id,name,slug,created_by) values (
  '169b1000-0000-4000-8000-000000000002',
  'Structure B 169B',
  'structure-b-169b',
  '169b0000-0000-4000-8000-000000000004'
);

insert into public.organization_memberships(
  id, organization_id, user_id, status, access_level
) values (
  '169b1100-0000-4000-8000-000000000105',
  '169b1000-0000-4000-8000-000000000002',
  '169b0000-0000-4000-8000-000000000005',
  'active',
  'limited'
);

-- People in Structure A, initially unlinked.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','169b0000-0000-4000-8000-000000000001',true);

insert into public.people(id,organization_id,name,created_by) values
  ('169b2000-0000-4000-8000-000000000001','169b1000-0000-4000-8000-000000000001','Unlinked Person',(select auth.uid())),
  ('169b2000-0000-4000-8000-000000000002','169b1000-0000-4000-8000-000000000001','Common Account Person A',(select auth.uid())),
  ('169b2000-0000-4000-8000-000000000003','169b1000-0000-4000-8000-000000000001','Full Linked Person',(select auth.uid())),
  ('169b2000-0000-4000-8000-000000000004','169b1000-0000-4000-8000-000000000001','Invited Linked Person',(select auth.uid())),
  ('169b2000-0000-4000-8000-000000000005','169b1000-0000-4000-8000-000000000001','Suspended Linked Person',(select auth.uid())),
  ('169b2000-0000-4000-8000-000000000006','169b1000-0000-4000-8000-000000000001','Replaceable Link Person',(select auth.uid())),
  ('169b2000-0000-4000-8000-000000000007','169b1000-0000-4000-8000-000000000001','Membership Delete Person',(select auth.uid())),
  ('169b2000-0000-4000-8000-000000000008','169b1000-0000-4000-8000-000000000001','Auth Delete Person',(select auth.uid())),
  ('169b2000-0000-4000-8000-000000000009','169b1000-0000-4000-8000-000000000001','Duplicate Candidate',(select auth.uid()));

-- Person in Structure B for the same Auth account.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','169b0000-0000-4000-8000-000000000004',true);

insert into public.people(id,organization_id,name,created_by) values (
  '169b2000-0000-4000-8000-000000000105',
  '169b1000-0000-4000-8000-000000000002',
  'Common Account Person B',
  (select auth.uid())
);

-- A pre-existing created_by provenance fixture, intentionally with no membership.
reset role;
insert into public.people(id,organization_id,name,created_by) values (
  '169b2000-0000-4000-8000-000000000109',
  '169b1000-0000-4000-8000-000000000001',
  'Created By Lock Person',
  '169b0000-0000-4000-8000-000000000009'
);

-- 1. Person without a link remains valid.
insert into _boralog_169b_results
select
  'UNLINKED_PERSON_VALID',
  organization_membership_id is null,
  ''
from public.people
where id='169b2000-0000-4000-8000-000000000001';

-- 2. OWNER links a Person to an active membership in the same Structure.
set local role authenticated;
select set_config('request.jwt.claim.sub','169b0000-0000-4000-8000-000000000001',true);

update public.people
set organization_membership_id='169b1100-0000-4000-8000-000000000005'
where id='169b2000-0000-4000-8000-000000000002';

insert into _boralog_169b_results
select
  'OWNER_LINK',
  organization_membership_id='169b1100-0000-4000-8000-000000000005',
  ''
from public.people
where id='169b2000-0000-4000-8000-000000000002';

-- 3. FULL links a Person using the existing People UPDATE model.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','169b0000-0000-4000-8000-000000000002',true);

update public.people
set organization_membership_id='169b1100-0000-4000-8000-000000000002'
where id='169b2000-0000-4000-8000-000000000003';

insert into _boralog_169b_results
select
  'FULL_LINK',
  organization_membership_id='169b1100-0000-4000-8000-000000000002',
  ''
from public.people
where id='169b2000-0000-4000-8000-000000000003';

-- 4-5. OWNER/FULL see the link.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','169b0000-0000-4000-8000-000000000001',true);
insert into _boralog_169b_results
select 'OWNER_SEES_LINK', count(*)=1, 'count='||count(*)
from public.people
where id='169b2000-0000-4000-8000-000000000002'
  and organization_membership_id='169b1100-0000-4000-8000-000000000005';

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','169b0000-0000-4000-8000-000000000002',true);
insert into _boralog_169b_results
select 'FULL_SEES_LINK', count(*)=1, 'count='||count(*)
from public.people
where id='169b2000-0000-4000-8000-000000000003'
  and organization_membership_id='169b1100-0000-4000-8000-000000000002';

-- 6-8. LIMITED gets no general People access and cannot establish/remove links.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','169b0000-0000-4000-8000-000000000003',true);

insert into _boralog_169b_results
select 'LIMITED_PEOPLE_ACCESS_UNCHANGED', count(*)=0, 'count='||count(*)
from public.people
where organization_id='169b1000-0000-4000-8000-000000000001';

do $$
declare
  changed bigint := 0;
begin
  begin
    update public.people
    set organization_membership_id='169b1100-0000-4000-8000-000000000003'
    where id='169b2000-0000-4000-8000-000000000001';
    get diagnostics changed = row_count;
  exception when insufficient_privilege then
    changed := 0;
  end;
  insert into _boralog_169b_results values ('LIMITED_LINK_DENIED', changed=0, 'changed='||changed);
end $$;

do $$
declare
  changed bigint := 0;
begin
  begin
    update public.people
    set organization_membership_id=null
    where id='169b2000-0000-4000-8000-000000000002';
    get diagnostics changed = row_count;
  exception when insufficient_privilege then
    changed := 0;
  end;
  insert into _boralog_169b_results values ('LIMITED_UNLINK_DENIED', changed=0, 'changed='||changed);
end $$;

-- 9. Cross-Structure membership is rejected with 23514.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','169b0000-0000-4000-8000-000000000001',true);

do $$
declare
  denied boolean := false;
begin
  begin
    update public.people
    set organization_membership_id='169b1100-0000-4000-8000-000000000105'
    where id='169b2000-0000-4000-8000-000000000001';
  exception when check_violation then
    denied := true;
  end;
  insert into _boralog_169b_results values ('CROSS_ORG_LINK_DENIED', denied, '');
end $$;

-- 10. Missing membership is structurally rejected.
do $$
declare
  denied boolean := false;
begin
  begin
    update public.people
    set organization_membership_id='169b1100-0000-4000-8000-000000009999'
    where id='169b2000-0000-4000-8000-000000000001';
  exception when check_violation then
    denied := true;
  end;
  insert into _boralog_169b_results values ('MISSING_MEMBERSHIP_DENIED', denied, '');
end $$;

-- 11. Active membership link already proven by OWNER_LINK.
insert into _boralog_169b_results
select
  'ACTIVE_LINK_ALLOWED',
  p.organization_membership_id=m.id and m.status='active'::public.membership_status,
  ''
from public.people p
join public.organization_memberships m on m.id=p.organization_membership_id
where p.id='169b2000-0000-4000-8000-000000000002';

-- 12. Invited membership can be linked.
update public.people
set organization_membership_id='169b1100-0000-4000-8000-000000000006'
where id='169b2000-0000-4000-8000-000000000004';

insert into _boralog_169b_results
select
  'INVITED_LINK_ALLOWED',
  p.organization_membership_id=m.id and m.status='invited'::public.membership_status,
  ''
from public.people p
join public.organization_memberships m on m.id=p.organization_membership_id
where p.id='169b2000-0000-4000-8000-000000000004';

-- 13. Suspended membership can be linked.
update public.people
set organization_membership_id='169b1100-0000-4000-8000-000000000007'
where id='169b2000-0000-4000-8000-000000000005';

insert into _boralog_169b_results
select
  'SUSPENDED_LINK_ALLOWED',
  p.organization_membership_id=m.id and m.status='suspended'::public.membership_status,
  ''
from public.people p
join public.organization_memberships m on m.id=p.organization_membership_id
where p.id='169b2000-0000-4000-8000-000000000005';

-- 14. active -> suspended preserves the identity link.
update public.organization_memberships
set status='suspended'
where id='169b1100-0000-4000-8000-000000000005';

insert into _boralog_169b_results
select
  'SUSPENSION_PRESERVES_LINK',
  organization_membership_id='169b1100-0000-4000-8000-000000000005',
  ''
from public.people
where id='169b2000-0000-4000-8000-000000000002';

-- 15. Suspended membership provides no active org access to the linked account.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','169b0000-0000-4000-8000-000000000005',true);

insert into _boralog_169b_results values (
  'SUSPENDED_HAS_NO_ACTIVE_ACCESS',
  private.boralog_org_access('169b1000-0000-4000-8000-000000000001') is null,
  ''
);

-- 16. Reactivation preserves the link.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','169b0000-0000-4000-8000-000000000001',true);

update public.organization_memberships
set status='active'
where id='169b1100-0000-4000-8000-000000000005';

insert into _boralog_169b_results
select
  'REACTIVATION_PRESERVES_LINK',
  organization_membership_id='169b1100-0000-4000-8000-000000000005',
  ''
from public.people
where id='169b2000-0000-4000-8000-000000000002';

-- 17-18. Removing a membership nulls the link and preserves the Person.
update public.people
set organization_membership_id='169b1100-0000-4000-8000-000000000008'
where id='169b2000-0000-4000-8000-000000000007';

delete from public.organization_memberships
where id='169b1100-0000-4000-8000-000000000008';

insert into _boralog_169b_results
select
  'MEMBERSHIP_DELETE_NULLS_LINK',
  organization_membership_id is null,
  ''
from public.people
where id='169b2000-0000-4000-8000-000000000007';

insert into _boralog_169b_results
select
  'PERSON_SURVIVES_MEMBERSHIP_DELETE',
  exists(select 1 from public.people where id='169b2000-0000-4000-8000-000000000007'),
  '';

-- 19. One membership cannot represent two People.
do $$
declare
  denied boolean := false;
begin
  begin
    update public.people
    set organization_membership_id='169b1100-0000-4000-8000-000000000005'
    where id='169b2000-0000-4000-8000-000000000009';
  exception when unique_violation then
    denied := true;
  end;
  insert into _boralog_169b_results values ('MEMBERSHIP_UNIQUE_TO_PERSON', denied, '');
end $$;

-- 20-22. Scalar link can be replaced and explicitly cleared.
update public.people
set organization_membership_id='169b1100-0000-4000-8000-000000000003'
where id='169b2000-0000-4000-8000-000000000006';

insert into _boralog_169b_results
select
  'PERSON_HAS_SINGLE_LINK',
  organization_membership_id='169b1100-0000-4000-8000-000000000003',
  ''
from public.people
where id='169b2000-0000-4000-8000-000000000006';

update public.people
set organization_membership_id=(
  select id
  from public.organization_memberships
  where organization_id='169b1000-0000-4000-8000-000000000001'
    and user_id='169b0000-0000-4000-8000-000000000001'
)
where id='169b2000-0000-4000-8000-000000000006';

insert into _boralog_169b_results
select
  'LINK_REPLACE_ALLOWED',
  m.user_id='169b0000-0000-4000-8000-000000000001',
  ''
from public.people p
join public.organization_memberships m on m.id=p.organization_membership_id
where p.id='169b2000-0000-4000-8000-000000000006';

update public.people
set organization_membership_id=null
where id='169b2000-0000-4000-8000-000000000006';

insert into _boralog_169b_results
select
  'EXPLICIT_UNLINK_ALLOWED',
  organization_membership_id is null,
  ''
from public.people
where id='169b2000-0000-4000-8000-000000000006';

-- 23-24. Same Auth account can represent one Person in each Structure.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','169b0000-0000-4000-8000-000000000004',true);

update public.people
set organization_membership_id='169b1100-0000-4000-8000-000000000105'
where id='169b2000-0000-4000-8000-000000000105';

reset role;
insert into _boralog_169b_results
select
  'MULTI_ORG_ACCOUNT',
  (
    select count(*)
    from public.people p
    join public.organization_memberships m on m.id=p.organization_membership_id
    where m.user_id='169b0000-0000-4000-8000-000000000005'
  )=2,
  '';

insert into _boralog_169b_results
select
  'MULTI_ORG_ACCOUNT_DISTINCT_PEOPLE',
  count(distinct p.organization_id)=2 and count(*)=2,
  'count='||count(*)
from public.people p
join public.organization_memberships m on m.id=p.organization_membership_id
where m.user_id='169b0000-0000-4000-8000-000000000005';

-- 25. Same account cannot represent two People in the same Structure.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','169b0000-0000-4000-8000-000000000001',true);

do $$
declare
  denied boolean := false;
begin
  begin
    update public.people
    set organization_membership_id='169b1100-0000-4000-8000-000000000005'
    where id='169b2000-0000-4000-8000-000000000009';
  exception when unique_violation then
    denied := true;
  end;
  insert into _boralog_169b_results values ('SAME_ACCOUNT_TWO_PEOPLE_SAME_ORG_DENIED', denied, '');
end $$;

-- 26. No direct Auth link was added: created_by remains the only People -> auth.users FK.
reset role;
insert into _boralog_169b_results
select
  'NO_DIRECT_AUTH_FK',
  count(*)=1 and bool_and(kcu.column_name='created_by'),
  coalesce(string_agg(kcu.column_name, ',' order by kcu.column_name),'')
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

-- 27. No People -> profiles FK.
insert into _boralog_169b_results
select
  'NO_PROFILE_FK',
  count(*)=0,
  'count='||count(*)
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
  and ccu.table_schema='public'
  and ccu.table_name='profiles';

-- 28. No parallel public table links People to organization_memberships.
insert into _boralog_169b_results
select
  'NO_PARALLEL_LINK_TABLE',
  not exists (
    select 1
    from pg_class t
    join pg_namespace n on n.oid=t.relnamespace
    where n.nspname='public'
      and t.relkind='r'
      and t.relname <> 'people'
      and exists (
        select 1 from pg_constraint c
        where c.conrelid=t.oid
          and c.contype='f'
          and c.confrelid='public.people'::regclass
      )
      and exists (
        select 1 from pg_constraint c
        where c.conrelid=t.oid
          and c.contype='f'
          and c.confrelid='public.organization_memberships'::regclass
      )
  ),
  '';

-- 29. Link column is nullable.
insert into _boralog_169b_results
select
  'COLUMN_NULLABLE',
  is_nullable='YES',
  is_nullable
from information_schema.columns
where table_schema='public'
  and table_name='people'
  and column_name='organization_membership_id';

-- 30-31. Exact FK to organization_memberships(id), ON DELETE SET NULL.
insert into _boralog_169b_results
select
  'FK_MEMBERSHIP_EXACT',
  count(*)=1
    and bool_and(kcu.column_name='organization_membership_id')
    and bool_and(ccu.table_schema='public')
    and bool_and(ccu.table_name='organization_memberships')
    and bool_and(ccu.column_name='id'),
  ''
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
  and kcu.column_name='organization_membership_id';

insert into _boralog_169b_results
select
  'ON_DELETE_SET_NULL',
  count(*)=1 and bool_and(confdeltype='n'),
  ''
from pg_constraint
where contype='f'
  and conrelid='public.people'::regclass
  and confrelid='public.organization_memberships'::regclass
  and conkey=array[
    (select attnum from pg_attribute
     where attrelid='public.people'::regclass
       and attname='organization_membership_id')
  ]::smallint[];

-- 32. Unique membership link exists.
insert into _boralog_169b_results
select
  'UNIQUE_MEMBERSHIP_LINK',
  exists(
    select 1
    from pg_indexes
    where schemaname='public'
      and tablename='people'
      and indexname='people_organization_membership_uidx'
      and indexdef like 'CREATE UNIQUE INDEX%'
      and indexdef like '%(organization_membership_id)%'
  ),
  '';

-- 33. Same-Structure trigger exists.
insert into _boralog_169b_results
select
  'CONSISTENCY_TRIGGER_PRESENT',
  exists(
    select 1
    from pg_trigger
    where tgrelid='public.people'::regclass
      and tgname='boralog_people_membership_consistency'
      and not tgisinternal
  ),
  '';

-- 34. Existing People column semantics/nullability remain unchanged.
insert into _boralog_169b_results
select
  'EXISTING_PEOPLE_COLUMNS_UNCHANGED',
  count(*)=8
  and bool_and(
    case column_name
      when 'id' then data_type='uuid' and is_nullable='NO'
      when 'organization_id' then data_type='uuid' and is_nullable='NO'
      when 'name' then data_type='text' and is_nullable='NO'
      when 'role_label' then data_type='text' and is_nullable='YES'
      when 'professional_email' then data_type='text' and is_nullable='YES'
      when 'professional_phone' then data_type='text' and is_nullable='YES'
      when 'created_by' then data_type='uuid' and is_nullable='NO'
      when 'created_at' then data_type='timestamp with time zone' and is_nullable='NO'
      else false
    end
  ),
  ''
from information_schema.columns
where table_schema='public'
  and table_name='people'
  and column_name in (
    'id','organization_id','name','role_label',
    'professional_email','professional_phone','created_by','created_at'
  );

-- 35. No self-People policy was added; canonical three policies remain.
insert into _boralog_169b_results
select
  'NO_SELF_ACCESS_POLICY',
  count(*)=3
    and bool_and(policyname in (
      'people owner full select',
      'people owner full insert',
      'people owner full update'
    )),
  coalesce(string_agg(policyname, ',' order by policyname),'')
from pg_policies
where schemaname='public'
  and tablename='people';

-- 36. RLS remains enabled.
insert into _boralog_169b_results
select
  'PEOPLE_RLS_ENABLED',
  relrowsecurity,
  ''
from pg_class
where oid='public.people'::regclass;

-- Existing OWNER/FULL policies still expose link mutation; LIMITED remains excluded.
insert into _boralog_169b_results
select
  'RLS_OWNER_FULL_UNCHANGED',
  count(*)=3,
  'count='||count(*)
from pg_policies
where schemaname='public'
  and tablename='people'
  and policyname in (
    'people owner full select',
    'people owner full insert',
    'people owner full update'
  );

insert into _boralog_169b_results
select
  'RLS_LIMITED_UNCHANGED',
  count(*)=0,
  'count='||count(*)
from pg_policies
where schemaname='public'
  and tablename='people'
  and (
    coalesce(qual,'') ilike '%limited%'
    or coalesce(with_check,'') ilike '%limited%'
  );

-- 37. Deleting a non-created_by Auth account cascades membership -> NULL, Person survives.
set local role authenticated;
select set_config('request.jwt.claim.sub','169b0000-0000-4000-8000-000000000001',true);

update public.people
set organization_membership_id='169b1100-0000-4000-8000-000000000010'
where id='169b2000-0000-4000-8000-000000000008';

reset role;
delete from auth.users
where id='169b0000-0000-4000-8000-000000000010';

insert into _boralog_169b_results
select
  'AUTH_DELETE_PRESERVES_PERSON',
  exists(
    select 1
    from public.people
    where id='169b2000-0000-4000-8000-000000000008'
      and organization_membership_id is null
  )
  and not exists(
    select 1
    from public.organization_memberships
    where id='169b1100-0000-4000-8000-000000000010'
  ),
  '';

-- 38. Pre-existing created_by FK behavior is unchanged.
do $$
declare
  denied boolean := false;
begin
  begin
    delete from auth.users
    where id='169b0000-0000-4000-8000-000000000009';
  exception when foreign_key_violation then
    denied := true;
  end;

  insert into _boralog_169b_results values (
    'PREEXISTING_CREATED_BY_BEHAVIOR_UNCHANGED',
    denied
      and exists(select 1 from auth.users where id='169b0000-0000-4000-8000-000000000009')
      and exists(
        select 1 from public.people
        where id='169b2000-0000-4000-8000-000000000109'
          and created_by='169b0000-0000-4000-8000-000000000009'
      ),
    ''
  );
end $$;

do $$
begin
  if exists(select 1 from _boralog_169b_results where not pass) then
    raise exception 'BORALOG-169B People membership link test failed';
  end if;
end $$;

select test,pass,detail
from _boralog_169b_results
order by test;

rollback;
