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

test("real organization boundary does not render demo fixtures", () => {
  const shell = fs.readFileSync("src/components/AppShell.tsx", "utf8");
  assert.doesNotMatch(shell, /demoToday|demoProjects|src\/data\/demo/);
  assert.match(shell, /Aucun projet pour le moment/);
  assert.match(shell, /identity\.organization\.name/);
});

test("no-organization UX exposes creation CTA", () => {
  const shell = fs.readFileSync("src/components/AppShell.tsx", "utf8");
  assert.match(shell, /Vous n&apos;avez pas encore de structure/);
  assert.match(shell, /href="\/organisations\/nouvelle"/);
});

test("real organization empty state exposes first project CTA", () => {
  const shell = fs.readFileSync("src/components/AppShell.tsx", "utf8");
  assert.match(shell, /href="\/projets\/nouveau"/);
  assert.match(shell, /Créer un projet/);
});

test("project creation UI slice is deliberately write-free", () => {
  const source = fs.readFileSync("src/app/projets/nouveau/page.tsx", "utf8");
  assert.match(source, /name="name"/);
  assert.match(source, /name="description"/);
  assert.match(source, /type="button" disabled/);
  assert.doesNotMatch(source, /supabase|\.insert\s*\(|action=|useActionState/);
});
