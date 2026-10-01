import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const actions = readFileSync("src/app/messages/actions.ts", "utf8");
const form = readFileSync("src/app/messages/CreateMessageForm.tsx", "utf8");
const page = readFileSync("src/app/messages/page.tsx", "utf8");

test("BORALOG-161 uses the atomic RPC rather than a two-step client write", () => {
  assert.match(actions, /\.rpc\("boralog_create_internal_message"/);
  assert.doesNotMatch(actions, /\.from\("messages"\)\.insert/);
  assert.doesNotMatch(actions, /\.from\("message_recipients"\)\.insert/);
});

test("BORALOG-161 rejects a restricted Message with zero selected people", () => {
  assert.match(actions, /visibility === "RESTRICTED" && recipientUserIds\.length === 0/);
  assert.match(actions, /Choisissez au moins une personne\./);
});

test("BORALOG-161 keeps the form minimal", () => {
  assert.match(form, /Toute l’organisation/);
  assert.match(form, /Personnes choisies/);
  assert.match(form, /"Enregistrer"/);
  assert.doesNotMatch(form, /project_id|event_id|recipient_group|Information|Tâche/);
});

test("BORALOG-161 reuses the secure recipient directory", () => {
  assert.match(page, /boralog_message_recipient_directory/);
  assert.match(page, /user_id/);
  assert.match(page, /display_name/);
});

test("BORALOG-161 does not introduce a frontend service role", () => {
  const combined = [actions, form, page].join("\n");
  assert.doesNotMatch(combined, /service_role|SUPABASE_SERVICE_ROLE|serviceRole/);
});
