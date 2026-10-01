-- BORALOG-165 human Message processing flow tests.
-- Self-contained: all fixtures and writes are rolled back.

begin;

create temporary table _boralog_165_results (
  test text primary key,
  pass boolean not null,
  detail text
) on commit drop;
grant select, insert, update on _boralog_165_results to authenticated;

insert into auth.users (
  id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('16500000-0000-4000-8000-000000000001','authenticated','authenticated','owner165@example.invalid','{}','{}',now(),now()),
  ('16500000-0000-4000-8000-000000000002','authenticated','authenticated','full165@example.invalid','{}','{}',now(),now()),
  ('16500000-0000-4000-8000-000000000003','authenticated','authenticated','limited165@example.invalid','{}','{}',now(),now());

set local role authenticated;
select set_config('request.jwt.claim.sub','16500000-0000-4000-8000-000000000001',true);

insert into public.organizations(id,name,slug,created_by) values
  ('16510000-0000-4000-8000-000000000001','BORALOG 165 Primary','boralog-165-primary',auth.uid()),
  ('16510000-0000-4000-8000-000000000002','BORALOG 165 Other','boralog-165-other',auth.uid());

reset role;

insert into public.organization_memberships(
  organization_id,user_id,role,status,access_level
) values
  ('16510000-0000-4000-8000-000000000001','16500000-0000-4000-8000-000000000002',null,'active','full'),
  ('16510000-0000-4000-8000-000000000001','16500000-0000-4000-8000-000000000003',null,'active','limited');

insert into public.projects(id,organization_id,name,created_by) values
  ('16520000-0000-4000-8000-000000000001','16510000-0000-4000-8000-000000000001','Accessible 165','16500000-0000-4000-8000-000000000001'),
  ('16520000-0000-4000-8000-000000000002','16510000-0000-4000-8000-000000000001','Inaccessible 165','16500000-0000-4000-8000-000000000001'),
  ('16520000-0000-4000-8000-000000000003','16510000-0000-4000-8000-000000000002','Other Org 165','16500000-0000-4000-8000-000000000001');

insert into public.project_memberships(project_id,user_id,role) values
  ('16520000-0000-4000-8000-000000000001','16500000-0000-4000-8000-000000000003',null);

insert into public.events(id,project_id,event_date,created_by) values
  ('16530000-0000-4000-8000-000000000001','16520000-0000-4000-8000-000000000001','2026-12-27','16500000-0000-4000-8000-000000000001'),
  ('16530000-0000-4000-8000-000000000002','16520000-0000-4000-8000-000000000002','2026-12-28','16500000-0000-4000-8000-000000000001');

alter table public.messages disable trigger boralog_message_provenance_insert;
insert into public.messages(
  id,organization_id,content,created_by
) values (
  '16540000-0000-4000-8000-000000000099',
  '16510000-0000-4000-8000-000000000001',
  'BORALOG 165 untouched historical fixture',
  '16500000-0000-4000-8000-000000000001'
);
alter table public.messages enable trigger boralog_message_provenance_insert;

create temporary table _boralog_165_historical_snapshot on commit drop as
select to_jsonb(m) as snapshot
from public.messages m
where m.id='16540000-0000-4000-8000-000000000099';

set local role authenticated;
select set_config('request.jwt.claim.sub','16500000-0000-4000-8000-000000000001',true);

create temporary table _boralog_165_messages(
  name text primary key,
  id uuid not null
) on commit drop;
grant select, insert on _boralog_165_messages to authenticated;

insert into _boralog_165_messages
select 'no-follow-up',id from public.boralog_create_internal_message(
  '16510000-0000-4000-8000-000000000001','165 no follow up','ORGANIZATION','{}',null,null
);

insert into _boralog_165_messages
select 'info-project',id from public.boralog_create_internal_message(
  '16510000-0000-4000-8000-000000000001','165 info project','ORGANIZATION','{}','16520000-0000-4000-8000-000000000001',null
);

insert into _boralog_165_messages
select 'task-date',id from public.boralog_create_internal_message(
  '16510000-0000-4000-8000-000000000001','165 task date','ORGANIZATION','{}',null,'16530000-0000-4000-8000-000000000001'
);

insert into _boralog_165_messages
select 'mixed',id from public.boralog_create_internal_message(
  '16510000-0000-4000-8000-000000000001','165 mixed','ORGANIZATION','{}','16520000-0000-4000-8000-000000000001',null
);

insert into _boralog_165_messages
select 'multi-info',id from public.boralog_create_internal_message(
  '16510000-0000-4000-8000-000000000001','165 multi info','ORGANIZATION','{}','16520000-0000-4000-8000-000000000001',null
);

insert into _boralog_165_messages
select 'multi-task',id from public.boralog_create_internal_message(
  '16510000-0000-4000-8000-000000000001','165 multi task','ORGANIZATION','{}','16520000-0000-4000-8000-000000000001',null
);

insert into _boralog_165_messages
select 'multi-mixed',id from public.boralog_create_internal_message(
  '16510000-0000-4000-8000-000000000001','165 multi mixed','ORGANIZATION','{}','16520000-0000-4000-8000-000000000001',null
);

insert into _boralog_165_messages
select 'restricted-owner',id from public.boralog_create_internal_message(
  '16510000-0000-4000-8000-000000000001','165 restricted source','RESTRICTED',
  array['16500000-0000-4000-8000-000000000002'::uuid],
  '16520000-0000-4000-8000-000000000001',null
);

insert into _boralog_165_messages
select 'limited-inaccessible',id from public.boralog_create_internal_message(
  '16510000-0000-4000-8000-000000000001','165 inaccessible limited','ORGANIZATION','{}',
  '16520000-0000-4000-8000-000000000002',null
);

insert into _boralog_165_messages
select 'limited-contextless-no-follow-up',id from public.boralog_create_internal_message(
  '16510000-0000-4000-8000-000000000001','165 limited contextless close','RESTRICTED',
  array['16500000-0000-4000-8000-000000000003'::uuid],
  null,null
);

insert into _boralog_165_messages
select 'limited-contextless-consequence',id from public.boralog_create_internal_message(
  '16510000-0000-4000-8000-000000000001','165 limited contextless consequence','RESTRICTED',
  array['16500000-0000-4000-8000-000000000003'::uuid],
  null,null
);

insert into public.message_reads(message_id,user_id)
select id,auth.uid()
from _boralog_165_messages
where name='info-project';

create temporary table _boralog_165_message_snapshot on commit drop as
select
  to_jsonb(m) as snapshot,
  (select count(*) from public.message_recipients r where r.message_id=m.id) as recipient_count,
  (select count(*) from public.message_reads r where r.message_id=m.id) as read_count
from public.messages m
where m.id=(select id from _boralog_165_messages where name='info-project');

-- A: explicit no follow up.
do $$
declare
  m public.messages%rowtype;
begin
  select processed.* into m
  from public.boralog_process_message(
    (select id from _boralog_165_messages where name='no-follow-up'),
    'NO_FOLLOW_UP','{}'::text[],'{}'::text[]
  ) processed;

  insert into _boralog_165_results values
    ('PROCESS_NO_FOLLOW_UP_PASS',m.status='PROCESSED','status='||m.status),
    ('NO_FOLLOW_UP_RESOLUTION_PASS',m.resolution='NO_FOLLOW_UP','resolution='||coalesce(m.resolution,'null')),
    ('PROCESSED_AT_SET',m.processed_at is not null,''),
    ('PROCESSED_BY_ACTOR',m.processed_by=auth.uid(),'');
end $$;

-- One Information and inherited Project.
do $$
declare
  m public.messages%rowtype;
  info public.informations%rowtype;
begin
  select processed.* into m
  from public.boralog_process_message(
    (select id from _boralog_165_messages where name='info-project'),
    'CONSEQUENCES_CREATED',
    array['Durable information 165'],
    '{}'::text[]
  ) processed;

  select i.* into info
  from public.informations i
  join public.information_message_sources s on s.information_id=i.id
  where s.message_id=m.id and i.content='Durable information 165';

  insert into _boralog_165_results values
    ('PROCESS_ONE_INFORMATION_PASS',info.id is not null,''),
    ('CONSEQUENCES_CREATED_RESOLUTION_PASS',m.status='PROCESSED' and m.resolution='CONSEQUENCES_CREATED',''),
    ('INFORMATION_PROVENANCE_PASS',exists(select 1 from public.information_message_sources s where s.information_id=info.id and s.message_id=m.id),''),
    ('INFORMATION_CONTEXT_INHERITS_MESSAGE',info.project_id=m.project_id and info.event_id is null,'');
end $$;

-- One Task and inherited Date.
do $$
declare
  m public.messages%rowtype;
  t public.tasks%rowtype;
begin
  select processed.* into m
  from public.boralog_process_message(
    (select id from _boralog_165_messages where name='task-date'),
    'CONSEQUENCES_CREATED',
    '{}'::text[],
    array['Human task 165']
  ) processed;

  select task.* into t
  from public.tasks task
  join public.task_message_sources s on s.task_id=task.id
  where s.message_id=m.id and task.content='Human task 165';

  insert into _boralog_165_results values
    ('PROCESS_ONE_TASK_PASS',t.id is not null,''),
    ('TASK_PROVENANCE_PASS',exists(select 1 from public.task_message_sources s where s.task_id=t.id and s.message_id=m.id),''),
    ('TASK_CONTEXT_INHERITS_MESSAGE',t.project_id=m.project_id and t.event_id=m.event_id,'');
end $$;

-- Information + Task.
do $$
declare
  mid uuid := (select id from _boralog_165_messages where name='mixed');
begin
  perform public.boralog_process_message(
    mid,'CONSEQUENCES_CREATED',
    array['Mixed information 165'],
    array['Mixed task 165']
  );

  insert into _boralog_165_results values (
    'PROCESS_INFORMATION_AND_TASK_PASS',
    (select count(*) from public.information_message_sources where message_id=mid)=1
      and (select count(*) from public.task_message_sources where message_id=mid)=1,
    ''
  );
end $$;

-- Multiple Informations.
do $$
declare
  mid uuid := (select id from _boralog_165_messages where name='multi-info');
begin
  perform public.boralog_process_message(
    mid,'CONSEQUENCES_CREATED',
    array['Info 165 A','Info 165 B','Info 165 C'],
    '{}'::text[]
  );
  insert into _boralog_165_results values (
    'PROCESS_MULTIPLE_INFORMATIONS_PASS',
    (select count(*) from public.information_message_sources where message_id=mid)=3,
    ''
  );
end $$;

-- Multiple Tasks.
do $$
declare
  mid uuid := (select id from _boralog_165_messages where name='multi-task');
begin
  perform public.boralog_process_message(
    mid,'CONSEQUENCES_CREATED',
    '{}'::text[],
    array['Task 165 A','Task 165 B','Task 165 C']
  );
  insert into _boralog_165_results values (
    'PROCESS_MULTIPLE_TASKS_PASS',
    (select count(*) from public.task_message_sources where message_id=mid)=3,
    ''
  );
end $$;

-- Multiple mixed consequences.
do $$
declare
  mid uuid := (select id from _boralog_165_messages where name='multi-mixed');
begin
  perform public.boralog_process_message(
    mid,'CONSEQUENCES_CREATED',
    array['Mixed Info 165 A','Mixed Info 165 B'],
    array['Mixed Task 165 A','Mixed Task 165 B']
  );
  insert into _boralog_165_results values (
    'PROCESS_MULTIPLE_MIXED_CONSEQUENCES_PASS',
    (select count(*) from public.information_message_sources where message_id=mid)=2
      and (select count(*) from public.task_message_sources where message_id=mid)=2,
    ''
  );
end $$;

-- Empty consequence mode, no-follow-up + consequence, and blank content are denied.
do $$
declare
  empty_mid uuid;
  no_follow_mid uuid;
  blank_mid uuid;
  empty_denied boolean:=false;
  no_follow_denied boolean:=false;
  blank_denied boolean:=false;
begin
  select id into empty_mid from public.boralog_create_internal_message(
    '16510000-0000-4000-8000-000000000001','165 empty consequence','ORGANIZATION','{}',null,null
  );
  select id into no_follow_mid from public.boralog_create_internal_message(
    '16510000-0000-4000-8000-000000000001','165 no follow conflict','ORGANIZATION','{}',null,null
  );
  select id into blank_mid from public.boralog_create_internal_message(
    '16510000-0000-4000-8000-000000000001','165 blank consequence','ORGANIZATION','{}',null,null
  );

  begin
    perform public.boralog_process_message(empty_mid,'CONSEQUENCES_CREATED','{}','{}');
  exception when check_violation then empty_denied:=true;
  end;

  begin
    perform public.boralog_process_message(no_follow_mid,'NO_FOLLOW_UP',array['Should not exist'],'{}');
  exception when check_violation then no_follow_denied:=true;
  end;

  begin
    perform public.boralog_process_message(blank_mid,'CONSEQUENCES_CREATED',array['   '],'{}');
  exception when check_violation then blank_denied:=true;
  end;

  insert into _boralog_165_results values
    ('PROCESS_EMPTY_WITHOUT_NO_FOLLOW_UP_DENIED',empty_denied,''),
    ('PROCESS_NO_FOLLOW_UP_WITH_CONSEQUENCE_DENIED',no_follow_denied,''),
    ('PROCESS_NONEMPTY_CONTENT_REQUIRED',blank_denied,'');
end $$;

-- Already processed cannot be processed again.
do $$
declare
  mid uuid;
  denied boolean:=false;
begin
  select id into mid from public.boralog_create_internal_message(
    '16510000-0000-4000-8000-000000000001','165 process once','ORGANIZATION','{}',null,null
  );
  perform public.boralog_process_message(mid,'NO_FOLLOW_UP','{}','{}');
  begin
    perform public.boralog_process_message(mid,'NO_FOLLOW_UP','{}','{}');
  exception when check_violation then denied:=true;
  end;

  insert into _boralog_165_results values ('PROCESS_ALREADY_PROCESSED_DENIED',denied,'');
end $$;

-- Direct CONSEQUENCES_CREATED transition without a source link is denied.
do $$
declare
  mid uuid;
  denied boolean:=false;
  current_status text;
begin
  select id into mid from public.boralog_create_internal_message(
    '16510000-0000-4000-8000-000000000001','165 direct invalid close','ORGANIZATION','{}',null,null
  );

  begin
    update public.messages
    set status='PROCESSED',resolution='CONSEQUENCES_CREATED'
    where id=mid;
  exception when check_violation then denied:=true;
  end;

  select status into current_status from public.messages where id=mid;
  insert into _boralog_165_results values (
    'CONSEQUENCES_CREATED_REQUIRES_SOURCE_LINK',
    denied and current_status='TO_PROCESS',
    ''
  );
end $$;

-- Force a failure after an Information was inserted; the whole RPC must roll back.
reset role;
create or replace function private._boralog_165_force_task_failure()
returns trigger
language plpgsql
as $$
begin
  if new.content='FORCE TASK FAILURE 165' then
    raise exception 'forced task failure' using errcode='23514';
  end if;
  return new;
end
$$;
create trigger _boralog_165_force_task_failure
before insert on public.tasks
for each row execute function private._boralog_165_force_task_failure();

set local role authenticated;
select set_config('request.jwt.claim.sub','16500000-0000-4000-8000-000000000001',true);

do $$
declare
  mid uuid;
  denied boolean:=false;
  information_rows bigint;
  task_rows bigint;
  message_status text;
begin
  select id into mid from public.boralog_create_internal_message(
    '16510000-0000-4000-8000-000000000001','165 atomic failure','ORGANIZATION','{}',
    '16520000-0000-4000-8000-000000000001',null
  );

  begin
    perform public.boralog_process_message(
      mid,'CONSEQUENCES_CREATED',
      array['ATOMIC INFORMATION 165'],
      array['FORCE TASK FAILURE 165']
    );
  exception when check_violation then denied:=true;
  end;

  select count(*) into information_rows from public.informations where content='ATOMIC INFORMATION 165';
  select count(*) into task_rows from public.tasks where content='FORCE TASK FAILURE 165';
  select status into message_status from public.messages where id=mid;

  insert into _boralog_165_results values
    ('PROCESS_ATOMICITY_PASS',denied and information_rows=0 and task_rows=0 and message_status='TO_PROCESS',''),
    ('PROCESS_FAILURE_LEAVES_NO_INFORMATION',information_rows=0,''),
    ('PROCESS_FAILURE_LEAVES_NO_TASK',task_rows=0,''),
    ('PROCESS_FAILURE_LEAVES_MESSAGE_TO_PROCESS',message_status='TO_PROCESS','');
end $$;

-- Message source fields, recipients and reads remain unchanged except processing fields.
do $$
declare
  mid uuid := (select id from _boralog_165_messages where name='info-project');
  before_row jsonb;
  after_row jsonb;
  before_recipient_count bigint;
  after_recipient_count bigint;
  before_read_count bigint;
  after_read_count bigint;
begin
  select snapshot,recipient_count,read_count
    into before_row,before_recipient_count,before_read_count
  from _boralog_165_message_snapshot;

  select to_jsonb(m), 
         (select count(*) from public.message_recipients r where r.message_id=m.id),
         (select count(*) from public.message_reads r where r.message_id=m.id)
    into after_row,after_recipient_count,after_read_count
  from public.messages m where m.id=mid;

  insert into _boralog_165_results values
    ('MESSAGE_CONTENT_UNCHANGED',after_row->'content'=before_row->'content',''),
    ('MESSAGE_CONTEXT_UNCHANGED',after_row->'project_id'=before_row->'project_id' and after_row->'event_id'=before_row->'event_id',''),
    ('MESSAGE_VISIBILITY_UNCHANGED',after_row->'visibility'=before_row->'visibility',''),
    ('MESSAGE_RECIPIENTS_UNCHANGED',after_recipient_count=before_recipient_count,''),
    ('MESSAGE_READ_STATE_UNCHANGED',after_read_count=before_read_count,'');
end $$;

-- Last consequence link cannot be removed from a processed CONSEQUENCES_CREATED Message.
create temporary table _boralog_165_last_link(
  message_id uuid not null,
  information_id uuid not null
) on commit drop;

do $
declare
  mid uuid;
  info_id uuid;
begin
  select id into mid from public.boralog_create_internal_message(
    '16510000-0000-4000-8000-000000000001','165 last link guard','ORGANIZATION','{}',
    '16520000-0000-4000-8000-000000000001',null
  );

  perform public.boralog_process_message(
    mid,'CONSEQUENCES_CREATED',array['Only consequence 165'],'{}'
  );

  select information_id into info_id
  from public.information_message_sources
  where message_id=mid;

  insert into _boralog_165_last_link values (mid,info_id);
end $;

reset role;

do $
declare
  mid uuid;
  info_id uuid;
  denied boolean:=false;
begin
  select message_id,information_id into mid,info_id
  from _boralog_165_last_link;

  begin
    delete from public.information_message_sources
    where information_id=info_id and message_id=mid;
    set constraints all immediate;
  exception when check_violation then
    denied:=true;
  end;

  set constraints all deferred;

  insert into _boralog_165_results values (
    'LAST_CONSEQUENCE_LINK_DELETE_DENIED_WHEN_PROCESSED',
    denied and exists(
      select 1 from public.information_message_sources
      where information_id=info_id and message_id=mid
    ),
    ''
  );
end $;

set local role authenticated;
select set_config('request.jwt.claim.sub','16500000-0000-4000-8000-000000000001',true);

-- Restricted Message: owner can process, LIMITED can see consequence but not source nor provenance edge.
do $$
declare
  mid uuid := (select id from _boralog_165_messages where name='restricted-owner');
begin
  perform public.boralog_process_message(
    mid,'CONSEQUENCES_CREATED',array['Restricted consequence visible 165'],'{}'
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','16500000-0000-4000-8000-000000000003',true);

do $$
declare
  mid uuid := (select id from _boralog_165_messages where name='restricted-owner');
  message_seen bigint;
  info_seen bigint;
  source_seen bigint;
  denied boolean:=false;
begin
  select count(*) into message_seen from public.messages where id=mid;
  select count(*) into info_seen from public.informations where content='Restricted consequence visible 165';
  select count(*) into source_seen
  from public.information_message_sources s
  join public.informations i on i.id=s.information_id
  where i.content='Restricted consequence visible 165';

  begin
    perform public.boralog_process_message(mid,'NO_FOLLOW_UP','{}','{}');
  exception when others then denied:=true;
  end;

  insert into _boralog_165_results values
    ('PROCESS_RESTRICTED_ACCESS_RULES_PRESERVED',message_seen=0 and denied,''),
    ('PROCESS_INACCESSIBLE_MESSAGE_DENIED',denied,''),
    ('PROCESS_RESTRICTED_ACCESS_RULES_PRESERVED_DETAIL',message_seen=0,''),
    ('PROCESS_RESTRICTED_ACCESS_RULES_PRESERVED_CONSEQUENCE',info_seen=1 and source_seen=0,'');
end $$;

-- LIMITED: accessible contextual consequence works; inaccessible Project and contextless consequence remain denied.
do $$
declare
  accessible_mid uuid;
  inaccessible_mid uuid := (select id from _boralog_165_messages where name='limited-inaccessible');
  contextless_close_mid uuid := (select id from _boralog_165_messages where name='limited-contextless-no-follow-up');
  contextless_consequence_mid uuid := (select id from _boralog_165_messages where name='limited-contextless-consequence');
  accessible_pass boolean:=false;
  inaccessible_denied boolean:=false;
  contextless_consequence_denied boolean:=false;
  contextless_close_pass boolean:=false;
begin
  select id into accessible_mid from public.boralog_create_internal_message(
    '16510000-0000-4000-8000-000000000001','165 limited accessible process','RESTRICTED',
    array['16500000-0000-4000-8000-000000000003'::uuid],
    '16520000-0000-4000-8000-000000000001',null
  );

  perform public.boralog_process_message(
    accessible_mid,'CONSEQUENCES_CREATED',array['Limited durable 165'],'{}'
  );
  accessible_pass:=exists(
    select 1 from public.information_message_sources where message_id=accessible_mid
  );

  begin
    perform public.boralog_process_message(
      inaccessible_mid,'NO_FOLLOW_UP','{}','{}'
    );
  exception when others then inaccessible_denied:=true;
  end;

  perform public.boralog_process_message(
    contextless_close_mid,'NO_FOLLOW_UP','{}','{}'
  );
  contextless_close_pass:=exists(
    select 1 from public.messages
    where id=contextless_close_mid and status='PROCESSED' and resolution='NO_FOLLOW_UP'
  );

  begin
    perform public.boralog_process_message(
      contextless_consequence_mid,'CONSEQUENCES_CREATED',array['Forbidden contextless info 165'],'{}'
    );
  exception when insufficient_privilege then contextless_consequence_denied:=true;
  end;

  insert into _boralog_165_results values (
    'LIMITED_RULES_PRESERVED',
    accessible_pass
      and inaccessible_denied
      and contextless_close_pass
      and contextless_consequence_denied
      and exists(
        select 1 from public.messages
        where id=contextless_consequence_mid and status='TO_PROCESS'
      )
      and not exists(
        select 1 from public.informations where content='Forbidden contextless info 165'
      ),
    ''
  );
end $$;

reset role;

-- Historical Message remains unchanged before any human smoke.
do $$
declare
  same boolean;
begin
  select to_jsonb(m)=h.snapshot into same
  from public.messages m
  cross join _boralog_165_historical_snapshot h
  where m.id='16540000-0000-4000-8000-000000000099';

  insert into _boralog_165_results values (
    'HISTORICAL_MESSAGES_UNCHANGED_BEFORE_SMOKE',
    coalesce(same,false),
    ''
  );
end $$;

do $$
begin
  if exists(select 1 from _boralog_165_results where not pass) then
    raise exception 'BORALOG-165 processing test failed';
  end if;
end $$;

select test,pass,detail
from _boralog_165_results
order by test;

rollback;
