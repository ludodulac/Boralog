import type { CookieOptions } from "@supabase/ssr";

export const AUTH_TRACE_COOKIE = "boralog-auth-trace";

const AUTH_COOKIE_PREFIX = "sb-jwtawyeuyvqjikjvfhri-auth-token";

type CookieLike = {
  name: string;
  value?: string;
  path?: string;
  domain?: string;
  maxAge?: number;
  expires?: Date | string;
  sameSite?: boolean | string;
  secure?: boolean;
};

export function authTraceEnabled(hostname: string) {
  return hostname === "deploy-preview-1--boralog.netlify.app";
}

export function isAuthCookieName(name: string) {
  return name === AUTH_COOKIE_PREFIX || name.startsWith(`${AUTH_COOKIE_PREFIX}.`);
}

export function authCookieNames(cookies: Array<{ name: string }>) {
  return cookies.filter(({ name }) => isAuthCookieName(name)).map(({ name }) => name).sort();
}

export function safeCookieMetadata(
  cookies: Array<{ name: string; options?: CookieOptions }>,
) {
  return cookies
    .filter(({ name }) => isAuthCookieName(name))
    .map(({ name, options }) => ({
      name,
      path: options?.path ?? null,
      domain: options?.domain ?? null,
      maxAge: options?.maxAge ?? null,
      expires: options?.expires instanceof Date ? options.expires.toISOString() : options?.expires ?? null,
      sameSite: options?.sameSite ?? null,
      secure: options?.secure ?? null,
      expiration: options?.maxAge === 0,
    }));
}

export function safeResponseCookieMetadata(cookies: CookieLike[]) {
  return cookies
    .filter(({ name }) => isAuthCookieName(name))
    .map(({ name, path, domain, maxAge, expires, sameSite, secure }) => ({
      name,
      path: path ?? null,
      domain: domain ?? null,
      maxAge: maxAge ?? null,
      expires: expires instanceof Date ? expires.toISOString() : expires ?? null,
      sameSite: sameSite ?? null,
      secure: secure ?? null,
      expiration: maxAge === 0 || (expires instanceof Date && expires.getTime() <= Date.now()),
    }));
}

export function authTraceLog(traceId: string, event: string, data: Record<string, unknown>) {
  console.info(JSON.stringify({
    source: "BORALOG_AUTH_TRACE_011M",
    traceId,
    event,
    timestamp: new Date().toISOString(),
    ...data,
  }));
}
