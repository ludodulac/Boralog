-- Mirrored from the existing Supabase migration history for the shared Boralog/Wikignose project.
-- Source version: 20260902225525; source name: darft_security_hardening
-- Added locally so Supabase CLI history comparison matches the already-applied remote history.

create or replace function public.is_darft_admin()
returns boolean
language sql
stable
security invoker
set search_path = public
as $$
  select exists (
    select 1 from public.darft_profiles
    where id = (select auth.uid()) and role in ('admin','reviewer')
  );
$$;

create or replace function public.darft_touch_submission_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke execute on function public.darft_log_submission_status_change() from public, anon, authenticated;
