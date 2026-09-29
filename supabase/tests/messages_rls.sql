-- BORALOG-127 targeted Messages RLS/consistency test.
-- Self-contained: all fixtures are rolled back.

begin;

create temporary table _boralog_messages_results (
  test text primary key,
  pass boolean not null,
  detail text
) on commit drop;

grant select, insert, update on _boralog_messages_results to authenticated;

insert into auth.users (
  id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('12700000-0000-4000-8000-000000000001','authenticated','authenticated','boralog127-owner@example.invalid','{}','{}',now(),now()),
  ('12700000-0000-4000-8000-000000000002','authenticated','authenticated','boralog127-full@example.invalid','{}','{}',now(),now()),
  ('12700000-0000-4000-8000-000000000003','authenticated','authenticated','boralog127-limited@example.invalid','{}','{}',now(),now());

select set_config('request.jwt.claim.sub','12700000-0000-4000-8000-000000000001',true);

insert into public.organizations(id, name, slug, created_by)
values (
  '12710000-0000-4000-8000-000000000001',
  'BORALOG 127 Messages Test',
  'boralog-127-messages-test',
  '12700000-0000-4000-8000-000000000001'
);

insert into public.organization_memberships(
  organization_id, user_id, role, status, access_level
) values
  ('12710000-0000-4000-8000-000000000001','12700000-0000-4000-8000-000000000002',null,'active','full'),
  ('12710000-0000-4000-8000-000000000001','12700000-0000-4000-8000-000000000003',null,'active','limited');

insert into public.projects(id, organization_id, name, created_by)
values
  ('12720000-0000-4000-8000-000000000001','12710000-0000-4000-8000-000000000001','Accessible project','12700000-0000-4000-8000-000000000001'),
  ('12720000-0000-4000-8000-000000000002','12710000-0000-4000-8000-000000000001','Inaccessible project','12700000-0000-4000-8000-000000000001');

insert into public.project_memberships(project_id, user_id, role)
values (
  '12720000-0000-4000-8000-000000000001',
  '12700000-0000-4000-8000-000000000003',
  null
);

insert into public.events(
  id, project_id, title, event_date, status, created_by
) values (
  '12730000-0000-4000-8000-000000000001',
  '12720000-0000-4000-8000-000000000001',
  'Accessible event',
  '2026-09-30',
  'draft',
  '12700000-0000-4000-8000-000000000001'
);

set local role authenticated;
select set_config('request.jwt.claim.sub','12700000-0000-4000-8000-000000000001',true);

do $$
declare v_id uuid; v_status text;
begin
  insert into public.messages(organization_id, content, created_by)
  values (
    '12710000-0000-4000-8000-000000000001',
    'owner org-only',
    auth.uid()
  )
  returning id into v_id;

  update public.messages set status='PROCESSED' where id=v_id;
  select status into v_status from public.messages where id=v_id;

  insert into _boralog_messages_results values ('OWNER', v_status='PROCESSED', coalesce(v_status,'missing'));
exception when others then
  insert into _boralog_messages_results values ('OWNER', false, sqlstate||' '||sqlerrm);
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','12700000-0000-4000-8000-000000000002',true);

do $$
declare v_id uuid; v_status text;
begin
  insert into public.messages(organization_id, content, created_by)
  values (
    '12710000-0000-4000-8000-000000000001',
    'full org-only',
    auth.uid()
  )
  returning id into v_id;

  update public.messages set status='PROCESSED' where id=v_id;
  select status into v_status from public.messages where id=v_id;

  insert into _boralog_messages_results values ('FULL', v_status='PROCESSED', coalesce(v_status,'missing'));
exception when others then
  insert into _boralog_messages_results values ('FULL', false, sqlstate||' '||sqlerrm);
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','12700000-0000-4000-8000-000000000003',true);

do $$
declare v_id uuid; v_status text;
begin
  insert into public.messages(organization_id, project_id, content, created_by)
  values (
    '12710000-0000-4000-8000-000000000001',
    '12720000-0000-4000-8000-000000000001',
    'limited project',
    auth.uid()
  )
  returning id into v_id;

  update public.messages set status='PROCESSED' where id=v_id;
  select status into v_status from public.messages where id=v_id;

  insert into _boralog_messages_results values ('LIMITED_PROJECT', v_status='PROCESSED', coalesce(v_status,'missing'));
exception when others then
  insert into _boralog_messages_results values ('LIMITED_PROJECT', false, sqlstate||' '||sqlerrm);
end $$;

do $$
declare v_visible bigint; v_denied boolean := false;
begin
  select count(*) into v_visible
  from public.messages
  where project_id is null and event_id is null;

  begin
    insert into public.messages(organization_id, content, created_by)
    values (
      '12710000-0000-4000-8000-000000000001',
      'limited forbidden org-only',
      auth.uid()
    );
  exception when others then
    v_denied := true;
  end;

  insert into _boralog_messages_results values (
    'LIMITED_ORG_ONLY_DENIED',
    v_visible=0 and v_denied,
    'visible='||v_visible||', denied='||v_denied
  );
end $$;

do $$
declare v_id uuid; v_seen bigint;
begin
  insert into public.messages(organization_id, event_id, content, created_by)
  values (
    '12710000-0000-4000-8000-000000000001',
    '12730000-0000-4000-8000-000000000001',
    'limited event-only',
    auth.uid()
  )
  returning id into v_id;

  select count(*) into v_seen from public.messages where id=v_id;
  insert into _boralog_messages_results values ('LIMITED_EVENT_ONLY', v_seen=1, 'seen='||v_seen);
exception when others then
  insert into _boralog_messages_results values ('LIMITED_EVENT_ONLY', false, sqlstate||' '||sqlerrm);
end $$;

do $$
declare v_id uuid; v_denied boolean := false; v_project uuid;
begin
  insert into public.messages(organization_id, project_id, content, created_by)
  values (
    '12710000-0000-4000-8000-000000000001',
    '12720000-0000-4000-8000-000000000001',
    'limited update escape source',
    auth.uid()
  )
  returning id into v_id;

  begin
    update public.messages
       set project_id=null, event_id=null
     where id=v_id;
  exception when others then
    v_denied := true;
  end;

  select project_id into v_project from public.messages where id=v_id;
  insert into _boralog_messages_results values (
    'UPDATE_ESCAPE_DENIED',
    v_denied and v_project='12720000-0000-4000-8000-000000000001'::uuid,
    'denied='||v_denied
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','12700000-0000-4000-8000-000000000001',true);

do $$
declare v_denied boolean := false;
begin
  begin
    insert into public.messages(
      organization_id, project_id, event_id, content, created_by
    ) values (
      '12710000-0000-4000-8000-000000000001',
      '12720000-0000-4000-8000-000000000002',
      '12730000-0000-4000-8000-000000000001',
      'inconsistent project/event',
      auth.uid()
    );
  exception when check_violation then
    v_denied := true;
  end;

  insert into _boralog_messages_results values ('CONSISTENCY_GUARD', v_denied, 'denied='||v_denied);
end $$;

reset role;

do $$
begin
  if exists (select 1 from _boralog_messages_results where not pass) then
    raise exception 'BORALOG-127 Messages DB test failed';
  end if;
end $$;

select test, pass, detail
from _boralog_messages_results
order by test;

rollback;
