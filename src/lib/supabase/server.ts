import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

function isSupabaseCookieName(name: string) {
  return name.startsWith("sb-");
}

export async function createClient() {
  const cookieStore = await cookies();
  const incomingCookies = cookieStore.getAll();
  console.info("[BORALOG_DIAG_046] SERVER ENTRY", {
    correlationId: "NOT_TRANSMITTED",
    cookieCount: incomingCookies.length,
    hasSupabaseCookie: incomingCookies.some(({ name }) => isSupabaseCookieName(name)),
  });
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
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
