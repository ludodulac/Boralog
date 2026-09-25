-- BORALOG access model 027 local/isolated proof protocol.
-- Run only against a disposable local Supabase database after applying the candidate migration.
-- This file rolls back all fixtures. It must never be pointed at the remote Boralog project.

begin;

insert into auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
 ('00000000-0000-4000-8000-000000000001','authenticated','authenticated','owner-027@example.invalid','',now(),'{}','{}',now(),now()),
 ('00000000-0000-4000-8000-000000000002','authenticated','authenticated','full-027@example.invalid','',now(),'{}','{}',now(),now()),
 ('00000000-0000-4000-8000-000000000003','authenticated','authenticated','limited-a-027@example.invalid','',now(),'{}','{}',now(),now()),
 ('00000000-0000-4000-8000-000000000004','authenticated','authenticated','limited-b-027@example.invalid','',now(),'{}','{}',now(),now()),
 ('00000000-0000-4000-8000-000000000005','authenticated','authenticated','outsider-027@example.invalid','',now(),'{}','{}',now(),now()),
 ('00000000-0000-4000-8000-000000000006','authenticated','authenticated','full-created-027@example.invalid','',now(),'{}','{}',now(),now()),
 ('00000000-0000-4000-8000-000000000007','authenticated','authenticated','limited-created-027@example.invalid','',now(),'{}','{}',now(),now()),
 ('00000000-0000-4000-8000-000000000008','authenticated','authenticated','owner-candidate-027@example.invalid','',now(),'{}','{}',now(),now());

create or replace function pg_temp.assert_eq(p_actual bigint, p_expected bigint, p_message text)
returns void language plpgsql as $$ begin if p_actual is distinct from p_expected then raise exception 'ASSERT_EQ failed: % actual=% expected=%',p_message,p_actual,p_expected; end if; end $$;

set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000001',true);
insert into public.organizations (id,name,slug,created_by)
values ('10000000-0000-4000-8000-000000000001','ORG A 027','org-a-027','00000000-0000-4000-8000-000000000001');
select pg_temp.assert_eq(count(*),1,'bootstrap creates exactly one active OWNER') from public.organization_memberships where organization_id='10000000-0000-4000-8000-000000000001' and user_id='00000000-0000-4000-8000-000000000001' and access_level='owner' and status='active';
insert into public.organizations (id,name,slug,created_by) values ('10000000-0000-4000-8000-000000000002','ORG B 027','org-b-027','00000000-0000-4000-8000-000000000001');

do $$ begin begin
 insert into public.organizations (name,slug,created_by) values ('BAD','bad-created-by-027','00000000-0000-4000-8000-000000000005');
 raise exception 'expected created_by denial';
exception when insufficient_privilege or check_violation then null; end; end $$;

insert into public.organization_memberships (organization_id,user_id,access_level,status)
values
 ('10000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000002','full','active'),
 ('10000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000003','limited','active'),
 ('10000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000004','limited','active');

insert into public.projects (id,organization_id,name,created_by) values
 ('20000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','PROJECT A1','00000000-0000-4000-8000-000000000001'),
 ('20000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000001','PROJECT A2','00000000-0000-4000-8000-000000000001');
insert into public.project_memberships (project_id,user_id) values ('20000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000003');
insert into public.events (id,project_id,title,created_by) values
 ('30000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','A1 EVENT','00000000-0000-4000-8000-000000000001'),
 ('30000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000002','A2 EVENT','00000000-0000-4000-8000-000000000001');
select pg_temp.assert_eq(count(*),2,'OWNER sees A1/A2') from public.projects where organization_id='10000000-0000-4000-8000-000000000001';

select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000002',true);
select pg_temp.assert_eq(count(*),2,'FULL sees A1/A2') from public.projects where organization_id='10000000-0000-4000-8000-000000000001';
insert into public.organization_memberships (organization_id,user_id,access_level,status) values ('10000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000006','full','active');
insert into public.organization_memberships (organization_id,user_id,access_level,status) values ('10000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000007','limited','active');
do $$ begin begin
 insert into public.organization_memberships (organization_id,user_id,access_level,status) values ('10000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000008','owner','active');
 raise exception 'expected FULL -> OWNER insert denial';
exception when insufficient_privilege or check_violation then null; end; end $$;
do $$ begin begin
 update public.organization_memberships set access_level='full' where organization_id='10000000-0000-4000-8000-000000000001' and user_id='00000000-0000-4000-8000-000000000001';
 if found then raise exception 'expected FULL modifying OWNER denial'; end if;
exception when insufficient_privilege or check_violation then null; end; end $$;
do $$ begin begin
 update public.organization_memberships set access_level='owner' where organization_id='10000000-0000-4000-8000-000000000001' and user_id='00000000-0000-4000-8000-000000000002';
 if found then raise exception 'expected FULL self-promotion denial'; end if;
exception when insufficient_privilege or check_violation then null; end; end $$;

do $$ begin begin
 update public.organization_memberships set user_id='00000000-0000-4000-8000-000000000005' where organization_id='10000000-0000-4000-8000-000000000001' and user_id='00000000-0000-4000-8000-000000000003';
 raise exception 'expected immutable user_id denial';
exception when others then if sqlerrm like 'expected immutable%' then raise; end if; end; end $$;
do $$ begin begin
 update public.organization_memberships set organization_id='10000000-0000-4000-8000-000000000002' where organization_id='10000000-0000-4000-8000-000000000001' and user_id='00000000-0000-4000-8000-000000000003';
 raise exception 'expected immutable organization_id denial';
exception when others then if sqlerrm like 'expected immutable%' then raise; end if; end; end $$;

select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000001',true);
insert into public.organization_memberships (organization_id,user_id,access_level,status)
values ('10000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000008','full','active');
update public.organization_memberships set access_level='owner'
where organization_id='10000000-0000-4000-8000-000000000001' and user_id='00000000-0000-4000-8000-000000000008';
select pg_temp.assert_eq(count(*),1,'OWNER promotes OWNER') from public.organization_memberships where organization_id='10000000-0000-4000-8000-000000000001' and user_id='00000000-0000-4000-8000-000000000008' and access_level='owner';
update public.organization_memberships set access_level='full'
where organization_id='10000000-0000-4000-8000-000000000001' and user_id='00000000-0000-4000-8000-000000000008';

select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000003',true);
select pg_temp.assert_eq(count(*),1,'LIMITED_A sees one project') from public.projects where organization_id='10000000-0000-4000-8000-000000000001';
select pg_temp.assert_eq(count(*),1,'LIMITED_A sees A1 exact') from public.projects where id='20000000-0000-4000-8000-000000000001';
select pg_temp.assert_eq(count(*),0,'LIMITED_A exact UUID A2 denied') from public.projects where id='20000000-0000-4000-8000-000000000002';
select pg_temp.assert_eq(count(*),1,'LIMITED_A sees A1 event') from public.events where id='30000000-0000-4000-8000-000000000001';
select pg_temp.assert_eq(count(*),0,'LIMITED_A cannot see A2 event') from public.events where id='30000000-0000-4000-8000-000000000002';
insert into public.events (project_id,title,created_by) values ('20000000-0000-4000-8000-000000000001','LIMITED A1 WRITE','00000000-0000-4000-8000-000000000003');
do $$ begin begin
 insert into public.events (project_id,title,created_by) values ('20000000-0000-4000-8000-000000000002','LIMITED A2 DENY','00000000-0000-4000-8000-000000000003');
 raise exception 'expected LIMITED A2 event denial';
exception when insufficient_privilege or check_violation then null; end; end $$;
do $$ begin begin
 insert into public.project_memberships (project_id,user_id) values ('20000000-0000-4000-8000-000000000002','00000000-0000-4000-8000-000000000003');
 raise exception 'expected LIMITED self-assignment denial';
exception when insufficient_privilege or check_violation then null; end; end $$;

select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000004',true);
select pg_temp.assert_eq(count(*),0,'LIMITED_B sees neither A1 nor A2') from public.projects where organization_id='10000000-0000-4000-8000-000000000001';

select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000005',true);
select pg_temp.assert_eq(count(*),0,'OUTSIDER organization denied') from public.organizations where id='10000000-0000-4000-8000-000000000001';
select pg_temp.assert_eq(count(*),0,'OUTSIDER project UUID denied') from public.projects where id='20000000-0000-4000-8000-000000000001';
select pg_temp.assert_eq(count(*),0,'OUTSIDER event UUID denied') from public.events where id='30000000-0000-4000-8000-000000000001';

select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000001',true);
do $$ begin begin update public.organizations set created_by='00000000-0000-4000-8000-000000000005' where id='10000000-0000-4000-8000-000000000001'; raise exception 'expected organization created_by immutable'; exception when others then if sqlerrm like 'expected organization%' then raise; end if; end; end $$;
do $$ begin begin update public.projects set created_by='00000000-0000-4000-8000-000000000005' where id='20000000-0000-4000-8000-000000000001'; raise exception 'expected project created_by immutable'; exception when others then if sqlerrm like 'expected project%' then raise; end if; end; end $$;
do $$ begin begin update public.events set created_by='00000000-0000-4000-8000-000000000005' where id='30000000-0000-4000-8000-000000000001'; raise exception 'expected event created_by immutable'; exception when others then if sqlerrm like 'expected event%' then raise; end if; end; end $$;

do $$ begin begin delete from public.organization_memberships where organization_id='10000000-0000-4000-8000-000000000001' and user_id='00000000-0000-4000-8000-000000000001'; raise exception 'expected last owner delete denial'; exception when others then if sqlerrm like 'expected last owner%' then raise; end if; end; end $$;
do $$ begin begin update public.organization_memberships set access_level='full' where organization_id='10000000-0000-4000-8000-000000000001' and user_id='00000000-0000-4000-8000-000000000001'; raise exception 'expected last owner downgrade denial'; exception when others then if sqlerrm like 'expected last owner%' then raise; end if; end; end $$;
do $$ begin begin update public.organization_memberships set status='suspended' where organization_id='10000000-0000-4000-8000-000000000001' and user_id='00000000-0000-4000-8000-000000000001'; raise exception 'expected last owner suspension denial'; exception when others then if sqlerrm like 'expected last owner%' then raise; end if; end; end $$;

-- CONCURRENCY IS NOT PROVEN BY THIS MONO-SESSION FILE.
-- Required separate proof after approval, against a disposable local database:
-- Session A removes OWNER_A and holds the transaction open.
-- Session B attempts to remove OWNER_B from the same organization.
-- Session B must block on the parent organizations row FOR UPDATE.
-- After A commits, B must resume, recount, and be denied as last active owner.
-- Never report concurrency PASS without this real two-session observation.

rollback;
