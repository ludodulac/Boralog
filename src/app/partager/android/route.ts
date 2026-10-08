import { buildSharedMessageDraft, SHARED_MESSAGE_STORAGE_KEY } from "../../../lib/android-share";

export const runtime = "nodejs";

function html(body: string, status = 200) {
  return new Response(body, {
    status,
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "no-store",
    },
  });
}

export async function POST(request: Request) {
  const formData = await request.formData();
  const draft = buildSharedMessageDraft({
    title: typeof formData.get("title") === "string" ? String(formData.get("title")) : "",
    text: typeof formData.get("text") === "string" ? String(formData.get("text")) : "",
    url: typeof formData.get("url") === "string" ? String(formData.get("url")) : "",
  });

  if (!draft) {
    return html("<!doctype html><html lang=\"fr\"><meta charset=\"utf-8\"><title>BORALOG</title><body><p>Aucun texte à partager.</p></body></html>", 400);
  }

  const encoded = Buffer.from(draft, "utf8").toString("base64");
  return html(`<!doctype html>
<html lang="fr">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>BORALOG</title>
<body>
<p>Ouverture de BORALOG…</p>
<script>
  const bytes = Uint8Array.from(atob("${encoded}"), c => c.charCodeAt(0));
  const draft = new TextDecoder().decode(bytes);
  sessionStorage.setItem("${SHARED_MESSAGE_STORAGE_KEY}", draft);
  location.replace("/messages/partager");
</script>
</body>
</html>`);
}
