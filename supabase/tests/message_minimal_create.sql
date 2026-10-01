-- BORALOG-161 atomic minimal Message creation tests.
-- Self-contained fixtures are rolled back.

begin;

create temporary table _boralog_161_results (
  test text primary key,
  pass boolean not null,
  detail text
) on commit drop;

grant select, insert, update on _boralog_161_results to authenticated;

insert into auth.users (
  id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('16100000-0000-4000-8000-000000000001','authenticated','authenticated','boralog161-owner@example.invalid','{}','{"display_name":"Owner 161"}',now(),now()),
  ('16100000-0000-4000-8000-000000000002','authenticated','authenticated','boralog161-full@example.invalid','{}','{"display_name":"Full 161"}',now(),now()),
  ('16100000-0000-4000-8000-000000000003','authenticated','authenticated','boralog161-limited@example.invalid','{}','{"display_name":"Limited 161"}',now(),now()),
  ('16100000-0000-4000-8000-000000000004','authenticated','authenticated','boralog161-second@example.invalid','{}','{"display_name":"Second 161"}',now(),now()),
  ('16100000-0000-4000-8000-000000000005','authenticated','authenticated','boralog161-suspended@example.invalid','{}','{"display_name":"Suspended 161"}',now(),now()),
  ('16100000-0000-4000-8000-000000000006','authenticated','authenticated','boralog161-other@example.invalid','{}','{"display_name":"Other 161"}',now(),now()),
  ('16100000-0000-4000-8000-000000000007','authenticated','authenticated','boralog161-limited-other@example.invalid','{}','{"display_name":"Limited Other 161"}',now(),now());

set local role authenticated;
select set_config('request.jwt.claim.sub','16100000-0000-4000-8000-000000000001',true);

insert into public.organizations(id, name, slug, created_by)
values
  ('16110000-0000-4000-8000-000000000001','BORALOG 161 Primary Org','boralog-161-primary-org',auth.uid()),
  ('16110000-0000-4000-8000-000000000002','BORALOG 161 Other Org','boralog-161-other-org',auth.uid());

reset role;

insert into public.organization_memberships(
  organization_id, user_id, role, status, access_level
) values
  ('16110000-0000-4000-8000-000000000001','16100000-0000-4000-8000-000000000002',null,'active','full'),
  ('16110000-0000-4000-8000-000000000001','16100000-0000-4000-8000-000000000003',null,'active','limited'),
  ('16110000-0000-4000-8000-000000000001','16100000-0000-4000-8000-000000000004',null,'active','full'),
  ('16110000-0000-4000-8000-000000000001','16100000-0000-4000-8000-000000000005',null,'suspended','full'),
  ('16110000-0000-4000-8000-000000000001','16100000-0000-4000-8000-000000000007',null,'active','limited'),
  ('16110000-0000-4000-8000-000000000002','16100000-0000-4000-8000-000000000006',null,'active','full');

-- One historical-like row with unknown provenance, matching the pre-155 data shape.
alter table public.messages disable trigger boralog_message_provenance_insert;
insert into public.messages(
  id, organization_id, content, created_by
) values (
  '16140000-0000-4000-8000-000000000099',
  '16110000-0000-4000-8000-000000000001',
  'BORALOG 161 untouched historical fixture',
  '16100000-0000-4000-8000-000000000001'
);
alter table public.messages enable trigger boralog_message_provenance_insert;

create temporary table _boralog_161_historical_snapshot
on commit drop
as
select to_jsonb(m) as row_snapshot
from public.messages as m
where m.id='16140000-0000-4000-8000-000000000099';

set local role authenticated;
select set_config('request.jwt.claim.sub','16100000-0000-4000-8000-000000000001',true);

do $$
declare
  v_id uuid;
  v_visibility text;
  v_recipient_count bigint;
begin
  select created.id
    into v_id
  from public.boralog_create_internal_message(
    '16110000-0000-4000-8000-000000000001',
    '  organization minimal create  ',
    'ORGANIZATION',
    '{}'::uuid[]
  ) as created;

  select m.visibility
    into v_visibility
  from public.messages as m
  where m.id=v_id;

  select count(*)
    into v_recipient_count
  from public.message_recipients
  where message_id=v_id;

  insert into _boralog_161_results values (
    'ORGANIZATION_CREATE_PASS',
    v_id is not null
      and v_visibility='ORGANIZATION'
      and v_recipient_count=0,
    'visibility='||coalesce(v_visibility,'missing')||', recipients='||v_recipient_count
  );
exception when others then
  insert into _boralog_161_results values ('ORGANIZATION_CREATE_PASS', false, sqlstate||' '||sqlerrm);
end $$;

do $$
declare
  v_id uuid;
  v_recipient_count bigint;
begin
  select created.id
    into v_id
  from public.boralog_create_internal_message(
    '16110000-0000-4000-8000-000000000001',
    'restricted minimal create',
    'RESTRICTED',
    array['16100000-0000-4000-8000-000000000002'::uuid]
  ) as created;

  select count(*)
    into v_recipient_count
  from public.message_recipients
  where message_id=v_id
    and user_id='16100000-0000-4000-8000-000000000002';

  insert into _boralog_161_results values (
    'RESTRICTED_CREATE_WITH_RECIPIENT_PASS',
    v_id is not null and v_recipient_count=1,
    'recipient_rows='||v_recipient_count
  );
exception when others then
  insert into _boralog_161_results values ('RESTRICTED_CREATE_WITH_RECIPIENT_PASS', false, sqlstate||' '||sqlerrm);
end $$;

do $$
declare
  v_id uuid;
  v_recipient_count bigint;
begin
  select created.id
    into v_id
  from public.boralog_create_internal_message(
    '16110000-0000-4000-8000-000000000001',
    'multiple recipients',
    'RESTRICTED',
    array[
      '16100000-0000-4000-8000-000000000002'::uuid,
      '16100000-0000-4000-8000-000000000004'::uuid
    ]
  ) as created;

  select count(*)
    into v_recipient_count
  from public.message_recipients
  where message_id=v_id;

  insert into _boralog_161_results values (
    'MULTIPLE_RECIPIENTS_PASS',
    v_recipient_count=2,
    'recipient_rows='||v_recipient_count
  );
exception when others then
  insert into _boralog_161_results values ('MULTIPLE_RECIPIENTS_PASS', false, sqlstate||' '||sqlerrm);
end $$;

do $$
declare
  v_denied boolean := false;
  v_rows bigint;
begin
  begin
    perform public.boralog_create_internal_message(
      '16110000-0000-4000-8000-000000000001',
      'cross org recipient denied',
      'RESTRICTED',
      array['16100000-0000-4000-8000-000000000006'::uuid]
    );
  exception when check_violation then
    v_denied := true;
  end;

  select count(*) into v_rows
  from public.messages
  where content='cross org recipient denied';

  insert into _boralog_161_results values (
    'CROSS_ORGANIZATION_RECIPIENT_DENIED',
    v_denied and v_rows=0,
    'denied='||v_denied||', messages='||v_rows
  );
end $$;

do $$
declare
  v_denied boolean := false;
  v_rows bigint;
begin
  begin
    perform public.boralog_create_internal_message(
      '16110000-0000-4000-8000-000000000001',
      'inactive recipient denied',
      'RESTRICTED',
      array['16100000-0000-4000-8000-000000000005'::uuid]
    );
  exception when check_violation then
    v_denied := true;
  end;

  select count(*) into v_rows
  from public.messages
  where content='inactive recipient denied';

  insert into _boralog_161_results values (
    'INACTIVE_RECIPIENT_DENIED',
    v_denied and v_rows=0,
    'denied='||v_denied||', messages='||v_rows
  );
end $$;

do $$
declare
  v_denied boolean := false;
  v_rows bigint;
begin
  begin
    perform public.boralog_create_internal_message(
      '16110000-0000-4000-8000-000000000001',
      '   ',
      'ORGANIZATION',
      '{}'::uuid[]
    );
  exception when check_violation then
    v_denied := true;
  end;

  select count(*) into v_rows
  from public.messages
  where btrim(content)='';

  insert into _boralog_161_results values (
    'EMPTY_CONTENT_DENIED',
    v_denied and v_rows=0,
    'denied='||v_denied||', messages='||v_rows
  );
end $$;

do $$
declare
  v_denied boolean := false;
  v_rows bigint;
begin
  begin
    perform public.boralog_create_internal_message(
      '16110000-0000-4000-8000-000000000001',
      'restricted zero recipients denied',
      'RESTRICTED',
      '{}'::uuid[]
    );
  exception when check_violation then
    v_denied := true;
  end;

  select count(*) into v_rows
  from public.messages
  where content='restricted zero recipients denied';

  insert into _boralog_161_results values (
    'RESTRICTED_ZERO_RECIPIENT_DENIED',
    v_denied and v_rows=0,
    'denied='||v_denied||', messages='||v_rows
  );
end $$;

do $$
declare
  v_denied boolean := false;
  v_message_rows bigint;
  v_recipient_rows bigint;
begin
  begin
    perform public.boralog_create_internal_message(
      '16110000-0000-4000-8000-000000000001',
      'atomic mixed recipients',
      'RESTRICTED',
      array[
        '16100000-0000-4000-8000-000000000002'::uuid,
        '16100000-0000-4000-8000-000000000006'::uuid
      ]
    );
  exception when check_violation then
    v_denied := true;
  end;

  select count(*) into v_message_rows
  from public.messages
  where content='atomic mixed recipients';

  select count(*) into v_recipient_rows
  from public.message_recipients as mr
  join public.messages as m on m.id=mr.message_id
  where m.content='atomic mixed recipients';

  insert into _boralog_161_results values (
    'ATOMICITY_PASS',
    v_denied and v_message_rows=0 and v_recipient_rows=0,
    'denied='||v_denied||', messages='||v_message_rows||', recipients='||v_recipient_rows
  );
end $$;

do $$
declare
  v_id uuid;
  v_origin text;
  v_created_by uuid;
  v_author uuid;
  v_external text;
  v_source text;
  v_occurred timestamptz;
begin
  select created.id
    into v_id
  from public.boralog_create_internal_message(
    '16110000-0000-4000-8000-000000000001',
    'provenance preserved',
    'ORGANIZATION',
    '{}'::uuid[]
  ) as created;

  select
    origin_type,
    created_by,
    author_user_id,
    external_author_label,
    source_kind,
    source_occurred_at
  into
    v_origin,
    v_created_by,
    v_author,
    v_external,
    v_source,
    v_occurred
  from public.messages
  where id=v_id;

  insert into _boralog_161_results values (
    'PROVENANCE_155_PRESERVED',
    v_origin='INTERNAL'
      and v_created_by=auth.uid()
      and v_author=auth.uid()
      and v_external is null
      and v_source is null
      and v_occurred is null,
    'origin='||coalesce(v_origin,'missing')
  );
exception when others then
  insert into _boralog_161_results values ('PROVENANCE_155_PRESERVED', false, sqlstate||' '||sqlerrm);
end $$;

-- A direct RESTRICTED insert cannot commit without a recipient either.
do $$
declare
  v_denied boolean := false;
begin
  begin
    insert into public.messages(
      organization_id, content, created_by, origin_type, author_user_id, visibility
    ) values (
      '16110000-0000-4000-8000-000000000001',
      'direct restricted without audience',
      auth.uid(),
      'INTERNAL',
      auth.uid(),
      'RESTRICTED'
    );

    set constraints boralog_restricted_message_recipient_required immediate;
  exception when check_violation then
    v_denied := true;
  end;

  set constraints boralog_restricted_message_recipient_required deferred;

  insert into _boralog_161_results values (
    'RESTRICTED_INVARIANT_PRESERVED',
    v_denied,
    'denied='||v_denied
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','16100000-0000-4000-8000-000000000003',true);

do $$
declare
  v_id uuid;
  v_seen bigint;
  v_self_recipient bigint;
begin
  select created.id
    into v_id
  from public.boralog_create_internal_message(
    '16110000-0000-4000-8000-000000000001',
    'limited restricted no context',
    'RESTRICTED',
    array['16100000-0000-4000-8000-000000000002'::uuid]
  ) as created;

  select count(*) into v_seen
  from public.messages
  where id=v_id;

  select count(*) into v_self_recipient
  from public.message_recipients
  where message_id=v_id
    and user_id=auth.uid();

  insert into _boralog_161_results values (
    'LIMITED_RESTRICTED_CREATOR_ACCESS',
    v_seen=1 and v_self_recipient=0,
    'seen='||v_seen||', self_recipient='||v_self_recipient
  );
exception when others then
  insert into _boralog_161_results values ('LIMITED_RESTRICTED_CREATOR_ACCESS', false, sqlstate||' '||sqlerrm);
end $$;

do $$
declare
  v_denied boolean := false;
begin
  begin
    perform public.boralog_create_internal_message(
      '16110000-0000-4000-8000-000000000001',
      'limited organization forbidden',
      'ORGANIZATION',
      '{}'::uuid[]
    );
  exception when insufficient_privilege then
    v_denied := true;
  end;

  insert into _boralog_161_results values (
    'LIMITED_ORGANIZATION_DENIED',
    v_denied,
    'denied='||v_denied
  );
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','16100000-0000-4000-8000-000000000007',true);

do $$
declare
  v_seen bigint;
begin
  select count(*) into v_seen
  from public.messages
  where content='restricted minimal create';

  insert into _boralog_161_results values (
    'VISIBILITY_157_PRESERVED',
    v_seen=0,
    'non_audience_seen='||v_seen
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
  cross join _boralog_161_historical_snapshot as snapshot
  where m.id='16140000-0000-4000-8000-000000000099';

  insert into _boralog_161_results values (
    'HISTORICAL_MESSAGES_UNCHANGED',
    coalesce(v_same,false),
    'unchanged='||coalesce(v_same,false)
  );
end $$;

do $$
begin
  if exists (select 1 from _boralog_161_results where not pass) then
    raise exception 'BORALOG-161 atomic minimal Message test failed';
  end if;
end $$;

select test, pass, detail
from _boralog_161_results
order by test;

rollback;
