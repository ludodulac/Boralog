import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const page = readFileSync("src/app/messages/partager/page.tsx", "utf8");
const combobox = readFileSync("src/app/messages/partager/PersonSenderCombobox.tsx", "utf8");
const action = readFileSync("src/app/messages/partager/actions.ts", "utf8");
const detail = readFileSync("src/app/messages/[id]/page.tsx", "utf8");
const clipboard = readFileSync("src/components/ImportClipboardButton.tsx", "utf8");
const confirm = readFileSync("src/app/messages/partager/SharedMessageConfirmation.tsx", "utf8");

test("BORALOG-178B People are scoped to current organization and ordered alphabetically", () => {
  assert.match(page, /\.from\("people"\)/);
  assert.match(page, /\.select\("id, name, role_label"\)/);
  assert.match(page, /\.eq\("organization_id", identity\.organization\.id\)/);
  assert.match(page, /\.order\("name", \{ ascending: true \}\)/);
});

test("BORALOG-178B sender combobox filters People client-side and stores UUID", () => {
  assert.match(combobox, /query/);
  assert.match(combobox, /selectedPersonId/);
  assert.match(combobox, /toLocaleLowerCase\("fr"\)/);
  assert.match(combobox, /person\.name/);
  assert.match(combobox, /person\.role_label/);
  assert.match(combobox, /name="sender_person_id"/);
  assert.match(combobox, /value=\{selectedPersonId\}/);
  assert.match(combobox, /setSelectedPersonId\(person\.id\)/);
});

test("BORALOG-178B supports registered, unregistered and unknown sender modes", () => {
  assert.match(combobox, /value="PERSON"/);
  assert.match(combobox, /value="UNREGISTERED"/);
  assert.match(combobox, /value="UNKNOWN"/);
  assert.match(combobox, /Personne non enregistrée/);
  assert.match(combobox, /name="external_author_label"/);
  assert.match(combobox, /Inconnu/);
});

test("BORALOG-178B server validates Person in same organization and author exclusivity", () => {
  assert.match(action, /sender_person_id/);
  assert.match(action, /external_author_label/);
  assert.match(action, /senderPersonId && externalAuthorLabel/);
  assert.match(action, /\.eq\("id", senderPersonId\)/);
  assert.match(action, /\.eq\("organization_id", identity\.organization\.id\)/);
  assert.match(action, /origin_type:\s*"EXTERNAL_MANUAL"/);
  assert.match(action, /author_user_id:\s*null/);
  assert.match(action, /external_author_person_id:\s*senderPersonId \|\| null/);
  assert.match(action, /external_author_label:\s*externalAuthorLabel \|\| null/);
  assert.match(action, /source_kind:\s*sourceKind/);
});

test("BORALOG-178B Message detail renders linked Person or free label as sender", () => {
  assert.match(detail, /external_author_person_id/);
  assert.match(detail, /\.from\("people"\)/);
  assert.match(detail, /externalAuthorPerson\?\.name/);
  assert.match(detail, /message\.external_author_label/);
  assert.match(detail, /Expéditeur : \{sourceAuthor \|\| "Inconnu"\}/);
  assert.match(detail, /Source : \{displaySourceKind\(message\.source_kind\)\}/);
});

test("BORALOG-178B clipboard and confirmation flows remain intact", () => {
  assert.match(clipboard, /navigator\.clipboard\?\.readText/);
  assert.match(clipboard, /sessionStorage\.setItem/);
  assert.match(clipboard, /router\.push\("\/messages\/partager"\)/);
  assert.match(confirm, /sessionStorage\.getItem/);
  assert.match(confirm, /value="WHATSAPP"/);
  assert.match(confirm, /value="OTHER"/);
});
