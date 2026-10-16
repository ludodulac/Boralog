-- BORALOG-176B external Message ingestion tests.
-- Self-contained fixtures; every write is rolled back.

begin;

insert into auth.users (
  id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values (
  '17610000-0000-4000-8000-000000000001',
  'authenticated',
  'authenticated',
  'owner176b@example.invalid',
  '{}',
  '{}',
  now(),
  now()
);

set local role authenticated;
select set_config('request.jwt.claim.sub','17610000-0000-4000-8000-000000000001',true);

insert into public.organizations(id,name,slug,created_by) values
  ('17611000-0000-4000-8000-000000000001','BORALOG 176B A','boralog-176b-a',auth.uid()),
  ('17611000-0000-4000-8000-000000000002','BORALOG 176B B','boralog-176b-b',auth.uid());

reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub','17610000-0000-4000-8000-000000000001',true);

insert into public.organization_memberships(
  organization_id,user_id,role,status,access_level
) values
  ('17611000-0000-4000-8000-000000000001','17610000-0000-4000-8000-000000000001',null,'active','owner'),
  ('17611000-0000-4000-8000-000000000002','17610000-0000-4000-8000-000000000001',null,'active','owner');

reset role;

create temporary table _boralog_176b_messages (
  name text primary key,
  id uuid not null
) on commit drop;

set local role service_role;

insert into _boralog_176b_messages(name,id)
select 'first', created.id
from public.boralog_ingest_external_message(
  '17611000-0000-4000-8000-000000000001',
  '  Premier WhatsApp réel  ',
  'whatsapp:+33600000000',
  'WHATSAPP',
  'SM176B0001',
  now()
) as created;

insert into _boralog_176b_messages(name,id)
select 'retry', created.id
from public.boralog_ingest_external_message(
  '17611000-0000-4000-8000-000000000001',
  'Premier WhatsApp réel',
  'whatsapp:+33600000000',
  'WHATSAPP',
  'SM176B0001',
  now()
) as created;

insert into _boralog_176b_messages(name,id)
select 'other-org', created.id
from public.boralog_ingest_external_message(
  '17611000-0000-4000-8000-000000000002',
  'Même SID autre structure',
  'whatsapp:+33600000000',
  'WHATSAPP',
  'SM176B0001',
  now()
) as created;

do $$
declare
  first_id uuid := (select id from _boralog_176b_messages where name='first');
  retry_id uuid := (select id from _boralog_176b_messages where name='retry');
  other_id uuid := (select id from _boralog_176b_messages where name='other-org');
  row public.messages%rowtype;
  duplicate_count bigint;
begin
  if first_id is distinct from retry_id then
    raise exception '176B retry created a second Message';
  end if;

  if first_id = other_id then
    raise exception '176B same SID collided across organizations';
  end if;

  select * into row from public.messages where id=first_id;

  if row.organization_id <> '17611000-0000-4000-8000-000000000001'
     or row.content <> 'Premier WhatsApp réel'
     or row.status <> 'TO_PROCESS'
     or row.visibility <> 'ORGANIZATION'
     or row.project_id is not null
     or row.event_id is not null
     or row.created_by is not null
     or row.origin_type <> 'EXTERNAL_IMPORTED'
     or row.author_user_id is not null
     or row.external_author_label <> 'whatsapp:+33600000000'
     or row.source_kind <> 'WHATSAPP'
     or row.source_external_id <> 'SM176B0001'
     or row.source_occurred_at is null then
    raise exception '176B imported Message contract mismatch';
  end if;

  select count(*) into duplicate_count
  from public.messages
  where organization_id='17611000-0000-4000-8000-000000000001'
    and source_kind='WHATSAPP'
    and source_external_id='SM176B0001';

  if duplicate_count <> 1 then
    raise exception '176B idempotence count mismatch: %', duplicate_count;
  end if;
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','17610000-0000-4000-8000-000000000001',true);

do $$
declare
  internal public.messages%rowtype;
  manual public.messages%rowtype;
  actor uuid := auth.uid();
begin
  select created.* into internal
  from public.boralog_create_internal_message(
    '17611000-0000-4000-8000-000000000001',
    'Message interne 176B',
    'ORGANIZATION',
    '{}'::uuid[],
    null,
    null
  ) as created;

  if internal.created_by is distinct from actor
     or internal.author_user_id is distinct from actor
     or internal.origin_type <> 'INTERNAL'
     or internal.source_external_id is not null then
    raise exception '176B INTERNAL actor contract regressed';
  end if;

  insert into public.messages(
    organization_id, content, created_by, origin_type, author_user_id,
    external_author_label, source_kind, source_occurred_at, visibility
  ) values (
    '17611000-0000-4000-8000-000000000001',
    'Message externe manuel 176B',
    actor,
    'EXTERNAL_MANUAL',
    null,
    'Contact manuel',
    'WHATSAPP',
    now(),
    'ORGANIZATION'
  )
  returning * into manual;

  if manual.created_by is distinct from actor
     or manual.origin_type <> 'EXTERNAL_MANUAL'
     or manual.source_external_id is not null then
    raise exception '176B EXTERNAL_MANUAL actor contract regressed';
  end if;
end $$;

do $$
declare
  denied boolean := false;
begin
  begin
    insert into public.messages(
      organization_id, content, created_by, origin_type, author_user_id,
      external_author_label, source_kind, source_occurred_at,
      source_external_id, visibility
    ) values (
      '17611000-0000-4000-8000-000000000001',
      'Tentative import hors RPC',
      null,
      'EXTERNAL_IMPORTED',
      null,
      'whatsapp:+33600000000',
      'WHATSAPP',
      now(),
      'SM176B-FORBIDDEN',
      'ORGANIZATION'
    );
  exception when insufficient_privilege then
    denied := true;
  end;

  if not denied then
    raise exception '176B direct imported insert was not denied';
  end if;
end $$;

do $$
declare
  mid uuid := (select id from _boralog_176b_messages where name='first');
  immutable_denied boolean := false;
  processed public.messages%rowtype;
  reopened public.messages%rowtype;
  history_count bigint;
  note_count bigint;
begin
  begin
    update public.messages
    set source_external_id='SM176B-CHANGED'
    where id=mid;
  exception when check_violation then
    immutable_denied := true;
  end;

  if not immutable_denied then
    raise exception '176B source_external_id was mutable';
  end if;

  select changed.* into processed
  from public.boralog_set_message_status(mid,'PROCESSED') as changed;

  perform public.boralog_add_message_note(mid,'Note 176B sur Message WhatsApp');

  select changed.* into reopened
  from public.boralog_set_message_status(mid,'TO_PROCESS') as changed;

  select count(*) into history_count
  from public.message_status_history
  where message_id=mid;

  select count(*) into note_count
  from public.message_notes
  where message_id=mid
    and content='Note 176B sur Message WhatsApp';

  if processed.status <> 'PROCESSED'
     or reopened.status <> 'TO_PROCESS'
     or reopened.processed_at is not null
     or reopened.processed_by is not null
     or history_count <> 2
     or note_count <> 1 then
    raise exception '176B regressed canonical 165R cycle or Notes';
  end if;
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','17610000-0000-4000-8000-000000000001',true);

do $
declare
  denied boolean := false;
begin
  begin
    perform public.boralog_ingest_external_message(
      '17611000-0000-4000-8000-000000000001',
      'Forbidden authenticated RPC',
      'whatsapp:+33600000000',
      'WHATSAPP',
      'SM176B-NOAUTH',
      now()
    );
  exception when insufficient_privilege then
    denied := true;
  end;

  if not denied then
    raise exception '176B external ingest RPC was executable by authenticated';
  end if;
end $;

reset role;
rollback;
