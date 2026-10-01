import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const actions = readFileSync("src/app/messages/actions.ts", "utf8");
const form = readFileSync("src/app/messages/CreateMessageForm.tsx", "utf8");
const page = readFileSync("src/app/messages/page.tsx", "utf8");

test("BORALOG-162 keeps Message -> audience -> optional context -> save", () => {
  const messageIndex = form.indexOf("Message");
  const audienceIndex = form.indexOf("Qui peut le lire ?");
  const contextIndex = form.indexOf("Contexte facultatif");
  const saveIndex = form.lastIndexOf("Enregistrer");

  assert.ok(messageIndex >= 0);
  assert.ok(audienceIndex > messageIndex);
  assert.ok(contextIndex > audienceIndex);
  assert.ok(saveIndex > contextIndex);
});

test("BORALOG-162 exposes exactly none, project, or date context modes", () => {
  assert.match(form, /value="NONE"/);
  assert.match(form, /value="PROJECT"/);
  assert.match(form, /value="DATE"/);
  assert.match(form, />Aucun</);
  assert.match(form, />Projet</);
  assert.match(form, />Date</);
});

test("BORALOG-162 never renders Project and Date selectors at the same time", () => {
  assert.match(form, /contextMode === "PROJECT"/);
  assert.match(form, /name="project_id"/);
  assert.match(form, /contextMode === "DATE"/);
  assert.match(form, /name="event_id"/);
  assert.doesNotMatch(form, /name="project_id"[\s\S]*name="event_id"[\s\S]*contextMode ===/);
});

test("BORALOG-162 submits context only through the atomic Message RPC", () => {
  assert.match(actions, /\.rpc\("boralog_create_internal_message"/);
  assert.match(actions, /p_project_id:/);
  assert.match(actions, /p_event_id:/);
  assert.doesNotMatch(actions, /\.from\("messages"\)\.insert/);
  assert.doesNotMatch(actions, /\.from\("message_recipients"\)\.insert/);
});

test("BORALOG-162 validates manually supplied context shape", () => {
  assert.match(actions, /contextMode === "NONE" && \(projectId \|\| eventId\)/);
  assert.match(actions, /contextMode === "PROJECT" && \(!isUuid\(projectId\) \|\| eventId\)/);
  assert.match(actions, /contextMode === "DATE" && \(!isUuid\(eventId\) \|\| projectId\)/);
});

test("BORALOG-162 reuses real project and event sources", () => {
  assert.match(page, /\.from\("projects"\)/);
  assert.match(page, /\.from\("events"\)/);
  assert.match(page, /\.in\("project_id", accessibleProjectIds\)/);
});

test("BORALOG-162 does not introduce frontend service role", () => {
  const combined = [actions, form, page].join("\n");
  assert.doesNotMatch(combined, /service_role|SUPABASE_SERVICE_ROLE|serviceRole/);
});

test("BORALOG-162 does not introduce forbidden next-contract surfaces", () => {
  const combined = [actions, form, page].join("\n");
  assert.doesNotMatch(combined, /pièces jointes|commentaires|threads|recherche globale/i);
});


test("BORALOG-162 keeps LIMITED organization audience gated by context", () => {
  assert.match(form, /organizationRequiresContext && contextMode === "NONE"/);
  assert.match(page, /organizationRequiresContext = identity\.organization\.accessLevel === "limited"/);
  assert.match(page, /hasContextOptions = projectOptions\.length > 0 \|\| dateOptions\.length > 0/);
});
