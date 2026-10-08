import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const home = readFileSync("src/app/page.tsx", "utf8");
const button = readFileSync("src/components/ImportClipboardButton.tsx", "utf8");
const confirm = readFileSync("src/app/messages/partager/SharedMessageConfirmation.tsx", "utf8");
const action = readFileSync("src/app/messages/partager/actions.ts", "utf8");
const helper = readFileSync("src/lib/android-share.ts", "utf8");

test("BORALOG-177C Today exposes clipboard import", () => {
  assert.match(home, /ImportClipboardButton/);
  assert.match(button, /Importer le texte copié/);
  assert.match(button, /Copiez un message dans WhatsApp, puis appuyez ici/);
});

test("BORALOG-177C reads clipboard only from explicit click handler", () => {
  assert.match(button, /async function importClipboard\(\)/);
  assert.match(button, /navigator\.clipboard\?\.readText/);
  assert.match(button, /onClick=\{\(\) => void importClipboard\(\)\}/);
  assert.doesNotMatch(button, /useEffect/);
  assert.doesNotMatch(button, /setInterval|setTimeout|requestAnimationFrame/);
});

test("BORALOG-177C reuses shared session draft and opens confirmation", () => {
  assert.match(helper, /boralog:shared-message:v1/);
  assert.match(button, /SHARED_MESSAGE_STORAGE_KEY/);
  assert.match(button, /sessionStorage\.setItem\(SHARED_MESSAGE_STORAGE_KEY, text\)/);
  assert.match(button, /router\.push\("\/messages\/partager"\)/);
});

test("BORALOG-177C handles empty, denied and unavailable clipboard", () => {
  assert.match(button, /Aucun texte copié\. Copiez d’abord un message puis réessayez\./);
  assert.match(button, /BORALOG n’a pas pu lire le presse-papiers\. Copiez le message puis réessayez\./);
  assert.match(button, /if \(!navigator\.clipboard\?\.readText\)/);
  assert.match(button, /catch \{/);
});

test("BORALOG-177C button never writes to database", () => {
  assert.doesNotMatch(button, /supabase|\.from\(|\.insert\(|rpc\(/);
});

test("BORALOG-177C existing confirmation and EXTERNAL_MANUAL flow remain intact", () => {
  assert.match(confirm, /sessionStorage\.getItem/);
  assert.match(confirm, /value="WHATSAPP"/);
  assert.match(confirm, /value="OTHER"/);
  assert.match(action, /origin_type:\s*"EXTERNAL_MANUAL"/);
  assert.match(action, /source_kind:\s*sourceKind/);
  assert.match(action, /status:\s*"TO_PROCESS"/);
  assert.match(action, /visibility:\s*"ORGANIZATION"/);
  assert.match(action, /project_id:\s*null/);
  assert.match(action, /event_id:\s*null/);
});
