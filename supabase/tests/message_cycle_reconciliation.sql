-- BORALOG-165R canonical Message cycle tests.
-- Self-contained fixtures; every write is rolled back.

begin;

create temporary table _boralog_165r_results (
  test text primary key,
  pass boolean not null,
  detail text
) on commit drop;
grant select, insert, update on _boralog_165r_results to authenticated;

insert into auth.users (
  id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('16510000-0000-4000-8000-000000000001','authenticated','authenticated','owner165r@example.invalid','{}','{}',now(),now()),
  ('16510000-0000-4000-8000-000000000002','authenticated','authenticated','recipient165r@example.invalid','{}','{}',now(),now()),
  ('16510000-0000-4000-8000-000000000003','authenticated','authenticated','outsider165r@example.invalid','{}','{}',now(),now()),
  ('16510000-0000-4000-8000-000000000004','authenticated','authenticated','limited165r@example.invalid','{}','{}',now(),now());

set local role authenticated;
select set_config('request.jwt.claim.sub','16510000-0000-4000-8000-000000000001',true);

insert into public.organizations(id,name,slug,created_by) values (
  '16511000-0000-4000-8000-000000000001',
  'BORALOG 165R',
  'boralog-165r',
  auth.uid()
);

reset role;

insert into public.organization_memberships(
  organization_id,user_id,role,status,access_level
) values
  ('16511000-0000-4000-8000-000000000001','16510000-0000-4000-8000-000000000002',null,'active','full'),
  ('16511000-0000-4000-8000-000000000001','16510000-0000-4000-8000-000000000003',null,'active','full'),
  ('16511000-0000-4000-8000-000000000001','16510000-0000-4000-8000-000000000004',null,'active','limited');

insert into public.projects(id,organization_id,name,created_by) values
  ('16512000-0000-4000-8000-000000000001','16511000-0000-4000-8000-000000000001','Accessible 165R','16510000-0000-4000-8000-000000000001'),
  ('16512000-0000-4000-8000-000000000002','16511000-0000-4000-8000-000000000001','Inaccessible 165R','16510000-0000-4000-8000-000000000001');

insert into public.project_memberships(project_id,user_id,role) values (
  '16512000-0000-4000-8000-000000000001',
  '16510000-0000-4000-8000-000000000004',
  null
);

set local role authenticated;
select set_config('request.jwt.claim.sub','16510000-0000-4000-8000-000000000001',true);

create temporary table _boralog_165r_messages (
  name text primary key,
  id uuid not null
) on commit drop;
grant select, insert on _boralog_165r_messages to authenticated;

insert into _boralog_165r_messages
select 'cycle', id from public.boralog_create_internal_message(
  '16511000-0000-4000-8000-000000000001',
  'BORALOG-165R CYCLE SOURCE',
  'ORGANIZATION',
  '{}'::uuid[],
  '16512000-0000-4000-8000-000000000001',
  null
);

insert into _boralog_165r_messages
select 'restricted', id from public.boralog_create_internal_message(
  '16511000-0000-4000-8000-000000000001',
  'BORALOG-165R RESTRICTED SOURCE',
  'RESTRICTED',
  array['16510000-0000-4000-8000-000000000002'::uuid],
  null,
  null
);

insert into _boralog_165r_messages
select 'limited-inaccessible', id from public.boralog_create_internal_message(
  '16511000-0000-4000-8000-000000000001',
  'BORALOG-165R LIMITED INACCESSIBLE',
  'ORGANIZATION',
  '{}'::uuid[],
  '16512000-0000-4000-8000-000000000002',
  null
);

insert into _boralog_165r_messages
select 'legacy', id from public.boralog_create_internal_message(
  '16511000-0000-4000-8000-000000000001',
  'BORALOG-165R LEGACY 165',
  'ORGANIZATION',
  '{}'::uuid[],
  null,
  null
);

create temporary table _boralog_165r_cycle_snapshot on commit drop as
select
  id,
  content,
  organization_id,
  project_id,
  event_id,
  created_by,
  created_at,
  origin_type,
  author_user_id,
  external_author_label,
  source_kind,
  source_occurred_at,
  visibility
from public.messages
where id=(select id from _boralog_165r_messages where name='cycle');

create temporary table _boralog_165r_restricted_snapshot on commit drop as
select
  m.id,
  m.visibility,
  count(r.user_id)::bigint as recipient_count
from public.messages m
left join public.message_recipients r on r.message_id=m.id
where m.id=(select id from _boralog_165r_messages where name='restricted')
group by m.id,m.visibility;

-- Valid Note, actor attribution and no implicit status transition.
do $$
declare
  mid uuid := (select id from _boralog_165r_messages where name='cycle');
  note public.message_notes%rowtype;
  message_status text;
begin
  select created.* into note
  from public.boralog_add_message_note(mid, ' BORALOG-165R NOTE VALID ') created;

  select status into message_status from public.messages where id=mid;

  insert into _boralog_165r_results values
    ('NOTE_VALID', note.message_id=mid and note.content='BORALOG-165R NOTE VALID', ''),
    ('NOTE_AUTHOR_IS_ACTOR', note.created_by=auth.uid() and note.created_at is not null, ''),
    ('NOTE_DOES_NOT_CHANGE_STATUS', message_status='TO_PROCESS', '');
end $$;

-- Blank Note is rejected.
do $$
declare
  mid uuid := (select id from _boralog_165r_messages where name='cycle');
  denied boolean := false;
begin
  begin
    perform public.boralog_add_message_note(mid, '   ');
  exception when check_violation then
    denied := true;
  end;

  insert into _boralog_165r_results values ('NOTE_EMPTY_DENIED', denied, '');
end $$;

-- Canonical reversible status cycle and Note while PROCESSED.
do $$
declare
  mid uuid := (select id from _boralog_165r_messages where name='cycle');
  processed public.messages%rowtype;
  reopened public.messages%rowtype;
  transition_path text;
begin
  select changed.* into processed
  from public.boralog_set_message_status(mid, 'PROCESSED') changed;

  perform public.boralog_add_message_note(mid, 'NOTE WHILE PROCESSED 165R');

  select changed.* into reopened
  from public.boralog_set_message_status(mid, 'TO_PROCESS') changed;

  select string_agg(
    history.from_status || '>' || history.to_status,
    ',' order by history.changed_at, history.id
  )
  into transition_path
  from public.message_status_history history
  where history.message_id=mid;

  insert into _boralog_165r_results values
    (
      'TO_PROCESS_TO_PROCESSED',
      processed.status='PROCESSED'
        and processed.processed_at is not null
        and processed.processed_by=auth.uid()
        and processed.resolution is null,
      ''
    ),
    (
      'PROCESSED_TO_TO_PROCESS',
      reopened.status='TO_PROCESS'
        and reopened.processed_at is null
        and reopened.processed_by is null
        and reopened.resolution is null,
      ''
    ),
    (
      'STATUS_HISTORY_EXACT_TWO_TRANSITIONS',
      transition_path='TO_PROCESS>PROCESSED,PROCESSED>TO_PROCESS'
        and (
          select count(*)
          from public.message_status_history history
          where history.message_id=mid
        )=2,
      coalesce(transition_path,'null')
    ),
    (
      'NOTE_ALLOWED_WHILE_PROCESSED',
      exists(
        select 1 from public.message_notes note
        where note.message_id=mid and note.content='NOTE WHILE PROCESSED 165R'
      ),
      ''
    );
end $$;

-- Source, provenance, context and audience stay unchanged through the cycle.
do $$
declare
  mid uuid := (select id from _boralog_165r_messages where name='cycle');
  unchanged boolean;
begin
  select
    current.content is not distinct from before.content
    and current.organization_id is not distinct from before.organization_id
    and current.project_id is not distinct from before.project_id
    and current.event_id is not distinct from before.event_id
    and current.created_by is not distinct from before.created_by
    and current.created_at is not distinct from before.created_at
    and current.origin_type is not distinct from before.origin_type
    and current.author_user_id is not distinct from before.author_user_id
    and current.external_author_label is not distinct from before.external_author_label
    and current.source_kind is not distinct from before.source_kind
    and current.source_occurred_at is not distinct from before.source_occurred_at
    and current.visibility is not distinct from before.visibility
  into unchanged
  from public.messages current
  cross join _boralog_165r_cycle_snapshot before
  where current.id=mid;

  insert into _boralog_165r_results values
    ('MESSAGE_SOURCE_PROVENANCE_CONTEXT_AUDIENCE_UNCHANGED', coalesce(unchanged,false), '');
end $$;

-- Restricted parent: create Note/history as an allowed actor.
do $$
declare
  mid uuid := (select id from _boralog_165r_messages where name='restricted');
begin
  perform public.boralog_add_message_note(mid, 'RESTRICTED NOTE 165R');
  perform public.boralog_set_message_status(mid, 'PROCESSED');
end $$;

-- Explicit recipient can read parent-derived Note/history.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','16510000-0000-4000-8000-000000000002',true);

do $$
declare
  mid uuid := (select id from _boralog_165r_messages where name='restricted');
  note_seen bigint;
  history_seen bigint;
begin
  select count(*) into note_seen
  from public.message_notes where message_id=mid;

  select count(*) into history_seen
  from public.message_status_history where message_id=mid;

  insert into _boralog_165r_results values (
    'NOTE_AND_HISTORY_VISIBLE_WITH_PARENT',
    note_seen=1 and history_seen=1,
    'notes='||note_seen||', history='||history_seen
  );
end $$;

-- Full member outside RESTRICTED audience cannot read or act on parent-derived objects.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','16510000-0000-4000-8000-000000000003',true);

do $$
declare
  mid uuid := (select id from _boralog_165r_messages where name='restricted');
  message_seen bigint;
  note_seen bigint;
  history_seen bigint;
  note_denied boolean := false;
  status_denied boolean := false;
begin
  select count(*) into message_seen from public.messages where id=mid;
  select count(*) into note_seen from public.message_notes where message_id=mid;
  select count(*) into history_seen from public.message_status_history where message_id=mid;

  begin
    perform public.boralog_add_message_note(mid, 'FORBIDDEN NOTE 165R');
  exception when insufficient_privilege then
    note_denied := true;
  end;

  begin
    perform public.boralog_set_message_status(mid, 'TO_PROCESS');
  exception when insufficient_privilege then
    status_denied := true;
  end;

  insert into _boralog_165r_results values
    (
      'RESTRICTED_NOT_DISCLOSED',
      message_seen=0 and note_seen=0 and history_seen=0,
      'message='||message_seen||', notes='||note_seen||', history='||history_seen
    ),
    ('NOTE_INACCESSIBLE_MESSAGE_DENIED', note_denied, ''),
    ('STATUS_INACCESSIBLE_MESSAGE_DENIED', status_denied, '');
end $$;

-- BORALOG-157 limited business eligibility still applies.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','16510000-0000-4000-8000-000000000004',true);

do $$
declare
  inaccessible_mid uuid := (select id from _boralog_165r_messages where name='limited-inaccessible');
  cycle_mid uuid := (select id from _boralog_165r_messages where name='cycle');
  inaccessible_seen bigint;
  accessible_seen bigint;
  note_denied boolean := false;
  status_denied boolean := false;
begin
  select count(*) into inaccessible_seen from public.messages where id=inaccessible_mid;
  select count(*) into accessible_seen from public.messages where id=cycle_mid;

  begin
    perform public.boralog_add_message_note(inaccessible_mid, 'FORBIDDEN LIMITED NOTE');
  exception when insufficient_privilege then
    note_denied := true;
  end;

  begin
    perform public.boralog_set_message_status(inaccessible_mid, 'PROCESSED');
  exception when insufficient_privilege then
    status_denied := true;
  end;

  insert into _boralog_165r_results values (
    'BORALOG_157_LIMITED_RULES_PRESERVED',
    inaccessible_seen=0 and accessible_seen=1 and note_denied and status_denied,
    'inaccessible='||inaccessible_seen||', accessible='||accessible_seen
  );
end $$;

-- Legacy 165 API and legacy resolution remain valid after supersession.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','16510000-0000-4000-8000-000000000001',true);

do $$
declare
  mid uuid := (select id from _boralog_165r_messages where name='legacy');
  legacy public.messages%rowtype;
  note public.message_notes%rowtype;
begin
  select processed.* into legacy
  from public.boralog_process_message(
    mid,
    'NO_FOLLOW_UP',
    '{}'::text[],
    '{}'::text[]
  ) processed;

  select created.* into note
  from public.boralog_add_message_note(mid, 'NOTE ON LEGACY PROCESSED 165') created;

  insert into _boralog_165r_results values (
    'LEGACY_165_PROCESSED_COMPATIBLE',
    legacy.status='PROCESSED'
      and legacy.resolution='NO_FOLLOW_UP'
      and legacy.processed_at is not null
      and legacy.processed_by=auth.uid()
      and note.message_id=mid,
    ''
  );
end $$;

-- Restricted audience itself is unchanged by status transition.
do $$
declare
  mid uuid := (select id from _boralog_165r_messages where name='restricted');
  current_visibility text;
  current_recipients bigint;
  before_visibility text;
  before_recipients bigint;
begin
  select visibility,recipient_count
    into before_visibility,before_recipients
  from _boralog_165r_restricted_snapshot;

  select
    m.visibility,
    count(r.user_id)::bigint
  into current_visibility,current_recipients
  from public.messages m
  left join public.message_recipients r on r.message_id=m.id
  where m.id=mid
  group by m.id,m.visibility;

  insert into _boralog_165r_results values (
    'RESTRICTED_AUDIENCE_UNCHANGED',
    current_visibility=before_visibility and current_recipients=before_recipients,
    ''
  );
end $$;

reset role;

do $$
begin
  if exists(select 1 from _boralog_165r_results where not pass) then
    raise exception 'BORALOG-165R Message cycle test failed';
  end if;
end $$;

select test,pass,detail
from _boralog_165r_results
order by test;

rollback;
