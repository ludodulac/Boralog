import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";

const projectsPage = readFileSync("src/app/projets/page.tsx", "utf8");
const createActions = readFileSync("src/app/projets/nouveau/actions.ts", "utf8");
const realProjectPage = readFileSync("src/app/projets/reel/[projectId]/page.tsx", "utf8");
const editActions = readFileSync("src/app/projets/reel/[projectId]/actions.ts", "utf8");
const editForm = readFileSync("src/app/projets/reel/[projectId]/ProjectEditForm.tsx", "utf8");
const calendarPage = readFileSync("src/app/calendrier/page.tsx", "utf8");

test("BORALOG-172A /projets uses only real current-Structure Projects", () => {
  assert.doesNotMatch(projectsPage, /demoProjects|data\/demo/);
  assert.match(projectsPage, /getCurrentIdentity/);
  assert.match(projectsPage, /\.from\("projects"\)/);
  assert.match(projectsPage, /\.eq\("organization_id", identity\.organization\.id\)/);
  assert.match(projectsPage, /href=\{\`\/projets\/reel\/\$\{project\.id\}\`\}/);
  assert.doesNotMatch(projectsPage, /\/projets\/\$\{project\.slug\}/);
  assert.match(projectsPage, /Aucun projet pour le moment/);
  assert.match(projectsPage, /href="\/projets\/nouveau"/);
});

test("BORALOG-172A createProject reuses canonical current Structure", () => {
  assert.match(createActions, /getCurrentIdentity/);
  assert.match(createActions, /organization_id: identity\.organization\.id/);
  assert.match(createActions, /created_by: identity\.userId/);
  assert.match(createActions, /identity\.organization\.accessLevel !== "owner"[\s\S]*identity\.organization\.accessLevel !== "full"/);
  assert.doesNotMatch(createActions, /\.from\("organization_memberships"\)[\s\S]{0,500}\.limit\(1\)/);
  assert.doesNotMatch(createActions, /formData\.get\("organization_id"\)/);
});

test("BORALOG-172A real Project page is bound to current Structure and exposes edit only to OWNER/FULL", () => {
  assert.match(realProjectPage, /getCurrentIdentity/);
  assert.match(realProjectPage, /\.eq\("organization_id", identity\.organization\.id\)/);
  assert.match(realProjectPage, /accessLevel === "owner"[\s\S]*accessLevel === "full"/);
  assert.match(realProjectPage, /ProjectEditForm/);
});

test("BORALOG-172A Project edit changes name and description only", () => {
  assert.match(editActions, /getCurrentIdentity/);
  assert.match(editActions, /identity\.organization\.accessLevel !== "owner"[\s\S]*identity\.organization\.accessLevel !== "full"/);
  assert.match(editActions, /\.eq\("organization_id", identity\.organization\.id\)/);
  assert.match(editActions, /\.update\(\{[\s\S]*name: parsedName\.value,[\s\S]*description,[\s\S]*\}\)/);
  assert.doesNotMatch(editActions, /organization_id\s*:/);
  assert.doesNotMatch(editActions, /created_by\s*:/);
  assert.doesNotMatch(editActions, /archived_at\s*:/);
  assert.match(editForm, /name="name"/);
  assert.match(editForm, /name="description"/);
  assert.match(editForm, /Modifier le projet/);
});

test("BORALOG-172A calendar remains the real Supabase calendar", () => {
  assert.match(calendarPage, /getCurrentIdentity/);
  assert.match(calendarPage, /\.from\("projects"\)/);
  assert.match(calendarPage, /identity\.organization\.id/);
  assert.doesNotMatch(calendarPage, /demoProjects|data\/demo/);
});

test("BORALOG-172A adds no migration", () => {
  assert.doesNotMatch(readdirSync("supabase/migrations").join("\n"), /172a/i);
});
