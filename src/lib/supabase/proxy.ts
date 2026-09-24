import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import {
  AUTH_TRACE_COOKIE,
  authCookieNames,
  authTraceEnabled,
  authTraceLog,
  safeCookieMetadata,
} from "../authTrace";

export async function updateSession(request: NextRequest) {
  let response = NextResponse.next({ request });
  const traceId = request.cookies.get(AUTH_TRACE_COOKIE)?.value;
  const traceEnabled = Boolean(traceId) && authTraceEnabled(request.nextUrl.hostname);

  if (traceEnabled && traceId) {
    const names = authCookieNames(request.cookies.getAll());
    authTraceLog(traceId, "PROXY_REQUEST_IN", {
      route: request.nextUrl.pathname,
      method: request.method,
      authCookieNames: names,
      authCookieCount: names.length,
    });
  }

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
    {
      cookies: {
        getAll: () => request.cookies.getAll(),
        setAll(cookiesToSet) {
          if (traceEnabled && traceId) {
            const metadata = safeCookieMetadata(cookiesToSet);
            authTraceLog(traceId, "PROXY_COOKIE_MUTATIONS_REQUESTED", {
              route: request.nextUrl.pathname,
              cookies: metadata,
              count: metadata.length,
            });
          }
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
          response = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) => response.cookies.set(name, value, options));
        },
      },
    }
  );

  // Security boundary: getUser() asks Supabase Auth to validate the current
  // session instead of trusting only a locally valid JWT.
  const { data, error } = await supabase.auth.getUser();
  const authenticated = !error && Boolean(data.user);

  if (traceEnabled && traceId) {
    authTraceLog(traceId, "PROXY_GETUSER_RESULT", {
      route: request.nextUrl.pathname,
      result: authenticated ? "USER_VALID" : "NO_VALID_USER",
      errorCode: error?.code ?? null,
    });
  }

  return { response, authenticated };
}
