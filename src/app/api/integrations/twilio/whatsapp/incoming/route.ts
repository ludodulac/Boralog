import { createAdminClient } from "@/lib/supabase/admin";
import { parseTwilioForm, validateTwilioWebhookSignature } from "@/lib/twilio/whatsapp";

export const runtime = "nodejs";

const XML_HEADERS = { "Content-Type": "text/xml; charset=utf-8" };

function xmlOk() {
  return new Response("<Response></Response>", { status: 200, headers: XML_HEADERS });
}

function textError(message: string, status: number) {
  return new Response(message, { status });
}

function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

function readParam(value: string | string[] | undefined) {
  return (Array.isArray(value) ? value[0] : value)?.trim() ?? "";
}

export async function POST(request: Request) {
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  const webhookUrl = process.env.BORALOG_TWILIO_WEBHOOK_URL;
  const expectedTo = process.env.BORALOG_TWILIO_WHATSAPP_TO;
  const organizationId = process.env.BORALOG_TWILIO_ORGANIZATION_ID;
  const supabaseSecret = process.env.SUPABASE_SECRET_KEY;

  if (!authToken || !webhookUrl || !expectedTo || !organizationId || !supabaseSecret || !isUuid(organizationId)) {
    return textError("Server configuration is incomplete.", 500);
  }

  const signature = request.headers.get("x-twilio-signature");
  if (!signature) return textError("Invalid Twilio signature.", 403);

  const rawBody = await request.text();
  const params = parseTwilioForm(rawBody);

  const signatureValid = validateTwilioWebhookSignature({
    authToken,
    signature,
    webhookUrl,
    params,
  });

  if (!signatureValid) return textError("Invalid Twilio signature.", 403);

  const messageSid = readParam(params.MessageSid);
  const from = readParam(params.From);
  const to = readParam(params.To);
  const content = readParam(params.Body);

  if (!messageSid) return textError("MessageSid is required.", 400);
  if (!from) return textError("From is required.", 400);
  if (!content) return textError("Body is required.", 400);
  if (to !== expectedTo) return textError("Unexpected WhatsApp destination.", 403);

  const supabase = createAdminClient();
  const { error } = await supabase.rpc("boralog_ingest_external_message", {
    p_organization_id: organizationId,
    p_content: content,
    p_external_author_label: from,
    p_source_kind: "WHATSAPP",
    p_source_external_id: messageSid,
    p_source_occurred_at: new Date().toISOString(),
  });

  if (error) return textError("Message ingestion failed.", 500);

  return xmlOk();
}
