-- Export BORALOG public data in a single JSON cell.
-- Read-only. Run in Boralog SQL Editor, then export result as CSV.
-- Contains personal/business data: DO NOT publish or share publicly.
-- IMPORTANT: does not include schema, policies, auth.users, or passwords.
SELECT jsonb_pretty(jsonb_build_object(
  'project', 'jwtawyeuyvqjikjvfhri',
  'exported_at', now(),
  'public_tables', jsonb_build_object(
    'companies', (SELECT coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) FROM public."companies" t),
    'events', (SELECT coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) FROM public."events" t),
    'information_message_sources', (SELECT coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) FROM public."information_message_sources" t),
    'informations', (SELECT coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) FROM public."informations" t),
    'message_notes', (SELECT coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) FROM public."message_notes" t),
    'message_reads', (SELECT coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) FROM public."message_reads" t),
    'message_recipients', (SELECT coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) FROM public."message_recipients" t),
    'message_status_history', (SELECT coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) FROM public."message_status_history" t),
    'messages', (SELECT coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) FROM public."messages" t),
    'organization_memberships', (SELECT coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) FROM public."organization_memberships" t),
    'organizations', (SELECT coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) FROM public."organizations" t),
    'pending_documents', (SELECT coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) FROM public."pending_documents" t),
    'people', (SELECT coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) FROM public."people" t),
    'person_companies', (SELECT coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) FROM public."person_companies" t),
    'profiles', (SELECT coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) FROM public."profiles" t),
    'project_memberships', (SELECT coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) FROM public."project_memberships" t),
    'projects', (SELECT coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) FROM public."projects" t),
    'recipient_group_members', (SELECT coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) FROM public."recipient_group_members" t),
    'recipient_groups', (SELECT coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) FROM public."recipient_groups" t),
    'task_message_sources', (SELECT coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) FROM public."task_message_sources" t),
    'tasks', (SELECT coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) FROM public."tasks" t),
    'wikignose_admins', (SELECT coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) FROM public."wikignose_admins" t)
  )
)) AS boralog_public_data_backup;
