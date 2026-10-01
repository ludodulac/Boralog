-- BORALOG-165: explicit human processing of a Message into 0..N durable consequences.

alter table public.messages
  drop constraint messages_resolution_check,
  drop constraint messages_processing_state_check;

alter table public.messages
  add constraint messages_resolution_check
    check (
      resolution is null
      or resolution in ('NO_FOLLOW_UP', 'CONSEQUENCES_CREATED')
    ),
  add constraint messages_processing_state_check
    check (
      (
        status = 'TO_PROCESS'
        and processed_at is null
        and processed_by is null
        and resolution is null
      )
      or
      (
        status = 'PROCESSED'
        and processed_at is not null
        and processed_by is not null
        and resolution in ('NO_FOLLOW_UP', 'CONSEQUENCES_CREATED')
      )
    );

create or replace function private.boralog_guard_message_provenance()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid;
begin
  if new.id is distinct from old.id
     or new.organization_id is distinct from old.organization_id
     or new.created_by is distinct from old.created_by
     or new.created_at is distinct from old.created_at
     or new.content is distinct from old.content
     or new.origin_type is distinct from old.origin_type
     or new.author_user_id is distinct from old.author_user_id
     or new.external_author_label is distinct from old.external_author_label
     or new.source_kind is distinct from old.source_kind
     or new.source_occurred_at is distinct from old.source_occurred_at then
    raise exception 'immutable message identity/provenance'
      using errcode = '23514';
  end if;

  if old.status = 'PROCESSED' then
    if new.status is distinct from old.status then
      raise exception 'processed message cannot be reopened'
        using errcode = '23514';
    end if;

    if new.project_id is distinct from old.project_id
       or new.event_id is distinct from old.event_id then
      raise exception 'processed message context is immutable'
        using errcode = '23514';
    end if;

    if new.processed_at is distinct from old.processed_at
       or new.processed_by is distinct from old.processed_by
       or new.resolution is distinct from old.resolution then
      raise exception 'processed message metadata is immutable'
        using errcode = '23514';
    end if;

    return new;
  end if;

  if new.status = 'TO_PROCESS' then
    if new.processed_at is not null
       or new.processed_by is not null
       or new.resolution is not null then
      raise exception 'processing metadata requires a valid closing transition'
        using errcode = '23514';
    end if;

    return new;
  end if;

  if new.status = 'PROCESSED' then
    if new.resolution not in ('NO_FOLLOW_UP', 'CONSEQUENCES_CREATED') then
      raise exception 'invalid message resolution'
        using errcode = '23514';
    end if;

    if new.processed_at is not null
       or new.processed_by is not null then
      raise exception 'processing metadata is database-generated'
        using errcode = '23514';
    end if;

    if new.resolution = 'CONSEQUENCES_CREATED'
       and not exists (
         select 1
         from public.information_message_sources as source
         where source.message_id = new.id
       )
       and not exists (
         select 1
         from public.task_message_sources as source
         where source.message_id = new.id
       ) then
      raise exception 'processed message consequences require a source link'
        using errcode = '23514';
    end if;

    v_actor := auth.uid();
    if v_actor is null then
      raise exception 'authenticated actor required to process message'
        using errcode = '42501';
    end if;

    new.processed_at := now();
    new.processed_by := v_actor;

    return new;
  end if;

  raise exception 'invalid message status transition'
    using errcode = '23514';
end
$$;

alter function private.boralog_guard_message_provenance() owner to postgres;
revoke all on function private.boralog_guard_message_provenance()
  from public, anon, authenticated, service_role;

create or replace function private.boralog_validate_new_message_processing_state()
returns trigger
language plpgsql
security definer
set search_path = ''
as $
begin
  if new.status <> 'TO_PROCESS'
     or new.processed_at is not null
     or new.processed_by is not null
     or new.resolution is not null then
    raise exception 'new message must start TO_PROCESS without processing metadata'
      using errcode = '23514';
  end if;

  return new;
end
$;

alter function private.boralog_validate_new_message_processing_state() owner to postgres;
revoke all on function private.boralog_validate_new_message_processing_state()
  from public, anon, authenticated, service_role;

create trigger boralog_new_message_processing_state
before insert
on public.messages
for each row
execute function private.boralog_validate_new_message_processing_state();

create or replace function private.boralog_assert_processed_message_has_consequence()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_message_id uuid;
  v_status text;
  v_resolution text;
begin
  if tg_table_name = 'messages' then
    v_message_id := new.id;
  else
    v_message_id := old.message_id;
  end if;

  select message.status, message.resolution
    into v_status, v_resolution
  from public.messages as message
  where message.id = v_message_id;

  if not found then
    return coalesce(new, old);
  end if;

  if v_status = 'PROCESSED'
     and v_resolution = 'CONSEQUENCES_CREATED'
     and not exists (
       select 1
       from public.information_message_sources as source
       where source.message_id = v_message_id
     )
     and not exists (
       select 1
       from public.task_message_sources as source
       where source.message_id = v_message_id
     ) then
    raise exception 'processed message consequences require at least one source link'
      using errcode = '23514';
  end if;

  return coalesce(new, old);
end
$$;

alter function private.boralog_assert_processed_message_has_consequence() owner to postgres;
revoke all on function private.boralog_assert_processed_message_has_consequence()
  from public, anon, authenticated, service_role;

create constraint trigger boralog_information_source_delete_guard
after delete or update
on public.information_message_sources
deferrable initially deferred
for each row
execute function private.boralog_assert_processed_message_has_consequence();

create constraint trigger boralog_task_source_delete_guard
after delete or update
on public.task_message_sources
deferrable initially deferred
for each row
execute function private.boralog_assert_processed_message_has_consequence();

create or replace function public.boralog_process_message(
  p_message_id uuid,
  p_resolution text,
  p_information_contents text[] default '{}'::text[],
  p_task_contents text[] default '{}'::text[]
)
returns public.messages
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid;
  v_message public.messages%rowtype;
  v_information_contents text[] := coalesce(p_information_contents, '{}'::text[]);
  v_task_contents text[] := coalesce(p_task_contents, '{}'::text[]);
  v_information_count integer := coalesce(cardinality(v_information_contents), 0);
  v_task_count integer := coalesce(cardinality(v_task_contents), 0);
  v_content text;
begin
  v_actor := auth.uid();
  if v_actor is null then
    raise exception 'authenticated actor required to process message'
      using errcode = '42501';
  end if;

  select *
    into v_message
  from public.messages
  where id = p_message_id
  for update;

  if v_message.id is null then
    raise exception 'message not accessible'
      using errcode = '42501';
  end if;

  if not private.boralog_message_access_allowed(
    v_message.id,
    v_message.organization_id,
    v_message.project_id,
    v_message.event_id,
    v_message.visibility,
    v_message.created_by,
    v_message.author_user_id
  ) then
    raise exception 'message not accessible'
      using errcode = '42501';
  end if;

  if v_message.status <> 'TO_PROCESS' then
    raise exception 'message is already processed'
      using errcode = '23514';
  end if;

  if p_resolution not in ('NO_FOLLOW_UP', 'CONSEQUENCES_CREATED') then
    raise exception 'invalid processing resolution'
      using errcode = '23514';
  end if;

  foreach v_content in array v_information_contents loop
    if nullif(btrim(v_content), '') is null then
      raise exception 'information consequence content is required'
        using errcode = '23514';
    end if;
  end loop;

  foreach v_content in array v_task_contents loop
    if nullif(btrim(v_content), '') is null then
      raise exception 'task consequence content is required'
        using errcode = '23514';
    end if;
  end loop;

  if p_resolution = 'NO_FOLLOW_UP' then
    if v_information_count <> 0 or v_task_count <> 0 then
      raise exception 'no follow up cannot include consequences'
        using errcode = '23514';
    end if;
  else
    if v_information_count + v_task_count = 0 then
      raise exception 'consequences resolution requires at least one consequence'
        using errcode = '23514';
    end if;
  end if;

  if p_resolution = 'CONSEQUENCES_CREATED' then
    foreach v_content in array v_information_contents loop
      if v_message.event_id is not null then
        perform public.boralog_create_information(
          v_message.organization_id,
          btrim(v_content),
          null,
          v_message.event_id,
          array[v_message.id]
        );
      elsif v_message.project_id is not null then
        perform public.boralog_create_information(
          v_message.organization_id,
          btrim(v_content),
          v_message.project_id,
          null,
          array[v_message.id]
        );
      else
        perform public.boralog_create_information(
          v_message.organization_id,
          btrim(v_content),
          null,
          null,
          array[v_message.id]
        );
      end if;
    end loop;

    foreach v_content in array v_task_contents loop
      if v_message.event_id is not null then
        perform public.boralog_create_task(
          v_message.organization_id,
          btrim(v_content),
          null,
          v_message.event_id,
          array[v_message.id]
        );
      elsif v_message.project_id is not null then
        perform public.boralog_create_task(
          v_message.organization_id,
          btrim(v_content),
          v_message.project_id,
          null,
          array[v_message.id]
        );
      else
        perform public.boralog_create_task(
          v_message.organization_id,
          btrim(v_content),
          null,
          null,
          array[v_message.id]
        );
      end if;
    end loop;
  end if;

  update public.messages
     set status = 'PROCESSED',
         resolution = p_resolution
   where id = v_message.id
     and status = 'TO_PROCESS'
  returning * into v_message;

  if v_message.id is null then
    raise exception 'message processing transition failed'
      using errcode = '23514';
  end if;

  return v_message;
end
$$;

alter function public.boralog_process_message(uuid, text, text[], text[]) owner to postgres;
revoke all on function public.boralog_process_message(uuid, text, text[], text[])
  from public, anon, service_role;
grant execute on function public.boralog_process_message(uuid, text, text[], text[])
  to authenticated;

create or replace function public.boralog_close_message_no_follow_up(p_message_id uuid)
returns public.messages
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_message public.messages%rowtype;
begin
  select processed.*
    into v_message
  from public.boralog_process_message(
    p_message_id,
    'NO_FOLLOW_UP',
    '{}'::text[],
    '{}'::text[]
  ) as processed;

  return v_message;
end
$$;

revoke all on function public.boralog_close_message_no_follow_up(uuid)
  from public, anon, service_role;
grant execute on function public.boralog_close_message_no_follow_up(uuid)
  to authenticated;
