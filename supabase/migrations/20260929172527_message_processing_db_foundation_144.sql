-- BORALOG-144: traceable and safe Message processing foundation.

alter table public.messages
  add column processed_at timestamptz null,
  add column processed_by uuid null references auth.users(id),
  add column resolution text null;

alter table public.messages
  add constraint messages_resolution_check
    check (resolution is null or resolution = 'NO_FOLLOW_UP'),
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
        and resolution = 'NO_FOLLOW_UP'
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
     or new.content is distinct from old.content then
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

create or replace function public.boralog_close_message_no_follow_up(p_message_id uuid)
returns public.messages
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_message public.messages;
begin
  update public.messages
     set status = 'PROCESSED',
         resolution = 'NO_FOLLOW_UP'
   where id = p_message_id
     and status = 'TO_PROCESS'
  returning * into v_message;

  if v_message.id is null then
    raise exception 'message not found or not processable'
      using errcode = 'P0002';
  end if;

  return v_message;
end
$$;

revoke all on function public.boralog_close_message_no_follow_up(uuid)
  from public, anon, service_role;
grant execute on function public.boralog_close_message_no_follow_up(uuid)
  to authenticated;
