import { randomUUID } from "node:crypto";
import { NextResponse, type NextRequest } from "next/server";
import {
  AUTH_TRACE_COOKIE,
  authCookieNames,
  authTraceEnabled,
  authTraceLog,
  safeResponseCookieMetadata,
} from "../../../lib/authTrace";
import { createClient } from "../../../lib/supabase/server";

export async function POST(request: NextRequest) {
  const traceEnabled = authTraceEnabled(request.nextUrl.hostname);
  const traceId = randomUUID();

  if (traceEnabled) {
    const names = authCookieNames(request.cookies.getAll());
    authTraceLog(traceId, "LOGOUT_REQUEST_IN", {
      route: request.nextUrl.pathname,
      method: request.method,
      authCookieNames: names,
      authCookieCount: names.length,
    });
  }

  const supabase = await createClient({ traceId, enabled: traceEnabled });
  const { error } = await supabase.auth.signOut();

  if (traceEnabled) {
    authTraceLog(traceId, "SIGNOUT_RESULT", {
      result: error ? "ERROR" : "SUCCESS",
      errorCode: error?.code ?? null,
    });
  }

  const response = NextResponse.redirect(
    new URL(error ? "/auth/connexion?erreur=deconnexion" : "/auth/connexion?deconnecte=1", request.url),
    { status: 303 },
  );

  if (traceEnabled) {
    response.cookies.set(AUTH_TRACE_COOKIE, traceId, {
      httpOnly: true,
      sameSite: "lax",
      secure: true,
      path: "/",
      maxAge: 600,
    });

    const responseAuthCookies = safeResponseCookieMetadata(response.cookies.getAll());
    authTraceLog(traceId, "LOGOUT_RESPONSE_CONSTRUCTED", {
      status: response.status,
      authSetCookieNames: responseAuthCookies.map(({ name }) => name),
      authSetCookieCount: responseAuthCookies.length,
      authSetCookies: responseAuthCookies,
    });
  }

  return response;
}
