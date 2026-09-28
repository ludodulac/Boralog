-- BORALOG-106: mandatory civil business date, optional real times.
-- Remote preflight proved public.events contained zero rows, so no backfill or timezone inference is required.
alter table public.events
  add column event_date date not null;
