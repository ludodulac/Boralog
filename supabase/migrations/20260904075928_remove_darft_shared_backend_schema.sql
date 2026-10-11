-- Mirrored from the existing Supabase migration history for the shared Boralog/Wikignose project.
-- Source version: 20260904075928; source name: remove_darft_shared_backend_schema
-- Added locally so Supabase CLI history comparison matches the already-applied remote history.

begin;

drop policy if exists darft_team_read_submission_files on storage.objects;

drop view if exists public.darft_submissions_admin;

drop table if exists public.darft_submission_status_history cascade;
drop table if exists public.darft_submission_images cascade;
drop table if exists public.darft_submissions cascade;
drop table if exists public.darft_artworks cascade;
drop table if exists public.darft_artists cascade;
drop table if exists public.darft_project_journal cascade;
drop table if exists public.darft_project_tasks cascade;
drop table if exists public.darft_profiles cascade;

drop function if exists public.darft_log_submission_status_change() cascade;
drop function if exists public.darft_touch_submission_updated_at() cascade;
drop function if exists public.darft_touch_project_updated_at() cascade;
drop function if exists public.is_darft_admin() cascade;
drop type if exists public.darft_submission_status cascade;

commit;
