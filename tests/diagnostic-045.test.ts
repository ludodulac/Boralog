import test from "node:test";
import assert from "node:assert/strict";
import { buildAuthenticatedIdentity } from "../src/lib/current-identity.ts";

const userId = "11111111-1111-4111-8111-111111111111";
const profile = { id: userId, display_name: "Profil Test", professional_email: null, professional_phone: null };

test("TEMPORARY DO NOT MERGE 045: authenticated profile with no memberships", () => {
  const result = buildAuthenticatedIdentity({ userId, email: "synthetic@example.invalid", profile, membershipRows: [] });
  assert.deepEqual(result, { userId, email: "synthetic@example.invalid", profile, organization: null, hasOrganization: false });
  assert.equal(Object.hasOwn(result, "organization"), true);
  assert.equal(Object.hasOwn(result, "hasOrganization"), true);
});

test("TEMPORARY DO NOT MERGE 045: authenticated profile with owner organization", () => {
  const result = buildAuthenticatedIdentity({ userId, email: null, profile, membershipRows: [{
    organization_id: "22222222-2222-4222-8222-222222222222",
    access_level: "owner",
    organizations: { id: "22222222-2222-4222-8222-222222222222", name: "Structure Test" },
  }] });
  assert.equal(result.organization?.accessLevel, "owner");
  assert.equal(result.organization?.name, "Structure Test");
  assert.equal(result.hasOrganization, true);
});
