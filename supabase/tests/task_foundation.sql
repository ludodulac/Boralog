-- BORALOG-164 canonical Task + Message provenance tests.
begin;

create temporary table _r(test text primary key, pass boolean not null, detail text) on commit drop;
grant select, insert, update on _r to authenticated;

insert into auth.users(id,aud,role,email,raw_app_meta_data,raw_user_meta_data,created_at,updated_at) values
('16400000-0000-4000-8000-000000000001','authenticated','authenticated','o164@example.invalid','{}','{}',now(),now()),
('16400000-0000-4000-8000-000000000002','authenticated','authenticated','f164@example.invalid','{}','{}',now(),now()),
('16400000-0000-4000-8000-000000000003','authenticated','authenticated','l164@example.invalid','{}','{}',now(),now()),
('16400000-0000-4000-8000-000000000004','authenticated','authenticated','x164@example.invalid','{}','{}',now(),now());

set local role authenticated;
select set_config('request.jwt.claim.sub','16400000-0000-4000-8000-000000000001',true);
insert into public.organizations(id,name,slug,created_by) values
('16410000-0000-4000-8000-000000000001','Org 164','org-164-a',auth.uid()),
('16410000-0000-4000-8000-000000000002','Other 164','org-164-b',auth.uid());
reset role;

insert into public.organization_memberships(organization_id,user_id,role,status,access_level) values
('16410000-0000-4000-8000-000000000001','16400000-0000-4000-8000-000000000002',null,'active','full'),
('16410000-0000-4000-8000-000000000001','16400000-0000-4000-8000-000000000003',null,'active','limited');

insert into public.projects(id,organization_id,name,created_by) values
('16420000-0000-4000-8000-000000000001','16410000-0000-4000-8000-000000000001','Accessible 164','16400000-0000-4000-8000-000000000001'),
('16420000-0000-4000-8000-000000000002','16410000-0000-4000-8000-000000000001','Inaccessible 164','16400000-0000-4000-8000-000000000001'),
('16420000-0000-4000-8000-000000000003','16410000-0000-4000-8000-000000000002','Other 164','16400000-0000-4000-8000-000000000001');

insert into public.project_memberships(project_id,user_id,role) values
('16420000-0000-4000-8000-000000000001','16400000-0000-4000-8000-000000000003',null);

insert into public.events(id,project_id,event_date,created_by) values
('16430000-0000-4000-8000-000000000001','16420000-0000-4000-8000-000000000001','2026-12-20','16400000-0000-4000-8000-000000000001'),
('16430000-0000-4000-8000-000000000002','16420000-0000-4000-8000-000000000002','2026-12-21','16400000-0000-4000-8000-000000000001'),
('16430000-0000-4000-8000-000000000003','16420000-0000-4000-8000-000000000003','2026-12-22','16400000-0000-4000-8000-000000000001');

alter table public.messages disable trigger boralog_message_provenance_insert;
insert into public.messages(id,organization_id,content,created_by) values
('16440000-0000-4000-8000-000000000099','16410000-0000-4000-8000-000000000001','Historical 164','16400000-0000-4000-8000-000000000001');
alter table public.messages enable trigger boralog_message_provenance_insert;

create temporary table _hist on commit drop as
select to_jsonb(m) snap from public.messages m where id='16440000-0000-4000-8000-000000000099';

set local role authenticated;
select set_config('request.jwt.claim.sub','16400000-0000-4000-8000-000000000001',true);

create temporary table _src(name text primary key,id uuid not null) on commit drop;
grant select,insert on _src to authenticated;
insert into _src select 'org1',id from public.boralog_create_internal_message('16410000-0000-4000-8000-000000000001','source 1','ORGANIZATION','{}','16420000-0000-4000-8000-000000000001',null);
insert into _src select 'org2',id from public.boralog_create_internal_message('16410000-0000-4000-8000-000000000001','source 2','ORGANIZATION','{}','16420000-0000-4000-8000-000000000001',null);
insert into _src select 'restricted',id from public.boralog_create_internal_message('16410000-0000-4000-8000-000000000001','restricted source','RESTRICTED',array['16400000-0000-4000-8000-000000000002'::uuid],'16420000-0000-4000-8000-000000000001',null);
insert into _src select 'other',id from public.boralog_create_internal_message('16410000-0000-4000-8000-000000000002','other source','ORGANIZATION','{}','16420000-0000-4000-8000-000000000003',null);

insert into public.message_reads(message_id,user_id) select id,auth.uid() from _src where name='org1';
create temporary table _msgsnap on commit drop as
select to_jsonb(m) snap,(select count(*) from public.message_reads mr where mr.message_id=m.id) reads
from public.messages m where m.id=(select id from _src where name='org1');

select id as info_id into temporary table _info from public.boralog_create_information(
'16410000-0000-4000-8000-000000000001','Info untouched','16420000-0000-4000-8000-000000000001',null,'{}');
create temporary table _infosnap on commit drop as
select to_jsonb(i) snap from public.informations i where i.id=(select info_id from _info);

do $$
declare t public.tasks%rowtype;
begin
  select * into t from public.boralog_create_task('16410000-0000-4000-8000-000000000001','No context task',null,null,'{}');
  insert into _r values ('TASK_CREATE_NO_CONTEXT_PASS',t.project_id is null and t.event_id is null,'');
  insert into _r values ('TASK_DEFAULT_STATUS_TO_DO',t.status='TO_DO' and t.completed_at is null and t.completed_by is null,t.status);
end $$;

do $$
declare t public.tasks%rowtype;
begin
  select * into t from public.boralog_create_task('16410000-0000-4000-8000-000000000001','Project task','16420000-0000-4000-8000-000000000001',null,array[(select id from _src where name='org1')]);
  insert into _r values ('TASK_CREATE_PROJECT_PASS',t.project_id='16420000-0000-4000-8000-000000000001' and t.event_id is null,'');
  insert into _r values ('SOURCE_MESSAGE_SAME_ORGANIZATION_PASS',exists(select 1 from public.task_message_sources s where s.task_id=t.id and s.message_id=(select id from _src where name='org1')),'');
end $$;

do $$
declare t public.tasks%rowtype;
begin
  select * into t from public.boralog_create_task('16410000-0000-4000-8000-000000000001','Date task',null,'16430000-0000-4000-8000-000000000001','{}');
  insert into _r values ('TASK_CREATE_DATE_PASS',t.event_id='16430000-0000-4000-8000-000000000001','');
  insert into _r values ('DATE_PROJECT_COHERENCE_PASS',t.project_id='16420000-0000-4000-8000-000000000001','');
end $$;

do $$
declare denied boolean:=false;
begin
  begin perform public.boralog_create_task('16410000-0000-4000-8000-000000000001','   ',null,null,'{}'); exception when check_violation then denied:=true; end;
  insert into _r values ('EMPTY_TASK_DENIED',denied,'');
end $$;

do $$
declare t public.tasks%rowtype; done public.tasks%rowtype; reopened public.tasks%rowtype;
begin
  select * into t from public.boralog_create_task('16410000-0000-4000-8000-000000000001','Completion task','16420000-0000-4000-8000-000000000001',null,'{}');
  select * into done from public.boralog_set_task_status(t.id,'DONE');
  insert into _r values ('TASK_COMPLETE_PASS',done.status='DONE','');
  insert into _r values ('TASK_COMPLETE_SETS_COMPLETED_AT',done.completed_at is not null,'');
  insert into _r values ('TASK_COMPLETE_SETS_COMPLETED_BY',done.completed_by=auth.uid(),'');
  select * into reopened from public.boralog_set_task_status(t.id,'TO_DO');
  insert into _r values ('TASK_REOPEN_PASS',reopened.status='TO_DO','');
  insert into _r values ('TASK_REOPEN_CLEARS_COMPLETION_METADATA',reopened.completed_at is null and reopened.completed_by is null,'');
end $$;

do $$
declare pd boolean:=false; dd boolean:=false;
begin
  begin perform public.boralog_create_task('16410000-0000-4000-8000-000000000001','Cross P','16420000-0000-4000-8000-000000000003',null,'{}'); exception when check_violation then pd:=true; end;
  begin perform public.boralog_create_task('16410000-0000-4000-8000-000000000001','Cross D',null,'16430000-0000-4000-8000-000000000003','{}'); exception when check_violation then dd:=true; end;
  insert into _r values ('CROSS_ORGANIZATION_PROJECT_DENIED',pd,'');
  insert into _r values ('CROSS_ORGANIZATION_DATE_DENIED',dd,'');
end $$;

do $$
declare denied boolean:=false; rows bigint;
begin
  begin perform public.boralog_create_task('16410000-0000-4000-8000-000000000001','Cross source','16420000-0000-4000-8000-000000000001',null,array[(select id from _src where name='other')]); exception when insufficient_privilege then denied:=true; end;
  select count(*) into rows from public.tasks where content='Cross source';
  insert into _r values ('SOURCE_MESSAGE_CROSS_ORGANIZATION_DENIED',denied and rows=0,'');
end $$;

do $$
declare a uuid;b uuid;links bigint;s uuid;
begin
  select id into s from _src where name='org1';
  select id into a from public.boralog_create_task('16410000-0000-4000-8000-000000000001','Multi task A','16420000-0000-4000-8000-000000000001',null,array[s]);
  select id into b from public.boralog_create_task('16410000-0000-4000-8000-000000000001','Multi task B','16420000-0000-4000-8000-000000000001',null,array[s]);
  select count(*) into links from public.task_message_sources where message_id=s and task_id in(a,b);
  insert into _r values ('ONE_MESSAGE_MULTIPLE_TASKS_SUPPORTED',links=2,'');
end $$;

do $$
declare tid uuid;links bigint;
begin
  select id into tid from public.boralog_create_task('16410000-0000-4000-8000-000000000001','Multi sources task','16420000-0000-4000-8000-000000000001',null,array[(select id from _src where name='org1'),(select id from _src where name='org2')]);
  select count(*) into links from public.task_message_sources where task_id=tid;
  insert into _r values ('MULTIPLE_MESSAGES_ONE_TASK_SUPPORTED',links=2,'');
end $$;

do $$
declare tid uuid;
begin
  select id into tid from public.boralog_create_task('16410000-0000-4000-8000-000000000001','Restricted-source task','16420000-0000-4000-8000-000000000001',null,array[(select id from _src where name='restricted')]);
  insert into _r values ('ATOMIC_TASK_AND_SOURCE_LINK_PASS',exists(select 1 from public.task_message_sources where task_id=tid and message_id=(select id from _src where name='restricted')),'');
end $$;

do $$
declare same boolean; reads_same boolean; info_same boolean;
begin
  select to_jsonb(m)=s.snap,(select count(*) from public.message_reads mr where mr.message_id=m.id)=s.reads
  into same,reads_same from public.messages m cross join _msgsnap s where m.id=(select id from _src where name='org1');
  select to_jsonb(i)=s.snap into info_same from public.informations i cross join _infosnap s where i.id=(select info_id from _info);
  insert into _r values ('MESSAGE_CONTENT_UNCHANGED',same,'');
  insert into _r values ('MESSAGE_STATUS_UNCHANGED',same,'');
  insert into _r values ('MESSAGE_PROCESSING_FIELDS_UNCHANGED',same,'');
  insert into _r values ('PROVENANCE_155_PRESERVED',same,'');
  insert into _r values ('READ_STATE_160_UNCHANGED',reads_same,'');
  insert into _r values ('INFORMATION_163_UNCHANGED',info_same,'');
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','16400000-0000-4000-8000-000000000003',true);

do $$
declare t public.tasks%rowtype; denied boolean:=false; ctx boolean:=false;
begin
  select * into t from public.boralog_create_task('16410000-0000-4000-8000-000000000001','Limited accessible','16420000-0000-4000-8000-000000000001',null,array[(select id from _src where name='org1')]);
  insert into _r values ('LIMITED_ACCESSIBLE_PROJECT_PASS',t.project_id='16420000-0000-4000-8000-000000000001','');
  begin perform public.boralog_create_task('16410000-0000-4000-8000-000000000001','Limited inaccessible','16420000-0000-4000-8000-000000000002',null,'{}'); exception when insufficient_privilege then denied:=true; end;
  insert into _r values ('LIMITED_INACCESSIBLE_PROJECT_DENIED',denied,'');
  begin perform public.boralog_create_task('16410000-0000-4000-8000-000000000001','Limited contextless',null,null,'{}'); exception when insufficient_privilege then ctx:=true; end;
  insert into _r values ('LIMITED_CONTEXTLESS_CREATE_DENIED',ctx,'');
end $$;

do $$
declare denied boolean:=false; rows bigint;
begin
  begin perform public.boralog_create_task('16410000-0000-4000-8000-000000000001','Inaccessible source','16420000-0000-4000-8000-000000000001',null,array[(select id from _src where name='restricted')]); exception when insufficient_privilege then denied:=true; end;
  select count(*) into rows from public.tasks where content='Inaccessible source';
  insert into _r values ('SOURCE_MESSAGE_INACCESSIBLE_DENIED',denied and rows=0,'');
  insert into _r values ('RESTRICTED_MESSAGE_CONFIDENTIALITY_PRESERVED',not exists(select 1 from public.messages where id=(select id from _src where name='restricted')),'');
end $$;

do $$
declare tv bigint;mv bigint;lv bigint;
begin
  select count(*) into tv from public.tasks where content='Restricted-source task';
  select count(*) into mv from public.messages where id=(select id from _src where name='restricted');
  select count(*) into lv from public.task_message_sources s join public.tasks t on t.id=s.task_id where t.content='Restricted-source task';
  insert into _r values ('TASK_VISIBILITY_DOES_NOT_LEAK_SOURCE_MESSAGE',tv=1 and mv=0 and lv=0,'');
  insert into _r values ('CONFIDENTIALITY_157_PRESERVED',mv=0,'');
end $$;

reset role;

do $$
declare same boolean;
begin
  select to_jsonb(m)=h.snap into same from public.messages m cross join _hist h where m.id='16440000-0000-4000-8000-000000000099';
  insert into _r values ('HISTORICAL_MESSAGES_UNCHANGED',coalesce(same,false),'');
end $$;

do $$
begin
  if exists(select 1 from _r where not pass) then raise exception 'BORALOG-164 task test failed'; end if;
end $$;

select test,pass,detail from _r order by test;
rollback;
