-- BORALOG-155F: minimal Supabase SQL primitives for ephemeral PostgreSQL CI.
-- No remote Supabase services or credentials are required.

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin;
  end if;

  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin;
  end if;

  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role nologin;
  end if;
end
$$;

create schema if not exists auth;

create table auth.users (
  id uuid primary key,
  aud text,
  role text,
  email text,
  raw_app_meta_data jsonb,
  raw_user_meta_data jsonb,
  created_at timestamptz,
  updated_at timestamptz
);

create or replace function auth.uid()
returns uuid
language sql
stable
set search_path = ''
as $$
  select nullif(
    current_setting('request.jwt.claim.sub', true),
    ''
  )::uuid
$$;

revoke all on schema auth from public;
grant usage on schema auth to authenticated;

revoke all on function auth.uid() from public;
grant execute on function auth.uid() to authenticated;
