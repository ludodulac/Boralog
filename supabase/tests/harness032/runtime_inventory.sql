\set ON_ERROR_STOP on
SELECT schemaname,tablename,policyname,roles,cmd,qual,with_check FROM pg_policies
WHERE schemaname='public' AND tablename IN ('organizations','organization_memberships','projects','project_memberships','events')
ORDER BY tablename,policyname;
DO $$ BEGIN
 IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public'
 AND tablename IN ('organizations','organization_memberships','projects','project_memberships','events')
 AND (coalesce(qual,'') ~* '(^|[^a-z_])(role|membership_role|can_manage_members|can_manage_roles)([^a-z_]|$)'
 OR coalesce(with_check,'') ~* '(^|[^a-z_])(role|membership_role|can_manage_members|can_manage_roles)([^a-z_]|$)'))
 THEN RAISE EXCEPTION 'legacy authorization remains in effective policies'; END IF;
 IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND policyname IN
 ('organization accessible select','project membership accessible select','project membership admin insert','project membership admin update','project membership admin delete'))
 THEN RAISE EXCEPTION 'dangerous legacy policy still active'; END IF;
END $$;
SELECT n.nspname,p.proname,pg_get_userbyid(p.proowner) owner,p.prosecdef security_definer,p.proacl,
 pg_get_function_identity_arguments(p.oid) args
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE (n.nspname='private' AND p.proname LIKE 'boralog_%')
 OR (n.nspname='public' AND p.proname='handle_new_boralog_user_profile')
ORDER BY n.nspname,p.proname;
SELECT n.nspname,c.relname,t.tgname,pg_get_triggerdef(t.oid)
FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE NOT t.tgisinternal AND n.nspname IN ('public','auth') ORDER BY n.nspname,c.relname,t.tgname;
SELECT table_name,column_name,is_nullable,data_type,udt_name,column_default FROM information_schema.columns
WHERE table_schema='public' AND ((table_name='organization_memberships' AND column_name IN ('access_level','role','can_manage_members','can_manage_roles'))
 OR (table_name='project_memberships' AND column_name='role')) ORDER BY table_name,column_name;
SELECT e.enumsortorder,e.enumlabel FROM pg_type t JOIN pg_enum e ON e.enumtypid=t.oid JOIN pg_namespace n ON n.oid=t.typnamespace
WHERE n.nspname='public' AND t.typname='organization_access_level' ORDER BY e.enumsortorder;
SELECT n.nspname,p.proname,has_function_privilege('authenticated',p.oid,'EXECUTE') authenticated_execute
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='private' AND p.proname LIKE 'boralog_%' ORDER BY p.proname;
DO $$ DECLARE f regprocedure; BEGIN
 f:=to_regprocedure('private.boralog_valid_project_assignment(uuid,uuid)');
 IF f IS NULL THEN RAISE EXCEPTION 'raw assignment oracle missing'; END IF;
 IF has_function_privilege('authenticated',f,'EXECUTE') THEN RAISE EXCEPTION 'authenticated can execute raw assignment oracle'; END IF;
END $$;
