-- BORALOG-155C targeted Message communication provenance tests.
-- Self-contained: all fixtures are rolled back.

begin;

create temporary table _boralog_155_results (
  test text primary key,
  pass boolean not null,
  detail text
) on commit drop;

grant select, insert, update on _boralog_155_results to authenticated;

insert into auth.users (
  id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('15500000-0000-4000-8000-000000000001','authenticated','authenticated','boralog155-owner@example.invalid','{}','{}',now(),now()),
  ('15500000-0000-4000-8000-000000000002','authenticated','authenticated','boralog155-active-author@example.invalid','{}','{}',now(),now()),
  ('15500000-0000-4000-8000-000000000003','authenticated','authenticated','boralog155-outside-author@example.invalid','{}','{}',now(),now()),
  ('15500000-0000-4000-8000-000000000004','authenticated','authenticated','boralog155-inactive-author@example.invalid','{}','{}',now(),now());

select set_config('request.jwt.claim.sub','15500000-0000-4000-8000-000000000001',true);

insert into public.organizations(id, name, slug, created_by)
values (
  '15510000-0000-4000-8000-000000000001',
  'BORALOG 155 Provenance Test',
  'boralog-155-provenance-test',
  '15500000-0000-4000-8000-000000000001'
);

insert into public.organization_memberships(
  organization_id, user_id, role, status, access_level
) values
  ('15510000-0000-4000-8000-000000000001','15500000-0000-4000-8000-000000000002',null,'active','full'),
  ('15510000-0000-4000-8000-000000000001','15500000-0000-4000-8000-000000000004',null,'suspended','full');

insert into public.projects(id, organization_id, name, created_by)
values (
  '15520000-0000-4000-8000-000000000001',
  '15510000-0000-4000-8000-000000000001',
  'Historical update project',
  '15500000-0000-4000-8000-000000000001'
);

-- Simulate one row that predates migration 155. The INSERT guard did not exist
-- when historical rows were created, so disable only that trigger for this fixture.
alter table public.messages disable trigger boralog_message_provenance_insert;

insert into public.messages(
  id, organization_id, content, created_by
) values (
  '15540000-0000-4000-8000-000000000001',
  '15510000-0000-4000-8000-000000000001',
  'historical provenance unknown',
  '15500000-0000-4000-8000-000000000001'
);

alter table public.messages enable trigger boralog_message_provenance_insert;

set local role authenticated;
select set_config('request.jwt.claim.sub','15500000-0000-4000-8000-000000000001',true);

do $$
declare
  v_origin text;
  v_author uuid;
  v_external text;
  v_source text;
  v_occurred timestamptz;
begin
  select origin_type, author_user_id, external_author_label, source_kind, source_occurred_at
    into v_origin, v_author, v_external, v_source, v_occurred
  from public.messages
  where id='15540000-0000-4000-8000-000000000001';

  insert into _boralog_155_results values (
    'HISTORICAL_NULL_ROW',
    v_origin is null
      and v_author is null
      and v_external is null
      and v_source is null
      and v_occurred is null,
    'origin='||coalesce(v_origin,'null')
  );
end $$;

do $$
declare
  v_project uuid;
  v_origin text;
begin
  update public.messages
     set project_id='15520000-0000-4000-8000-000000000001'
   where id='15540000-0000-4000-8000-000000000001';

  select project_id, origin_type
    into v_project, v_origin
  from public.messages
  where id='15540000-0000-4000-8000-000000000001';

  insert into _boralog_155_results values (
    'HISTORICAL_ALLOWED_UPDATE',
    v_project='15520000-0000-4000-8000-000000000001'::uuid
      and v_origin is null,
    'origin='||coalesce(v_origin,'null')
  );
exception when others then
  insert into _boralog_155_results values (
    'HISTORICAL_ALLOWED_UPDATE',
    false,
    sqlstate||' '||sqlerrm
  );
end $$;

do $$
declare
  v_id uuid;
  v_origin text;
  v_author uuid;
begin
  insert into public.messages(
    organization_id, content, created_by, origin_type, author_user_id
  ) values (
    '15510000-0000-4000-8000-000000000001',
    'valid internal',
    auth.uid(),
    'INTERNAL',
    auth.uid()
  )
  returning id, origin_type, author_user_id
    into v_id, v_origin, v_author;

  insert into _boralog_155_results values (
    'INTERNAL_VALID',
    v_id is not null and v_origin='INTERNAL' and v_author=auth.uid(),
    'origin='||coalesce(v_origin,'null')
  );
exception when others then
  insert into _boralog_155_results values ('INTERNAL_VALID', false, sqlstate||' '||sqlerrm);
end $$;

do $$
declare
  v_missing_origin boolean := false;
  v_missing_author boolean := false;
  v_wrong_author boolean := false;
  v_wrong_creator boolean := false;
  v_external_label boolean := false;
  v_source boolean := false;
  v_source_time boolean := false;
begin
  begin
    insert into public.messages(organization_id, content, created_by)
    values ('15510000-0000-4000-8000-000000000001','missing origin',auth.uid());
  exception when check_violation then
    v_missing_origin := true;
  end;

  begin
    insert into public.messages(organization_id, content, created_by, origin_type)
    values ('15510000-0000-4000-8000-000000000001','missing author',auth.uid(),'INTERNAL');
  exception when check_violation then
    v_missing_author := true;
  end;

  begin
    insert into public.messages(
      organization_id, content, created_by, origin_type, author_user_id
    ) values (
      '15510000-0000-4000-8000-000000000001',
      'wrong internal author',
      auth.uid(),
      'INTERNAL',
      '15500000-0000-4000-8000-000000000002'
    );
  exception when check_violation then
    v_wrong_author := true;
  end;

  begin
    insert into public.messages(
      organization_id, content, created_by, origin_type, author_user_id
    ) values (
      '15510000-0000-4000-8000-000000000001',
      'forged creator',
      '15500000-0000-4000-8000-000000000002',
      'INTERNAL',
      auth.uid()
    );
  exception when check_violation then
    v_wrong_creator := true;
  end;

  begin
    insert into public.messages(
      organization_id, content, created_by, origin_type, author_user_id, external_author_label
    ) values (
      '15510000-0000-4000-8000-000000000001',
      'internal external label',
      auth.uid(),
      'INTERNAL',
      auth.uid(),
      'External'
    );
  exception when check_violation then
    v_external_label := true;
  end;

  begin
    insert into public.messages(
      organization_id, content, created_by, origin_type, author_user_id, source_kind
    ) values (
      '15510000-0000-4000-8000-000000000001',
      'internal source',
      auth.uid(),
      'INTERNAL',
      auth.uid(),
      'EMAIL'
    );
  exception when check_violation then
    v_source := true;
  end;

  begin
    insert into public.messages(
      organization_id, content, created_by, origin_type, author_user_id, source_occurred_at
    ) values (
      '15510000-0000-4000-8000-000000000001',
      'internal source time',
      auth.uid(),
      'INTERNAL',
      auth.uid(),
      now()
    );
  exception when check_violation then
    v_source_time := true;
  end;

  insert into _boralog_155_results values (
    'INTERNAL_INVALID_CASES',
    v_missing_origin
      and v_missing_author
      and v_wrong_author
      and v_wrong_creator
      and v_external_label
      and v_source
      and v_source_time,
    'missing_origin='||v_missing_origin
      ||', missing_author='||v_missing_author
      ||', wrong_author='||v_wrong_author
      ||', wrong_creator='||v_wrong_creator
      ||', external_label='||v_external_label
      ||', source='||v_source
      ||', source_time='||v_source_time
  );
end $$;

do $$
declare v_id uuid;
begin
  insert into public.messages(
    organization_id, content, created_by, origin_type
  ) values (
    '15510000-0000-4000-8000-000000000001',
    'minimal imported',
    auth.uid(),
    'EXTERNAL_IMPORTED'
  )
  returning id into v_id;

  insert into _boralog_155_results values (
    'EXTERNAL_IMPORTED_MINIMAL',
    v_id is not null,
    'inserted='||(v_id is not null)
  );
exception when others then
  insert into _boralog_155_results values ('EXTERNAL_IMPORTED_MINIMAL', false, sqlstate||' '||sqlerrm);
end $$;

do $$
declare v_id uuid;
begin
  insert into public.messages(
    organization_id, content, created_by, origin_type
  ) values (
    '15510000-0000-4000-8000-000000000001',
    'minimal manual external',
    auth.uid(),
    'EXTERNAL_MANUAL'
  )
  returning id into v_id;

  insert into _boralog_155_results values (
    'EXTERNAL_MANUAL_MINIMAL',
    v_id is not null,
    'inserted='||(v_id is not null)
  );
exception when others then
  insert into _boralog_155_results values ('EXTERNAL_MANUAL_MINIMAL', false, sqlstate||' '||sqlerrm);
end $$;

do $$
declare v_denied boolean := false;
begin
  begin
    insert into public.messages(
      organization_id, content, created_by, origin_type, author_user_id, external_author_label
    ) values (
      '15510000-0000-4000-8000-000000000001',
      'two authors',
      auth.uid(),
      'EXTERNAL_IMPORTED',
      '15500000-0000-4000-8000-000000000002',
      'External Author'
    );
  exception when check_violation then
    v_denied := true;
  end;

  insert into _boralog_155_results values (
    'AUTHOR_EXCLUSIVITY',
    v_denied,
    'denied='||v_denied
  );
end $$;

do $$
declare v_id uuid;
begin
  insert into public.messages(
    organization_id, content, created_by, origin_type, author_user_id
  ) values (
    '15510000-0000-4000-8000-000000000001',
    'active member author',
    auth.uid(),
    'EXTERNAL_IMPORTED',
    '15500000-0000-4000-8000-000000000002'
  )
  returning id into v_id;

  insert into _boralog_155_results values (
    'ACTIVE_MEMBER_AUTHOR',
    v_id is not null,
    'inserted='||(v_id is not null)
  );
exception when others then
  insert into _boralog_155_results values ('ACTIVE_MEMBER_AUTHOR', false, sqlstate||' '||sqlerrm);
end $$;

do $$
declare v_denied boolean := false;
begin
  begin
    insert into public.messages(
      organization_id, content, created_by, origin_type, author_user_id
    ) values (
      '15510000-0000-4000-8000-000000000001',
      'outside organization author',
      auth.uid(),
      'EXTERNAL_MANUAL',
      '15500000-0000-4000-8000-000000000003'
    );
  exception when check_violation then
    v_denied := true;
  end;

  insert into _boralog_155_results values (
    'OUTSIDE_ORG_AUTHOR_REJECTED',
    v_denied,
    'denied='||v_denied
  );
end $$;

do $$
declare v_denied boolean := false;
begin
  begin
    insert into public.messages(
      organization_id, content, created_by, origin_type, author_user_id
    ) values (
      '15510000-0000-4000-8000-000000000001',
      'inactive member author',
      auth.uid(),
      'EXTERNAL_IMPORTED',
      '15500000-0000-4000-8000-000000000004'
    );
  exception when check_violation then
    v_denied := true;
  end;

  insert into _boralog_155_results values (
    'INACTIVE_MEMBER_AUTHOR_REJECTED',
    v_denied,
    'denied='||v_denied
  );
end $$;

do $$
declare
  v_source text;
  v_allowed integer := 0;
  v_invalid_denied boolean := false;
begin
  foreach v_source in array array['WHATSAPP','EMAIL','SMS','PHONE','OTHER'] loop
    insert into public.messages(
      organization_id, content, created_by, origin_type, source_kind
    ) values (
      '15510000-0000-4000-8000-000000000001',
      'allowed source '||v_source,
      auth.uid(),
      'EXTERNAL_IMPORTED',
      v_source
    );
    v_allowed := v_allowed + 1;
  end loop;

  begin
    insert into public.messages(
      organization_id, content, created_by, origin_type, source_kind
    ) values (
      '15510000-0000-4000-8000-000000000001',
      'invalid source',
      auth.uid(),
      'EXTERNAL_IMPORTED',
      'TELEGRAM'
    );
  exception when check_violation then
    v_invalid_denied := true;
  end;

  insert into _boralog_155_results values (
    'SOURCE_KIND',
    v_allowed=5 and v_invalid_denied,
    'allowed='||v_allowed||', invalid_denied='||v_invalid_denied
  );
end $$;

do $$
declare
  v_id uuid;
  v_origin_denied boolean := false;
  v_author_denied boolean := false;
  v_external_denied boolean := false;
  v_source_denied boolean := false;
  v_occurred_denied boolean := false;
begin
  insert into public.messages(
    organization_id, content, created_by, origin_type, author_user_id, source_kind, source_occurred_at
  ) values (
    '15510000-0000-4000-8000-000000000001',
    'immutable communication provenance',
    auth.uid(),
    'EXTERNAL_IMPORTED',
    '15500000-0000-4000-8000-000000000002',
    'WHATSAPP',
    '2026-09-30T08:00:00Z'
  )
  returning id into v_id;

  begin
    update public.messages set origin_type='EXTERNAL_MANUAL' where id=v_id;
  exception when check_violation then v_origin_denied := true;
  end;

  begin
    update public.messages set author_user_id=auth.uid() where id=v_id;
  exception when check_violation then v_author_denied := true;
  end;

  begin
    update public.messages set external_author_label='Changed' where id=v_id;
  exception when check_violation then v_external_denied := true;
  end;

  begin
    update public.messages set source_kind='EMAIL' where id=v_id;
  exception when check_violation then v_source_denied := true;
  end;

  begin
    update public.messages set source_occurred_at='2026-09-30T09:00:00Z' where id=v_id;
  exception when check_violation then v_occurred_denied := true;
  end;

  insert into _boralog_155_results values (
    'PROVENANCE_IMMUTABILITY',
    v_origin_denied
      and v_author_denied
      and v_external_denied
      and v_source_denied
      and v_occurred_denied,
    'origin='||v_origin_denied
      ||', author='||v_author_denied
      ||', external='||v_external_denied
      ||', source='||v_source_denied
      ||', occurred='||v_occurred_denied
  );
end $$;

do $$
declare
  v_id uuid;
  v_content_denied boolean := false;
  v_created_by_denied boolean := false;
begin
  insert into public.messages(
    organization_id, content, created_by, origin_type, author_user_id
  ) values (
    '15510000-0000-4000-8000-000000000001',
    'previous immutability remains',
    auth.uid(),
    'INTERNAL',
    auth.uid()
  )
  returning id into v_id;

  begin
    update public.messages set content='tampered' where id=v_id;
  exception when check_violation then v_content_denied := true;
  end;

  begin
    update public.messages
       set created_by='15500000-0000-4000-8000-000000000002'
     where id=v_id;
  exception when check_violation then v_created_by_denied := true;
  end;

  insert into _boralog_155_results values (
    'PREVIOUS_IMMUTABILITY',
    v_content_denied and v_created_by_denied,
    'content='||v_content_denied||', created_by='||v_created_by_denied
  );
end $$;

reset role;

do $$
begin
  if exists (select 1 from _boralog_155_results where not pass) then
    raise exception 'BORALOG-155 Message provenance test failed';
  end if;
end $$;

select test, pass, detail
from _boralog_155_results
order by test;

rollback;
