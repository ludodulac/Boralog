-- BORALOG-163: canonical durable Information + explicit Message provenance.
-- No UI, no Message processing transition, no automatic content copy.

create table public.informations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid references public.projects(id) on delete cascade,
  event_id uuid references public.events(id) on delete cascade,
  content text not null,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  constraint informations_content_nonempty_check
    check (nullif(btrim(content), '') is not null),
  constraint informations_event_requires_project_check
    check (event_id is null or project_id is not null)
);

create index informations_organization_created_idx
  on public.informations(organization_id, created_at desc);

create index informations_project_created_idx
  on public.informations(project_id, created_at desc)
  where project_id is not null;

create index informations_event_created_idx
  on public.informations(event_id, created_at desc)
  where event_id is not null;

create table public.information_message_sources (
  information_id uuid not null references public.informations(id) on delete cascade,
  message_id uuid not null references public.messages(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (information_id, message_id)
);

create index information_message_sources_message_idx
  on public.information_message_sources(message_id, information_id);

create or replace function private.boralog_information_context_consistency()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_project_organization_id uuid;
  v_event_project_id uuid;
begin
  if new.project_id is null and new.event_id is not null then
    raise exception 'information date requires its project'
      using errcode = '23514';
  end if;

  if new.project_id is not null then
    select p.organization_id
      into v_project_organization_id
    from public.projects as p
    where p.id = new.project_id;

    if v_project_organization_id is null
       or v_project_organization_id <> new.organization_id then
      raise exception 'information project must belong to information organization'
        using errcode = '23514';
    end if;
  end if;

  if new.event_id is not null then
    select e.project_id
      into v_event_project_id
    from public.events as e
    where e.id = new.event_id;

    if v_event_project_id is null
       or v_event_project_id <> new.project_id then
      raise exception 'information date must belong to information project'
        using errcode = '23514';
    end if;
  end if;

  return new;
end
$$;

alter function private.boralog_information_context_consistency() owner to postgres;
revoke all on function private.boralog_information_context_consistency()
  from public, anon, authenticated, service_role;

create trigger boralog_information_context_consistency
before insert or update of organization_id, project_id, event_id
on public.informations
for each row
execute function private.boralog_information_context_consistency();

create or replace function private.boralog_information_source_consistency()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_information_organization_id uuid;
  v_message_organization_id uuid;
begin
  select i.organization_id
    into v_information_organization_id
  from public.informations as i
  where i.id = new.information_id;

  select m.organization_id
    into v_message_organization_id
  from public.messages as m
  where m.id = new.message_id;

  if v_information_organization_id is null
     or v_message_organization_id is null
     or v_information_organization_id <> v_message_organization_id then
    raise exception 'information and source message must belong to same organization'
      using errcode = '23514';
  end if;

  return new;
end
$$;

alter function private.boralog_information_source_consistency() owner to postgres;
revoke all on function private.boralog_information_source_consistency()
  from public, anon, authenticated, service_role;

create trigger boralog_information_source_consistency
before insert or update of information_id, message_id
on public.information_message_sources
for each row
execute function private.boralog_information_source_consistency();

create or replace function private.boralog_information_access_allowed(
  p_organization_id uuid,
  p_project_id uuid
)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid;
  v_access public.organization_access_level;
begin
  v_actor := auth.uid();
  if v_actor is null then
    return false;
  end if;

  select m.access_level
    into v_access
  from public.organization_memberships as m
  where m.organization_id = p_organization_id
    and m.user_id = v_actor
    and m.status = 'active'::public.membership_status
  limit 1;

  if v_access in (
    'owner'::public.organization_access_level,
    'full'::public.organization_access_level
  ) then
    return true;
  end if;

  if v_access = 'limited'::public.organization_access_level
     and p_project_id is not null then
    return private.boralog_can_access_project(p_project_id);
  end if;

  return false;
end
$$;

alter function private.boralog_information_access_allowed(uuid, uuid) owner to postgres;
revoke all on function private.boralog_information_access_allowed(uuid, uuid)
  from public, anon, service_role;
grant execute on function private.boralog_information_access_allowed(uuid, uuid)
  to authenticated;

alter table public.informations enable row level security;
alter table public.information_message_sources enable row level security;

create policy "information accessible select"
on public.informations
for select
to authenticated
using (
  private.boralog_information_access_allowed(organization_id, project_id)
);

create policy "information source visible only with both objects"
on public.information_message_sources
for select
to authenticated
using (
  exists (
    select 1
    from public.informations as i
    where i.id = information_id
  )
  and exists (
    select 1
    from public.messages as m
    where m.id = message_id
  )
);

revoke all on table public.informations from anon, authenticated;
revoke all on table public.information_message_sources from anon, authenticated;

grant select on table public.informations to authenticated;
grant select on table public.information_message_sources to authenticated;

create or replace function public.boralog_create_information(
  p_organization_id uuid,
  p_content text,
  p_project_id uuid default null,
  p_event_id uuid default null,
  p_source_message_ids uuid[] default '{}'::uuid[]
)
returns public.informations
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid;
  v_access public.organization_access_level;
  v_context_project_id uuid := null;
  v_context_event_id uuid := null;
  v_context_organization_id uuid := null;
  v_source_ids uuid[] := coalesce(p_source_message_ids, '{}'::uuid[]);
  v_source_count integer := 0;
  v_accessible_source_count integer := 0;
  v_information public.informations%rowtype;
begin
  v_actor := auth.uid();
  if v_actor is null then
    raise exception 'authenticated actor required to create information'
      using errcode = '42501';
  end if;

  if nullif(btrim(p_content), '') is null then
    raise exception 'information content is required'
      using errcode = '23514';
  end if;

  select membership.access_level
    into v_access
  from public.organization_memberships as membership
  where membership.organization_id = p_organization_id
    and membership.user_id = v_actor
    and membership.status = 'active'::public.membership_status
  limit 1;

  if v_access is null then
    raise exception 'active organization membership required'
      using errcode = '42501';
  end if;

  if p_project_id is not null and p_event_id is not null then
    raise exception 'information context must be a project or a date, not both'
      using errcode = '23514';
  end if;

  if p_project_id is not null then
    select project.organization_id
      into v_context_organization_id
    from public.projects as project
    where project.id = p_project_id;

    if v_context_organization_id is null
       or v_context_organization_id <> p_organization_id then
      raise exception 'information project must belong to information organization'
        using errcode = '23514';
    end if;

    if not private.boralog_can_access_project(p_project_id) then
      raise exception 'information project is not accessible to actor'
        using errcode = '42501';
    end if;

    v_context_project_id := p_project_id;
  elsif p_event_id is not null then
    select event.project_id, project.organization_id
      into v_context_project_id, v_context_organization_id
    from public.events as event
    join public.projects as project on project.id = event.project_id
    where event.id = p_event_id;

    if v_context_project_id is null
       or v_context_organization_id <> p_organization_id then
      raise exception 'information date must belong to information organization'
        using errcode = '23514';
    end if;

    if not private.boralog_can_access_project(v_context_project_id) then
      raise exception 'information date is not accessible to actor'
        using errcode = '42501';
    end if;

    v_context_event_id := p_event_id;
  elsif v_access = 'limited'::public.organization_access_level then
    raise exception 'limited member cannot create contextless information'
      using errcode = '42501';
  end if;

  if exists (
    select 1
    from unnest(v_source_ids) as supplied(message_id)
    where supplied.message_id is null
  ) then
    raise exception 'source message ids cannot contain null'
      using errcode = '23514';
  end if;

  select count(distinct supplied.message_id)
    into v_source_count
  from unnest(v_source_ids) as supplied(message_id);

  if v_source_count > 0 then
    select count(*)
      into v_accessible_source_count
    from public.messages as message
    where message.id in (
      select distinct supplied.message_id
      from unnest(v_source_ids) as supplied(message_id)
    )
      and message.organization_id = p_organization_id
      and private.boralog_message_access_allowed(
        message.id,
        message.organization_id,
        message.project_id,
        message.event_id,
        message.visibility,
        message.created_by,
        message.author_user_id
      );

    if v_accessible_source_count <> v_source_count then
      raise exception 'all source messages must be accessible in the information organization'
        using errcode = '42501';
    end if;
  end if;

  insert into public.informations(
    organization_id,
    project_id,
    event_id,
    content,
    created_by
  ) values (
    p_organization_id,
    v_context_project_id,
    v_context_event_id,
    btrim(p_content),
    v_actor
  )
  returning * into v_information;

  if v_source_count > 0 then
    insert into public.information_message_sources(
      information_id,
      message_id
    )
    select
      v_information.id,
      supplied.message_id
    from (
      select distinct source.message_id
      from unnest(v_source_ids) as source(message_id)
    ) as supplied;
  end if;

  return v_information;
end
$$;

alter function public.boralog_create_information(
  uuid, text, uuid, uuid, uuid[]
) owner to postgres;

revoke all on function public.boralog_create_information(
  uuid, text, uuid, uuid, uuid[]
) from public, anon, service_role;

grant execute on function public.boralog_create_information(
  uuid, text, uuid, uuid, uuid[]
) to authenticated;
