import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { chromium } from "playwright";

const port = 32071;
const server = spawn("npm", ["run", "start", "--", "-p", String(port)], { detached: true, stdio: ["ignore", "pipe", "pipe"], env: { ...process.env, NEXT_PUBLIC_SUPABASE_URL: "https://example.supabase.co", NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: "test-only-placeholder-not-a-real-key" } });
let output = "";
server.stdout.on("data", data => { output += data.toString(); });
server.stderr.on("data", data => { output += data.toString(); });
let browser;
try {
  const origin = `http://127.0.0.1:${port}`;
  let ready = false;
  for (let i = 0; i < 100; i++) {
    if (server.exitCode !== null) throw new Error("Next server exited: " + output);
    try { const response = await fetch(origin + "/demo/organisation"); if (response.status === 200) { ready = true; break; } } catch {}
    await new Promise(resolve => setTimeout(resolve, 300));
  }
  assert.ok(ready, "Demo route did not return 200: " + output);
  browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  const supabaseCalls = [];
  page.on("request", req => { if (/supabase/i.test(req.url())) supabaseCalls.push(req.url()); });
  await page.goto(origin + "/demo/organisation");
  await page.getByTestId("demo-organization-name").getByText("Compagnie Horizon").waitFor();
  await page.reload();
  await page.getByTestId("demo-organization-name").getByText("Compagnie Horizon").waitFor();
  assert.deepEqual(supabaseCalls, []);
  const protectedResponse = await page.request.get(origin + "/projets", { maxRedirects: 0 });
  assert.equal(protectedResponse.status(), 307);
  assert.match(protectedResponse.headers().location ?? "", /auth\/connexion/);
  console.log("BORALOG-DEMO-003B Chromium PASS");
} finally {
  await browser?.close();
  // npm starts a child Next.js server: terminate the process group, not only npm.
  if (server.pid) process.kill(-server.pid, "SIGTERM");
}
