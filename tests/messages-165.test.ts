import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const messagesPage = readFileSync("src/app/messages/page.tsx","utf8");
const detailPage = readFileSync("src/app/messages/[id]/page.tsx","utf8");
const detailActions = readFileSync("src/app/messages/[id]/actions.ts","utf8");
const detailClient = readFileSync("src/app/messages/[id]/MessageDetailActions.tsx","utf8");
const legacyRoute = readFileSync("src/app/messages/[id]/traiter/page.tsx","utf8");
const legacyMigration = readFileSync("supabase/migrations/20261002052307_message_processing_flow_165.sql","utf8");
const reconciliationMigration = readFileSync("supabase/migrations/20261003163000_message_cycle_reconciliation_165r.sql","utf8");
const appShell = readFileSync("src/components/AppShell.tsx","utf8");
const foundationWorkflow = readFileSync(".github/workflows/foundation-build.yml","utf8");

test("BORALOG-165R inbox defaults to all accessible statuses with simple filters",()=>{
  assert.doesNotMatch(messagesPage,/\.eq\("status", "TO_PROCESS"\)[\s\S]*\.order\("created_at"/);
  assert.match(messagesPage,/href="\/messages">Tous</);
  assert.match(messagesPage,/href="\/messages\?etat=to-process">À traiter</);
  assert.match(messagesPage,/href="\/messages\?etat=processed">Traités</);
  assert.match(messagesPage,/message_notes/);
  assert.match(messagesPage,/message\.id/);
});

test("BORALOG-165R canonical detail route accepts both Message states",()=>{
  assert.match(detailPage,/Fiche Message/);
  assert.match(detailPage,/Source originale/);
  assert.match(detailPage,/Notes/);
  assert.doesNotMatch(detailPage,/\.eq\("status", "TO_PROCESS"\)/);
  assert.doesNotMatch(detailPage,/\.eq\("status", "PROCESSED"\)/);
  assert.match(detailPage,/MessageDetailActions/);
});

test("BORALOG-165R uses independent Note and status RPCs",()=>{
  assert.match(detailActions,/\.rpc\("boralog_add_message_note"/);
  assert.match(detailActions,/\.rpc\("boralog_set_message_status"/);
  assert.doesNotMatch(detailActions,/boralog_process_message/);
  assert.match(detailClient,/Marquer traité/);
  assert.match(detailClient,/Remettre à traiter/);
});

test("BORALOG-165R Note content remains in FormData while pending",()=>{
  assert.match(detailClient,/name="content"[\s\S]*readOnly=\{notePending\}/);
  assert.doesNotMatch(detailClient,/name="content"[\s\S]{0,180}disabled=\{notePending\}/);
});

test("BORALOG-165R old traiter route redirects to canonical Message detail",()=>{
  assert.match(legacyRoute,/redirect/);
  assert.match(legacyRoute,/\/messages\//);
  assert.doesNotMatch(legacyRoute,/ProcessMessageForm|boralog_process_message/);
});

test("BORALOG-165R keeps migration 165 historical and supersedes append-only",()=>{
  assert.match(legacyMigration,/processed message cannot be reopened/);
  assert.match(reconciliationMigration,/create table public\.message_notes/);
  assert.match(reconciliationMigration,/create table public\.message_status_history/);
  assert.match(reconciliationMigration,/public\.boralog_add_message_note/);
  assert.match(reconciliationMigration,/public\.boralog_set_message_status/);
  assert.match(reconciliationMigration,/resolution is legacy 144\/165 history/);
  assert.doesNotMatch(reconciliationMigration,/set status = p_status,\s*resolution = null/);
  assert.doesNotMatch(reconciliationMigration,/new\.resolution := null/);
});

test("BORALOG-165R AppShell no longer maintains a product-route allowlist",()=>{
  assert.doesNotMatch(appShell,/isMessagesRoute|isCalendarRoute|isRealProjectRoute|isProjectCreationRoute/);
  assert.match(appShell,/\) : children\}/);
});

test("Foundation build runs test, lint and build",()=>{
  assert.match(foundationWorkflow,/- run: npm test/);
  assert.match(foundationWorkflow,/- run: npm run lint/);
  assert.match(foundationWorkflow,/- run: npm run build/);
  assert.match(foundationWorkflow,/message-cycle-browser\.mjs/);
});
