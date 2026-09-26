import test from "node:test";
import assert from "node:assert/strict";
import { normalizeOrganizationName, organizationSlug } from "../src/lib/organization-onboarding.ts";
import fs from "node:fs";

const attemptA = "123e4567-e89b-42d3-a456-426614174000";
const attemptB = "223e4567-e89b-42d3-a456-426614174000";

test("empty organization name is rejected", () => {
  assert.ok("error" in normalizeOrganizationName("   "));
});

test("valid organization name is normalized", () => {
  assert.deepEqual(normalizeOrganizationName("  Compagnie   Bora Bora  "), { value: "Compagnie Bora Bora" });
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
