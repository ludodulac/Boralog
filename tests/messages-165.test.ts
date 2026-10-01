import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const messagesPage = readFileSync("src/app/messages/page.tsx","utf8");
const processPage = readFileSync("src/app/messages/[id]/traiter/page.tsx","utf8");
const processForm = readFileSync("src/app/messages/[id]/traiter/ProcessMessageForm.tsx","utf8");
const processActions = readFileSync("src/app/messages/[id]/traiter/actions.ts","utf8");
const migration = readFileSync("supabase/migrations/20261001214500_message_processing_flow_165.sql","utf8");

test("BORALOG-165 Messages list shows only TO_PROCESS with Traiter action",()=>{
  assert.match(messagesPage,/\.eq\("status", "TO_PROCESS"\)/);
  assert.match(messagesPage,/href=\{\`\/messages\/\$\{message\.id\}\/traiter\`\}/);
  assert.match(messagesPage,/>\s*Traiter\s*</);
});

test("BORALOG-165 dedicated route renders source read-only and the human choices",()=>{
  assert.match(processPage,/Traiter ce message/);
  assert.match(processPage,/Message source/);
  assert.match(processPage,/message\.content/);
  assert.match(processForm,/\+ Créer une information/);
  assert.match(processForm,/\+ Créer une tâche/);
  assert.match(processForm,/Sans suite/);
  assert.match(processForm,/Terminer le traitement/);
});

test("BORALOG-165 drafts stay client-side until the final atomic RPC",()=>{
  assert.doesNotMatch(processForm,/\.rpc\(/);
  assert.match(processActions,/\.rpc\("boralog_process_message"/);
  assert.doesNotMatch(processActions,/boralog_create_information|boralog_create_task/);
});

test("BORALOG-165 supports multiple Information and Task drafts",()=>{
  assert.match(processForm,/setInformationFields\(\(fields\) => \[\.\.\.fields, nextId\.current\+\+\]\)/);
  assert.match(processForm,/setTaskFields\(\(fields\) => \[\.\.\.fields, nextId\.current\+\+\]\)/);
  assert.match(processForm,/name="information_contents"/);
  assert.match(processForm,/name="task_contents"/);
});

test("BORALOG-165 Sans suite is exclusive and clears consequence drafts",()=>{
  assert.match(processForm,/setNoFollowUp\(true\)/);
  assert.match(processForm,/setInformationFields\(\[\]\)/);
  assert.match(processForm,/setTaskFields\(\[\]\)/);
  assert.match(processActions,/NO_FOLLOW_UP/);
  assert.match(processActions,/Sans suite ne peut pas contenir de conséquence/);
});

test("BORALOG-165 does not ask for a second Project or Date context",()=>{
  assert.doesNotMatch(processForm,/project_id|event_id|Contexte facultatif|Choisir un projet|Choisir une date/);
  assert.doesNotMatch(processActions,/p_project_id|p_event_id/);
});

test("BORALOG-165 unified DB RPC inherits context and uses canonical consequences",()=>{
  assert.match(migration,/public\.boralog_create_information/);
  assert.match(migration,/public\.boralog_create_task/);
  assert.match(migration,/v_message\.event_id/);
  assert.match(migration,/v_message\.project_id/);
  assert.match(migration,/array\[v_message\.id\]/);
});

test("BORALOG-165 keeps old no-follow-up RPC as a strict wrapper",()=>{
  assert.match(migration,/create or replace function public\.boralog_close_message_no_follow_up/);
  assert.match(migration,/public\.boralog_process_message/);
  assert.match(migration,/'NO_FOLLOW_UP'/);
});

test("BORALOG-165 adds no frontend service role",()=>{
  const combined=[messagesPage,processPage,processForm,processActions].join("\n");
  assert.doesNotMatch(combined,/SUPABASE_SERVICE_ROLE|service_role|serviceRole/);
});
