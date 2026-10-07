import twilio from "twilio";

export type TwilioWebhookParams = Record<string, string>;

export function parseTwilioForm(body: string): TwilioWebhookParams {
  const params = new URLSearchParams(body);
  return Object.fromEntries(params.entries());
}

export function validateTwilioWebhookSignature(args: {
  authToken: string;
  signature: string;
  webhookUrl: string;
  params: TwilioWebhookParams;
}) {
  return twilio.validateRequest(
    args.authToken,
    args.signature,
    args.webhookUrl,
    args.params,
  );
}
