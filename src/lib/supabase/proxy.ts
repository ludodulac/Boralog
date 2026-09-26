import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

function isSupabaseCookieName(name: string) {
  return name.startsWith("sb-");
}

export async function updateSession(request: NextRequest) {
  const correlationId = crypto.randomUUID();
  const entryCookies = request.cookies.getAll();
  let setAllCalled = false;
  let cookiesWritten = 0;
  let response = NextResponse.next({ request });

  console.info("[BORALOG_DIAG_046] PROXY ENTRY", {
    correlationId,
    cookieCount: entryCookies.length,
    hasSupabaseCookie: entryCookies.some(({ name }) => isSupabaseCookieName(name)),
  });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
    {
      cookies: {
        getAll: () => request.cookies.getAll(),
        setAll(cookiesToSet) {
          setAllCalled = true;
          cookiesWritten += cookiesToSet.length;
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
  console.info("[BORALOG_DIAG_046] PROXY AUTH", {
    correlationId,
    getUser: error || !data.user ? "FAIL" : "PASS",
    errorCode: error?.code ?? null,
    setAllCalled,
    cookiesWritten,
  });
  console.info("[BORALOG_DIAG_046] PROXY EXIT", {
    correlationId,
    supabaseResponseCookieCount: response.cookies.getAll().filter(({ name }) => isSupabaseCookieName(name)).length,
  });
  return { response, authenticated: !error && Boolean(data.user) };
}
