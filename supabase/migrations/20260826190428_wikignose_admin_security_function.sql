-- Mirrored from the existing Supabase migration history for the shared Boralog/Wikignose project.
-- Source version: 20260826190428; source name: wikignose_admin_security_function
-- Added locally so Supabase CLI history comparison matches the already-applied remote history.

create or replace function public.is_wikignose_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.wikignose_admins a
    where lower(a.email) = lower(coalesce(auth.jwt()->>'email',''))
  );
$$;

revoke all on function public.is_wikignose_admin() from public;
grant execute on function public.is_wikignose_admin() to authenticated;

drop policy if exists "wikignose admins view pending documents" on public.pending_documents;
drop policy if exists "wikignose admins insert pending documents" on public.pending_documents;
drop policy if exists "wikignose admins update pending documents" on public.pending_documents;
drop policy if exists "wikignose admins delete pending documents" on public.pending_documents;

create policy "wikignose admins view pending documents"
on public.pending_documents for select to authenticated
using (public.is_wikignose_admin());

create policy "wikignose admins insert pending documents"
on public.pending_documents for insert to authenticated
with check (public.is_wikignose_admin());

create policy "wikignose admins update pending documents"
on public.pending_documents for update to authenticated
using (public.is_wikignose_admin())
with check (public.is_wikignose_admin());

create policy "wikignose admins delete pending documents"
on public.pending_documents for delete to authenticated
using (public.is_wikignose_admin());

drop policy if exists "wikignose admins upload pdfs" on storage.objects;
drop policy if exists "wikignose admins read pdfs" on storage.objects;
drop policy if exists "wikignose admins update pdfs" on storage.objects;
drop policy if exists "wikignose admins delete pdfs" on storage.objects;

create policy "wikignose admins upload pdfs"
on storage.objects for insert to authenticated
with check (bucket_id = 'wikignose-pdfs' and public.is_wikignose_admin());

create policy "wikignose admins read pdfs"
on storage.objects for select to authenticated
using (bucket_id = 'wikignose-pdfs' and public.is_wikignose_admin());

create policy "wikignose admins update pdfs"
on storage.objects for update to authenticated
using (bucket_id = 'wikignose-pdfs' and public.is_wikignose_admin())
with check (bucket_id = 'wikignose-pdfs' and public.is_wikignose_admin());

create policy "wikignose admins delete pdfs"
on storage.objects for delete to authenticated
using (bucket_id = 'wikignose-pdfs' and public.is_wikignose_admin());
