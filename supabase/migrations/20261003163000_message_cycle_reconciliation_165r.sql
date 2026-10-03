-- BORALOG-165R: canonical reversible Message cycle, Notes and minimal status history.
-- Append-only supersession of 20261002052307_message_processing_flow_165.

alter table public.messages
  drop constraint messages_processing_state_check;

alter table public.messages
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
        and (
          resolution is null
          or resolution in ('NO_FOLLOW_UP', 'CONSEQUENCES_CREATED')
        )
      )
    );

create table public.message_status_history (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  from_status text not null,
  to_status text not null,
  changed_by uuid not null references auth.users(id),
  changed_at timestamptz not null default now(),
  constraint message_status_history_from_status_check
    check (from_status in ('TO_PROCESS', 'PROCESSED')),
  constraint message_status_history_to_status_check
    check (to_status in ('TO_PROCESS', 'PROCESSED')),
  constraint message_status_history_transition_check
    check (from_status <> to_status)
);

create index message_status_history_message_changed_idx
  on public.message_status_history(message_id, changed_at, id);

alter table public.message_status_history enable row level security;

create policy "message status history follows message visibility"
on public.message_status_history
for select
to authenticated
using (
  exists (
    select 1
    from public.messages as message
    where message.id = message_id
  )
);

revoke all on table public.message_status_history
  from public, anon, authenticated, service_role;
grant select on table public.message_status_history to authenticated;

create table public.message_notes (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  content text not null,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  constraint message_notes_content_nonempty
    check (nullif(btrim(content), '') is not null)
);

create index message_notes_message_created_idx
  on public.message_notes(message_id, created_at, id);

alter table public.message_notes enable row level security;

create policy "message notes follow message visibility"
on public.message_notes
for select
to authenticated
using (
  exists (
    select 1
    from public.messages as message
    where message.id = message_id
  )
);

revoke all on table public.message_notes
  from public, anon, authenticated, service_role;
grant select on table public.message_notes to authenticated;

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

  if new.status is not distinct from old.status then
    if old.status = 'PROCESSED'
       and (
         new.project_id is distinct from old.project_id
         or new.event_id is distinct from old.event_id
       ) then
      raise exception 'processed message context is immutable'
        using errcode = '23514';
    end if;

    if new.processed_at is distinct from old.processed_at
       or new.processed_by is distinct from old.processed_by
       or new.resolution is distinct from old.resolution then
      raise exception 'message processing metadata changes only with status'
        using errcode = '23514';
    end if;

    if new.status = 'TO_PROCESS'
       and (
         new.processed_at is not null
         or new.processed_by is not null
         or new.resolution is not null
       ) then
      raise exception 'to-process message cannot carry processing metadata'
        using errcode = '23514';
    end if;

    return new;
  end if;

  if new.status not in ('TO_PROCESS', 'PROCESSED') then
    raise exception 'invalid message status transition'
      using errcode = '23514';
  end if;

  if new.project_id is distinct from old.project_id
     or new.event_id is distinct from old.event_id
     or new.visibility is distinct from old.visibility then
    raise exception 'status transition cannot change message context or audience'
      using errcode = '23514';
  end if;

  v_actor := auth.uid();
  if v_actor is null then
    raise exception 'authenticated actor required to change message status'
      using errcode = '42501';
  end if;

  if new.status = 'PROCESSED' then
    if new.processed_at is not null
       or new.processed_by is not null then
      raise exception 'processing metadata is database-generated'
        using errcode = '23514';
    end if;

    if new.resolution is not null
       and new.resolution not in ('NO_FOLLOW_UP', 'CONSEQUENCES_CREATED') then
      raise exception 'invalid message resolution'
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

    new.processed_at := now();
    new.processed_by := v_actor;
    return new;
  end if;

  new.processed_at := null;
  new.processed_by := null;
  new.resolution := null;
  return new;
end
$$;

alter function private.boralog_guard_message_provenance() owner to postgres;
revoke all on function private.boralog_guard_message_provenance()
  from public, anon, authenticated, service_role;

create or replace function private.boralog_record_message_status_transition()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid;
begin
  if new.status is not distinct from old.status then
    return new;
  end if;

  v_actor := auth.uid();
  if v_actor is null then
    raise exception 'authenticated actor required to record message status'
      using errcode = '42501';
  end if;

  insert into public.message_status_history(
    message_id,
    from_status,
    to_status,
    changed_by,
    changed_at
  ) values (
    new.id,
    old.status,
    new.status,
    v_actor,
    now()
  );

  return new;
end
$$;

alter function private.boralog_record_message_status_transition() owner to postgres;
revoke all on function private.boralog_record_message_status_transition()
  from public, anon, authenticated, service_role;

create trigger boralog_message_status_history
after update of status
on public.messages
for each row
when (old.status is distinct from new.status)
execute function private.boralog_record_message_status_transition();

-- Preserve a minimal trace for Messages already closed by historical 144/165 flows.
insert into public.message_status_history(
  message_id,
  from_status,
  to_status,
  changed_by,
  changed_at
)
select
  message.id,
  'TO_PROCESS',
  'PROCESSED',
  message.processed_by,
  message.processed_at
from public.messages as message
where message.status = 'PROCESSED'
  and message.processed_by is not null
  and message.processed_at is not null
  and not exists (
    select 1
    from public.message_status_history as history
    where history.message_id = message.id
  );

create or replace function public.boralog_add_message_note(
  p_message_id uuid,
  p_content text
)
returns public.message_notes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid;
  v_message public.messages%rowtype;
  v_note public.message_notes%rowtype;
begin
  v_actor := auth.uid();
  if v_actor is null then
    raise exception 'authenticated actor required to add message note'
      using errcode = '42501';
  end if;

  if nullif(btrim(p_content), '') is null then
    raise exception 'message note content is required'
      using errcode = '23514';
  end if;

  select *
    into v_message
  from public.messages
  where id = p_message_id;

  if v_message.id is null
     or not private.boralog_message_access_allowed(
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

  insert into public.message_notes(
    message_id,
    content,
    created_by
  ) values (
    v_message.id,
    btrim(p_content),
    v_actor
  )
  returning * into v_note;

  return v_note;
end
$$;

alter function public.boralog_add_message_note(uuid, text) owner to postgres;
revoke all on function public.boralog_add_message_note(uuid, text)
  from public, anon, authenticated, service_role;
grant execute on function public.boralog_add_message_note(uuid, text)
  to authenticated;

create or replace function public.boralog_set_message_status(
  p_message_id uuid,
  p_status text
)
returns public.messages
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid;
  v_message public.messages%rowtype;
begin
  v_actor := auth.uid();
  if v_actor is null then
    raise exception 'authenticated actor required to change message status'
      using errcode = '42501';
  end if;

  if p_status not in ('TO_PROCESS', 'PROCESSED') then
    raise exception 'invalid message status'
      using errcode = '23514';
  end if;

  select *
    into v_message
  from public.messages
  where id = p_message_id
  for update;

  if v_message.id is null
     or not private.boralog_message_access_allowed(
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

  if v_message.status = p_status then
    return v_message;
  end if;

  update public.messages
     set status = p_status,
         resolution = null
   where id = v_message.id
  returning * into v_message;

  return v_message;
end
$$;

alter function public.boralog_set_message_status(uuid, text) owner to postgres;
revoke all on function public.boralog_set_message_status(uuid, text)
  from public, anon, authenticated, service_role;
grant execute on function public.boralog_set_message_status(uuid, text)
  to authenticated;
