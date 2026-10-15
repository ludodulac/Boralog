-- Cloudflare D1 staging only. No production cutover.
PRAGMA foreign_keys=ON;
CREATE TABLE IF NOT EXISTS organizations (
 id TEXT PRIMARY KEY, name TEXT NOT NULL, slug TEXT UNIQUE, created_by TEXT, created_at TEXT
);
CREATE TABLE IF NOT EXISTS profiles (
 id TEXT PRIMARY KEY, display_name TEXT, professional_email TEXT, professional_phone TEXT, created_at TEXT, updated_at TEXT
);
CREATE TABLE IF NOT EXISTS organization_memberships (
 id TEXT PRIMARY KEY, organization_id TEXT NOT NULL REFERENCES organizations(id),
 user_id TEXT NOT NULL REFERENCES profiles(id), role TEXT NOT NULL,
 status TEXT NOT NULL, can_manage_members INTEGER NOT NULL DEFAULT 0,
 can_manage_roles INTEGER NOT NULL DEFAULT 0, access_level TEXT, created_at TEXT,
 UNIQUE(organization_id,user_id)
);
CREATE TABLE IF NOT EXISTS projects (
 id TEXT PRIMARY KEY, organization_id TEXT NOT NULL REFERENCES organizations(id),
 name TEXT NOT NULL, description TEXT, archived_at TEXT, created_by TEXT, created_at TEXT
);
CREATE TABLE IF NOT EXISTS project_memberships (
 project_id TEXT NOT NULL REFERENCES projects(id), user_id TEXT NOT NULL REFERENCES profiles(id),
 role TEXT NOT NULL, created_at TEXT, PRIMARY KEY(project_id,user_id)
);
CREATE TABLE IF NOT EXISTS events (
 id TEXT PRIMARY KEY, project_id TEXT NOT NULL REFERENCES projects(id), title TEXT NOT NULL,
 venue_name TEXT, city TEXT, starts_at TEXT, ends_at TEXT, status TEXT,
 created_by TEXT, created_at TEXT, event_date TEXT
);
CREATE TABLE IF NOT EXISTS messages (
 id TEXT PRIMARY KEY, organization_id TEXT NOT NULL REFERENCES organizations(id),
 project_id TEXT REFERENCES projects(id), event_id TEXT REFERENCES events(id),
 content TEXT NOT NULL, status TEXT, created_by TEXT, created_at TEXT,
 processed_at TEXT, processed_by TEXT, resolution TEXT, origin_type TEXT,
 author_user_id TEXT, external_author_label TEXT, source_kind TEXT,
 source_occurred_at TEXT, visibility TEXT
);
CREATE TABLE IF NOT EXISTS informations (
 id TEXT PRIMARY KEY, organization_id TEXT NOT NULL REFERENCES organizations(id),
 project_id TEXT REFERENCES projects(id), event_id TEXT REFERENCES events(id),
 content TEXT NOT NULL, created_by TEXT, created_at TEXT
);
CREATE TABLE IF NOT EXISTS tasks (
 id TEXT PRIMARY KEY, organization_id TEXT NOT NULL REFERENCES organizations(id),
 project_id TEXT REFERENCES projects(id), event_id TEXT REFERENCES events(id),
 content TEXT NOT NULL, status TEXT, created_by TEXT, created_at TEXT,
 completed_at TEXT, completed_by TEXT
);
CREATE TABLE IF NOT EXISTS companies (
 id TEXT PRIMARY KEY, organization_id TEXT NOT NULL REFERENCES organizations(id),
 name TEXT NOT NULL, created_by TEXT, created_at TEXT
);
CREATE TABLE IF NOT EXISTS people (
 id TEXT PRIMARY KEY, organization_id TEXT NOT NULL REFERENCES organizations(id),
 name TEXT NOT NULL, role_label TEXT, professional_email TEXT,
 professional_phone TEXT, created_by TEXT, created_at TEXT,
 organization_membership_id TEXT REFERENCES organization_memberships(id)
);
CREATE TABLE IF NOT EXISTS person_companies (
 person_id TEXT NOT NULL REFERENCES people(id), company_id TEXT NOT NULL REFERENCES companies(id),
 created_at TEXT, PRIMARY KEY(person_id,company_id)
);
CREATE TABLE IF NOT EXISTS message_recipients (
 message_id TEXT NOT NULL REFERENCES messages(id), user_id TEXT NOT NULL REFERENCES profiles(id),
 created_at TEXT, PRIMARY KEY(message_id,user_id)
);
CREATE TABLE IF NOT EXISTS message_reads (
 message_id TEXT NOT NULL REFERENCES messages(id), user_id TEXT NOT NULL REFERENCES profiles(id),
 read_at TEXT, PRIMARY KEY(message_id,user_id)
);
CREATE TABLE IF NOT EXISTS message_notes (
 id TEXT PRIMARY KEY, message_id TEXT NOT NULL REFERENCES messages(id),
 content TEXT NOT NULL, created_by TEXT, created_at TEXT
);
CREATE TABLE IF NOT EXISTS message_status_history (
 id TEXT PRIMARY KEY, message_id TEXT NOT NULL REFERENCES messages(id),
 from_status TEXT, to_status TEXT, changed_by TEXT, changed_at TEXT
);
CREATE TABLE IF NOT EXISTS information_message_sources (
 information_id TEXT NOT NULL REFERENCES informations(id), message_id TEXT NOT NULL REFERENCES messages(id),
 created_at TEXT, PRIMARY KEY(information_id,message_id)
);
CREATE TABLE IF NOT EXISTS task_message_sources (
 task_id TEXT NOT NULL REFERENCES tasks(id), message_id TEXT NOT NULL REFERENCES messages(id),
 created_at TEXT, PRIMARY KEY(task_id,message_id)
);
CREATE TABLE IF NOT EXISTS recipient_groups (
 id TEXT PRIMARY KEY, organization_id TEXT NOT NULL REFERENCES organizations(id),
 name TEXT NOT NULL, created_by TEXT, created_at TEXT
);
CREATE TABLE IF NOT EXISTS recipient_group_members (
 group_id TEXT NOT NULL REFERENCES recipient_groups(id), user_id TEXT NOT NULL REFERENCES profiles(id),
 created_at TEXT, PRIMARY KEY(group_id,user_id)
);
CREATE INDEX IF NOT EXISTS idx_projects_org ON projects(organization_id);
CREATE INDEX IF NOT EXISTS idx_messages_org ON messages(organization_id,created_at);
CREATE INDEX IF NOT EXISTS idx_events_project ON events(project_id,event_date);
CREATE INDEX IF NOT EXISTS idx_tasks_org ON tasks(organization_id,status);
-- Wikignose's two unrelated tables deliberately NOT migrated.
-- Verify no external consumers before removing the original Supabase project.
