import { NextResponse } from "next/server";
import { createClient } from "../../../../lib/supabase/server";

function safeError(error: { code?: string; message?: string } | null) {
  return error ? { code: error.code ?? "unknown", message: error.message ?? "unknown" } : null;
}

export async function GET() {
  const checkpoints: Record<string, unknown> = {};
  try {
    checkpoints.env = {
      supabaseUrlPresent: Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL),
      publishableKeyPresent: Boolean(process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY),
    };
    checkpoints.createClient = "BEFORE";
    const supabase = await createClient();
    checkpoints.createClient = "PASS";

    checkpoints.authGetUser = "BEFORE";
    const auth = await supabase.auth.getUser();
    checkpoints.authGetUser = { status: auth.error ? "FAIL" : "PASS", authenticated: Boolean(auth.data.user), error: safeError(auth.error) };

    checkpoints.membershipRelation = "BEFORE";
    const membership = await supabase
      .from("organization_memberships")
      .select("organization_id, access_level, organizations(id, name)")
      .limit(1);
    checkpoints.membershipRelation = { status: membership.error ? "FAIL" : "PASS", rowCount: membership.data?.length ?? 0, error: safeError(membership.error) };

    return NextResponse.json({ probe: "BORALOG_DIAG_044", checkpoints });
  } catch (error) {
    const safe = error instanceof Error ? { name: error.name, message: error.message } : { name: "unknown", message: "unknown" };
    return NextResponse.json({ probe: "BORALOG_DIAG_044", checkpoints, unhandled: safe }, { status: 500 });
  }
}
