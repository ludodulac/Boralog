-- BORALOG-159: recipient groups and snapshot materialization foundation.
-- Groups are data-only in this contract: no authenticated table access yet.

create table public.recipient_groups (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 120),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create index recipient_groups_organization_name_idx
  on public.recipient_groups(organization_id, name);

create table public.recipient_group_members (
  group_id uuid not null references public.recipient_groups(id) on delete cascade,
  user_id uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

create index recipient_group_members_user_group_idx
  on public.recipient_group_members(user_id, group_id);

create or replace function private.boralog_validate_recipient_group()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.created_by is distinct from auth.uid() then
    raise exception 'recipient group creator must match authenticated actor'
      using errcode = '23514';
  end if;

  if not exists (
    select 1
    from public.organization_memberships as m
    where m.organization_id = new.organization_id
      and m.user_id = new.created_by
      and m.status = 'active'::public.membership_status
  ) then
    raise exception 'recipient group creator must be an active organization member'
      using errcode = '23514';
  end if;

  return new;
end
$$;

alter function private.boralog_validate_recipient_group() owner to postgres;
revoke all on function private.boralog_validate_recipient_group()
  from public, anon, authenticated, service_role;

create trigger boralog_recipient_group_coherence
before insert or update of organization_id, created_by
on public.recipient_groups
for each row
execute function private.boralog_validate_recipient_group();

create or replace function private.boralog_validate_recipient_group_member()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_organization_id uuid;
begin
  select g.organization_id
    into v_organization_id
  from public.recipient_groups as g
  where g.id = new.group_id;

  if v_organization_id is null then
    raise exception 'recipient group member requires an existing group'
      using errcode = '23514';
  end if;

  if not exists (
    select 1
    from public.organization_memberships as m
    where m.organization_id = v_organization_id
      and m.user_id = new.user_id
      and m.status = 'active'::public.membership_status
  ) then
    raise exception 'recipient group member must be an active member of the group organization'
      using errcode = '23514';
  end if;

  return new;
end
$$;

alter function private.boralog_validate_recipient_group_member() owner to postgres;
revoke all on function private.boralog_validate_recipient_group_member()
  from public, anon, authenticated, service_role;

create trigger boralog_recipient_group_member_coherence
before insert or update of group_id, user_id
on public.recipient_group_members
for each row
execute function private.boralog_validate_recipient_group_member();

create or replace function private.boralog_materialize_recipient_group(
  p_message_id uuid,
  p_group_id uuid
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_message_organization_id uuid;
  v_group_organization_id uuid;
  v_inserted bigint;
begin
  select m.organization_id
    into v_message_organization_id
  from public.messages as m
  where m.id = p_message_id;

  select g.organization_id
    into v_group_organization_id
  from public.recipient_groups as g
  where g.id = p_group_id;

  if v_message_organization_id is null or v_group_organization_id is null then
    raise exception 'message and recipient group must exist'
      using errcode = '23514';
  end if;

  if v_message_organization_id <> v_group_organization_id then
    raise exception 'recipient group must belong to the message organization'
      using errcode = '23514';
  end if;

  insert into public.message_recipients(message_id, user_id)
  select
    p_message_id,
    gm.user_id
  from public.recipient_group_members as gm
  join public.organization_memberships as membership
    on membership.organization_id = v_message_organization_id
   and membership.user_id = gm.user_id
   and membership.status = 'active'::public.membership_status
  where gm.group_id = p_group_id
  on conflict (message_id, user_id) do nothing;

  get diagnostics v_inserted = row_count;
  return v_inserted;
end
$$;

alter function private.boralog_materialize_recipient_group(uuid, uuid) owner to postgres;
revoke all on function private.boralog_materialize_recipient_group(uuid, uuid)
  from public, anon, authenticated, service_role;

alter table public.recipient_groups enable row level security;
alter table public.recipient_group_members enable row level security;

revoke all on table public.recipient_groups from anon, authenticated;
revoke all on table public.recipient_group_members from anon, authenticated;
