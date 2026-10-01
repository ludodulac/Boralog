-- BORALOG-157 targeted Message visibility/RLS tests.
-- Self-contained: all fixtures are rolled back.

begin;

create temporary table _boralog_157_results (
  test text primary key,
  pass boolean not null,
  detail text
) on commit drop;

grant select, insert, update on _boralog_157_results to authenticated;

insert into auth.users (
  id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('15700000-0000-4000-8000-000000000001','authenticated','authenticated','boralog157-owner@example.invalid','{}','{}',now(),now()),
  ('15700000-0000-4000-8000-000000000002','authenticated','authenticated','boralog157-full-creator@example.invalid','{}','{}',now(),now()),
  ('15700000-0000-4000-8000-000000000003','authenticated','authenticated','boralog157-full-recipient@example.invalid','{}','{}',now(),now()),
  ('15700000-0000-4000-8000-000000000004','authenticated','authenticated','boralog157-full-outsider@example.invalid','{}','{}',now(),now()),
  ('15700000-0000-4000-8000-000000000005','authenticated','authenticated','boralog157-limited-project@example.invalid','{}','{}',now(),now()),
  ('15700000-0000-4000-8000-000000000006','authenticated','authenticated','boralog157-limited-no-project@example.invalid','{}','{}',now(),now()),
  ('15700000-0000-4000-8000-000000000007','authenticated','authenticated','boralog157-internal-author@example.invalid','{}','{}',now(),now());

set local role authenticated;
select set_config('request.jwt.claim.sub','15700000-0000-4000-8000-000000000001',true);

insert into public.organizations(id, name, slug, created_by)
values (
  '15710000-0000-4000-8000-000000000001',
  'BORALOG 157 Visibility Org',
  'boralog-157-visibility-org',
  auth.uid()
);

reset role;

insert into public.organization_memberships(
  organization_id, user_id, role, status, access_level
) values
  ('15710000-0000-4000-8000-000000000001','15700000-0000-4000-8000-000000000002',null,'active','full'),
  ('15710000-0000-4000-8000-000000000001','15700000-0000-4000-8000-000000000003',null,'active','full'),
  ('15710000-0000-4000-8000-000000000001','15700000-0000-4000-8000-000000000004',null,'active','full'),
  ('15710000-0000-4000-8000-000000000001','15700000-0000-4000-8000-000000000005',null,'active','limited'),
  ('15710000-0000-4000-8000-000000000001','15700000-0000-4000-8000-000000000006',null,'active','limited'),
  ('15710000-0000-4000-8000-000000000001','15700000-0000-4000-8000-000000000007',null,'active','full');

insert into public.projects(id, organization_id, name, created_by)
values (
  '15720000-0000-4000-8000-000000000001',
  '15710000-0000-4000-8000-000000000001',
  'BORALOG 157 Project',
  '15700000-0000-4000-8000-000000000001'
);

insert into public.project_memberships(project_id, user_id, role)
values (
  '15720000-0000-4000-8000-000000000001',
  '15700000-0000-4000-8000-000000000005',
  null
);

set local role authenticated;
select set_config('request.jwt.claim.sub','15700000-0000-4000-8000-000000000002',true);

insert into public.messages(
  id, organization_id, content, created_by, origin_type, author_user_id
) values (
  '15740000-0000-4000-8000-000000000001',
  '15710000-0000-4000-8000-000000000001',
  'organization default',
  auth.uid(),
  'INTERNAL',
  auth.uid()
);

insert into public.messages(
  id, organization_id, content, created_by, origin_type, author_user_id, visibility
) values
  (
    '15740000-0000-4000-8000-000000000002',
    '15710000-0000-4000-8000-000000000001',
    'restricted org-only',
    auth.uid(),
    'INTERNAL',
    auth.uid(),
    'RESTRICTED'
  ),
  (
    '15740000-0000-4000-8000-000000000003',
    '15710000-0000-4000-8000-000000000001',
    'restricted project',
    auth.uid(),
    'INTERNAL',
    auth.uid(),
    'RESTRICTED'
  );

update public.messages
set project_id='15720000-0000-4000-8000-000000000001'
where id='15740000-0000-4000-8000-000000000003';

reset role;

-- External/imported message whose known Boralog author differs from importer.
set local role authenticated;
select set_config('request.jwt.claim.sub','15700000-0000-4000-8000-000000000001',true);

insert into public.messages(
  id, organization_id, content, created_by, origin_type, author_user_id, visibility
) values (
  '15740000-0000-4000-8000-000000000004',
  '15710000-0000-4000-8000-000000000001',
  'restricted external with internal author',
  auth.uid(),
  'EXTERNAL_IMPORTED',
  '15700000-0000-4000-8000-000000000007',
  'RESTRICTED'
);

reset role;

insert into public.message_recipients(message_id, user_id)
values
  ('15740000-0000-4000-8000-000000000002','15700000-0000-4000-8000-000000000003'),
  ('15740000-0000-4000-8000-000000000002','15700000-0000-4000-8000-000000000006'),
  ('15740000-0000-4000-8000-000000000003','15700000-0000-4000-8000-000000000003'),
  ('15740000-0000-4000-8000-000000000003','15700000-0000-4000-8000-000000000005'),
  ('15740000-0000-4000-8000-000000000003','15700000-0000-4000-8000-000000000006');

do $$
declare v_visibility text;
begin
  select visibility into v_visibility
  from public.messages
  where id='15740000-0000-4000-8000-000000000001';

  insert into _boralog_157_results values (
    'DEFAULT_VISIBILITY_ORGANIZATION',
    v_visibility='ORGANIZATION',
    coalesce(v_visibility,'null')
  );
end $$;

set local role authenticated;
select set_config('request.jwt.claim.sub','15700000-0000-4000-8000-000000000002',true);

do $$
declare v_seen bigint;
begin
  select count(*) into v_seen
  from public.messages
  where id='15740000-0000-4000-8000-000000000002';

  insert into _boralog_157_results values (
    'RESTRICTED_CREATOR_CAN_READ',
    v_seen=1,
    'seen='||v_seen
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','15700000-0000-4000-8000-000000000001',true);

do $$
declare v_seen bigint;
begin
  select count(*) into v_seen
  from public.messages
  where id='15740000-0000-4000-8000-000000000002';

  insert into _boralog_157_results values (
    'RESTRICTED_OWNER_NO_BYPASS',
    v_seen=0,
    'seen='||v_seen
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','15700000-0000-4000-8000-000000000004',true);

do $$
declare v_seen bigint;
begin
  select count(*) into v_seen
  from public.messages
  where id='15740000-0000-4000-8000-000000000002';

  insert into _boralog_157_results values (
    'RESTRICTED_FULL_NO_BYPASS',
    v_seen=0,
    'seen='||v_seen
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','15700000-0000-4000-8000-000000000003',true);

do $$
declare v_seen bigint;
begin
  select count(*) into v_seen
  from public.messages
  where id='15740000-0000-4000-8000-000000000002';

  insert into _boralog_157_results values (
    'RESTRICTED_EXPLICIT_RECIPIENT_CAN_READ',
    v_seen=1,
    'seen='||v_seen
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','15700000-0000-4000-8000-000000000007',true);

do $$
declare v_seen bigint;
begin
  select count(*) into v_seen
  from public.messages
  where id='15740000-0000-4000-8000-000000000004';

  insert into _boralog_157_results values (
    'RESTRICTED_INTERNAL_AUTHOR_CAN_READ',
    v_seen=1,
    'seen='||v_seen
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','15700000-0000-4000-8000-000000000005',true);

do $$
declare v_seen bigint;
begin
  select count(*) into v_seen
  from public.messages
  where id='15740000-0000-4000-8000-000000000003';

  insert into _boralog_157_results values (
    'LIMITED_PROJECT_RECIPIENT_CAN_READ',
    v_seen=1,
    'seen='||v_seen
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','15700000-0000-4000-8000-000000000006',true);

do $$
declare
  v_project_seen bigint;
  v_org_only_seen bigint;
begin
  select count(*) into v_project_seen
  from public.messages
  where id='15740000-0000-4000-8000-000000000003';

  select count(*) into v_org_only_seen
  from public.messages
  where id='15740000-0000-4000-8000-000000000002';

  insert into _boralog_157_results values (
    'LIMITED_CONTEXT_RULES',
    v_project_seen=0 and v_org_only_seen=1,
    'project_seen='||v_project_seen||', org_only_seen='||v_org_only_seen
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','15700000-0000-4000-8000-000000000005',true);

do $$
declare v_seen bigint;
begin
  select count(*) into v_seen
  from public.messages
  where id='15740000-0000-4000-8000-000000000001';

  insert into _boralog_157_results values (
    'LIMITED_ORGANIZATION_NO_CONTEXT_REQUIRES_RECIPIENT',
    v_seen=0,
    'seen='||v_seen
  );
end $$;

reset role;

-- Add the limited project member as explicit recipient of the contextless ORGANIZATION message.
insert into public.message_recipients(message_id, user_id)
values (
  '15740000-0000-4000-8000-000000000001',
  '15700000-0000-4000-8000-000000000005'
);

set local role authenticated;
select set_config('request.jwt.claim.sub','15700000-0000-4000-8000-000000000005',true);

do $$
declare v_seen bigint;
begin
  select count(*) into v_seen
  from public.messages
  where id='15740000-0000-4000-8000-000000000001';

  insert into _boralog_157_results values (
    'LIMITED_ORGANIZATION_NO_CONTEXT_RECIPIENT_CAN_READ',
    v_seen=1,
    'seen='||v_seen
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','15700000-0000-4000-8000-000000000003',true);

do $$
declare v_status text;
begin
  perform public.boralog_close_message_no_follow_up(
    '15740000-0000-4000-8000-000000000002'
  );

  select status into v_status
  from public.messages
  where id='15740000-0000-4000-8000-000000000002';

  insert into _boralog_157_results values (
    'RESTRICTED_RECIPIENT_CAN_PROCESS',
    v_status='PROCESSED',
    coalesce(v_status,'missing')
  );
exception when others then
  insert into _boralog_157_results values (
    'RESTRICTED_RECIPIENT_CAN_PROCESS',
    false,
    sqlstate||' '||sqlerrm
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','15700000-0000-4000-8000-000000000004',true);

do $$
declare v_denied boolean := false;
begin
  begin
    perform public.boralog_close_message_no_follow_up(
      '15740000-0000-4000-8000-000000000003'
    );
  exception when no_data_found then
    v_denied := true;
  when others then
    if sqlstate='P0002' then
      v_denied := true;
    else
      raise;
    end if;
  end;

  insert into _boralog_157_results values (
    'RESTRICTED_NON_AUDIENCE_CANNOT_PROCESS',
    v_denied,
    'denied='||v_denied
  );
end $$;

reset role;

do $$
begin
  if exists (select 1 from _boralog_157_results where not pass) then
    raise exception 'BORALOG-157 visibility/RLS test failed';
  end if;
end $$;

select test, pass, detail
from _boralog_157_results
order by test;

rollback;
