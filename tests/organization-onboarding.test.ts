import test from "node:test";
import assert from "node:assert/strict";
import { normalizeOrganizationName, organizationSlug } from "../src/lib/organization-onboarding.ts";
import fs from "node:fs";

const attemptA = "123e4567-e89b-42d3-a456-426614174000";
const attemptB = "223e4567-e89b-42d3-a456-426614174000";

test("empty organization name is rejected", () => {
  assert.equal(normalizeOrganizationName("   ").ok, false);
});

test("valid organization name is normalized", () => {
  assert.deepEqual(normalizeOrganizationName("  Compagnie   Bora Bora  "), { ok: true, value: "Compagnie Bora Bora" });
});

test("French accents produce a schema-compatible slug", () => {
  assert.equal(organizationSlug("Théâtre de l'Équinoxe", attemptA), "theatre-de-l-equinoxe-123e4567");
});

test("same visible name gets distinct slugs for distinct logical attempts", () => {
  assert.notEqual(organizationSlug("Compagnie Bora Bora", attemptA), organizationSlug("Compagnie Bora Bora", attemptB));
});

test("server action owns created_by and never writes memberships", () => {
  const source = fs.readFileSync("src/app/organisations/nouvelle/actions.ts", "utf8");
  assert.match(source, /created_by:\s*authData\.user\.id/);
  assert.doesNotMatch(source, /formData\.get\(["']created_by/);
  assert.doesNotMatch(source, /from\(["']organization_memberships/);
});

test("organization insert does not request RETURNING visibility", () => {
  const source = fs.readFileSync("src/app/organisations/nouvelle/actions.ts", "utf8");
  const insertStart = source.indexOf('.from("organizations")\n    .insert({');
  const errorBranch = source.indexOf("\n\n  if (error) {", insertStart);
  assert.ok(insertStart >= 0 && errorBranch > insertStart);
  const insertChain = source.slice(insertStart, errorBranch);
  assert.doesNotMatch(insertChain, /\.select\s*\(/);
  assert.doesNotMatch(insertChain, /\.single\s*\(|\.maybeSingle\s*\(/);
  assert.match(insertChain, /id:\s*attemptId/);
});

test("same attempt id is read before insert for lost-response recovery", () => {
  const source = fs.readFileSync("src/app/organisations/nouvelle/actions.ts", "utf8");
  const read = source.indexOf('.eq("id", attemptId)');
  const insert = source.indexOf('.insert({');
  assert.ok(read >= 0 && insert > read);
});

test("form disables submit while pending", () => {
  const source = fs.readFileSync("src/app/organisations/nouvelle/CreateOrganizationForm.tsx", "utf8");
  assert.match(source, /disabled=\{pending\}/);
  assert.match(source, /pending \? "Création…" : "Créer ma structure"/);
});

test("existing membership redirects away from first-organization creation", () => {
  const source = fs.readFileSync("src/app/organisations/nouvelle/page.tsx", "utf8");
  assert.match(source, /if \(identity\.organization\) redirect\("\/"\)/);
});

test("real organization boundary stays structural and does not render demo fixtures", () => {
  const shell = fs.readFileSync("src/components/AppShell.tsx", "utf8");
  assert.doesNotMatch(shell, /demoToday|demoProjects|src\/data\/demo/);
  assert.match(shell, /identity\.organization\?\.name/);
  assert.match(shell, /\) : children\}/);
});

test("normal product routes render their own child without a manual route allowlist", () => {
  const shell = fs.readFileSync("src/components/AppShell.tsx", "utf8");
  assert.doesNotMatch(shell, /isCalendarRoute|isMessagesRoute|isProjectCreationRoute|isRealProjectRoute/);
  assert.match(shell, /\) : children\}/);
});

test("no-organization UX exposes creation CTA", () => {
  const shell = fs.readFileSync("src/components/AppShell.tsx", "utf8");
  assert.match(shell, /Vous n&apos;avez pas encore de structure/);
  assert.match(shell, /href="\/organisations\/nouvelle"/);
});

test("real organization home exposes first project CTA", () => {
  const home = fs.readFileSync("src/app/page.tsx", "utf8");
  assert.match(home, /href="\/projets\/nouveau"/);
  assert.match(home, /Créer un projet/);
});

test("project creation UI slice is extracted and deliberately write-free", () => {
  const page = fs.readFileSync("src/app/projets/nouveau/page.tsx", "utf8");
  const form = fs.readFileSync("src/app/projets/nouveau/CreateProjectForm.tsx", "utf8");
  assert.match(page, /import \{ CreateProjectForm \} from "\.\/CreateProjectForm"/);
  assert.match(page, /<CreateProjectForm attemptId=\{randomUUID\(\)\}\/>/);
  assert.doesNotMatch(page, /supabase|\.insert\s*\(/);
  assert.match(form, /name="name"/);
  assert.match(form, /name="description"/);
  assert.match(form, /type="submit" disabled=\{pending\}/);
  assert.match(form, /useActionState\(createProject, initialCreateProjectState\)/);
  assert.doesNotMatch(form, /supabase|\.insert\s*\(/);
});

test("project create action reuses canonical current organization", () => {
  const source = fs.readFileSync("src/app/projets/nouveau/actions.ts", "utf8");
  assert.match(source, /getCurrentIdentity/);
  assert.match(source, /identity\.organization\.id/);
  assert.match(source, /identity\.userId/);
  assert.match(source, /identity\.organization\.accessLevel/);
  assert.match(source, /"owner"/);
  assert.match(source, /"full"/);
  assert.doesNotMatch(source, /formData\.get\(["']organization_id/);
  assert.doesNotMatch(source, /\.from\("organization_memberships"\)[\s\S]{0,500}\.limit\(1\)/);
});

test("project insert never requests RETURNING visibility", () => {
  const source = fs.readFileSync("src/app/projets/nouveau/actions.ts", "utf8");
  const insertStart = source.indexOf('.from("projects")\n    .insert({');
  const errorBranch = source.indexOf("\n\n  if (error) {", insertStart);
  assert.ok(insertStart >= 0 && errorBranch > insertStart);
  const insertChain = source.slice(insertStart, errorBranch);
  assert.doesNotMatch(insertChain, /\.select\s*\(/);
  assert.doesNotMatch(insertChain, /\.single\s*\(|\.maybeSingle\s*\(/);
  assert.match(insertChain, /id:\s*attemptId/);
});

test("project form protects against repeated submit while pending", () => {
  const source = fs.readFileSync("src/app/projets/nouveau/CreateProjectForm.tsx", "utf8");
  assert.match(source, /disabled=\{pending\}/);
  assert.match(source, /pending \? "Création…" : "Créer le projet"/);
});

test("real project success route reads projects and not demo fixtures", () => {
  const source = fs.readFileSync("src/app/projets/reel/[projectId]/page.tsx", "utf8");
  assert.match(source, /from\("projects"\)/);
  assert.doesNotMatch(source, /demoProjects|demoToday|data\/demo/);
});

test("real structure home loads projects filtered by current organization", () => {
  const source = fs.readFileSync("src/app/page.tsx", "utf8");
  assert.match(source, /from\("projects"\)/);
  assert.match(source, /\.eq\("organization_id", identity\.organization\.id\)/);
  assert.match(source, /\.is\("archived_at", null\)/);
  assert.doesNotMatch(source, /demoProjects|demoToday|data\/demo/);
});

test("real structure home conditionally renders empty state and project links", () => {
  const source = fs.readFileSync("src/app/page.tsx", "utf8");
  assert.match(source, /realProjects\.length === 0/);
  assert.match(source, /Aucun projet pour le moment/);
  assert.match(source, /href=\{\`\/projets\/reel\/\$\{project\.id\}\`\}/);
  assert.match(source, /href="\/projets\/nouveau"/);
});

test("real project page is a durable project sheet using only real project data", () => {
  const source = fs.readFileSync("src/app/projets/reel/[projectId]/page.tsx", "utf8");
  assert.match(source, /← \{organizationName\}/);
  assert.match(source, /PROJET · \{organizationName\.toUpperCase\(\)\}/);
  assert.match(source, /\{project\.name\}/);
  assert.match(source, /project\.description &&/);
  assert.doesNotMatch(source, /Projet créé|Ce projet est enregistré dans Boralog|demoProjects|demoToday|data\/demo/);
});

test("future project areas are visibly non-interactive", () => {
  const source = fs.readFileSync("src/app/projets/reel/[projectId]/page.tsx", "utf8");
  for (const area of ["Informations", "Messages", "Équipe", "Documents"]) assert.match(source, new RegExp(area));
  assert.match(source, /<small>À venir<\/small>/);
  assert.doesNotMatch(source, /futureAreas\.map[\s\S]*?<Link|futureAreas\.map[\s\S]*?<button/);
});

test("Dates is the only interactive future project area", () => {
  const source = fs.readFileSync("src/app/projets/reel/[projectId]/page.tsx", "utf8");
  assert.match(source, /href=\{\`\/projets\/reel\/\$\{project\.id\}\/dates\`\}/);
  assert.match(source, /<span>Dates<\/span>/);
});

test("first real date UI keeps required fields and uses the extracted submit form", () => {
  const page = fs.readFileSync("src/app/projets/reel/[projectId]/dates/nouvelle/page.tsx", "utf8");
  const form = fs.readFileSync("src/app/projets/reel/[projectId]/dates/nouvelle/CreateDateForm.tsx", "utf8");
  assert.match(page, /import \{ CreateDateForm \} from "\.\/CreateDateForm"/);
  assert.match(page, /<CreateDateForm projectId=\{project\.id\}\/>/);
  assert.doesNotMatch(page, /\.insert\s*\(|demo/);
  assert.match(form, /name="date" type="date" required/);
  assert.match(form, /name="time" type="time"/);
  assert.match(form, /name="city"/);
  assert.match(form, /name="venue"/);
  assert.match(form, /<form className="date-create-form" action=\{action\}/);
  assert.match(form, /type="submit"/);
  assert.doesNotMatch(form, /demo/);
});

test("first real date insert is authenticated and project-bound", () => {
  const source = fs.readFileSync("src/app/projets/reel/[projectId]/dates/nouvelle/actions.ts", "utf8");
  assert.match(source, /supabase\.auth\.getUser\(\)/);
  assert.match(source, /from\("projects"\)[\s\S]*select\("id"\)[\s\S]*eq\("id", projectId\)/);
  assert.match(source, /from\("events"\)\.insert\(\{/);
  assert.match(source, /project_id: project\.id/);
  assert.match(source, /created_by: authData\.user\.id/);
  assert.match(source, /status: "draft"/);
  assert.doesNotMatch(source, /ends_at/);
});

test("first real date preserves optional time semantics", () => {
  const source = fs.readFileSync("src/app/projets/reel/[projectId]/dates/nouvelle/actions.ts", "utf8");
  assert.match(source, /const startsAt = time \? .* : null/);
  assert.match(source, /event_date: eventDate/);
  assert.match(source, /starts_at: startsAt/);
});

test("date form protects double submit and preserves values on error", () => {
  const source = fs.readFileSync("src/app/projets/reel/[projectId]/dates/nouvelle/CreateDateForm.tsx", "utf8");
  assert.match(source, /disabled=\{pending\}/);
  assert.match(source, /pending \? "Enregistrement…" : "Créer la date"/);
  assert.match(source, /defaultValue=\{state\.values\.date\}/);
  assert.match(source, /defaultValue=\{state\.values\.time\}/);
});

test("Dates page reads real events for the current project without demo data", () => {
  const source = fs.readFileSync("src/app/projets/reel/[projectId]/dates/page.tsx", "utf8");
  assert.match(source, /from\("events"\)/);
  assert.match(source, /\.eq\("project_id", project\.id\)/);
  assert.match(source, /dates\.length === 0/);
  assert.doesNotMatch(source, /demoToday|demoProjects|data\/demo/);
});


test("Message writer preserves INTERNAL provenance through the atomic RPC", () => {
  const source = fs.readFileSync("src/app/messages/actions.ts", "utf8");
  const migration = fs.readFileSync(
    "supabase/migrations/20261001141500_message_minimal_create_161.sql",
    "utf8"
  );

  assert.match(source, /\.rpc\("boralog_create_internal_message"/);
  assert.match(migration, /insert into public\.messages\([\s\S]*?created_by,[\s\S]*?origin_type,[\s\S]*?author_user_id/);
  assert.match(migration, /v_actor,[\s\S]*?'INTERNAL',[\s\S]*?v_actor/);
});

test("Message writer has no legacy provenance bridge after 155 rollout", () => {
  const source = fs.readFileSync("src/app/messages/actions.ts", "utf8");
  assert.doesNotMatch(source, /PGRST204/);
  assert.doesNotMatch(source, /isMissingProvenanceColumnError/);
  assert.doesNotMatch(source, /legacyInsertError|messageInsert/);
  assert.match(source, /\.rpc\("boralog_create_internal_message"/);
  assert.doesNotMatch(source, /\.from\("messages"\)\.insert/);
});
