import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";

const migration = readFileSync(
  "supabase/migrations/20261001163000_information_foundation_163.sql",
  "utf8"
);

function readTree(root: string): string {
  return readdirSync(root)
    .flatMap((name) => {
      const path = join(root, name);
      return statSync(path).isDirectory() ? [readTree(path)] : [readFileSync(path, "utf8")];
    })
    .join("\n");
}

const frontend = readTree("src");

test("BORALOG-163 creates canonical Information and N:N Message provenance", () => {
  assert.match(migration, /create table public\.informations/);
  assert.match(migration, /create table public\.information_message_sources/);
  assert.match(migration, /primary key \(information_id, message_id\)/);
});

test("BORALOG-163 keeps Information content human-owned and non-empty", () => {
  assert.match(migration, /informations_content_nonempty_check/);
  assert.doesNotMatch(migration, /insert into public\.informations[\s\S]*select[\s\S]*message\.content/i);
});

test("BORALOG-163 uses one atomic Information creation RPC", () => {
  assert.match(migration, /create or replace function public\.boralog_create_information/);
  assert.match(migration, /insert into public\.informations/);
  assert.match(migration, /insert into public\.information_message_sources/);
});

test("BORALOG-163 provenance visibility requires Information and Message access", () => {
  assert.match(migration, /information source visible only with both objects/);
  assert.match(migration, /from public\.informations as i/);
  assert.match(migration, /from public\.messages as m/);
});

test("BORALOG-163 does not change Message processing semantics", () => {
  assert.doesNotMatch(migration, /update\s+public\.messages/i);
  assert.doesNotMatch(migration, /processed_at\s*=/i);
  assert.doesNotMatch(migration, /processed_by\s*=/i);
});

test("BORALOG-163 adds no frontend service role", () => {
  assert.doesNotMatch(frontend, /SUPABASE_SERVICE_ROLE|service_role|serviceRole/);
});
