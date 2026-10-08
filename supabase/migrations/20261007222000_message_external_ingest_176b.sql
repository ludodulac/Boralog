-- BORALOG-176B: signed external Message ingestion foundation for Twilio WhatsApp.
-- Local/versioned only in this mission. No remote apply.

alter table public.messages
  alter column created_by drop not null;

alter table public.messages
  add column source_external_id text null;

alter table public.messages
  add constraint messages_source_external_id_nonempty_check
    check (
      source_external_id is null
      or nullif(btrim(source_external_id), '') is not null
    );

create unique index messages_external_source_unique_idx
  on public.messages(organization_id, source_kind, source_external_id)
  where source_external_id is not null;

create or replace function private.boralog_validate_message_provenance_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid;
  v_external_ingest_enabled boolean :=
    coalesce(current_setting('boralog.external_ingest', true), '') = 'on';
begin
  if new.origin_type is null then
    raise exception 'new message origin_type is required'
      using errcode = '23514';
  end if;

  v_actor := auth.uid();

  if new.origin_type = 'EXTERNAL_IMPORTED' then
    if not v_external_ingest_enabled then
      raise exception 'external imported message requires dedicated ingestion path'
        using errcode = '42501';
    end if;

    if v_actor is not null
       or new.created_by is not null
       or new.author_user_id is not null then
      raise exception 'external imported message cannot impersonate a Boralog actor'
        using errcode = '23514';
    end if;

    if nullif(btrim(new.external_author_label), '') is null
       or new.source_kind is null
       or nullif(btrim(new.source_external_id), '') is null
       or new.source_occurred_at is null then
      raise exception 'external imported message requires complete source provenance'
        using errcode = '23514';
    end if;

    return new;
  end if;

  if v_actor is null then
    raise exception 'authenticated actor required to create message'
      using errcode = '42501';
  end if;

  if new.created_by is distinct from v_actor then
    raise exception 'message created_by must match authenticated actor'
      using errcode = '23514';
  end if;

  if new.source_external_id is not null then
    raise exception 'human-created message cannot set external source id'
      using errcode = '23514';
  end if;

  if new.origin_type = 'INTERNAL' then
    if new.author_user_id is distinct from v_actor then
      raise exception 'internal message author must match authenticated actor'
        using errcode = '23514';
    end if;
  elsif new.origin_type = 'EXTERNAL_MANUAL' then
    if new.author_user_id is not null
       and not exists (
         select 1
         from public.organization_memberships as m
         where m.organization_id = new.organization_id
           and m.user_id = new.author_user_id
           and m.status = 'active'::public.membership_status
       ) then
      raise exception 'external message Boralog author must be an active organization member'
        using errcode = '23514';
    end if;
  else
    raise exception 'invalid message origin_type'
      using errcode = '23514';
  end if;

  return new;
end
$$;

alter function private.boralog_validate_message_provenance_insert() owner to postgres;
revoke all on function private.boralog_validate_message_provenance_insert()
  from public, anon, authenticated, service_role;

-- Preserve BORALOG-165R exactly, adding only source_external_id immutability.
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
     or new.source_occurred_at is distinct from old.source_occurred_at
     or new.source_external_id is distinct from old.source_external_id then
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
       ) then
      raise exception 'to-process message cannot carry active processing metadata'
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
  -- resolution is legacy 144/165 history: reopening must not erase it.
  new.resolution := old.resolution;
  return new;
end
$$;

alter function private.boralog_guard_message_provenance() owner to postgres;
revoke all on function private.boralog_guard_message_provenance()
  from public, anon, authenticated, service_role;

create or replace function public.boralog_ingest_external_message(
  p_organization_id uuid,
  p_content text,
  p_external_author_label text,
  p_source_kind text,
  p_source_external_id text,
  p_source_occurred_at timestamptz
)
returns public.messages
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_message public.messages%rowtype;
begin
  if not exists (
    select 1 from public.organizations as organization
    where organization.id = p_organization_id
  ) then
    raise exception 'organization not found'
      using errcode = '23503';
  end if;

  if nullif(btrim(p_content), '') is null then
    raise exception 'message content is required'
      using errcode = '23514';
  end if;

  if nullif(btrim(p_external_author_label), '') is null then
    raise exception 'external author label is required'
      using errcode = '23514';
  end if;

  if p_source_kind is null
     or p_source_kind not in ('WHATSAPP', 'EMAIL', 'SMS', 'PHONE', 'OTHER') then
    raise exception 'invalid external source kind'
      using errcode = '23514';
  end if;

  if nullif(btrim(p_source_external_id), '') is null then
    raise exception 'external source id is required'
      using errcode = '23514';
  end if;

  perform set_config('boralog.external_ingest', 'on', true);

  insert into public.messages(
    organization_id,
    project_id,
    event_id,
    content,
    status,
    created_by,
    origin_type,
    author_user_id,
    external_author_label,
    source_kind,
    source_occurred_at,
    source_external_id,
    visibility
  ) values (
    p_organization_id,
    null,
    null,
    btrim(p_content),
    'TO_PROCESS',
    null,
    'EXTERNAL_IMPORTED',
    null,
    btrim(p_external_author_label),
    p_source_kind,
    coalesce(p_source_occurred_at, now()),
    btrim(p_source_external_id),
    'ORGANIZATION'
  )
  on conflict (organization_id, source_kind, source_external_id)
    where source_external_id is not null
  do nothing
  returning * into v_message;

  if v_message.id is null then
    select *
      into v_message
    from public.messages
    where organization_id = p_organization_id
      and source_kind = p_source_kind
      and source_external_id = btrim(p_source_external_id);
  end if;

  return v_message;
end
$$;

alter function public.boralog_ingest_external_message(
  uuid, text, text, text, text, timestamptz
) owner to postgres;

revoke all on function public.boralog_ingest_external_message(
  uuid, text, text, text, text, timestamptz
) from public, anon, authenticated;

grant execute on function public.boralog_ingest_external_message(
  uuid, text, text, text, text, timestamptz
) to service_role;
