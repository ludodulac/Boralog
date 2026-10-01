-- BORALOG-156 targeted individual Message recipient coherence tests.
-- Self-contained: all fixtures are rolled back.

begin;

create temporary table _boralog_156_results (
  test text primary key,
  pass boolean not null,
  detail text
) on commit drop;

insert into auth.users (
  id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('15600000-0000-4000-8000-000000000001','authenticated','authenticated','boralog156-owner@example.invalid','{}','{}',now(),now()),
  ('15600000-0000-4000-8000-000000000002','authenticated','authenticated','boralog156-active@example.invalid','{}','{}',now(),now()),
  ('15600000-0000-4000-8000-000000000003','authenticated','authenticated','boralog156-suspended@example.invalid','{}','{}',now(),now()),
  ('15600000-0000-4000-8000-000000000004','authenticated','authenticated','boralog156-other-org@example.invalid','{}','{}',now(),now()),
  ('15600000-0000-4000-8000-000000000005','authenticated','authenticated','boralog156-outsider@example.invalid','{}','{}',now(),now());

set local role authenticated;
select set_config('request.jwt.claim.sub','15600000-0000-4000-8000-000000000001',true);

insert into public.organizations(id, name, slug, created_by)
values
  ('15610000-0000-4000-8000-000000000001','BORALOG 156 Primary Org','boralog-156-primary-org',auth.uid()),
  ('15610000-0000-4000-8000-000000000002','BORALOG 156 Other Org','boralog-156-other-org',auth.uid());

reset role;

insert into public.organization_memberships(
  organization_id, user_id, role, status, access_level
) values
  ('15610000-0000-4000-8000-000000000001','15600000-0000-4000-8000-000000000002',null,'active','full'),
  ('15610000-0000-4000-8000-000000000001','15600000-0000-4000-8000-000000000003',null,'suspended','full'),
  ('15610000-0000-4000-8000-000000000002','15600000-0000-4000-8000-000000000004',null,'active','full');

set local role authenticated;
select set_config('request.jwt.claim.sub','15600000-0000-4000-8000-000000000001',true);

insert into public.messages(
  id, organization_id, content, created_by, origin_type, author_user_id
) values
  ('15640000-0000-4000-8000-000000000001','15610000-0000-4000-8000-000000000001','recipient coherence source',auth.uid(),'INTERNAL',auth.uid()),
  ('15640000-0000-4000-8000-000000000002','15610000-0000-4000-8000-000000000001','cascade source',auth.uid(),'INTERNAL',auth.uid());

reset role;

do $$
declare
  v_count bigint;
begin
  insert into public.message_recipients(message_id, user_id)
  values (
    '15640000-0000-4000-8000-000000000001',
    '15600000-0000-4000-8000-000000000002'
  );

  select count(*) into v_count
  from public.message_recipients
  where message_id='15640000-0000-4000-8000-000000000001'
    and user_id='15600000-0000-4000-8000-000000000002';

  insert into _boralog_156_results values (
    'ACTIVE_SAME_ORG_RECIPIENT',
    v_count=1,
    'rows='||v_count
  );
end $$;

do $$
declare v_denied boolean := false;
begin
  begin
    insert into public.message_recipients(message_id, user_id)
    values (
      '15640000-0000-4000-8000-000000000001',
      '15600000-0000-4000-8000-000000000002'
    );
  exception when unique_violation then
    v_denied := true;
  end;

  insert into _boralog_156_results values ('DUPLICATE_RECIPIENT_DENIED', v_denied, 'denied='||v_denied);
end $$;

do $$
declare v_denied boolean := false;
begin
  begin
    insert into public.message_recipients(message_id, user_id)
    values (
      '15640000-0000-4000-8000-000000000001',
      '15600000-0000-4000-8000-000000000003'
    );
  exception when check_violation then
    v_denied := true;
  end;

  insert into _boralog_156_results values ('SUSPENDED_MEMBER_DENIED', v_denied, 'denied='||v_denied);
end $$;

do $$
declare v_denied boolean := false;
begin
  begin
    insert into public.message_recipients(message_id, user_id)
    values (
      '15640000-0000-4000-8000-000000000001',
      '15600000-0000-4000-8000-000000000004'
    );
  exception when check_violation then
    v_denied := true;
  end;

  insert into _boralog_156_results values ('CROSS_ORG_MEMBER_DENIED', v_denied, 'denied='||v_denied);
end $$;

do $$
declare v_denied boolean := false;
begin
  begin
    insert into public.message_recipients(message_id, user_id)
    values (
      '15640000-0000-4000-8000-000000000001',
      '15600000-0000-4000-8000-000000000005'
    );
  exception when check_violation then
    v_denied := true;
  end;

  insert into _boralog_156_results values ('NON_MEMBER_DENIED', v_denied, 'denied='||v_denied);
end $$;

do $$
declare
  v_select boolean;
  v_insert boolean;
  v_update boolean;
  v_delete boolean;
begin
  select
    has_table_privilege('authenticated','public.message_recipients','SELECT'),
    has_table_privilege('authenticated','public.message_recipients','INSERT'),
    has_table_privilege('authenticated','public.message_recipients','UPDATE'),
    has_table_privilege('authenticated','public.message_recipients','DELETE')
  into v_select, v_insert, v_update, v_delete;

  insert into _boralog_156_results values (
    'NO_CLIENT_ACCESS_YET',
    not v_select and not v_insert and not v_update and not v_delete,
    'select='||v_select||', insert='||v_insert||', update='||v_update||', delete='||v_delete
  );
end $$;

do $$
declare v_remaining bigint;
begin
  insert into public.message_recipients(message_id, user_id)
  values (
    '15640000-0000-4000-8000-000000000002',
    '15600000-0000-4000-8000-000000000002'
  );

  delete from public.messages
  where id='15640000-0000-4000-8000-000000000002';

  select count(*) into v_remaining
  from public.message_recipients
  where message_id='15640000-0000-4000-8000-000000000002';

  insert into _boralog_156_results values (
    'MESSAGE_DELETE_CASCADES_RECIPIENTS',
    v_remaining=0,
    'remaining='||v_remaining
  );
end $$;

do $$
begin
  if exists (select 1 from _boralog_156_results where not pass) then
    raise exception 'BORALOG-156 recipient coherence test failed';
  end if;
end $$;

select test, pass, detail
from _boralog_156_results
order by test;

rollback;
