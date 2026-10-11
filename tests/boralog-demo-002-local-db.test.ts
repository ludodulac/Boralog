import test from "node:test";
import assert from "node:assert/strict";
import { DB_NAME, DB_VERSION, STORE_NAMES, SEED, RELATIONS, DEMO_ORG_ID, DEMO_USER_ID, initializeDemo, openDemoDatabase, getRecord, listRecords, mutateDemo } from "../src/lib/demo/local-db.ts";

test("demo schema declares all core collections", () => {
  assert.equal(DB_NAME, "boralog-demo");
  assert.equal(DB_VERSION, 1);
  assert.equal(STORE_NAMES.length, 20);
  for (const store of ["organizations","users","organization_memberships","projects","people","companies","person_companies","messages","message_notes","message_status_history","informations","tasks","events"]) assert.ok(STORE_NAMES.includes(store as typeof STORE_NAMES[number]));
});
test("seed is deterministic and relationally coherent", () => {
  assert.equal(SEED.length, 3);
  assert.equal(new Set(SEED.map(row => row.value.id)).size, SEED.length);
  assert.equal(SEED.find(row => row.store === "users")?.value.display_name, "Démonstrateur");
  assert.equal(SEED.find(row => row.store === "organizations")?.value.name, "Compagnie Horizon");
  const membership = SEED.find(row => row.store === "organization_memberships")?.value;
  assert.equal(membership?.organization_id, DEMO_ORG_ID);
  assert.equal(membership?.user_id, DEMO_USER_ID);
  assert.equal(membership?.access_level, "owner");
  for (const row of SEED) for (const relation of RELATIONS[row.store] ?? []) {
    assert.ok(SEED.some(candidate => candidate.store === relation.target && candidate.value.id === row.value[relation.field]));
  }
});
test("IndexedDB persistence, idempotence, CRUD and FK enforcement (browser runtime)", { skip: typeof indexedDB === "undefined" ? "Node has no IndexedDB; run this test in a browser-equipped runtime" : false }, async () => {
  const db = await openDemoDatabase();
  try {
    await initializeDemo(db);
    await initializeDemo(db);
    assert.equal((await listRecords(db, "users")).length, 1);
    const id = "00000000-0000-4000-8000-000000000004";
    await mutateDemo(db, [{ operation: "create", store: "projects", id, value: { id, organization_id: DEMO_ORG_ID, name: "Projet de test" } }]);
    await mutateDemo(db, [{ operation: "update", store: "projects", id, value: { id, organization_id: DEMO_ORG_ID, name: "Projet modifié" } }]);
    db.close();
    const reopened = await openDemoDatabase();
    try {
      assert.equal((await getRecord(reopened, "projects", id))?.name, "Projet modifié");
      await assert.rejects(mutateDemo(reopened, [{ operation: "delete", store: "organizations", id: DEMO_ORG_ID }]));
      await mutateDemo(reopened, [{ operation: "delete", store: "projects", id }]);
      assert.equal(await getRecord(reopened, "projects", id), undefined);
    } finally { reopened.close(); }
  } finally { db.close(); }
});
