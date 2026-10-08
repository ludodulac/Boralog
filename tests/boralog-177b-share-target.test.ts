import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";
import { buildSharedMessageDraft, safeInternalReturnPath } from "../src/lib/android-share.ts";

const manifest = readFileSync("src/app/manifest.ts", "utf8");
const receiver = readFileSync("src/app/partager/android/route.ts", "utf8");
const proxy = readFileSync("src/proxy.ts", "utf8");
const confirm = readFileSync("src/app/messages/partager/SharedMessageConfirmation.tsx", "utf8");
const action = readFileSync("src/app/messages/partager/actions.ts", "utf8");
const login = readFileSync("src/app/auth/connexion/page.tsx", "utf8");
const authForm = readFileSync("src/components/AuthForm.tsx", "utf8");
const normalMessageAction = readFileSync("src/app/messages/actions.ts", "utf8");
const cycleMigration = readFileSync("supabase/migrations/20261004065450_message_cycle_reconciliation_165r.sql", "utf8");

test("BORALOG-177B manifest exposes POST text share target and install icons", () => {
  assert.match(manifest, /name:\s*"BORALOG"/);
  assert.match(manifest, /short_name:\s*"BORALOG"/);
  assert.match(manifest, /start_url:\s*"\/"/);
  assert.match(manifest, /scope:\s*"\/"/);
  assert.match(manifest, /display:\s*"standalone"/);
  assert.match(manifest, /action:\s*"\/partager\/android"/);
  assert.match(manifest, /method:\s*"POST"/);
  assert.match(manifest, /application\/x-www-form-urlencoded/);
  assert.match(manifest, /boralog-192\.png/);
  assert.match(manifest, /boralog-512\.png/);
});

test("BORALOG-177B share draft prefers text and does not duplicate title", () => {
  assert.equal(buildSharedMessageDraft({ title: "Titre", text: "Texte", url: "https://x.test" }), "Titre\n\nTexte");
  assert.equal(buildSharedMessageDraft({ title: "Texte", text: "Texte" }), "Texte");
  assert.equal(buildSharedMessageDraft({ url: "https://x.test" }), "https://x.test");
  assert.equal(buildSharedMessageDraft({}), "");
});

test("BORALOG-177B receiver keeps content out of URL and stores session draft", () => {
  assert.match(receiver, /request\.formData\(\)/);
  assert.match(receiver, /sessionStorage\.setItem/);
  assert.match(receiver, /location\.replace\("\/messages\/partager"\)/);
  assert.doesNotMatch(receiver, /searchParams\.set|URLSearchParams/);
  assert.match(receiver, /Aucun texte à partager/);
});

test("BORALOG-177B only exact Android receiver bypasses auth", () => {
  assert.match(proxy, /pathname === "\/partager\/android"/);
  assert.match(proxy, /updateSession/);
  assert.match(proxy, /url\.pathname = "\/auth\/connexion"/);
});

test("BORALOG-177B auth return accepts internal paths and rejects open redirects", () => {
  assert.equal(safeInternalReturnPath("/messages/partager"), "/messages/partager");
  assert.equal(safeInternalReturnPath("/messages/partager?x=1"), "/messages/partager?x=1");
  assert.equal(safeInternalReturnPath("//evil.example"), "/");
  assert.equal(safeInternalReturnPath("https://evil.example"), "/");
  assert.equal(safeInternalReturnPath("http://evil.example"), "/");
  assert.equal(safeInternalReturnPath("\\\\evil.example"), "/");
  assert.match(login, /safeInternalReturnPath/);
  assert.match(authForm, /router\.replace\(safeReturnTo\)/);
});

test("BORALOG-177B confirmation reads editable session draft and asks source", () => {
  assert.match(confirm, /sessionStorage\.getItem/);
  assert.match(confirm, /textarea/);
  assert.match(confirm, /onChange/);
  assert.match(confirm, /value="WHATSAPP"/);
  assert.match(confirm, /value="OTHER"/);
  assert.match(confirm, /ne la détecte pas automatiquement/);
  assert.match(confirm, /sessionStorage\.removeItem/);
  assert.match(confirm, /router\.replace\("\/"\)/);
});

test("BORALOG-177B dedicated insert is EXTERNAL_MANUAL only", () => {
  assert.match(action, /getCurrentIdentity/);
  assert.match(action, /accessLevel !== "owner"[\s\S]*accessLevel !== "full"/);
  assert.match(action, /origin_type:\s*"EXTERNAL_MANUAL"/);
  assert.match(action, /source_kind:\s*sourceKind/);
  assert.match(action, /created_by:\s*identity\.userId/);
  assert.match(action, /author_user_id:\s*null/);
  assert.match(action, /external_author_label:\s*null/);
  assert.match(action, /source_occurred_at:\s*null/);
  assert.match(action, /visibility:\s*"ORGANIZATION"/);
  assert.match(action, /project_id:\s*null/);
  assert.match(action, /event_id:\s*null/);
  assert.match(action, /status:\s*"TO_PROCESS"/);
  assert.doesNotMatch(action, /service_role|SUPABASE_SECRET_KEY|boralog_create_internal_message/);
});

test("BORALOG-177B normal INTERNAL Message flow and reversible cycle remain present", () => {
  assert.match(normalMessageAction, /boralog_create_internal_message/);
  assert.match(cycleMigration, /PROCESSED_TO_TO_PROCESS|new\.status = 'TO_PROCESS'|new\.processed_at := null/);
  assert.match(cycleMigration, /boralog_add_message_note/);
});

test("BORALOG-177B adds no database migration", () => {
  const migrations = readdirSync("supabase/migrations");
  assert.doesNotMatch(migrations.join("\n"), /177b|share_target|android_share/i);
});
