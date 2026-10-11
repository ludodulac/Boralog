import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";

const menu = readFileSync("src/components/SecondaryMenu.tsx", "utf8");
const page = readFileSync("src/app/parametres/page.tsx", "utf8");
const actions = readFileSync("src/app/parametres/actions.ts", "utf8");

test("BORALOG-171A hamburger links to Parameters", () => {
  assert.match(menu, /href="\/parametres"/);
  assert.doesNotMatch(menu, /Paramètres<\/span><small>Bientôt disponible/);
});

test("BORALOG-171A Parameters page separates account, profile and Structure", () => {
  assert.match(page, /MON PROFIL \/ MON COMPTE/);
  assert.match(page, /identity\.email/);
  assert.match(page, /href="\/moi"/);
  assert.match(page, /MA STRUCTURE/);
  assert.match(page, /identity\.organization\?\.name/);
});

test("BORALOG-171A rename action uses canonical current organization and OWNER only", () => {
  assert.match(actions, /getCurrentIdentity/);
  assert.match(actions, /identity\.organization\.accessLevel !== "owner"/);
  assert.match(actions, /\.update\(\{ name: normalized\.value \}\)/);
  assert.match(actions, /\.eq\("id", identity\.organization\.id\)/);
  assert.doesNotMatch(actions, /formData\.get\("organization_id"\)/);
  assert.doesNotMatch(actions, /slug\s*:/);
  assert.doesNotMatch(actions, /created_by|created_at/);
});

test("BORALOG-171A FULL and LIMITED cannot invoke rename successfully", () => {
  assert.match(page, /identity\.organization\.accessLevel === "owner"/);
  assert.match(page, /Seul un OWNER peut renommer la Structure/);
  assert.match(actions, /Seul un OWNER peut renommer la Structure/);
});

test("BORALOG-171A reuses canonical organization name normalization", () => {
  assert.match(actions, /normalizeOrganizationName/);
});

test("BORALOG-171A adds no migration", () => {
  const migrationNames = readdirSync("supabase/migrations");
  assert.doesNotMatch(migrationNames.join("\n"), /171a|parametres|settings/i);
});
