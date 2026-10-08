-- BORALOG-163 canonical Information + Message provenance tests.
-- All fixtures and writes are rolled back.

begin;

create temporary table _boralog_163_results (
  test text primary key,
  pass boolean not null,
  detail text
) on commit drop;

grant select, insert, update on _boralog_163_results to authenticated;

insert into auth.users (
  id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('16300000-0000-4000-8000-000000000001','authenticated','authenticated','boralog163-owner@example.invalid','{}','{"display_name":"Owner 163"}',now(),now()),
  ('16300000-0000-4000-8000-000000000002','authenticated','authenticated','boralog163-full@example.invalid','{}','{"display_name":"Full 163"}',now(),now()),
  ('16300000-0000-4000-8000-000000000003','authenticated','authenticated','boralog163-limited-a@example.invalid','{}','{"display_name":"Limited A 163"}',now(),now()),
  ('16300000-0000-4000-8000-000000000004','authenticated','authenticated','boralog163-limited-b@example.invalid','{}','{"display_name":"Limited B 163"}',now(),now());

set local role authenticated;
select set_config('request.jwt.claim.sub','16300000-0000-4000-8000-000000000001',true);

insert into public.organizations(id, name, slug, created_by)
values
  ('16310000-0000-4000-8000-000000000001','BORALOG 163 Primary Org','boralog-163-primary-org',auth.uid()),
  ('16310000-0000-4000-8000-000000000002','BORALOG 163 Other Org','boralog-163-other-org',auth.uid());

reset role;

insert into public.organization_memberships(
  organization_id, user_id, role, status, access_level
) values
  ('16310000-0000-4000-8000-000000000001','16300000-0000-4000-8000-000000000002',null,'active','full'),
  ('16310000-0000-4000-8000-000000000001','16300000-0000-4000-8000-000000000003',null,'active','limited'),
  ('16310000-0000-4000-8000-000000000001','16300000-0000-4000-8000-000000000004',null,'active','limited');

insert into public.projects(id, organization_id, name, created_by)
values
  ('16320000-0000-4000-8000-000000000001','16310000-0000-4000-8000-000000000001','Accessible Project 163','16300000-0000-4000-8000-000000000001'),
  ('16320000-0000-4000-8000-000000000002','16310000-0000-4000-8000-000000000001','Inaccessible Project 163','16300000-0000-4000-8000-000000000001'),
  ('16320000-0000-4000-8000-000000000003','16310000-0000-4000-8000-000000000002','Other Org Project 163','16300000-0000-4000-8000-000000000001');

insert into public.project_memberships(project_id, user_id, role)
values
  ('16320000-0000-4000-8000-000000000001','16300000-0000-4000-8000-000000000003',null),
  ('16320000-0000-4000-8000-000000000001','16300000-0000-4000-8000-000000000004',null);

insert into public.events(id, project_id, event_date, venue_name, city, created_by)
values
  ('16330000-0000-4000-8000-000000000001','16320000-0000-4000-8000-000000000001','2026-12-10','Accessible Venue','Nantes','16300000-0000-4000-8000-000000000001'),
  ('16330000-0000-4000-8000-000000000002','16320000-0000-4000-8000-000000000002','2026-12-11','Inaccessible Venue','Rennes','16300000-0000-4000-8000-000000000001'),
  ('16330000-0000-4000-8000-000000000003','16320000-0000-4000-8000-000000000003','2026-12-12','Other Venue','Paris','16300000-0000-4000-8000-000000000001');

-- Historical-like row: preserve a pre-155 Message shape exactly.
alter table public.messages disable trigger boralog_message_provenance_insert;
insert into public.messages(
  id, organization_id, content, created_by
) values (
  '16340000-0000-4000-8000-000000000099',
  '16310000-0000-4000-8000-000000000001',
  'BORALOG 163 untouched historical fixture',
  '16300000-0000-4000-8000-000000000001'
);
alter table public.messages enable trigger boralog_message_provenance_insert;

create temporary table _boralog_163_historical_snapshot
on commit drop
as
select to_jsonb(m) as row_snapshot
from public.messages as m
where m.id='16340000-0000-4000-8000-000000000099';

set local role authenticated;
select set_config('request.jwt.claim.sub','16300000-0000-4000-8000-000000000001',true);

-- Canonical source Messages.
create temporary table _boralog_163_sources (
  name text primary key,
  id uuid not null
) on commit drop;
grant select, insert on _boralog_163_sources to authenticated;

insert into _boralog_163_sources(name, id)
select 'org-1', created.id
from public.boralog_create_internal_message(
  '16310000-0000-4000-8000-000000000001',
  'BORALOG 163 source organization one',
  'ORGANIZATION',
  '{}'::uuid[],
  '16320000-0000-4000-8000-000000000001',
  null
) as created;

insert into _boralog_163_sources(name, id)
select 'org-2', created.id
from public.boralog_create_internal_message(
  '16310000-0000-4000-8000-000000000001',
  'BORALOG 163 source organization two',
  'ORGANIZATION',
  '{}'::uuid[],
  '16320000-0000-4000-8000-000000000001',
  null
) as created;

insert into _boralog_163_sources(name, id)
select 'restricted', created.id
from public.boralog_create_internal_message(
  '16310000-0000-4000-8000-000000000001',
  'BORALOG 163 restricted source',
  'RESTRICTED',
  array['16300000-0000-4000-8000-000000000002'::uuid],
  '16320000-0000-4000-8000-000000000001',
  null
) as created;

insert into _boralog_163_sources(name, id)
select 'other-org', created.id
from public.boralog_create_internal_message(
  '16310000-0000-4000-8000-000000000002',
  'BORALOG 163 source other organization',
  'ORGANIZATION',
  '{}'::uuid[],
  '16320000-0000-4000-8000-000000000003',
  null
) as created;

insert into public.message_reads(message_id, user_id)
select id, auth.uid()
from _boralog_163_sources
where name='org-1';

create temporary table _boralog_163_source_snapshot
on commit drop
as
select
  to_jsonb(m) as message_snapshot,
  (select count(*) from public.message_reads mr where mr.message_id=m.id) as read_count
from public.messages m
where m.id=(select id from _boralog_163_sources where name='org-1');

-- No context.
do $$
declare
  v_information public.informations%rowtype;
begin
  select created.* into v_information
  from public.boralog_create_information(
    '16310000-0000-4000-8000-000000000001',
    'Durable information without context',
    null,
    null,
    '{}'::uuid[]
  ) as created;

  insert into _boralog_163_results values (
    'INFORMATION_CREATE_NO_CONTEXT_PASS',
    v_information.id is not null
      and v_information.project_id is null
      and v_information.event_id is null
      and v_information.content='Durable information without context'
      and v_information.created_by=auth.uid(),
    'created='||(v_information.id is not null)
  );
exception when others then
  insert into _boralog_163_results values ('INFORMATION_CREATE_NO_CONTEXT_PASS', false, sqlstate||' '||sqlerrm);
end $$;

-- Project context.
do $$
declare
  v_information public.informations%rowtype;
begin
  select created.* into v_information
  from public.boralog_create_information(
    '16310000-0000-4000-8000-000000000001',
    'Durable project information',
    '16320000-0000-4000-8000-000000000001',
    null,
    array[(select id from _boralog_163_sources where name='org-1')]
  ) as created;

  insert into _boralog_163_results values (
    'INFORMATION_CREATE_PROJECT_PASS',
    v_information.project_id='16320000-0000-4000-8000-000000000001'::uuid
      and v_information.event_id is null,
    'project='||coalesce(v_information.project_id::text,'null')
  );

  insert into _boralog_163_results values (
    'SOURCE_MESSAGE_SAME_ORGANIZATION_PASS',
    exists (
      select 1
      from public.information_message_sources ims
      where ims.information_id=v_information.id
        and ims.message_id=(select id from _boralog_163_sources where name='org-1')
    ),
    'linked'
  );
exception when others then
  insert into _boralog_163_results values ('INFORMATION_CREATE_PROJECT_PASS', false, sqlstate||' '||sqlerrm)
  on conflict (test) do update set pass=false, detail=excluded.detail;
  insert into _boralog_163_results values ('SOURCE_MESSAGE_SAME_ORGANIZATION_PASS', false, sqlstate||' '||sqlerrm)
  on conflict (test) do update set pass=false, detail=excluded.detail;
end $$;

-- Date context stores the real owning Project.
do $$
declare
  v_information public.informations%rowtype;
begin
  select created.* into v_information
  from public.boralog_create_information(
    '16310000-0000-4000-8000-000000000001',
    'Durable date information',
    null,
    '16330000-0000-4000-8000-000000000001',
    '{}'::uuid[]
  ) as created;

  insert into _boralog_163_results values (
    'INFORMATION_CREATE_DATE_PASS',
    v_information.event_id='16330000-0000-4000-8000-000000000001'::uuid,
    'event='||coalesce(v_information.event_id::text,'null')
  );

  insert into _boralog_163_results values (
    'DATE_PROJECT_COHERENCE_PASS',
    v_information.project_id='16320000-0000-4000-8000-000000000001'::uuid,
    'project='||coalesce(v_information.project_id::text,'null')
  );
exception when others then
  insert into _boralog_163_results values ('INFORMATION_CREATE_DATE_PASS', false, sqlstate||' '||sqlerrm)
  on conflict (test) do update set pass=false, detail=excluded.detail;
  insert into _boralog_163_results values ('DATE_PROJECT_COHERENCE_PASS', false, sqlstate||' '||sqlerrm)
  on conflict (test) do update set pass=false, detail=excluded.detail;
end $$;

-- Empty content.
do $$
declare
  v_denied boolean := false;
begin
  begin
    perform public.boralog_create_information(
      '16310000-0000-4000-8000-000000000001',
      '   ',
      null,
      null,
      '{}'::uuid[]
    );
  exception when check_violation then
    v_denied := true;
  end;

  insert into _boralog_163_results values (
    'EMPTY_INFORMATION_DENIED',
    v_denied,
    'denied='||v_denied
  );
end $$;

-- Cross-organization Project and Date.
do $$
declare
  v_project_denied boolean := false;
  v_date_denied boolean := false;
begin
  begin
    perform public.boralog_create_information(
      '16310000-0000-4000-8000-000000000001',
      'Cross org project information',
      '16320000-0000-4000-8000-000000000003',
      null,
      '{}'::uuid[]
    );
  exception when check_violation then
    v_project_denied := true;
  end;

  begin
    perform public.boralog_create_information(
      '16310000-0000-4000-8000-000000000001',
      'Cross org date information',
      null,
      '16330000-0000-4000-8000-000000000003',
      '{}'::uuid[]
    );
  exception when check_violation then
    v_date_denied := true;
  end;

  insert into _boralog_163_results values (
    'CROSS_ORGANIZATION_PROJECT_DENIED',
    v_project_denied,
    'denied='||v_project_denied
  );

  insert into _boralog_163_results values (
    'CROSS_ORGANIZATION_DATE_DENIED',
    v_date_denied,
    'denied='||v_date_denied
  );
end $$;

-- Cross-organization source Message.
do $$
declare
  v_denied boolean := false;
  v_rows bigint;
begin
  begin
    perform public.boralog_create_information(
      '16310000-0000-4000-8000-000000000001',
      'Cross org source information',
      '16320000-0000-4000-8000-000000000001',
      null,
      array[(select id from _boralog_163_sources where name='other-org')]
    );
  exception when insufficient_privilege then
    v_denied := true;
  end;

  select count(*) into v_rows
  from public.informations
  where content='Cross org source information';

  insert into _boralog_163_results values (
    'SOURCE_MESSAGE_CROSS_ORGANIZATION_DENIED',
    v_denied and v_rows=0,
    'denied='||v_denied||', rows='||v_rows
  );
end $$;

-- One source Message can feed multiple Informations.
do $$
declare
  v_first uuid;
  v_second uuid;
  v_links bigint;
  v_source uuid;
begin
  select id into v_source from _boralog_163_sources where name='org-1';

  select created.id into v_first
  from public.boralog_create_information(
    '16310000-0000-4000-8000-000000000001',
    'One message multiple information A',
    '16320000-0000-4000-8000-000000000001',
    null,
    array[v_source]
  ) as created;

  select created.id into v_second
  from public.boralog_create_information(
    '16310000-0000-4000-8000-000000000001',
    'One message multiple information B',
    '16320000-0000-4000-8000-000000000001',
    null,
    array[v_source]
  ) as created;

  select count(*) into v_links
  from public.information_message_sources
  where message_id=v_source
    and information_id in (v_first, v_second);

  insert into _boralog_163_results values (
    'ONE_MESSAGE_MULTIPLE_INFORMATION_SOURCES_SUPPORTED',
    v_links=2,
    'links='||v_links
  );
exception when others then
  insert into _boralog_163_results values ('ONE_MESSAGE_MULTIPLE_INFORMATION_SOURCES_SUPPORTED', false, sqlstate||' '||sqlerrm);
end $$;

-- Multiple source Messages can feed one Information.
do $$
declare
  v_information_id uuid;
  v_links bigint;
begin
  select created.id into v_information_id
  from public.boralog_create_information(
    '16310000-0000-4000-8000-000000000001',
    'Multiple messages one information',
    '16320000-0000-4000-8000-000000000001',
    null,
    array[
      (select id from _boralog_163_sources where name='org-1'),
      (select id from _boralog_163_sources where name='org-2')
    ]
  ) as created;

  select count(*) into v_links
  from public.information_message_sources
  where information_id=v_information_id;

  insert into _boralog_163_results values (
    'MULTIPLE_MESSAGES_ONE_INFORMATION_SUPPORTED',
    v_links=2,
    'links='||v_links
  );
exception when others then
  insert into _boralog_163_results values ('MULTIPLE_MESSAGES_ONE_INFORMATION_SUPPORTED', false, sqlstate||' '||sqlerrm);
end $$;

-- Owner can create an Information from a RESTRICTED Message they can read.
do $$
declare
  v_information_id uuid;
begin
  select created.id into v_information_id
  from public.boralog_create_information(
    '16310000-0000-4000-8000-000000000001',
    'Information visible independently of restricted source',
    '16320000-0000-4000-8000-000000000001',
    null,
    array[(select id from _boralog_163_sources where name='restricted')]
  ) as created;

  insert into _boralog_163_results values (
    'ATOMIC_INFORMATION_AND_SOURCE_LINK_PASS',
    exists (
      select 1
      from public.informations i
      join public.information_message_sources ims on ims.information_id=i.id
      where i.id=v_information_id
        and ims.message_id=(select id from _boralog_163_sources where name='restricted')
    ),
    'information='||v_information_id
  );
exception when others then
  insert into _boralog_163_results values ('ATOMIC_INFORMATION_AND_SOURCE_LINK_PASS', false, sqlstate||' '||sqlerrm);
end $$;

-- Original Message and read state remain untouched after Information creation.
do $$
declare
  v_message_same boolean;
  v_read_same boolean;
begin
  select
    to_jsonb(m)=snapshot.message_snapshot,
    (select count(*) from public.message_reads mr where mr.message_id=m.id)=snapshot.read_count
  into v_message_same, v_read_same
  from public.messages m
  cross join _boralog_163_source_snapshot snapshot
  where m.id=(select id from _boralog_163_sources where name='org-1');

  insert into _boralog_163_results values (
    'MESSAGE_CONTENT_UNCHANGED',
    coalesce(v_message_same,false),
    'unchanged='||coalesce(v_message_same,false)
  );

  insert into _boralog_163_results values (
    'MESSAGE_STATUS_UNCHANGED',
    coalesce(v_message_same,false),
    'unchanged='||coalesce(v_message_same,false)
  );

  insert into _boralog_163_results values (
    'PROVENANCE_155_PRESERVED',
    coalesce(v_message_same,false),
    'unchanged='||coalesce(v_message_same,false)
  );

  insert into _boralog_163_results values (
    'READ_STATE_160_UNCHANGED',
    coalesce(v_read_same,false),
    'unchanged='||coalesce(v_read_same,false)
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','16300000-0000-4000-8000-000000000003',true);

-- LIMITED can create only inside an assigned Project.
do $$
declare
  v_information public.informations%rowtype;
begin
  select created.* into v_information
  from public.boralog_create_information(
    '16310000-0000-4000-8000-000000000001',
    'Limited accessible project information',
    '16320000-0000-4000-8000-000000000001',
    null,
    array[(select id from _boralog_163_sources where name='org-1')]
  ) as created;

  insert into _boralog_163_results values (
    'LIMITED_ACCESSIBLE_PROJECT_PASS',
    v_information.project_id='16320000-0000-4000-8000-000000000001'::uuid,
    'project='||coalesce(v_information.project_id::text,'null')
  );
exception when others then
  insert into _boralog_163_results values ('LIMITED_ACCESSIBLE_PROJECT_PASS', false, sqlstate||' '||sqlerrm);
end $$;

do $$
declare
  v_denied boolean := false;
begin
  begin
    perform public.boralog_create_information(
      '16310000-0000-4000-8000-000000000001',
      'Limited inaccessible project information',
      '16320000-0000-4000-8000-000000000002',
      null,
      '{}'::uuid[]
    );
  exception when insufficient_privilege then
    v_denied := true;
  end;

  insert into _boralog_163_results values (
    'LIMITED_INACCESSIBLE_PROJECT_DENIED',
    v_denied,
    'denied='||v_denied
  );
end $$;

-- LIMITED cannot source an otherwise inaccessible RESTRICTED Message.
do $$
declare
  v_denied boolean := false;
  v_rows bigint;
begin
  begin
    perform public.boralog_create_information(
      '16310000-0000-4000-8000-000000000001',
      'Limited inaccessible source information',
      '16320000-0000-4000-8000-000000000001',
      null,
      array[(select id from _boralog_163_sources where name='restricted')]
    );
  exception when insufficient_privilege then
    v_denied := true;
  end;

  select count(*) into v_rows
  from public.informations
  where content='Limited inaccessible source information';

  insert into _boralog_163_results values (
    'SOURCE_MESSAGE_INACCESSIBLE_DENIED',
    v_denied and v_rows=0,
    'denied='||v_denied||', rows='||v_rows
  );

  insert into _boralog_163_results values (
    'RESTRICTED_MESSAGE_CONFIDENTIALITY_PRESERVED',
    not exists (
      select 1
      from public.messages
      where id=(select id from _boralog_163_sources where name='restricted')
    ),
    'restricted_source_hidden'
  );
end $$;

-- LIMITED without Project/Date gets no general organization Information access.
do $$
declare
  v_create_denied boolean := false;
  v_contextless_seen bigint;
begin
  begin
    perform public.boralog_create_information(
      '16310000-0000-4000-8000-000000000001',
      'Limited contextless information denied',
      null,
      null,
      '{}'::uuid[]
    );
  exception when insufficient_privilege then
    v_create_denied := true;
  end;

  select count(*) into v_contextless_seen
  from public.informations
  where content='Durable information without context';

  insert into _boralog_163_results values (
    'LIMITED_CONTEXTLESS_INFORMATION_HIDDEN',
    v_create_denied and v_contextless_seen=0,
    'create_denied='||v_create_denied||', seen='||v_contextless_seen
  );
end $$;

-- Information can be visible while its source Message and provenance edge remain hidden.
do $$
declare
  v_information_seen bigint;
  v_message_seen bigint;
  v_link_seen bigint;
begin
  select count(*) into v_information_seen
  from public.informations
  where content='Information visible independently of restricted source';

  select count(*) into v_message_seen
  from public.messages
  where id=(select id from _boralog_163_sources where name='restricted');

  select count(*) into v_link_seen
  from public.information_message_sources ims
  join public.informations i on i.id=ims.information_id
  where i.content='Information visible independently of restricted source';

  insert into _boralog_163_results values (
    'INFORMATION_VISIBILITY_DOES_NOT_LEAK_SOURCE_MESSAGE',
    v_information_seen=1 and v_message_seen=0 and v_link_seen=0,
    'information='||v_information_seen||', message='||v_message_seen||', link='||v_link_seen
  );

  insert into _boralog_163_results values (
    'CONFIDENTIALITY_157_PRESERVED',
    v_message_seen=0,
    'message_seen='||v_message_seen
  );
end $$;

reset role;

-- Historical Message fixture stays byte-for-byte unchanged.
do $$
declare
  v_same boolean;
begin
  select to_jsonb(m)=snapshot.row_snapshot
    into v_same
  from public.messages m
  cross join _boralog_163_historical_snapshot snapshot
  where m.id='16340000-0000-4000-8000-000000000099';

  insert into _boralog_163_results values (
    'HISTORICAL_MESSAGES_UNCHANGED',
    coalesce(v_same,false),
    'unchanged='||coalesce(v_same,false)
  );
end $$;

do $$
begin
  if exists (select 1 from _boralog_163_results where not pass) then
    raise exception 'BORALOG-163 Information foundation test failed';
  end if;
end $$;

select test, pass, detail
from _boralog_163_results
order by test;

rollback;
