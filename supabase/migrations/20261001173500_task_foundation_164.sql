-- BORALOG-164: canonical Task + explicit Message provenance. No UI.

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid references public.projects(id) on delete cascade,
  event_id uuid references public.events(id) on delete cascade,
  content text not null,
  status text not null default 'TO_DO',
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  completed_by uuid references auth.users(id),
  constraint tasks_content_nonempty_check check (nullif(btrim(content), '') is not null),
  constraint tasks_status_check check (status in ('TO_DO','DONE')),
  constraint tasks_event_requires_project_check check (event_id is null or project_id is not null),
  constraint tasks_completion_metadata_check check (
    (status='TO_DO' and completed_at is null and completed_by is null)
    or
    (status='DONE' and completed_at is not null and completed_by is not null)
  )
);

create index tasks_organization_created_idx on public.tasks(organization_id, created_at desc);
create index tasks_project_created_idx on public.tasks(project_id, created_at desc) where project_id is not null;
create index tasks_event_created_idx on public.tasks(event_id, created_at desc) where event_id is not null;

create table public.task_message_sources (
  task_id uuid not null references public.tasks(id) on delete cascade,
  message_id uuid not null references public.messages(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (task_id, message_id)
);

create index task_message_sources_message_idx on public.task_message_sources(message_id, task_id);

create or replace function private.boralog_task_context_consistency()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_project_org uuid;
  v_event_project uuid;
begin
  if new.project_id is null and new.event_id is not null then
    raise exception 'task date requires its project' using errcode='23514';
  end if;

  if new.project_id is not null then
    select p.organization_id into v_project_org
    from public.projects p where p.id=new.project_id;

    if v_project_org is null or v_project_org <> new.organization_id then
      raise exception 'task project must belong to task organization' using errcode='23514';
    end if;
  end if;

  if new.event_id is not null then
    select e.project_id into v_event_project
    from public.events e where e.id=new.event_id;

    if v_event_project is null or v_event_project <> new.project_id then
      raise exception 'task date must belong to task project' using errcode='23514';
    end if;
  end if;

  return new;
end
$$;

alter function private.boralog_task_context_consistency() owner to postgres;
revoke all on function private.boralog_task_context_consistency() from public, anon, authenticated, service_role;

create trigger boralog_task_context_consistency
before insert or update of organization_id, project_id, event_id
on public.tasks
for each row execute function private.boralog_task_context_consistency();

create or replace function private.boralog_task_source_consistency()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_task_org uuid;
  v_message_org uuid;
begin
  select t.organization_id into v_task_org from public.tasks t where t.id=new.task_id;
  select m.organization_id into v_message_org from public.messages m where m.id=new.message_id;

  if v_task_org is null or v_message_org is null or v_task_org <> v_message_org then
    raise exception 'task and source message must belong to same organization' using errcode='23514';
  end if;

  return new;
end
$$;

alter function private.boralog_task_source_consistency() owner to postgres;
revoke all on function private.boralog_task_source_consistency() from public, anon, authenticated, service_role;

create trigger boralog_task_source_consistency
before insert or update of task_id, message_id
on public.task_message_sources
for each row execute function private.boralog_task_source_consistency();

create or replace function private.boralog_task_access_allowed(
  p_organization_id uuid,
  p_project_id uuid
)
returns boolean
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_actor uuid;
  v_access public.organization_access_level;
begin
  v_actor := auth.uid();
  if v_actor is null then return false; end if;

  select m.access_level into v_access
  from public.organization_memberships m
  where m.organization_id=p_organization_id
    and m.user_id=v_actor
    and m.status='active'::public.membership_status
  limit 1;

  if v_access in ('owner'::public.organization_access_level,'full'::public.organization_access_level) then
    return true;
  end if;

  if v_access='limited'::public.organization_access_level and p_project_id is not null then
    return private.boralog_can_access_project(p_project_id);
  end if;

  return false;
end
$$;

alter function private.boralog_task_access_allowed(uuid,uuid) owner to postgres;
revoke all on function private.boralog_task_access_allowed(uuid,uuid) from public, anon, service_role;
grant execute on function private.boralog_task_access_allowed(uuid,uuid) to authenticated;

alter table public.tasks enable row level security;
alter table public.task_message_sources enable row level security;

create policy "task accessible select"
on public.tasks for select to authenticated
using (private.boralog_task_access_allowed(organization_id, project_id));

create policy "task source visible only with both objects"
on public.task_message_sources for select to authenticated
using (
  exists (select 1 from public.tasks t where t.id=task_id)
  and exists (select 1 from public.messages m where m.id=message_id)
);

revoke all on table public.tasks from anon, authenticated;
revoke all on table public.task_message_sources from anon, authenticated;
grant select on table public.tasks to authenticated;
grant select on table public.task_message_sources to authenticated;

create or replace function public.boralog_create_task(
  p_organization_id uuid,
  p_content text,
  p_project_id uuid default null,
  p_event_id uuid default null,
  p_source_message_ids uuid[] default '{}'::uuid[]
)
returns public.tasks
language plpgsql
security definer
set search_path=''
as $$
declare
  v_actor uuid;
  v_access public.organization_access_level;
  v_context_project uuid := null;
  v_context_event uuid := null;
  v_context_org uuid := null;
  v_source_ids uuid[] := coalesce(p_source_message_ids,'{}'::uuid[]);
  v_source_count integer := 0;
  v_accessible_source_count integer := 0;
  v_task public.tasks%rowtype;
begin
  v_actor:=auth.uid();
  if v_actor is null then raise exception 'authenticated actor required' using errcode='42501'; end if;
  if nullif(btrim(p_content),'') is null then raise exception 'task content is required' using errcode='23514'; end if;

  select membership.access_level into v_access
  from public.organization_memberships membership
  where membership.organization_id=p_organization_id
    and membership.user_id=v_actor
    and membership.status='active'::public.membership_status
  limit 1;

  if v_access is null then raise exception 'active organization membership required' using errcode='42501'; end if;

  if p_project_id is not null and p_event_id is not null then
    raise exception 'task context must be a project or a date, not both' using errcode='23514';
  end if;

  if p_project_id is not null then
    select p.organization_id into v_context_org from public.projects p where p.id=p_project_id;
    if v_context_org is null or v_context_org <> p_organization_id then
      raise exception 'task project must belong to task organization' using errcode='23514';
    end if;
    if not private.boralog_can_access_project(p_project_id) then
      raise exception 'task project is not accessible to actor' using errcode='42501';
    end if;
    v_context_project:=p_project_id;
  elsif p_event_id is not null then
    select e.project_id,p.organization_id into v_context_project,v_context_org
    from public.events e join public.projects p on p.id=e.project_id
    where e.id=p_event_id;

    if v_context_project is null or v_context_org <> p_organization_id then
      raise exception 'task date must belong to task organization' using errcode='23514';
    end if;
    if not private.boralog_can_access_project(v_context_project) then
      raise exception 'task date is not accessible to actor' using errcode='42501';
    end if;
    v_context_event:=p_event_id;
  elsif v_access='limited'::public.organization_access_level then
    raise exception 'limited member cannot create contextless task' using errcode='42501';
  end if;

  if exists (select 1 from unnest(v_source_ids) s(message_id) where s.message_id is null) then
    raise exception 'source message ids cannot contain null' using errcode='23514';
  end if;

  select count(distinct s.message_id) into v_source_count from unnest(v_source_ids) s(message_id);

  if v_source_count>0 then
    select count(*) into v_accessible_source_count
    from public.messages m
    where m.id in (select distinct s.message_id from unnest(v_source_ids) s(message_id))
      and m.organization_id=p_organization_id
      and private.boralog_message_access_allowed(
        m.id,m.organization_id,m.project_id,m.event_id,m.visibility,m.created_by,m.author_user_id
      );

    if v_accessible_source_count <> v_source_count then
      raise exception 'all source messages must be accessible in the task organization' using errcode='42501';
    end if;
  end if;

  insert into public.tasks(
    organization_id,project_id,event_id,content,status,created_by,completed_at,completed_by
  ) values (
    p_organization_id,v_context_project,v_context_event,btrim(p_content),'TO_DO',v_actor,null,null
  ) returning * into v_task;

  if v_source_count>0 then
    insert into public.task_message_sources(task_id,message_id)
    select v_task.id,supplied.message_id
    from (select distinct s.message_id from unnest(v_source_ids) s(message_id)) supplied;
  end if;

  return v_task;
end
$$;

alter function public.boralog_create_task(uuid,text,uuid,uuid,uuid[]) owner to postgres;
revoke all on function public.boralog_create_task(uuid,text,uuid,uuid,uuid[]) from public, anon, service_role;
grant execute on function public.boralog_create_task(uuid,text,uuid,uuid,uuid[]) to authenticated;

create or replace function public.boralog_set_task_status(
  p_task_id uuid,
  p_status text
)
returns public.tasks
language plpgsql
security definer
set search_path=''
as $$
declare
  v_actor uuid;
  v_task public.tasks%rowtype;
begin
  v_actor:=auth.uid();
  if v_actor is null then raise exception 'authenticated actor required' using errcode='42501'; end if;
  if p_status not in ('TO_DO','DONE') then raise exception 'invalid task status' using errcode='23514'; end if;

  select * into v_task from public.tasks where id=p_task_id;
  if v_task.id is null then raise exception 'task not found' using errcode='42501'; end if;

  if not private.boralog_task_access_allowed(v_task.organization_id,v_task.project_id) then
    raise exception 'task is not accessible to actor' using errcode='42501';
  end if;

  if v_task.status=p_status then return v_task; end if;

  if p_status='DONE' then
    update public.tasks
    set status='DONE', completed_at=now(), completed_by=v_actor
    where id=p_task_id
    returning * into v_task;
  else
    update public.tasks
    set status='TO_DO', completed_at=null, completed_by=null
    where id=p_task_id
    returning * into v_task;
  end if;

  return v_task;
end
$$;

alter function public.boralog_set_task_status(uuid,text) owner to postgres;
revoke all on function public.boralog_set_task_status(uuid,text) from public, anon, service_role;
grant execute on function public.boralog_set_task_status(uuid,text) to authenticated;
