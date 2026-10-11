-- BORALOG-178B: Message external Person sender contract.
begin;

insert into auth.users (
  id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('17810000-0000-4000-8000-000000000001','authenticated','authenticated','owner178b@example.invalid','{}','{}',now(),now()),
  ('17810000-0000-4000-8000-000000000002','authenticated','authenticated','owner2-178b@example.invalid','{}','{}',now(),now());

insert into public.organizations(id,name,slug,created_by) values
  ('17811000-0000-4000-8000-000000000001','BORALOG 178B A','boralog-178b-a','17810000-0000-4000-8000-000000000001'),
  ('17811000-0000-4000-8000-000000000002','BORALOG 178B B','boralog-178b-b','17810000-0000-4000-8000-000000000002');

insert into public.organization_memberships(
  organization_id,user_id,role,status,access_level
) values
  ('17811000-0000-4000-8000-000000000001','17810000-0000-4000-8000-000000000001',null,'active','owner'),
  ('17811000-0000-4000-8000-000000000002','17810000-0000-4000-8000-000000000002',null,'active','owner');

insert into public.people(
  id,organization_id,name,role_label,created_by
) values
  ('17812000-0000-4000-8000-000000000001','17811000-0000-4000-8000-000000000001','Alice 178B','Régisseuse','17810000-0000-4000-8000-000000000001'),
  ('17812000-0000-4000-8000-000000000002','17811000-0000-4000-8000-000000000002','Bob 178B',null,'17810000-0000-4000-8000-000000000002');

set local role authenticated;
select set_config('request.jwt.claim.sub','17810000-0000-4000-8000-000000000001',true);

-- EXTERNAL_MANUAL with same-organization Person.
insert into public.messages(
  id,organization_id,project_id,event_id,content,status,created_by,
  origin_type,author_user_id,external_author_person_id,external_author_label,
  source_kind,source_occurred_at,visibility
) values (
  '17813000-0000-4000-8000-000000000001',
  '17811000-0000-4000-8000-000000000001',
  null,null,'Person sender 178B','TO_PROCESS',
  '17810000-0000-4000-8000-000000000001',
  'EXTERNAL_MANUAL',null,'17812000-0000-4000-8000-000000000001',null,
  'WHATSAPP',null,'ORGANIZATION'
);

do $$
begin
  if not exists (
    select 1 from public.messages
    where id='17813000-0000-4000-8000-000000000001'
      and external_author_person_id='17812000-0000-4000-8000-000000000001'
      and external_author_label is null
      and author_user_id is null
  ) then
    raise exception 'EXTERNAL_MANUAL same-org Person sender not persisted';
  end if;
end $$;

-- Cross-organization Person rejected.
do $$
declare denied boolean := false;
begin
  begin
    insert into public.messages(
      organization_id,content,created_by,origin_type,external_author_person_id,
      source_kind,visibility
    ) values (
      '17811000-0000-4000-8000-000000000001','cross-org 178B',
      '17810000-0000-4000-8000-000000000001','EXTERNAL_MANUAL',
      '17812000-0000-4000-8000-000000000002','WHATSAPP','ORGANIZATION'
    );
  exception when check_violation then denied := true;
  end;
  if not denied then raise exception 'cross-organization Person sender accepted'; end if;
end $$;

-- author_user_id + Person rejected.
do $$
declare denied boolean := false;
begin
  begin
    insert into public.messages(
      organization_id,content,created_by,origin_type,author_user_id,
      external_author_person_id,source_kind,visibility
    ) values (
      '17811000-0000-4000-8000-000000000001','double author 178B',
      '17810000-0000-4000-8000-000000000001','EXTERNAL_MANUAL',
      '17810000-0000-4000-8000-000000000001',
      '17812000-0000-4000-8000-000000000001','WHATSAPP','ORGANIZATION'
    );
  exception when check_violation then denied := true;
  end;
  if not denied then raise exception 'author_user_id + Person accepted'; end if;
end $$;

-- label + Person rejected.
do $$
declare denied boolean := false;
begin
  begin
    insert into public.messages(
      organization_id,content,created_by,origin_type,external_author_person_id,
      external_author_label,source_kind,visibility
    ) values (
      '17811000-0000-4000-8000-000000000001','double external author 178B',
      '17810000-0000-4000-8000-000000000001','EXTERNAL_MANUAL',
      '17812000-0000-4000-8000-000000000001','Mamie','WHATSAPP','ORGANIZATION'
    );
  exception when check_violation then denied := true;
  end;
  if not denied then raise exception 'Person + external label accepted'; end if;
end $$;

-- INTERNAL with Person rejected.
do $$
declare denied boolean := false;
begin
  begin
    insert into public.messages(
      organization_id,content,created_by,origin_type,author_user_id,
      external_author_person_id,visibility
    ) values (
      '17811000-0000-4000-8000-000000000001','internal Person 178B',
      '17810000-0000-4000-8000-000000000001','INTERNAL',
      '17810000-0000-4000-8000-000000000001',
      '17812000-0000-4000-8000-000000000001','ORGANIZATION'
    );
  exception when check_violation then denied := true;
  end;
  if not denied then raise exception 'INTERNAL Person sender accepted'; end if;
end $$;

-- EXTERNAL_MANUAL label and unknown remain valid.
insert into public.messages(
  organization_id,content,created_by,origin_type,external_author_label,source_kind,visibility
) values (
  '17811000-0000-4000-8000-000000000001','label sender 178B',
  '17810000-0000-4000-8000-000000000001','EXTERNAL_MANUAL',
  'Mamie','WHATSAPP','ORGANIZATION'
);

insert into public.messages(
  organization_id,content,created_by,origin_type,source_kind,visibility
) values (
  '17811000-0000-4000-8000-000000000001','unknown sender 178B',
  '17810000-0000-4000-8000-000000000001','EXTERNAL_MANUAL',
  'OTHER','ORGANIZATION'
);

-- Provenance Person link is immutable.
do $$
declare denied boolean := false;
begin
  begin
    update public.messages
    set external_author_person_id = null
    where id='17813000-0000-4000-8000-000000000001';
  exception when check_violation then denied := true;
  end;
  if not denied then raise exception 'external_author_person_id mutation accepted'; end if;
end $$;

-- Canonical 165R cycle remains reversible and Notes remain compatible.
do $$
declare
  changed public.messages%rowtype;
  note public.message_notes%rowtype;
begin
  select x.* into changed
  from public.boralog_set_message_status(
    '17813000-0000-4000-8000-000000000001','PROCESSED'
  ) as x;
  if changed.status <> 'PROCESSED' then raise exception 'TO_PROCESS -> PROCESSED failed'; end if;

  select x.* into note
  from public.boralog_add_message_note(
    '17813000-0000-4000-8000-000000000001','Note 178B'
  ) as x;
  if note.content <> 'Note 178B' then raise exception 'Message Note failed'; end if;

  select x.* into changed
  from public.boralog_set_message_status(
    '17813000-0000-4000-8000-000000000001','TO_PROCESS'
  ) as x;
  if changed.status <> 'TO_PROCESS' then raise exception 'PROCESSED -> TO_PROCESS failed'; end if;
end $$;

rollback;
