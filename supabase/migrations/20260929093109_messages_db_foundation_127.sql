-- BORALOG-127: minimal real Messages database foundation.

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid references public.projects(id) on delete set null,
  event_id uuid references public.events(id) on delete set null,
  content text not null check (char_length(btrim(content)) > 0),
  status text not null default 'TO_PROCESS'
    check (status in ('TO_PROCESS', 'PROCESSED')),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create index messages_organization_created_idx
  on public.messages(organization_id, created_at desc);

create index messages_project_idx
  on public.messages(project_id)
  where project_id is not null;

create index messages_event_idx
  on public.messages(event_id)
  where event_id is not null;

create or replace function private.boralog_validate_message_context()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_project_organization_id uuid;
  v_event_project_id uuid;
  v_event_organization_id uuid;
begin
  if new.project_id is not null then
    select p.organization_id
      into v_project_organization_id
    from public.projects as p
    where p.id = new.project_id;

    if v_project_organization_id is null
       or v_project_organization_id <> new.organization_id then
      raise exception 'message project must belong to message organization'
        using errcode = '23514';
    end if;
  end if;

  if new.event_id is not null then
    select e.project_id, p.organization_id
      into v_event_project_id, v_event_organization_id
    from public.events as e
    join public.projects as p on p.id = e.project_id
    where e.id = new.event_id;

    if v_event_project_id is null
       or v_event_organization_id <> new.organization_id then
      raise exception 'message event must belong to message organization'
        using errcode = '23514';
    end if;

    if new.project_id is not null
       and v_event_project_id <> new.project_id then
      raise exception 'message event must belong to message project'
        using errcode = '23514';
    end if;
  end if;

  return new;
end
$$;

alter function private.boralog_validate_message_context() owner to postgres;
revoke all on function private.boralog_validate_message_context()
  from public, anon, authenticated, service_role;

create trigger boralog_message_context_consistency
before insert or update of organization_id, project_id, event_id
on public.messages
for each row
execute function private.boralog_validate_message_context();

create or replace function private.boralog_guard_message_provenance()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.id is distinct from old.id
     or new.organization_id is distinct from old.organization_id
     or new.created_by is distinct from old.created_by
     or new.created_at is distinct from old.created_at then
    raise exception 'immutable message identity/provenance'
      using errcode = '23514';
  end if;

  return new;
end
$$;

alter function private.boralog_guard_message_provenance() owner to postgres;
revoke all on function private.boralog_guard_message_provenance()
  from public, anon, authenticated, service_role;

create trigger boralog_message_provenance_immutable
before update
on public.messages
for each row
execute function private.boralog_guard_message_provenance();

alter table public.messages enable row level security;

revoke all on table public.messages from anon, authenticated;
grant select, insert, update on table public.messages to authenticated;

create policy "message accessible select"
on public.messages
for select
to authenticated
using (
  private.boralog_org_access(organization_id) in (
    'owner'::public.organization_access_level,
    'full'::public.organization_access_level
  )
  or (
    private.boralog_org_access(organization_id) = 'limited'::public.organization_access_level
    and (
      (
        project_id is not null
        and private.boralog_can_access_project(project_id)
      )
      or (
        project_id is null
        and event_id is not null
        and exists (
          select 1
          from public.events as e
          where e.id = messages.event_id
            and private.boralog_can_access_project(e.project_id)
        )
      )
    )
  )
);

create policy "message accessible insert"
on public.messages
for insert
to authenticated
with check (
  created_by = (select auth.uid())
  and (
    private.boralog_org_access(organization_id) in (
      'owner'::public.organization_access_level,
      'full'::public.organization_access_level
    )
    or (
      private.boralog_org_access(organization_id) = 'limited'::public.organization_access_level
      and (
        (
          project_id is not null
          and private.boralog_can_access_project(project_id)
        )
        or (
          project_id is null
          and event_id is not null
          and exists (
            select 1
            from public.events as e
            where e.id = messages.event_id
              and private.boralog_can_access_project(e.project_id)
          )
        )
      )
    )
  )
);

create policy "message accessible update"
on public.messages
for update
to authenticated
using (
  private.boralog_org_access(organization_id) in (
    'owner'::public.organization_access_level,
    'full'::public.organization_access_level
  )
  or (
    private.boralog_org_access(organization_id) = 'limited'::public.organization_access_level
    and (
      (
        project_id is not null
        and private.boralog_can_access_project(project_id)
      )
      or (
        project_id is null
        and event_id is not null
        and exists (
          select 1
          from public.events as e
          where e.id = messages.event_id
            and private.boralog_can_access_project(e.project_id)
        )
      )
    )
  )
)
with check (
  private.boralog_org_access(organization_id) in (
    'owner'::public.organization_access_level,
    'full'::public.organization_access_level
  )
  or (
    private.boralog_org_access(organization_id) = 'limited'::public.organization_access_level
    and (
      (
        project_id is not null
        and private.boralog_can_access_project(project_id)
      )
      or (
        project_id is null
        and event_id is not null
        and exists (
          select 1
          from public.events as e
          where e.id = messages.event_id
            and private.boralog_can_access_project(e.project_id)
        )
      )
    )
  )
);
