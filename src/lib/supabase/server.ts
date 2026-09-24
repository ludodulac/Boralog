import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import { authTraceLog, safeCookieMetadata } from "../authTrace";

type TraceContext = {
  traceId: string;
  enabled: boolean;
};

export async function createClient(trace?: TraceContext) {
  const cookieStore = await cookies();
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          if (trace?.enabled) {
            authTraceLog(trace.traceId, "SSR_COOKIE_MUTATIONS_REQUESTED", {
              cookies: safeCookieMetadata(cookiesToSet),
              count: safeCookieMetadata(cookiesToSet).length,
            });
          }
          try {
            cookiesToSet.forEach(({ name, value, options }) => cookieStore.set(name, value, options));
          } catch {
            // Server Components cannot write cookies. proxy.ts refreshes the session.
          }
        },
      },
    }
  );
}
