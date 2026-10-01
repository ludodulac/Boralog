-- BORALOG-160 per-user Message read/unread tests.
-- Self-contained: all fixtures are rolled back.

begin;

create temporary table _boralog_160_results (
  test text primary key,
  pass boolean not null,
  detail text
) on commit drop;

grant select, insert, update on _boralog_160_results to authenticated;

insert into auth.users (
  id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('16000000-0000-4000-8000-000000000001','authenticated','authenticated','boralog160-owner@example.invalid','{}','{}',now(),now()),
  ('16000000-0000-4000-8000-000000000002','authenticated','authenticated','boralog160-full@example.invalid','{}','{}',now(),now()),
  ('16000000-0000-4000-8000-000000000003','authenticated','authenticated','boralog160-recipient@example.invalid','{}','{}',now(),now()),
  ('16000000-0000-4000-8000-000000000004','authenticated','authenticated','boralog160-outsider@example.invalid','{}','{}',now(),now());

set local role authenticated;
select set_config('request.jwt.claim.sub','16000000-0000-4000-8000-000000000001',true);

insert into public.organizations(id, name, slug, created_by)
values (
  '16010000-0000-4000-8000-000000000001',
  'BORALOG 160 Read State Org',
  'boralog-160-read-state-org',
  auth.uid()
);

reset role;

insert into public.organization_memberships(
  organization_id, user_id, role, status, access_level
) values
  ('16010000-0000-4000-8000-000000000001','16000000-0000-4000-8000-000000000002',null,'active','full'),
  ('16010000-0000-4000-8000-000000000001','16000000-0000-4000-8000-000000000003',null,'active','limited'),
  ('16010000-0000-4000-8000-000000000001','16000000-0000-4000-8000-000000000004',null,'active','full');

set local role authenticated;
select set_config('request.jwt.claim.sub','16000000-0000-4000-8000-000000000001',true);

insert into public.messages(
  id, organization_id, content, created_by, origin_type, author_user_id, visibility
) values
  (
    '16040000-0000-4000-8000-000000000001',
    '16010000-0000-4000-8000-000000000001',
    'organization read state',
    auth.uid(),
    'INTERNAL',
    auth.uid(),
    'ORGANIZATION'
  ),
  (
    '16040000-0000-4000-8000-000000000002',
    '16010000-0000-4000-8000-000000000001',
    'restricted read state',
    auth.uid(),
    'INTERNAL',
    auth.uid(),
    'RESTRICTED'
  );

reset role;

insert into public.message_recipients(message_id, user_id)
values (
  '16040000-0000-4000-8000-000000000002',
  '16000000-0000-4000-8000-000000000003'
);

set local role authenticated;
select set_config('request.jwt.claim.sub','16000000-0000-4000-8000-000000000001',true);

do $$
declare
  v_rows bigint;
  v_status text;
begin
  insert into public.message_reads(message_id, user_id)
  values ('16040000-0000-4000-8000-000000000001', auth.uid());

  select count(*) into v_rows
  from public.message_reads
  where message_id='16040000-0000-4000-8000-000000000001'
    and user_id=auth.uid();

  select status into v_status
  from public.messages
  where id='16040000-0000-4000-8000-000000000001';

  insert into _boralog_160_results values (
    'READ_STATE_DOES_NOT_PROCESS_MESSAGE',
    v_rows=1 and v_status='TO_PROCESS',
    'rows='||v_rows||', status='||coalesce(v_status,'missing')
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','16000000-0000-4000-8000-000000000002',true);

do $$
declare
  v_owner_rows bigint;
  v_own_rows bigint;
begin
  select count(*) into v_owner_rows
  from public.message_reads
  where message_id='16040000-0000-4000-8000-000000000001';

  insert into public.message_reads(message_id, user_id)
  values ('16040000-0000-4000-8000-000000000001', auth.uid());

  select count(*) into v_own_rows
  from public.message_reads
  where message_id='16040000-0000-4000-8000-000000000001';

  insert into _boralog_160_results values (
    'READ_STATE_IS_PER_USER',
    v_owner_rows=0 and v_own_rows=1,
    'before='||v_owner_rows||', own='||v_own_rows
  );
end $$;

delete from public.message_reads
where message_id='16040000-0000-4000-8000-000000000001'
  and user_id=auth.uid();

do $$
declare v_rows bigint;
begin
  select count(*) into v_rows
  from public.message_reads
  where message_id='16040000-0000-4000-8000-000000000001';

  insert into _boralog_160_results values (
    'MARK_UNREAD_DELETES_OWN_STATE',
    v_rows=0,
    'rows='||v_rows
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','16000000-0000-4000-8000-000000000003',true);

do $$
declare v_rows bigint;
begin
  insert into public.message_reads(message_id, user_id)
  values ('16040000-0000-4000-8000-000000000002', auth.uid());

  select count(*) into v_rows
  from public.message_reads
  where message_id='16040000-0000-4000-8000-000000000002';

  insert into _boralog_160_results values (
    'RESTRICTED_RECIPIENT_CAN_MARK_READ',
    v_rows=1,
    'rows='||v_rows
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','16000000-0000-4000-8000-000000000004',true);

do $$
declare v_denied boolean := false;
begin
  begin
    insert into public.message_reads(message_id, user_id)
    values ('16040000-0000-4000-8000-000000000002', auth.uid());
  exception when insufficient_privilege then
    v_denied := true;
  when check_violation then
    v_denied := true;
  end;

  insert into _boralog_160_results values (
    'RESTRICTED_NON_AUDIENCE_CANNOT_MARK_READ',
    v_denied,
    'denied='||v_denied
  );
end $$;

reset role;

do $$
declare
  v_message_id uuid := '16040000-0000-4000-8000-000000000001';
  v_before bigint;
  v_after bigint;
begin
  select count(*) into v_before
  from public.message_reads
  where message_id=v_message_id;

  delete from public.messages where id=v_message_id;

  select count(*) into v_after
  from public.message_reads
  where message_id=v_message_id;

  insert into _boralog_160_results values (
    'MESSAGE_DELETE_CASCADES_READ_STATE',
    v_before=1 and v_after=0,
    'before='||v_before||', after='||v_after
  );
end $$;

do $$
begin
  if exists (select 1 from _boralog_160_results where not pass) then
    raise exception 'BORALOG-160 read state test failed';
  end if;
end $$;

select test, pass, detail
from _boralog_160_results
order by test;

rollback;
