-- BORALOG-160: per-user Message read/unread state.
-- Absence of a row means unread. Shared Message processing status is untouched.

create table public.message_reads (
  message_id uuid not null references public.messages(id) on delete cascade,
  user_id uuid not null references auth.users(id),
  read_at timestamptz not null default now(),
  primary key (message_id, user_id)
);

create index message_reads_user_message_idx
  on public.message_reads(user_id, message_id);

alter table public.message_reads enable row level security;

create policy "message read own select"
on public.message_reads
for select
to authenticated
using (
  user_id = (select auth.uid())
  and exists (
    select 1
    from public.messages as m
    where m.id = message_id
  )
);

create policy "message read own insert"
on public.message_reads
for insert
to authenticated
with check (
  user_id = (select auth.uid())
  and exists (
    select 1
    from public.messages as m
    where m.id = message_id
  )
);

create policy "message read own delete"
on public.message_reads
for delete
to authenticated
using (
  user_id = (select auth.uid())
  and exists (
    select 1
    from public.messages as m
    where m.id = message_id
  )
);

revoke all on table public.message_reads from anon;
grant select, insert, delete on table public.message_reads to authenticated;
