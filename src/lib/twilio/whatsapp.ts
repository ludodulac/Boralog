import twilio from "twilio";

export type TwilioWebhookParams = Record<string, string | string[]>;

export function parseTwilioForm(body: string): TwilioWebhookParams {
  const form = new URLSearchParams(body);
  const params: TwilioWebhookParams = {};

  for (const [key, value] of form.entries()) {
    const current = params[key];
    if (current === undefined) params[key] = value;
    else if (Array.isArray(current)) current.push(value);
    else params[key] = [current, value];
  }

  return params;
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
