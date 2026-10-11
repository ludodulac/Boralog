-- BORALOG-178B: durable external sender Person link for Messages.
-- Append-only. Preserve BORALOG-165R reversible Message cycle semantics.

alter table public.messages
  add column external_author_person_id uuid null
    references public.people(id);

create index messages_external_author_person_idx
  on public.messages(external_author_person_id)
  where external_author_person_id is not null;

alter table public.messages
  drop constraint messages_author_exclusivity_check,
  drop constraint messages_historical_provenance_null_check,
  drop constraint messages_internal_provenance_check;

alter table public.messages
  add constraint messages_author_exclusivity_check
    check (
      num_nonnulls(
        author_user_id,
        external_author_person_id,
        external_author_label
      ) <= 1
    ),
  add constraint messages_historical_provenance_null_check
    check (
      origin_type is not null
      or (
        author_user_id is null
        and external_author_person_id is null
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
        and external_author_person_id is null
        and external_author_label is null
        and source_kind is null
        and source_occurred_at is null
      )
    );

create or replace function private.boralog_message_external_person_consistency()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_person_organization_id uuid;
begin
  if new.external_author_person_id is null then
    return new;
  end if;

  select person.organization_id
    into v_person_organization_id
  from public.people as person
  where person.id = new.external_author_person_id;

  if v_person_organization_id is null
     or v_person_organization_id <> new.organization_id then
    raise exception 'message external author person must belong to message organization'
      using errcode = '23514';
  end if;

  return new;
end
$$;

alter function private.boralog_message_external_person_consistency() owner to postgres;
revoke all on function private.boralog_message_external_person_consistency()
  from public, anon, authenticated, service_role;

create trigger boralog_message_external_person_consistency
before insert or update of organization_id, external_author_person_id
on public.messages
for each row
execute function private.boralog_message_external_person_consistency();

-- Canonical BORALOG-165R guard, extended only with external_author_person_id immutability.
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
     or new.external_author_person_id is distinct from old.external_author_person_id
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
