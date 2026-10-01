import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";

const migration = readFileSync("supabase/migrations/20261001173500_task_foundation_164.sql","utf8");

function readTree(root:string):string{
  return readdirSync(root).flatMap((name)=>{
    const p=join(root,name);
    return statSync(p).isDirectory()?[readTree(p)]:[readFileSync(p,"utf8")];
  }).join("\n");
}
const frontend=readTree("src");

test("BORALOG-164 creates canonical Task and N:N Message provenance",()=>{
  assert.match(migration,/create table public\.tasks/);
  assert.match(migration,/create table public\.task_message_sources/);
  assert.match(migration,/primary key \(task_id, message_id\)/);
});

test("BORALOG-164 keeps the closed TO_DO DONE status model",()=>{
  assert.match(migration,/tasks_status_check/);
  assert.match(migration,/status in \('TO_DO','DONE'\)/);
  assert.match(migration,/tasks_completion_metadata_check/);
});

test("BORALOG-164 uses atomic create and secure status RPCs",()=>{
  assert.match(migration,/create or replace function public\.boralog_create_task/);
  assert.match(migration,/create or replace function public\.boralog_set_task_status/);
  assert.match(migration,/completed_at=now\(\), completed_by=v_actor/);
  assert.match(migration,/completed_at=null, completed_by=null/);
});

test("BORALOG-164 source provenance visibility requires Task and Message access",()=>{
  assert.match(migration,/task source visible only with both objects/);
  assert.match(migration,/from public\.tasks t where t\.id=task_id/);
  assert.match(migration,/from public\.messages m where m\.id=message_id/);
});

test("BORALOG-164 never mutates Message or Information objects",()=>{
  assert.doesNotMatch(migration,/update\s+public\.messages/i);
  assert.doesNotMatch(migration,/update\s+public\.informations/i);
  assert.doesNotMatch(migration,/insert into public\.informations/i);
});

test("BORALOG-164 adds no frontend service role or UI",()=>{
  assert.doesNotMatch(frontend,/SUPABASE_SERVICE_ROLE|service_role|serviceRole/);
  assert.doesNotMatch(frontend,/boralog_create_task|boralog_set_task_status/);
});
