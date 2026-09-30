-- BORALOG-144 targeted Message processing traceability tests.
-- Self-contained: all fixtures are rolled back.

begin;

create temporary table _boralog_144_results (
  test text primary key,
  pass boolean not null,
  detail text
) on commit drop;

grant select, insert, update on _boralog_144_results to authenticated;

insert into auth.users (
  id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('14400000-0000-4000-8000-000000000001','authenticated','authenticated','boralog144-owner@example.invalid','{}','{}',now(),now()),
  ('14400000-0000-4000-8000-000000000002','authenticated','authenticated','boralog144-full@example.invalid','{}','{}',now(),now()),
  ('14400000-0000-4000-8000-000000000003','authenticated','authenticated','boralog144-limited@example.invalid','{}','{}',now(),now());

select set_config('request.jwt.claim.sub','14400000-0000-4000-8000-000000000001',true);

insert into public.organizations(id, name, slug, created_by)
values (
  '14410000-0000-4000-8000-000000000001',
  'BORALOG 144 Processing Test',
  'boralog-144-processing-test',
  '14400000-0000-4000-8000-000000000001'
);

insert into public.organization_memberships(
  organization_id, user_id, role, status, access_level
) values
  ('14410000-0000-4000-8000-000000000001','14400000-0000-4000-8000-000000000002',null,'active','full'),
  ('14410000-0000-4000-8000-000000000001','14400000-0000-4000-8000-000000000003',null,'active','limited');

insert into public.projects(id, organization_id, name, created_by)
values
  ('14420000-0000-4000-8000-000000000001','14410000-0000-4000-8000-000000000001','Accessible project','14400000-0000-4000-8000-000000000001'),
  ('14420000-0000-4000-8000-000000000002','14410000-0000-4000-8000-000000000001','Inaccessible project','14400000-0000-4000-8000-000000000001');

insert into public.project_memberships(project_id, user_id, role)
values (
  '14420000-0000-4000-8000-000000000001',
  '14400000-0000-4000-8000-000000000003',
  null
);

insert into public.events(
  id, project_id, title, event_date, status, created_by
) values
  ('14430000-0000-4000-8000-000000000001','14420000-0000-4000-8000-000000000001','Accessible event A','2026-09-30','draft','14400000-0000-4000-8000-000000000001'),
  ('14430000-0000-4000-8000-000000000002','14420000-0000-4000-8000-000000000001','Accessible event B','2026-10-01','draft','14400000-0000-4000-8000-000000000001');

set local role authenticated;
select set_config('request.jwt.claim.sub','14400000-0000-4000-8000-000000000001',true);

do $$
declare
  v_id uuid;
  v_status text;
  v_processed_at timestamptz;
  v_processed_by uuid;
  v_resolution text;
begin
  insert into public.messages(
    organization_id, project_id, event_id, content, created_by, origin_type, author_user_id
  ) values (
    '14410000-0000-4000-8000-000000000001',
    '14420000-0000-4000-8000-000000000001',
    '14430000-0000-4000-8000-000000000001',
    'coherent to process',
    auth.uid(),
    'INTERNAL',
    auth.uid()
  )
  returning id, status, processed_at, processed_by, resolution
  into v_id, v_status, v_processed_at, v_processed_by, v_resolution;

  insert into _boralog_144_results values (
    'TO_PROCESS_COHERENT',
    v_status='TO_PROCESS'
      and v_processed_at is null
      and v_processed_by is null
      and v_resolution is null,
    'status='||coalesce(v_status,'null')
  );
end $$;

do $$
declare
  v_id uuid;
  v_status text;
  v_processed_at timestamptz;
  v_processed_by uuid;
  v_resolution text;
begin
  insert into public.messages(
    organization_id, project_id, event_id, content, created_by, origin_type, author_user_id
  ) values (
    '14410000-0000-4000-8000-000000000001',
    '14420000-0000-4000-8000-000000000001',
    '14430000-0000-4000-8000-000000000001',
    'close no follow up',
    auth.uid(),
    'INTERNAL',
    auth.uid()
  )
  returning id into v_id;

  perform public.boralog_close_message_no_follow_up(v_id);

  select status, processed_at, processed_by, resolution
    into v_status, v_processed_at, v_processed_by, v_resolution
  from public.messages
  where id=v_id;

  insert into _boralog_144_results values (
    'NO_FOLLOW_UP_TRANSITION',
    v_status='PROCESSED'
      and v_resolution='NO_FOLLOW_UP'
      and v_processed_at is not null
      and v_processed_by=auth.uid(),
    'status='||coalesce(v_status,'null')||', resolution='||coalesce(v_resolution,'null')
  );

  insert into _boralog_144_results values (
    'PROCESSED_BY_AUTH_UID',
    v_processed_by=auth.uid(),
    'matches='||(v_processed_by=auth.uid())
  );

  insert into _boralog_144_results values (
    'PROCESSED_AT_GENERATED',
    v_processed_at is not null,
    'generated='||(v_processed_at is not null)
  );
end $$;

do $$
declare
  v_id uuid;
  v_denied boolean := false;
  v_status text;
  v_processed_by uuid;
begin
  insert into public.messages(organization_id, content, created_by, origin_type, author_user_id)
  values (
    '14410000-0000-4000-8000-000000000001',
    'forged metadata source',
    auth.uid(),
    'INTERNAL',
    auth.uid()
  )
  returning id into v_id;

  begin
    update public.messages
       set status='PROCESSED',
           resolution='NO_FOLLOW_UP',
           processed_by='14400000-0000-4000-8000-000000000002'
     where id=v_id;
  exception when check_violation then
    v_denied := true;
  end;

  select status, processed_by
    into v_status, v_processed_by
  from public.messages
  where id=v_id;

  insert into _boralog_144_results values (
    'METADATA_FORGERY_DENIED',
    v_denied and v_status='TO_PROCESS' and v_processed_by is null,
    'denied='||v_denied
  );
end $$;

do $$
declare
  v_id uuid;
  v_denied boolean := false;
  v_content text;
begin
  insert into public.messages(organization_id, content, created_by, origin_type, author_user_id)
  values (
    '14410000-0000-4000-8000-000000000001',
    'immutable original content',
    auth.uid(),
    'INTERNAL',
    auth.uid()
  )
  returning id into v_id;

  begin
    update public.messages
       set content='tampered content'
     where id=v_id;
  exception when check_violation then
    v_denied := true;
  end;

  select content into v_content
  from public.messages
  where id=v_id;

  insert into _boralog_144_results values (
    'CONTENT_IMMUTABLE',
    v_denied and v_content='immutable original content',
    'denied='||v_denied
  );
end $$;

do $$
declare
  v_id uuid;
  v_denied boolean := false;
  v_project_id uuid;
  v_event_id uuid;
begin
  insert into public.messages(
    organization_id, project_id, event_id, content, created_by, origin_type, author_user_id
  ) values (
    '14410000-0000-4000-8000-000000000001',
    '14420000-0000-4000-8000-000000000001',
    '14430000-0000-4000-8000-000000000001',
    'processed context immutable',
    auth.uid(),
    'INTERNAL',
    auth.uid()
  )
  returning id into v_id;

  perform public.boralog_close_message_no_follow_up(v_id);

  begin
    update public.messages
       set event_id='14430000-0000-4000-8000-000000000002'
     where id=v_id;
  exception when check_violation then
    v_denied := true;
  end;

  select project_id, event_id
    into v_project_id, v_event_id
  from public.messages
  where id=v_id;

  insert into _boralog_144_results values (
    'PROCESSED_CONTEXT_IMMUTABLE',
    v_denied
      and v_project_id='14420000-0000-4000-8000-000000000001'::uuid
      and v_event_id='14430000-0000-4000-8000-000000000001'::uuid,
    'denied='||v_denied
  );
end $$;

do $$
declare
  v_id uuid;
  v_denied boolean := false;
  v_status text;
begin
  insert into public.messages(organization_id, content, created_by, origin_type, author_user_id)
  values (
    '14410000-0000-4000-8000-000000000001',
    'direct reopen denied',
    auth.uid(),
    'INTERNAL',
    auth.uid()
  )
  returning id into v_id;

  perform public.boralog_close_message_no_follow_up(v_id);

  begin
    update public.messages
       set status='TO_PROCESS',
           processed_at=null,
           processed_by=null,
           resolution=null
     where id=v_id;
  exception when check_violation then
    v_denied := true;
  end;

  select status into v_status
  from public.messages
  where id=v_id;

  insert into _boralog_144_results values (
    'DIRECT_REOPEN_DENIED',
    v_denied and v_status='PROCESSED',
    'denied='||v_denied
  );
end $$;

do $$
declare
  v_id uuid;
  v_denied boolean := false;
  v_status text;
begin
  insert into public.messages(organization_id, content, created_by, origin_type, author_user_id)
  values (
    '14410000-0000-4000-8000-000000000001',
    'processed without resolution denied',
    auth.uid(),
    'INTERNAL',
    auth.uid()
  )
  returning id into v_id;

  begin
    update public.messages
       set status='PROCESSED'
     where id=v_id;
  exception when check_violation then
    v_denied := true;
  end;

  select status into v_status
  from public.messages
  where id=v_id;

  insert into _boralog_144_results values (
    'PROCESSED_WITHOUT_RESOLUTION_DENIED',
    v_denied and v_status='TO_PROCESS',
    'denied='||v_denied
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','14400000-0000-4000-8000-000000000002',true);

do $$
declare
  v_id uuid;
  v_status text;
begin
  insert into public.messages(organization_id, content, created_by, origin_type, author_user_id)
  values (
    '14410000-0000-4000-8000-000000000001',
    'full can close org message',
    auth.uid(),
    'INTERNAL',
    auth.uid()
  )
  returning id into v_id;

  perform public.boralog_close_message_no_follow_up(v_id);

  select status into v_status
  from public.messages
  where id=v_id;

  insert into _boralog_144_results values (
    'FULL_PROCESSING_PRESERVED',
    v_status='PROCESSED',
    'status='||coalesce(v_status,'null')
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','14400000-0000-4000-8000-000000000003',true);

do $$
declare
  v_id uuid;
  v_status text;
  v_actor uuid;
begin
  insert into public.messages(
    organization_id, project_id, content, created_by, origin_type, author_user_id
  ) values (
    '14410000-0000-4000-8000-000000000001',
    '14420000-0000-4000-8000-000000000001',
    'limited accessible processing',
    auth.uid(),
    'INTERNAL',
    auth.uid()
  )
  returning id into v_id;

  perform public.boralog_close_message_no_follow_up(v_id);

  select status, processed_by
    into v_status, v_actor
  from public.messages
  where id=v_id;

  insert into _boralog_144_results values (
    'LIMITED_ACCESSIBLE_CAN_PROCESS',
    v_status='PROCESSED' and v_actor=auth.uid(),
    'status='||coalesce(v_status,'null')
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','14400000-0000-4000-8000-000000000001',true);

insert into public.messages(
  id, organization_id, project_id, content, created_by, origin_type, author_user_id
) values (
  '14440000-0000-4000-8000-000000000001',
  '14410000-0000-4000-8000-000000000001',
  '14420000-0000-4000-8000-000000000002',
  'limited must not access',
  auth.uid(),
    'INTERNAL',
    auth.uid()
);

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','14400000-0000-4000-8000-000000000003',true);

do $$
declare
  v_visible bigint;
  v_denied boolean := false;
begin
  select count(*) into v_visible
  from public.messages
  where id='14440000-0000-4000-8000-000000000001';

  begin
    perform public.boralog_close_message_no_follow_up(
      '14440000-0000-4000-8000-000000000001'
    );
  exception when others then
    v_denied := true;
  end;

  insert into _boralog_144_results values (
    'LIMITED_INACCESSIBLE_PRESERVED',
    v_visible=0 and v_denied,
    'visible='||v_visible||', denied='||v_denied
  );
end $$;

reset role;

do $$
begin
  if exists (select 1 from _boralog_144_results where not pass) then
    raise exception 'BORALOG-144 Message processing test failed';
  end if;
end $$;

select test, pass, detail
from _boralog_144_results
order by test;

rollback;
