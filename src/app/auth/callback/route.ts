import { NextResponse, type NextRequest } from "next/server";
import { createClient } from "../../../lib/supabase/server";

export async function GET(request: NextRequest) {
  const code = request.nextUrl.searchParams.get("code");
  const supabase = await createClient();

  if (code) {
    const { data, error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error && data.user) {
      const displayName = typeof data.user.user_metadata?.display_name === "string" ? data.user.user_metadata.display_name.trim() : "";
      if (displayName) {
        await supabase.from("profiles").upsert({ id: data.user.id, display_name: displayName, professional_email: data.user.email ?? null }, { onConflict: "id", ignoreDuplicates: true });
      }
      return NextResponse.redirect(new URL("/", request.url));
    }
  }

  return NextResponse.redirect(new URL("/auth/connexion?erreur=confirmation", request.url));
}
