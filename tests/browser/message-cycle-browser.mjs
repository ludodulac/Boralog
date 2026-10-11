import http from "node:http";
import assert from "node:assert/strict";
import { chromium } from "playwright";

const html = [
  "<!doctype html>",
  "<html lang=\"fr\"><head><meta charset=\"utf-8\"><title>BORALOG-165R browser contract</title></head><body>",
  "<main><h1>Fiche Message</h1><span id=\"status\" role=\"status\">À traiter</span>",
  "<section><h2>Source originale</h2><p>BORALOG-165R BROWSER SOURCE</p></section>",
  "<section><h2>Notes</h2><div id=\"notes\"></div>",
  "<form id=\"note-form\"><label>Note <textarea name=\"content\" required></textarea></label><button type=\"submit\">Ajouter la note</button></form></section>",
  "<form id=\"status-form\"><button id=\"status-button\" type=\"submit\">Marquer traité</button></form></main>",
  "<script>",
  "const notes=document.querySelector('#notes');const status=document.querySelector('#status');const statusButton=document.querySelector('#status-button');",
  "document.querySelector('#note-form').addEventListener('submit',(event)=>{event.preventDefault();const textarea=event.currentTarget.elements.content;const content=textarea.value.trim();if(!content)return;const article=document.createElement('article');article.textContent=content;notes.append(article);textarea.value='';});",
  "document.querySelector('#status-form').addEventListener('submit',(event)=>{event.preventDefault();if(status.textContent==='À traiter'){status.textContent='Traité';statusButton.textContent='Remettre à traiter';}else{status.textContent='À traiter';statusButton.textContent='Marquer traité';}});",
  "</script></body></html>"
].join("");

const server = http.createServer((_request, response) => {
  response.writeHead(200, { "content-type": "text/html; charset=utf-8" });
  response.end(html);
});

await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
const address = server.address();
if (!address || typeof address === "string") throw new Error("browser server did not bind");
const browser = await chromium.launch({ headless: true });

try {
  const page = await browser.newPage();
  await page.goto("http://127.0.0.1:" + address.port + "/");
  await page.getByRole("heading", { name: "Fiche Message" }).waitFor();

  await page.getByLabel("Note").fill("BORALOG-165R NOTE BROWSER");
  await page.getByRole("button", { name: "Ajouter la note" }).click();
  await page.getByText("BORALOG-165R NOTE BROWSER").waitFor();

  await page.getByRole("button", { name: "Marquer traité" }).click();
  assert.equal(await page.locator("#status").textContent(), "Traité");

  await page.getByRole("button", { name: "Remettre à traiter" }).click();
  assert.equal(await page.locator("#status").textContent(), "À traiter");
} finally {
  await browser.close();
  await new Promise((resolve) => server.close(resolve));
}
