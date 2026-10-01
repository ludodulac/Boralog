-- BORALOG-158: secure minimal recipient directory for Message audience selection.

create or replace function public.boralog_message_recipient_directory(
  p_organization_id uuid
)
returns table (
  user_id uuid,
  display_name text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    target.user_id,
    profile.display_name
  from public.organization_memberships as target
  left join public.profiles as profile
    on profile.id = target.user_id
  where target.organization_id = p_organization_id
    and target.status = 'active'::public.membership_status
    and exists (
      select 1
      from public.organization_memberships as actor
      where actor.organization_id = p_organization_id
        and actor.user_id = auth.uid()
        and actor.status = 'active'::public.membership_status
    )
  order by profile.display_name nulls last, target.user_id
$$;

alter function public.boralog_message_recipient_directory(uuid) owner to postgres;

revoke all on function public.boralog_message_recipient_directory(uuid)
  from public, anon, service_role;

grant execute on function public.boralog_message_recipient_directory(uuid)
  to authenticated;
