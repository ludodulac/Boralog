// BORALOG-DEMO-002A — execute the repository's actual TypeScript module in Chromium.
// Run with: npm install --no-save playwright && npx playwright install chromium && node tests/demo-indexeddb-browser.mjs
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { createServer } from "node:http";
import ts from "typescript";
import { chromium } from "playwright";

const source = readFileSync(new URL("../src/lib/demo/local-db.ts", import.meta.url), "utf8");
const compiled = ts.transpileModule(source, { compilerOptions: { target: ts.ScriptTarget.ES2022, module: ts.ModuleKind.ES2022 } }).outputText;
const server = createServer((req, res) => {
  res.setHeader("Content-Type", req.url === "/local-db.js" ? "text/javascript" : "text/html");
  res.end(req.url === "/local-db.js" ? compiled : "<!doctype html><html><body>IndexedDB browser harness</body></html>");
});
await new Promise(resolve => server.listen(0, "127.0.0.1", resolve));
const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();
try {
  const url = `http://127.0.0.1:${server.address().port}/`;
  await page.goto(url);
  const initial = await page.evaluate(async () => {
    const m = await import("/local-db.js");
    const db = await m.openDemoDatabase();
    await m.initializeDemo(db);
    await m.initializeDemo(db);
    const users = await m.listRecords(db, "users");
    const orgs = await m.listRecords(db, "organizations");
    const id = "00000000-0000-4000-8000-000000000004";
    await m.mutateDemo(db, [{ operation: "create", store: "projects", id, value: { id, organization_id: m.DEMO_ORG_ID, name: "Avant" } }]);
    await m.mutateDemo(db, [{ operation: "update", store: "projects", id, value: { id, organization_id: m.DEMO_ORG_ID, name: "Après" } }]);
    let invalidRelationRejected = false;
    try {
      await m.mutateDemo(db, [{ operation: "create", store: "projects", id: "bad", value: { id: "bad", organization_id: "missing", name: "Invalid" } }]);
    } catch { invalidRelationRejected = true; }
    let deleteProtected = false;
    try { await m.mutateDemo(db, [{ operation: "delete", store: "organizations", id: m.DEMO_ORG_ID }]); }
    catch { deleteProtected = true; }
    db.close();
    return { users, orgs, invalidRelationRejected, deleteProtected };
  });
  assert.equal(initial.users.length, 1);
  assert.equal(initial.users[0].display_name, "Démonstrateur");
  assert.equal(initial.orgs.length, 1);
  assert.equal(initial.orgs[0].name, "Compagnie Horizon");
  assert.ok(initial.invalidRelationRejected);
  assert.ok(initial.deleteProtected);
  await page.reload();
  const afterReload = await page.evaluate(async () => {
    const m = await import("/local-db.js");
    const db = await m.openDemoDatabase();
    await m.initializeDemo(db);
    const users = await m.listRecords(db, "users");
    const orgs = await m.listRecords(db, "organizations");
    const projects = await m.listRecords(db, "projects");
    const id = "00000000-0000-4000-8000-000000000004";
    const beforeDelete = await m.getRecord(db, "projects", id);
    await m.mutateDemo(db, [{ operation: "delete", store: "projects", id }]);
    const afterDelete = await m.getRecord(db, "projects", id);
    db.close();
    return { users: users.length, orgs: orgs.length, projects: projects.length, beforeDelete, afterDelete };
  });
  assert.equal(afterReload.users, 1);
  assert.equal(afterReload.orgs, 1);
  assert.equal(afterReload.projects, 1);
  assert.equal(afterReload.beforeDelete.name, "Après");
  assert.equal(afterReload.afterDelete, undefined);
  console.log("BORALOG-DEMO-002A Chromium IndexedDB PASS");
} finally {
  await browser.close();
  await new Promise(resolve => server.close(resolve));
}
