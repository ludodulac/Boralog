\set ON_ERROR_STOP on
CREATE ROLE anon NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
CREATE ROLE authenticated NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
CREATE ROLE service_role NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
GRANT authenticated, anon, service_role TO postgres;
CREATE SCHEMA auth;
CREATE TABLE auth.users (
 id uuid PRIMARY KEY,
 aud text,
 role text,
 email text,
 encrypted_password text,
 email_confirmed_at timestamptz,
 raw_app_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb,
 raw_user_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb,
 created_at timestamptz NOT NULL DEFAULT now(),
 updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE OR REPLACE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS $$
 SELECT nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;
GRANT USAGE ON SCHEMA auth TO authenticated, anon, service_role;
GRANT EXECUTE ON FUNCTION auth.uid() TO authenticated, anon, service_role;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
SELECT rolname, rolsuper, rolinherit, rolcreaterole, rolcreatedb, rolcanlogin, rolbypassrls
FROM pg_roles WHERE rolname IN ('anon','authenticated','service_role','postgres') ORDER BY rolname;
