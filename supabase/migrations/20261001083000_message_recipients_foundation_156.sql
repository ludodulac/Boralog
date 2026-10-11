-- BORALOG-156: canonical individual Message recipients.
-- This migration adds recipient data only. It does not change Message visibility/RLS.

create table public.message_recipients (
  message_id uuid not null references public.messages(id) on delete cascade,
  user_id uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  primary key (message_id, user_id)
);

create index message_recipients_user_message_idx
  on public.message_recipients(user_id, message_id);

create or replace function private.boralog_validate_message_recipient()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_organization_id uuid;
begin
  select m.organization_id
    into v_organization_id
  from public.messages as m
  where m.id = new.message_id;

  if v_organization_id is null then
    raise exception 'message recipient requires an existing message'
      using errcode = '23514';
  end if;

  if not exists (
    select 1
    from public.organization_memberships as membership
    where membership.organization_id = v_organization_id
      and membership.user_id = new.user_id
      and membership.status = 'active'::public.membership_status
  ) then
    raise exception 'message recipient must be an active member of the message organization'
      using errcode = '23514';
  end if;

  return new;
end
$$;

alter function private.boralog_validate_message_recipient() owner to postgres;
revoke all on function private.boralog_validate_message_recipient()
  from public, anon, authenticated, service_role;

create trigger boralog_message_recipient_coherence
before insert or update of message_id, user_id
on public.message_recipients
for each row
execute function private.boralog_validate_message_recipient();

alter table public.message_recipients enable row level security;

-- BORALOG-156 deliberately exposes no client access yet.
-- Message visibility and recipient-based RLS belong to the next contract.
revoke all on table public.message_recipients from anon, authenticated;
