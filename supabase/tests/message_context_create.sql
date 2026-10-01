-- BORALOG-162 optional Project / Date context tests.
-- Self-contained fixtures are rolled back.

begin;

create temporary table _boralog_162_results (
  test text primary key,
  pass boolean not null,
  detail text
) on commit drop;

grant select, insert, update on _boralog_162_results to authenticated;

create or replace function private._boralog_162_test_recipient_count(
  p_message_id uuid
)
returns bigint
language sql
stable
security definer
set search_path = ''
as $$
  select count(*)
  from public.message_recipients as mr
  where mr.message_id = p_message_id
$$;

alter function private._boralog_162_test_recipient_count(uuid) owner to postgres;
revoke all on function private._boralog_162_test_recipient_count(uuid)
  from public, anon, service_role;
grant execute on function private._boralog_162_test_recipient_count(uuid)
  to authenticated;

insert into auth.users (
  id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('16200000-0000-4000-8000-000000000001','authenticated','authenticated','boralog162-owner@example.invalid','{}','{"display_name":"Owner 162"}',now(),now()),
  ('16200000-0000-4000-8000-000000000002','authenticated','authenticated','boralog162-full@example.invalid','{}','{"display_name":"Full 162"}',now(),now()),
  ('16200000-0000-4000-8000-000000000003','authenticated','authenticated','boralog162-limited-a@example.invalid','{}','{"display_name":"Limited A 162"}',now(),now()),
  ('16200000-0000-4000-8000-000000000004','authenticated','authenticated','boralog162-limited-b@example.invalid','{}','{"display_name":"Limited B 162"}',now(),now());

set local role authenticated;
select set_config('request.jwt.claim.sub','16200000-0000-4000-8000-000000000001',true);

insert into public.organizations(id, name, slug, created_by)
values
  ('16210000-0000-4000-8000-000000000001','BORALOG 162 Primary Org','boralog-162-primary-org',auth.uid()),
  ('16210000-0000-4000-8000-000000000002','BORALOG 162 Other Org','boralog-162-other-org',auth.uid());

reset role;

insert into public.organization_memberships(
  organization_id, user_id, role, status, access_level
) values
  ('16210000-0000-4000-8000-000000000001','16200000-0000-4000-8000-000000000002',null,'active','full'),
  ('16210000-0000-4000-8000-000000000001','16200000-0000-4000-8000-000000000003',null,'active','limited'),
  ('16210000-0000-4000-8000-000000000001','16200000-0000-4000-8000-000000000004',null,'active','limited');

insert into public.projects(id, organization_id, name, created_by)
values
  ('16220000-0000-4000-8000-000000000001','16210000-0000-4000-8000-000000000001','Accessible Project 162','16200000-0000-4000-8000-000000000001'),
  ('16220000-0000-4000-8000-000000000002','16210000-0000-4000-8000-000000000001','Inaccessible Project 162','16200000-0000-4000-8000-000000000001'),
  ('16220000-0000-4000-8000-000000000003','16210000-0000-4000-8000-000000000002','Other Org Project 162','16200000-0000-4000-8000-000000000001');

insert into public.project_memberships(project_id, user_id, role)
values
  ('16220000-0000-4000-8000-000000000001','16200000-0000-4000-8000-000000000003',null),
  ('16220000-0000-4000-8000-000000000001','16200000-0000-4000-8000-000000000004',null);

insert into public.events(id, project_id, event_date, venue_name, city, created_by)
values
  ('16230000-0000-4000-8000-000000000001','16220000-0000-4000-8000-000000000001','2026-11-10','Accessible Venue','Nantes','16200000-0000-4000-8000-000000000001'),
  ('16230000-0000-4000-8000-000000000002','16220000-0000-4000-8000-000000000002','2026-11-11','Inaccessible Venue','Rennes','16200000-0000-4000-8000-000000000001'),
  ('16230000-0000-4000-8000-000000000003','16220000-0000-4000-8000-000000000003','2026-11-12','Other Venue','Paris','16200000-0000-4000-8000-000000000001');

alter table public.messages disable trigger boralog_message_provenance_insert;
insert into public.messages(
  id, organization_id, content, created_by
) values (
  '16240000-0000-4000-8000-000000000099',
  '16210000-0000-4000-8000-000000000001',
  'BORALOG 162 untouched historical fixture',
  '16200000-0000-4000-8000-000000000001'
);
alter table public.messages enable trigger boralog_message_provenance_insert;

create temporary table _boralog_162_historical_snapshot
on commit drop
as
select to_jsonb(m) as row_snapshot
from public.messages as m
where m.id='16240000-0000-4000-8000-000000000099';

set local role authenticated;
select set_config('request.jwt.claim.sub','16200000-0000-4000-8000-000000000001',true);

do $$
declare
  v_message public.messages%rowtype;
begin
  select created.* into v_message
  from public.boralog_create_internal_message(
    '16210000-0000-4000-8000-000000000001',
    '162 no context',
    'ORGANIZATION',
    '{}'::uuid[],
    null,
    null
  ) as created;

  insert into _boralog_162_results values (
    'NO_CONTEXT_CREATE_PASS',
    v_message.id is not null
      and v_message.project_id is null
      and v_message.event_id is null,
    'project='||coalesce(v_message.project_id::text,'null')||', event='||coalesce(v_message.event_id::text,'null')
  );
exception when others then
  insert into _boralog_162_results values ('NO_CONTEXT_CREATE_PASS', false, sqlstate||' '||sqlerrm);
end $$;

do $$
declare
  v_message public.messages%rowtype;
begin
  select created.* into v_message
  from public.boralog_create_internal_message(
    '16210000-0000-4000-8000-000000000001',
    '162 project context',
    'ORGANIZATION',
    '{}'::uuid[],
    '16220000-0000-4000-8000-000000000001',
    null
  ) as created;

  insert into _boralog_162_results values (
    'PROJECT_CONTEXT_CREATE_PASS',
    v_message.project_id='16220000-0000-4000-8000-000000000001'::uuid
      and v_message.event_id is null,
    'project='||coalesce(v_message.project_id::text,'null')||', event='||coalesce(v_message.event_id::text,'null')
  );
exception when others then
  insert into _boralog_162_results values ('PROJECT_CONTEXT_CREATE_PASS', false, sqlstate||' '||sqlerrm);
end $$;

do $$
declare
  v_message public.messages%rowtype;
begin
  select created.* into v_message
  from public.boralog_create_internal_message(
    '16210000-0000-4000-8000-000000000001',
    '162 date context',
    'ORGANIZATION',
    '{}'::uuid[],
    null,
    '16230000-0000-4000-8000-000000000001'
  ) as created;

  insert into _boralog_162_results values (
    'DATE_CONTEXT_CREATE_PASS',
    v_message.event_id='16230000-0000-4000-8000-000000000001'::uuid,
    'event='||coalesce(v_message.event_id::text,'null')
  );

  insert into _boralog_162_results values (
    'DATE_STORES_MATCHING_PROJECT_PASS',
    v_message.project_id='16220000-0000-4000-8000-000000000001'::uuid,
    'project='||coalesce(v_message.project_id::text,'null')
  );
exception when others then
  insert into _boralog_162_results values ('DATE_CONTEXT_CREATE_PASS', false, sqlstate||' '||sqlerrm)
  on conflict (test) do update set pass=false, detail=excluded.detail;
  insert into _boralog_162_results values ('DATE_STORES_MATCHING_PROJECT_PASS', false, sqlstate||' '||sqlerrm)
  on conflict (test) do update set pass=false, detail=excluded.detail;
end $$;

do $$
declare
  v_denied boolean := false;
begin
  begin
    perform public.boralog_create_internal_message(
      '16210000-0000-4000-8000-000000000001',
      '162 cross org project',
      'ORGANIZATION',
      '{}'::uuid[],
      '16220000-0000-4000-8000-000000000003',
      null
    );
  exception when check_violation then
    v_denied := true;
  end;

  insert into _boralog_162_results values (
    'CROSS_ORGANIZATION_PROJECT_DENIED',
    v_denied,
    'denied='||v_denied
  );
end $$;

do $$
declare
  v_denied boolean := false;
begin
  begin
    perform public.boralog_create_internal_message(
      '16210000-0000-4000-8000-000000000001',
      '162 cross org date',
      'ORGANIZATION',
      '{}'::uuid[],
      null,
      '16230000-0000-4000-8000-000000000003'
    );
  exception when check_violation then
    v_denied := true;
  end;

  insert into _boralog_162_results values (
    'CROSS_ORGANIZATION_DATE_DENIED',
    v_denied,
    'denied='||v_denied
  );
end $$;

do $$
declare
  v_denied boolean := false;
begin
  begin
    perform public.boralog_create_internal_message(
      '16210000-0000-4000-8000-000000000001',
      '162 mismatch impossible',
      'ORGANIZATION',
      '{}'::uuid[],
      '16220000-0000-4000-8000-000000000002',
      '16230000-0000-4000-8000-000000000001'
    );
  exception when check_violation then
    v_denied := true;
  end;

  insert into _boralog_162_results values (
    'PROJECT_DATE_MISMATCH_IMPOSSIBLE',
    v_denied,
    'denied='||v_denied
  );
end $$;

do $$
declare
  v_message public.messages%rowtype;
begin
  select created.* into v_message
  from public.boralog_create_internal_message(
    '16210000-0000-4000-8000-000000000001',
    '162 organization audience still works',
    'ORGANIZATION',
    '{}'::uuid[],
    '16220000-0000-4000-8000-000000000001',
    null
  ) as created;

  insert into _boralog_162_results values (
    'ORGANIZATION_AUDIENCE_STILL_PASS',
    v_message.visibility='ORGANIZATION'
      and private._boralog_162_test_recipient_count(v_message.id)=0,
    'visibility='||v_message.visibility
  );
exception when others then
  insert into _boralog_162_results values ('ORGANIZATION_AUDIENCE_STILL_PASS', false, sqlstate||' '||sqlerrm);
end $$;

do $$
declare
  v_message public.messages%rowtype;
begin
  select created.* into v_message
  from public.boralog_create_internal_message(
    '16210000-0000-4000-8000-000000000001',
    '162 restricted audience still works',
    'RESTRICTED',
    array['16200000-0000-4000-8000-000000000002'::uuid],
    null,
    '16230000-0000-4000-8000-000000000001'
  ) as created;

  insert into _boralog_162_results values (
    'RESTRICTED_AUDIENCE_STILL_PASS',
    v_message.visibility='RESTRICTED'
      and private._boralog_162_test_recipient_count(v_message.id)=1,
    'visibility='||v_message.visibility
  );
exception when others then
  insert into _boralog_162_results values ('RESTRICTED_AUDIENCE_STILL_PASS', false, sqlstate||' '||sqlerrm);
end $$;

do $$
declare
  v_message public.messages%rowtype;
begin
  select created.* into v_message
  from public.boralog_create_internal_message(
    '16210000-0000-4000-8000-000000000001',
    '162 provenance preserved',
    'ORGANIZATION',
    '{}'::uuid[],
    null,
    '16230000-0000-4000-8000-000000000001'
  ) as created;

  insert into _boralog_162_results values (
    'PROVENANCE_155_PRESERVED',
    v_message.origin_type='INTERNAL'
      and v_message.author_user_id=auth.uid()
      and v_message.created_by=auth.uid()
      and v_message.external_author_label is null
      and v_message.source_kind is null
      and v_message.source_occurred_at is null,
    'origin='||coalesce(v_message.origin_type,'null')
  );
exception when others then
  insert into _boralog_162_results values ('PROVENANCE_155_PRESERVED', false, sqlstate||' '||sqlerrm);
end $$;

do $$
declare
  v_denied boolean := false;
  v_rows bigint;
begin
  begin
    perform public.boralog_create_internal_message(
      '16210000-0000-4000-8000-000000000001',
      '162 atomicity preserved',
      'RESTRICTED',
      array['16200000-0000-4000-8000-000000000001'::uuid, '16200000-0000-4000-8000-00000000ffff'::uuid],
      '16220000-0000-4000-8000-000000000001',
      null
    );
  exception when foreign_key_violation or check_violation then
    v_denied := true;
  end;

  select count(*) into v_rows
  from public.messages
  where content='162 atomicity preserved';

  insert into _boralog_162_results values (
    'ATOMICITY_161_PRESERVED',
    v_denied and v_rows=0,
    'denied='||v_denied||', rows='||v_rows
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','16200000-0000-4000-8000-000000000003',true);

do $$
declare
  v_message public.messages%rowtype;
begin
  select created.* into v_message
  from public.boralog_create_internal_message(
    '16210000-0000-4000-8000-000000000001',
    '162 limited accessible project',
    'ORGANIZATION',
    '{}'::uuid[],
    '16220000-0000-4000-8000-000000000001',
    null
  ) as created;

  insert into _boralog_162_results values (
    'LIMITED_ACCESSIBLE_PROJECT_PASS',
    v_message.project_id='16220000-0000-4000-8000-000000000001'::uuid,
    'project='||coalesce(v_message.project_id::text,'null')
  );
exception when others then
  insert into _boralog_162_results values ('LIMITED_ACCESSIBLE_PROJECT_PASS', false, sqlstate||' '||sqlerrm);
end $$;

do $$
declare
  v_denied boolean := false;
begin
  begin
    perform public.boralog_create_internal_message(
      '16210000-0000-4000-8000-000000000001',
      '162 limited inaccessible project',
      'RESTRICTED',
      array['16200000-0000-4000-8000-000000000002'::uuid],
      '16220000-0000-4000-8000-000000000002',
      null
    );
  exception when insufficient_privilege then
    v_denied := true;
  end;

  insert into _boralog_162_results values (
    'LIMITED_INACCESSIBLE_PROJECT_DENIED',
    v_denied,
    'denied='||v_denied
  );

  insert into _boralog_162_results values (
    'INACCESSIBLE_PROJECT_DENIED',
    v_denied,
    'denied='||v_denied
  );
end $$;

do $$
declare
  v_denied boolean := false;
begin
  begin
    perform public.boralog_create_internal_message(
      '16210000-0000-4000-8000-000000000001',
      '162 limited inaccessible date',
      'RESTRICTED',
      array['16200000-0000-4000-8000-000000000002'::uuid],
      null,
      '16230000-0000-4000-8000-000000000002'
    );
  exception when insufficient_privilege then
    v_denied := true;
  end;

  insert into _boralog_162_results values (
    'INACCESSIBLE_DATE_DENIED',
    v_denied,
    'denied='||v_denied
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','16200000-0000-4000-8000-000000000001',true);

do $$
declare
  v_message_id uuid;
begin
  select created.id into v_message_id
  from public.boralog_create_internal_message(
    '16210000-0000-4000-8000-000000000001',
    '162 confidentiality target',
    'RESTRICTED',
    array['16200000-0000-4000-8000-000000000002'::uuid],
    '16220000-0000-4000-8000-000000000001',
    null
  ) as created;
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','16200000-0000-4000-8000-000000000004',true);

do $$
declare
  v_seen bigint;
begin
  select count(*) into v_seen
  from public.messages
  where content='162 confidentiality target';

  insert into _boralog_162_results values (
    'CONFIDENTIALITY_157_PRESERVED',
    v_seen=0,
    'non_recipient_seen='||v_seen
  );
end $$;

reset role;

do $$
declare
  v_same boolean;
begin
  select to_jsonb(m)=snapshot.row_snapshot
    into v_same
  from public.messages as m
  cross join _boralog_162_historical_snapshot as snapshot
  where m.id='16240000-0000-4000-8000-000000000099';

  insert into _boralog_162_results values (
    'HISTORICAL_MESSAGES_UNCHANGED',
    coalesce(v_same,false),
    'unchanged='||coalesce(v_same,false)
  );
end $$;

do $$
begin
  if exists (select 1 from _boralog_162_results where not pass) then
    raise exception 'BORALOG-162 optional Message context test failed';
  end if;
end $$;

select test, pass, detail
from _boralog_162_results
order by test;

rollback;
