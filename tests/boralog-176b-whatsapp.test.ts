import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import twilio from "twilio";
import { validateTwilioWebhookSignature } from "../src/lib/twilio/whatsapp.ts";

const route = readFileSync("src/app/api/integrations/twilio/whatsapp/incoming/route.ts", "utf8");
const admin = readFileSync("src/lib/supabase/admin.ts", "utf8");
const migration = readFileSync("supabase/migrations/20261007222000_message_external_ingest_176b.sql", "utf8");
const pkg = JSON.parse(readFileSync("package.json", "utf8"));

test("BORALOG-176B uses official Twilio signature validation and accepts valid signatures", () => {
  const authToken = "test-auth-token";
  const webhookUrl = "https://deploy-preview-176--boralog.netlify.app/api/integrations/twilio/whatsapp/incoming";
  const params = {
    MessageSid: "SM176BTEST",
    From: "whatsapp:+33600000000",
    To: "whatsapp:+14155238886",
    Body: "Bonjour Boralog",
  };
  const signature = twilio.getExpectedTwilioSignature(authToken, webhookUrl, params);
  assert.equal(validateTwilioWebhookSignature({ authToken, signature, webhookUrl, params }), true);
  assert.equal(validateTwilioWebhookSignature({ authToken, signature: "invalid", webhookUrl, params }), false);
  assert.equal(pkg.dependencies.twilio, "6.1.2");
});

test("BORALOG-176B route uses exact configured webhook URL and server-only configuration", () => {
  assert.match(route, /BORALOG_TWILIO_WEBHOOK_URL/);
  assert.match(route, /TWILIO_AUTH_TOKEN/);
  assert.match(route, /BORALOG_TWILIO_WHATSAPP_TO/);
  assert.match(route, /BORALOG_TWILIO_ORGANIZATION_ID/);
  assert.match(route, /SUPABASE_SECRET_KEY/);
  assert.match(route, /x-twilio-signature/);
  assert.match(route, /validateTwilioWebhookSignature/);
  assert.match(route, /webhookUrl,/);
  assert.doesNotMatch(route, /NEXT_PUBLIC_(TWILIO|BORALOG_TWILIO|SUPABASE_SECRET)/);
});

test("BORALOG-176B rejects invalid payloads before ingestion", () => {
  assert.match(route, /if \(!signature\).*403/);
  assert.match(route, /if \(!signatureValid\).*403/);
  assert.match(route, /if \(!messageSid\).*400/);
  assert.match(route, /if \(!from\).*400/);
  assert.match(route, /if \(!content\).*400/);
  assert.match(route, /if \(to !== expectedTo\).*403/);
  assert.match(route, /Server configuration is incomplete/);
});

test("BORALOG-176B valid payload calls the dedicated idempotent external ingestion RPC", () => {
  assert.match(route, /\.rpc\("boralog_ingest_external_message"/);
  assert.match(route, /p_organization_id: organizationId/);
  assert.match(route, /p_content: content/);
  assert.match(route, /p_external_author_label: from/);
  assert.match(route, /p_source_kind: "WHATSAPP"/);
  assert.match(route, /p_source_external_id: messageSid/);
  assert.match(route, /p_source_occurred_at: new Date\(\)\.toISOString\(\)/);
  assert.match(route, /<Response><\/Response>/);
  assert.match(route, /Content-Type": "text\/xml; charset=utf-8"/);
});

test("BORALOG-176B privileged Supabase client is server-only in behavior", () => {
  assert.match(admin, /SUPABASE_SECRET_KEY/);
  assert.match(admin, /NEXT_PUBLIC_SUPABASE_URL/);
  assert.match(admin, /persistSession: false/);
  assert.match(admin, /autoRefreshToken: false/);
  assert.match(admin, /detectSessionInUrl: false/);
  assert.doesNotMatch(admin, /cookies|NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY/);
});

test("BORALOG-176B migration encodes imported Message contract and idempotence", () => {
  assert.match(migration, /alter column created_by drop not null/);
  assert.match(migration, /add column source_external_id text null/);
  assert.match(migration, /unique index messages_external_source_unique_idx/);
  assert.match(migration, /organization_id, source_kind, source_external_id/);
  assert.match(migration, /origin_type[\s\S]*'EXTERNAL_IMPORTED'/);
  assert.match(migration, /'TO_PROCESS'/);
  assert.match(migration, /'ORGANIZATION'/);
  assert.match(migration, /on conflict \(organization_id, source_kind, source_external_id\)/);
  assert.match(migration, /new\.source_external_id is distinct from old\.source_external_id/);
});

test("BORALOG-176B external RPC is service-role only and cannot fabricate INTERNAL", () => {
  assert.match(migration, /revoke all on function public\.boralog_ingest_external_message[\s\S]*from public, anon, authenticated/);
  assert.match(migration, /grant execute on function public\.boralog_ingest_external_message[\s\S]*to service_role/);
  assert.doesNotMatch(migration, /p_origin_type|p_status|p_visibility|p_created_by|p_author_user_id/);
  assert.match(migration, /null,[\s\S]*'EXTERNAL_IMPORTED',[\s\S]*null,/);
});

test("BORALOG-176B preserves human auth rules and canonical reversible 165R cycle", () => {
  assert.match(migration, /authenticated actor required to create message/);
  assert.match(migration, /message created_by must match authenticated actor/);
  assert.match(migration, /internal message author must match authenticated actor/);
  assert.match(migration, /elsif new\.origin_type = 'EXTERNAL_MANUAL'/);
  assert.doesNotMatch(migration, /processed message cannot be reopened/);
  assert.match(migration, /new\.processed_at := null/);
  assert.match(migration, /new\.processed_by := null/);
  assert.match(migration, /new\.resolution := old\.resolution/);
});
