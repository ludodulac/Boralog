-- BORALOG-159 recipient groups and snapshot materialization tests.
-- Self-contained: all fixtures are rolled back.

begin;

create temporary table _boralog_159_results (
  test text primary key,
  pass boolean not null,
  detail text
) on commit drop;

insert into auth.users (
  id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('15900000-0000-4000-8000-000000000001','authenticated','authenticated','boralog159-owner@example.invalid','{}','{}',now(),now()),
  ('15900000-0000-4000-8000-000000000002','authenticated','authenticated','boralog159-a@example.invalid','{}','{}',now(),now()),
  ('15900000-0000-4000-8000-000000000003','authenticated','authenticated','boralog159-b@example.invalid','{}','{}',now(),now()),
  ('15900000-0000-4000-8000-000000000004','authenticated','authenticated','boralog159-c@example.invalid','{}','{}',now(),now()),
  ('15900000-0000-4000-8000-000000000005','authenticated','authenticated','boralog159-suspended@example.invalid','{}','{}',now(),now()),
  ('15900000-0000-4000-8000-000000000006','authenticated','authenticated','boralog159-other@example.invalid','{}','{}',now(),now());

set local role authenticated;
select set_config('request.jwt.claim.sub','15900000-0000-4000-8000-000000000001',true);

insert into public.organizations(id, name, slug, created_by)
values
  ('15910000-0000-4000-8000-000000000001','BORALOG 159 Primary Org','boralog-159-primary-org',auth.uid()),
  ('15910000-0000-4000-8000-000000000002','BORALOG 159 Other Org','boralog-159-other-org',auth.uid());

reset role;

insert into public.organization_memberships(
  organization_id, user_id, role, status, access_level
) values
  ('15910000-0000-4000-8000-000000000001','15900000-0000-4000-8000-000000000002',null,'active','full'),
  ('15910000-0000-4000-8000-000000000001','15900000-0000-4000-8000-000000000003',null,'active','limited'),
  ('15910000-0000-4000-8000-000000000001','15900000-0000-4000-8000-000000000004',null,'active','limited'),
  ('15910000-0000-4000-8000-000000000001','15900000-0000-4000-8000-000000000005',null,'suspended','full'),
  ('15910000-0000-4000-8000-000000000002','15900000-0000-4000-8000-000000000006',null,'active','full');

set local role authenticated;
select set_config('request.jwt.claim.sub','15900000-0000-4000-8000-000000000001',true);

insert into public.recipient_groups(
  id, organization_id, name, created_by
) values (
  '15950000-0000-4000-8000-000000000001',
  '15910000-0000-4000-8000-000000000001',
  'Équipe diffusion',
  auth.uid()
);

insert into public.messages(
  id, organization_id, content, created_by, origin_type, author_user_id, visibility
) values (
  '15940000-0000-4000-8000-000000000001',
  '15910000-0000-4000-8000-000000000001',
  'group materialization source',
  auth.uid(),
  'INTERNAL',
  auth.uid(),
  'RESTRICTED'
);

reset role;

insert into public.recipient_group_members(group_id, user_id)
values
  ('15950000-0000-4000-8000-000000000001','15900000-0000-4000-8000-000000000002'),
  ('15950000-0000-4000-8000-000000000001','15900000-0000-4000-8000-000000000003');

do $$
declare v_denied boolean := false;
begin
  begin
    insert into public.recipient_group_members(group_id, user_id)
    values (
      '15950000-0000-4000-8000-000000000001',
      '15900000-0000-4000-8000-000000000005'
    );
  exception when check_violation then
    v_denied := true;
  end;

  insert into _boralog_159_results values (
    'SUSPENDED_GROUP_MEMBER_DENIED',
    v_denied,
    'denied='||v_denied
  );
end $$;

do $$
declare v_denied boolean := false;
begin
  begin
    insert into public.recipient_group_members(group_id, user_id)
    values (
      '15950000-0000-4000-8000-000000000001',
      '15900000-0000-4000-8000-000000000006'
    );
  exception when check_violation then
    v_denied := true;
  end;

  insert into _boralog_159_results values (
    'CROSS_ORG_GROUP_MEMBER_DENIED',
    v_denied,
    'denied='||v_denied
  );
end $$;

do $$
declare
  v_inserted bigint;
  v_a bigint;
  v_b bigint;
begin
  v_inserted := private.boralog_materialize_recipient_group(
    '15940000-0000-4000-8000-000000000001',
    '15950000-0000-4000-8000-000000000001'
  );

  select count(*) into v_a
  from public.message_recipients
  where message_id='15940000-0000-4000-8000-000000000001'
    and user_id='15900000-0000-4000-8000-000000000002';

  select count(*) into v_b
  from public.message_recipients
  where message_id='15940000-0000-4000-8000-000000000001'
    and user_id='15900000-0000-4000-8000-000000000003';

  insert into _boralog_159_results values (
    'MATERIALIZES_CURRENT_MEMBERS',
    v_inserted=2 and v_a=1 and v_b=1,
    'inserted='||v_inserted||', a='||v_a||', b='||v_b
  );
end $$;

-- Change the group after materialization. Existing Message recipients must not change.
delete from public.recipient_group_members
where group_id='15950000-0000-4000-8000-000000000001'
  and user_id='15900000-0000-4000-8000-000000000003';

insert into public.recipient_group_members(group_id, user_id)
values (
  '15950000-0000-4000-8000-000000000001',
  '15900000-0000-4000-8000-000000000004'
);

do $$
declare
  v_b bigint;
  v_c bigint;
  v_total bigint;
begin
  select count(*) into v_b
  from public.message_recipients
  where message_id='15940000-0000-4000-8000-000000000001'
    and user_id='15900000-0000-4000-8000-000000000003';

  select count(*) into v_c
  from public.message_recipients
  where message_id='15940000-0000-4000-8000-000000000001'
    and user_id='15900000-0000-4000-8000-000000000004';

  select count(*) into v_total
  from public.message_recipients
  where message_id='15940000-0000-4000-8000-000000000001';

  insert into _boralog_159_results values (
    'MATERIALIZED_AUDIENCE_IS_SNAPSHOT',
    v_b=1 and v_c=0 and v_total=2,
    'b='||v_b||', c='||v_c||', total='||v_total
  );
end $$;

do $$
declare
  v_groups_select boolean;
  v_groups_insert boolean;
  v_members_select boolean;
  v_members_insert boolean;
  v_materialize_exec boolean;
begin
  select
    has_table_privilege('authenticated','public.recipient_groups','SELECT'),
    has_table_privilege('authenticated','public.recipient_groups','INSERT'),
    has_table_privilege('authenticated','public.recipient_group_members','SELECT'),
    has_table_privilege('authenticated','public.recipient_group_members','INSERT'),
    has_function_privilege('authenticated','private.boralog_materialize_recipient_group(uuid,uuid)','EXECUTE')
  into
    v_groups_select,
    v_groups_insert,
    v_members_select,
    v_members_insert,
    v_materialize_exec;

  insert into _boralog_159_results values (
    'NO_CLIENT_GROUP_MANAGEMENT_YET',
    not v_groups_select
      and not v_groups_insert
      and not v_members_select
      and not v_members_insert
      and not v_materialize_exec,
    'groups_select='||v_groups_select
      ||', groups_insert='||v_groups_insert
      ||', members_select='||v_members_select
      ||', members_insert='||v_members_insert
      ||', materialize_exec='||v_materialize_exec
  );
end $$;

do $$
begin
  if exists (select 1 from _boralog_159_results where not pass) then
    raise exception 'BORALOG-159 recipient group test failed';
  end if;
end $$;

select test, pass, detail
from _boralog_159_results
order by test;

rollback;
