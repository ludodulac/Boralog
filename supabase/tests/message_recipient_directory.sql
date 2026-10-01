-- BORALOG-158 secure recipient directory tests.
-- Self-contained: all fixtures are rolled back.

begin;

create temporary table _boralog_158_results (
  test text primary key,
  pass boolean not null,
  detail text
) on commit drop;

grant select, insert, update on _boralog_158_results to authenticated;

insert into auth.users (
  id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('15800000-0000-4000-8000-000000000001','authenticated','authenticated','boralog158-owner@example.invalid','{}','{"display_name":"Owner 158"}',now(),now()),
  ('15800000-0000-4000-8000-000000000002','authenticated','authenticated','boralog158-full@example.invalid','{}','{"display_name":"Full 158"}',now(),now()),
  ('15800000-0000-4000-8000-000000000003','authenticated','authenticated','boralog158-limited@example.invalid','{}','{"display_name":"Limited 158"}',now(),now()),
  ('15800000-0000-4000-8000-000000000004','authenticated','authenticated','boralog158-suspended@example.invalid','{}','{"display_name":"Suspended 158"}',now(),now()),
  ('15800000-0000-4000-8000-000000000005','authenticated','authenticated','boralog158-other@example.invalid','{}','{"display_name":"Other Org 158"}',now(),now()),
  ('15800000-0000-4000-8000-000000000006','authenticated','authenticated','boralog158-outsider@example.invalid','{}','{"display_name":"Outsider 158"}',now(),now());

update public.profiles
set professional_email = case id
  when '15800000-0000-4000-8000-000000000001'::uuid then 'owner-private@example.invalid'
  when '15800000-0000-4000-8000-000000000002'::uuid then 'full-private@example.invalid'
  else null
end,
professional_phone = case id
  when '15800000-0000-4000-8000-000000000001'::uuid then '+33000000001'
  when '15800000-0000-4000-8000-000000000002'::uuid then '+33000000002'
  else null
end;

set local role authenticated;
select set_config('request.jwt.claim.sub','15800000-0000-4000-8000-000000000001',true);

insert into public.organizations(id, name, slug, created_by)
values
  ('15810000-0000-4000-8000-000000000001','BORALOG 158 Primary Org','boralog-158-primary-org',auth.uid()),
  ('15810000-0000-4000-8000-000000000002','BORALOG 158 Other Org','boralog-158-other-org',auth.uid());

reset role;

insert into public.organization_memberships(
  organization_id, user_id, role, status, access_level
) values
  ('15810000-0000-4000-8000-000000000001','15800000-0000-4000-8000-000000000002',null,'active','full'),
  ('15810000-0000-4000-8000-000000000001','15800000-0000-4000-8000-000000000003',null,'active','limited'),
  ('15810000-0000-4000-8000-000000000001','15800000-0000-4000-8000-000000000004',null,'suspended','full'),
  ('15810000-0000-4000-8000-000000000002','15800000-0000-4000-8000-000000000005',null,'active','full');

set local role authenticated;
select set_config('request.jwt.claim.sub','15800000-0000-4000-8000-000000000001',true);

do $$
declare
  v_count bigint;
  v_suspended bigint;
  v_other bigint;
begin
  select count(*) into v_count
  from public.boralog_message_recipient_directory(
    '15810000-0000-4000-8000-000000000001'
  );

  select count(*) into v_suspended
  from public.boralog_message_recipient_directory(
    '15810000-0000-4000-8000-000000000001'
  )
  where user_id='15800000-0000-4000-8000-000000000004';

  select count(*) into v_other
  from public.boralog_message_recipient_directory(
    '15810000-0000-4000-8000-000000000001'
  )
  where user_id='15800000-0000-4000-8000-000000000005';

  insert into _boralog_158_results values (
    'ACTIVE_MEMBERS_ONLY',
    v_count=3 and v_suspended=0 and v_other=0,
    'count='||v_count||', suspended='||v_suspended||', other='||v_other
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','15800000-0000-4000-8000-000000000003',true);

do $$
declare v_count bigint;
begin
  select count(*) into v_count
  from public.boralog_message_recipient_directory(
    '15810000-0000-4000-8000-000000000001'
  );

  insert into _boralog_158_results values (
    'LIMITED_MEMBER_CAN_USE_DIRECTORY',
    v_count=3,
    'count='||v_count
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','15800000-0000-4000-8000-000000000005',true);

do $$
declare v_count bigint;
begin
  select count(*) into v_count
  from public.boralog_message_recipient_directory(
    '15810000-0000-4000-8000-000000000001'
  );

  insert into _boralog_158_results values (
    'CROSS_ORG_DENIED',
    v_count=0,
    'count='||v_count
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','15800000-0000-4000-8000-000000000006',true);

do $$
declare v_count bigint;
begin
  select count(*) into v_count
  from public.boralog_message_recipient_directory(
    '15810000-0000-4000-8000-000000000001'
  );

  insert into _boralog_158_results values (
    'NON_MEMBER_DENIED',
    v_count=0,
    'count='||v_count
  );
end $$;

reset role;

do $$
declare v_result text;
begin
  select pg_get_function_result(
    'public.boralog_message_recipient_directory(uuid)'::regprocedure
  ) into v_result;

  insert into _boralog_158_results values (
    'MINIMAL_RESULT_SHAPE',
    v_result = 'TABLE(user_id uuid, display_name text)',
    v_result
  );
end $$;

set local role authenticated;
select set_config('request.jwt.claim.sub','15800000-0000-4000-8000-000000000002',true);

do $$
declare v_direct_visible bigint;
begin
  select count(*) into v_direct_visible
  from public.profiles
  where id='15800000-0000-4000-8000-000000000001';

  insert into _boralog_158_results values (
    'PROFILE_TABLE_REMAINS_PRIVATE',
    v_direct_visible=0,
    'direct_visible='||v_direct_visible
  );
end $$;

reset role;

do $$
begin
  if exists (select 1 from _boralog_158_results where not pass) then
    raise exception 'BORALOG-158 recipient directory test failed';
  end if;
end $$;

select test, pass, detail
from _boralog_158_results
order by test;

rollback;
