-- Boralog foundation. Applied to Supabase project jwtawyeuyvqjikjvfhri.
-- Existing legacy Wikignose/Darft objects are intentionally outside this migration.

create extension if not exists pgcrypto;

create type public.membership_role as enum ('owner','admin','production','administration','diffusion','logistics','technical','communication','artist','technician','payroll','accounting');
create type public.membership_status as enum ('invited','active','suspended');
create type public.event_status as enum ('draft','option','confirmed','completed','cancelled');

create table public.profiles (id uuid primary key references auth.users(id) on delete cascade,display_name text not null check (char_length(display_name) between 1 and 120),professional_email text,professional_phone text,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table public.organizations (id uuid primary key default gen_random_uuid(),name text not null check (char_length(name) between 1 and 160),slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),created_by uuid not null references auth.users(id),created_at timestamptz not null default now());
create table public.organization_memberships (id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id) on delete cascade,user_id uuid not null references auth.users(id) on delete cascade,role public.membership_role not null,status public.membership_status not null default 'active',can_manage_members boolean not null default false,can_manage_roles boolean not null default false,created_at timestamptz not null default now(),unique(organization_id,user_id));
create table public.projects (id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id) on delete cascade,name text not null check (char_length(name) between 1 and 180),description text,archived_at timestamptz,created_by uuid not null references auth.users(id),created_at timestamptz not null default now());
create table public.project_memberships (project_id uuid not null references public.projects(id) on delete cascade,user_id uuid not null references auth.users(id) on delete cascade,role public.membership_role not null,created_at timestamptz not null default now(),primary key(project_id,user_id));
create table public.events (id uuid primary key default gen_random_uuid(),project_id uuid not null references public.projects(id) on delete cascade,title text,venue_name text,city text,starts_at timestamptz,ends_at timestamptz,status public.event_status not null default 'draft',created_by uuid not null references auth.users(id),created_at timestamptz not null default now(),constraint event_dates_order check (ends_at is null or starts_at is null or ends_at >= starts_at));

create index memberships_user_org_idx on public.organization_memberships(user_id,organization_id) where status='active';
create index projects_org_idx on public.projects(organization_id);
create index project_memberships_user_idx on public.project_memberships(user_id,project_id);
create index events_project_start_idx on public.events(project_id,starts_at);

alter table public.profiles enable row level security; alter table public.organizations enable row level security; alter table public.organization_memberships enable row level security; alter table public.projects enable row level security; alter table public.project_memberships enable row level security; alter table public.events enable row level security;

create policy "profile own select" on public.profiles for select to authenticated using ((select auth.uid())=id);
create policy "profile own insert" on public.profiles for insert to authenticated with check ((select auth.uid())=id);
create policy "profile own update" on public.profiles for update to authenticated using ((select auth.uid())=id) with check ((select auth.uid())=id);
create policy "organization creator insert" on public.organizations for insert to authenticated with check ((select auth.uid())=created_by);
create policy "organization creator select" on public.organizations for select to authenticated using ((select auth.uid())=created_by);
create policy "creator membership access" on public.organization_memberships for all to authenticated using (exists(select 1 from public.organizations o where o.id=organization_id and o.created_by=(select auth.uid()))) with check (exists(select 1 from public.organizations o where o.id=organization_id and o.created_by=(select auth.uid())));
create policy "member organization select" on public.organizations for select to authenticated using (exists(select 1 from public.organization_memberships m where m.organization_id=id and m.user_id=(select auth.uid()) and m.status='active'));
create policy "member project select" on public.projects for select to authenticated using (exists(select 1 from public.organization_memberships m where m.organization_id=projects.organization_id and m.user_id=(select auth.uid()) and m.status='active'));
create policy "organization creator project insert" on public.projects for insert to authenticated with check ((select auth.uid())=created_by and exists(select 1 from public.organizations o where o.id=organization_id and o.created_by=(select auth.uid())));
create policy "project member rows select" on public.project_memberships for select to authenticated using (user_id=(select auth.uid()) or exists(select 1 from public.projects p join public.organization_memberships m on m.organization_id=p.organization_id where p.id=project_id and m.user_id=(select auth.uid()) and m.status='active'));
create policy "org admin project member manage" on public.project_memberships for all to authenticated using (exists(select 1 from public.projects p join public.organization_memberships m on m.organization_id=p.organization_id where p.id=project_id and m.user_id=(select auth.uid()) and m.status='active' and (m.role in ('owner','admin') or m.can_manage_members))) with check (exists(select 1 from public.projects p join public.organization_memberships m on m.organization_id=p.organization_id where p.id=project_id and m.user_id=(select auth.uid()) and m.status='active' and (m.role in ('owner','admin') or m.can_manage_members)));
create policy "project event select" on public.events for select to authenticated using (exists(select 1 from public.projects p join public.organization_memberships m on m.organization_id=p.organization_id where p.id=events.project_id and m.user_id=(select auth.uid()) and m.status='active'));
create policy "org staff event insert" on public.events for insert to authenticated with check ((select auth.uid())=created_by and exists(select 1 from public.projects p join public.organization_memberships m on m.organization_id=p.organization_id where p.id=events.project_id and m.user_id=(select auth.uid()) and m.status='active' and m.role in ('owner','admin','production','administration')));

grant select,insert,update on public.profiles to authenticated; grant select,insert,update on public.organizations to authenticated; grant select,insert,update,delete on public.organization_memberships to authenticated; grant select,insert,update on public.projects to authenticated; grant select,insert,update,delete on public.project_memberships to authenticated; grant select,insert,update on public.events to authenticated;
