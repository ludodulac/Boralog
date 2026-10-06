import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const nav = readFileSync("src/components/MainNavigation.tsx", "utf8");
const peopleList = readFileSync("src/app/personnes/page.tsx", "utf8");
const peopleActions = readFileSync("src/app/personnes/actions.ts", "utf8");
const personDetail = readFileSync("src/app/personnes/[id]/page.tsx", "utf8");
const personForms = readFileSync("src/app/personnes/[id]/PersonDetailForms.tsx", "utf8");
const messageDetail = readFileSync("src/app/messages/[id]/page.tsx", "utf8");

test("BORALOG-170B navigation exposes Personnes", () => {
  assert.match(nav, /"Personnes", "\/personnes"/);
  assert.match(nav, /label === "Personnes"/);
});

test("BORALOG-170B Person UI uses existing business fields only", () => {
  assert.match(peopleList, /organization_membership_id/);
  for (const field of ["name", "role_label", "professional_email", "professional_phone"]) {
    assert.match(peopleActions, new RegExp(field));
  }
  assert.doesNotMatch(peopleActions, /\.insert\(\{[\s\S]*organization_id:\s*readString/);
  assert.match(peopleActions, /organization_id: actor\.organizationId/);
  assert.match(peopleActions, /created_by: actor\.userId/);
});

test("BORALOG-170B companies use canonical tables for link and unlink", () => {
  assert.match(peopleActions, /from\("person_companies"\)\.insert/);
  assert.match(peopleActions, /from\("person_companies"\)\.delete/);
  assert.match(peopleActions, /from\("companies"\)[\s\S]*\.insert/);
  assert.match(personForms, /Créer et associer/);
});

test("BORALOG-170B account linking only accepts active same-organization memberships", () => {
  assert.match(peopleActions, /from\("organization_memberships"\)/);
  assert.match(peopleActions, /\.eq\("organization_id", actor\.organizationId\)/);
  assert.match(peopleActions, /\.eq\("status", "active"\)/);
  assert.match(peopleActions, /organization_membership_id: nextMembershipId/);
  assert.match(peopleActions, /organization_membership_id: nextMembershipId/);
});

test("BORALOG-170B keeps LIMITED outside Person management", () => {
  assert.match(peopleActions, /\.in\("access_level", \["owner", "full"\]\)/);
  assert.match(peopleList, /accessLevel === "owner"[\s\S]*accessLevel === "full"/);
  assert.match(personDetail, /accessLevel === "owner"[\s\S]*accessLevel === "full"/);
});

test("BORALOG-170B Message resolves internal author through membership then Person and Companies", () => {
  assert.match(messageDetail, /organization_memberships/);
  assert.match(messageDetail, /organization_membership_id/);
  assert.match(messageDetail, /person_companies/);
  assert.match(messageDetail, /companies/);
  assert.match(messageDetail, /origin_type === "INTERNAL"/);
});

test("BORALOG-170B Message preserves profile fallback and external source behavior", () => {
  assert.match(messageDetail, /authorProfile\?\.display_name/);
  assert.match(messageDetail, /external_author_label/);
  assert.match(messageDetail, /MessageDetailActions/);
  assert.match(messageDetail, /Marquer traité|MessageDetailActions/);
});
