-- BORALOG-155B: Message communication provenance foundation.
-- Local migration only in this mission. Historical rows remain unclassified.

alter table public.messages
  add column origin_type text null,
  add column author_user_id uuid null references auth.users(id),
  add column external_author_label text null,
  add column source_kind text null,
  add column source_occurred_at timestamptz null;

alter table public.messages
  add constraint messages_origin_type_check
    check (
      origin_type is null
      or origin_type in ('INTERNAL', 'EXTERNAL_IMPORTED', 'EXTERNAL_MANUAL')
    ),
  add constraint messages_source_kind_check
    check (
      source_kind is null
      or source_kind in ('WHATSAPP', 'EMAIL', 'SMS', 'PHONE', 'OTHER')
    ),
  add constraint messages_author_exclusivity_check
    check (
      author_user_id is null
      or external_author_label is null
    ),
  add constraint messages_historical_provenance_null_check
    check (
      origin_type is not null
      or (
        author_user_id is null
        and external_author_label is null
        and source_kind is null
        and source_occurred_at is null
      )
    ),
  add constraint messages_internal_provenance_check
    check (
      origin_type is distinct from 'INTERNAL'
      or (
        author_user_id is not null
        and author_user_id = created_by
        and external_author_label is null
        and source_kind is null
        and source_occurred_at is null
      )
    );

create or replace function private.boralog_validate_message_provenance_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid;
begin
  if new.origin_type is null then
    raise exception 'new message origin_type is required'
      using errcode = '23514';
  end if;

  v_actor := auth.uid();
  if v_actor is null then
    raise exception 'authenticated actor required to create message'
      using errcode = '42501';
  end if;

  if new.created_by is distinct from v_actor then
    raise exception 'message created_by must match authenticated actor'
      using errcode = '23514';
  end if;

  if new.origin_type = 'INTERNAL' then
    if new.author_user_id is distinct from v_actor then
      raise exception 'internal message author must match authenticated actor'
        using errcode = '23514';
    end if;
  elsif new.origin_type in ('EXTERNAL_IMPORTED', 'EXTERNAL_MANUAL') then
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

create trigger boralog_message_provenance_insert
before insert
on public.messages
for each row
execute function private.boralog_validate_message_provenance_insert();

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
    if new.resolution is distinct from 'NO_FOLLOW_UP' then
      raise exception 'only NO_FOLLOW_UP closing is currently supported'
        using errcode = '23514';
    end if;

    if new.processed_at is not null
       or new.processed_by is not null then
      raise exception 'processing metadata is database-generated'
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
