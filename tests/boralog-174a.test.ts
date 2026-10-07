import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";

const home = readFileSync("src/app/page.tsx", "utf8");
const taskPage = readFileSync("src/app/aujourdhui/a-faire/page.tsx", "utf8");
const dateTime = readFileSync("src/lib/date-time.ts", "utf8");
const nav = readFileSync("src/components/MainNavigation.tsx", "utf8");
const proxy = readFileSync("src/proxy.ts", "utf8");
const sessionProxy = readFileSync("src/lib/supabase/proxy.ts", "utf8");

test("BORALOG-174A home is Today, not Structure or Project administration", () => {
  assert.match(home, /AUJOURD’HUI/);
  assert.match(home, /<h1>Aujourd’hui<\/h1>/);
  assert.doesNotMatch(home, /Votre structure est prête|Créer un projet/);
  assert.doesNotMatch(home, /demoToday|demoProjects|demoRecentActivity|data\/demo/);
});

test("BORALOG-174A home loads real TO_PROCESS Messages in current organization", () => {
  assert.match(home, /from\("messages"\)/);
  assert.match(home, /\.eq\("organization_id", identity\.organization\.id\)/);
  assert.match(home, /\.eq\("status", "TO_PROCESS"\)/);
  assert.match(home, /\/messages\/.*message\.id/);
  assert.match(home, /href="\/messages\?etat=to-process"/);
});

test("BORALOG-174A home loads real TO_DO Tasks without invented fields", () => {
  assert.match(home, /from\("tasks"\)/);
  assert.match(home, /\.eq\("status", "TO_DO"\)/);
  assert.doesNotMatch(home, /priority|deadline|assignee|responsable|échéance/i);
  assert.match(home, /href="\/aujourdhui\/a-faire"/);
});

test("BORALOG-174A task page is real and separates TO_DO from DONE", () => {
  assert.match(taskPage, /from\("tasks"\)/);
  assert.match(taskPage, /identity\.organization\.id/);
  assert.match(taskPage, /"TO_DO"/);
  assert.match(taskPage, /"DONE"/);
  assert.match(taskPage, /const todo = realTasks\.filter/);
  assert.match(taskPage, /const done = realTasks\.filter/);
  assert.doesNotMatch(taskPage, /demoToday|demoProjects|data\/demo|Bientôt/);
  assert.doesNotMatch(taskPage, /priority|deadline|assignee|responsable|échéance/i);
});

test("BORALOG-174A upcoming Dates use real events and Paris civil date", () => {
  assert.match(home, /from\("events"\)/);
  assert.match(home, /\.gte\("event_date", today\)/);
  assert.match(home, /getBoralogCivilDate/);
  assert.match(home, /href="\/calendrier"/);
  assert.match(dateTime, /BORALOG_TIME_ZONE = "Europe\/Paris"/);
  assert.match(dateTime, /getBoralogCivilDate/);
  assert.match(dateTime, /timeZone: BORALOG_TIME_ZONE/);
});

test("BORALOG-174A navigation remains unchanged", () => {
  for (const item of ["Aujourd’hui", "Messages", "Projets", "Personnes", "Recherche", "Moi"]) {
    assert.ok(nav.includes(item));
  }
  assert.ok(nav.includes('["Aujourd’hui", "/"]'));
});

test("BORALOG-174A SSR session architecture remains intact", () => {
  assert.match(sessionProxy, /createServerClient/);
  assert.match(sessionProxy, /supabase\.auth\.getUser\(\)/);
  assert.match(proxy, /updateSession/);
  assert.match(proxy, /url\.pathname = "\/auth\/connexion"/);
  assert.match(proxy, /url\.pathname = "\/"/);
});

test("BORALOG-174A adds no migration", () => {
  assert.doesNotMatch(readdirSync("supabase/migrations").join("\n"), /174a/i);
});
