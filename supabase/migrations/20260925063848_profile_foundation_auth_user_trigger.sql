alter table public.profiles
  alter column display_name drop not null;

create or replace function public.handle_new_boralog_user_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  safe_display_name text;
begin
  safe_display_name :=
    case
      when jsonb_typeof(new.raw_user_meta_data -> 'display_name') = 'string'
        then nullif(btrim(new.raw_user_meta_data ->> 'display_name'), '')
      else null
    end;

  insert into public.profiles (id, display_name)
  values (new.id, safe_display_name)
  on conflict (id) do nothing;

  return new;
end;
$$;

revoke all on function public.handle_new_boralog_user_profile() from public;
revoke all on function public.handle_new_boralog_user_profile() from anon;
revoke all on function public.handle_new_boralog_user_profile() from authenticated;

drop trigger if exists on_auth_user_created_boralog_profile on auth.users;
create trigger on_auth_user_created_boralog_profile
  after insert on auth.users
  for each row
  execute function public.handle_new_boralog_user_profile();

insert into public.profiles (id, display_name)
select
  u.id,
  case
    when jsonb_typeof(u.raw_user_meta_data -> 'display_name') = 'string'
      then nullif(btrim(u.raw_user_meta_data ->> 'display_name'), '')
    else null
  end
from auth.users u
where not exists (
  select 1 from public.profiles p where p.id = u.id
)
on conflict (id) do nothing;
