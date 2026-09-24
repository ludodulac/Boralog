import { NextResponse, type NextRequest } from "next/server";
import { createClient } from "../../../lib/supabase/server";

export async function POST(request: NextRequest) {
  const supabase = await createClient();
  const { error } = await supabase.auth.signOut();

  if (error) {
    return NextResponse.redirect(new URL("/auth/connexion?erreur=deconnexion", request.url), { status: 303 });
  }

  return NextResponse.redirect(new URL("/auth/connexion?deconnecte=1", request.url), { status: 303 });
}
