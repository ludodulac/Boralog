-- Mirrored from the existing Supabase migration history for the shared Boralog/Wikignose project.
-- Source version: 20260826190336; source name: wikignose_private_pdf_storage
-- Added locally so Supabase CLI history comparison matches the already-applied remote history.

create table if not exists public.wikignose_admins (
  email text primary key,
  created_at timestamptz not null default now()
);

alter table public.wikignose_admins enable row level security;

create table if not exists public.pending_documents (
  id uuid primary key default gen_random_uuid(),
  storage_path text not null unique,
  original_filename text not null,
  file_size bigint,
  title_hint text,
  course_hint text,
  school_hint text,
  current_hint text,
  masters_hint text[],
  status text not null default 'pending',
  uploaded_by uuid default auth.uid(),
  uploaded_at timestamptz not null default now(),
  indexed_at timestamptz
);

alter table public.pending_documents enable row level security;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('wikignose-pdfs', 'wikignose-pdfs', false, 104857600, array['application/pdf'])
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "wikignose admins view pending documents"
on public.pending_documents for select to authenticated
using (exists (
  select 1 from public.wikignose_admins a
  where lower(a.email) = lower(coalesce(auth.jwt()->>'email',''))
));

create policy "wikignose admins insert pending documents"
on public.pending_documents for insert to authenticated
with check (exists (
  select 1 from public.wikignose_admins a
  where lower(a.email) = lower(coalesce(auth.jwt()->>'email',''))
));

create policy "wikignose admins update pending documents"
on public.pending_documents for update to authenticated
using (exists (
  select 1 from public.wikignose_admins a
  where lower(a.email) = lower(coalesce(auth.jwt()->>'email',''))
))
with check (exists (
  select 1 from public.wikignose_admins a
  where lower(a.email) = lower(coalesce(auth.jwt()->>'email',''))
));

create policy "wikignose admins delete pending documents"
on public.pending_documents for delete to authenticated
using (exists (
  select 1 from public.wikignose_admins a
  where lower(a.email) = lower(coalesce(auth.jwt()->>'email',''))
));

create policy "wikignose admins upload pdfs"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'wikignose-pdfs'
  and exists (
    select 1 from public.wikignose_admins a
    where lower(a.email) = lower(coalesce(auth.jwt()->>'email',''))
  )
);

create policy "wikignose admins read pdfs"
on storage.objects for select to authenticated
using (
  bucket_id = 'wikignose-pdfs'
  and exists (
    select 1 from public.wikignose_admins a
    where lower(a.email) = lower(coalesce(auth.jwt()->>'email',''))
  )
);

create policy "wikignose admins update pdfs"
on storage.objects for update to authenticated
using (
  bucket_id = 'wikignose-pdfs'
  and exists (
    select 1 from public.wikignose_admins a
    where lower(a.email) = lower(coalesce(auth.jwt()->>'email',''))
  )
)
with check (
  bucket_id = 'wikignose-pdfs'
  and exists (
    select 1 from public.wikignose_admins a
    where lower(a.email) = lower(coalesce(auth.jwt()->>'email',''))
  )
);

create policy "wikignose admins delete pdfs"
on storage.objects for delete to authenticated
using (
  bucket_id = 'wikignose-pdfs'
  and exists (
    select 1 from public.wikignose_admins a
    where lower(a.email) = lower(coalesce(auth.jwt()->>'email',''))
  )
);
