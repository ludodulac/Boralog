-- Mirrored from the existing Supabase migration history for the shared Boralog/Wikignose project.
-- Source version: 20260826190527; source name: harden_wikignose_admin_check
-- Added locally so Supabase CLI history comparison matches the already-applied remote history.

create policy "admins can verify own authorization"
on public.wikignose_admins for select to authenticated
using (lower(email) = lower(coalesce(auth.jwt()->>'email','')));

create or replace function public.is_wikignose_admin()
returns boolean
language sql
stable
security invoker
set search_path = public
as $$
  select exists (
    select 1 from public.wikignose_admins a
    where lower(a.email) = lower(coalesce(auth.jwt()->>'email',''))
  );
$$;

revoke all on function public.is_wikignose_admin() from public;
revoke all on function public.is_wikignose_admin() from anon;
grant execute on function public.is_wikignose_admin() to authenticated;
