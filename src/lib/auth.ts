import { createClient } from "./supabase/server";
import { buildAuthenticatedIdentity, type CurrentOrganization } from "./current-identity";

export type { CurrentOrganization, CurrentIdentity } from "./current-identity";

function diagnosticError(error: { code?: string; message?: string } | null) {
  return error ? { code: error.code ?? "unknown", message: error.message ?? "unknown" } : null;
}

export async function getCurrentIdentity() {
  console.info("[BORALOG_DIAG_044] A getCurrentIdentity enter");
  console.info("[BORALOG_DIAG_044] B createClient before");
  const supabase = await createClient();
  console.info("[BORALOG_DIAG_044] B createClient after");
  console.info("[BORALOG_DIAG_044] C auth.getUser before");
  const { data, error } = await supabase.auth.getUser();
  console.info("[BORALOG_DIAG_044] D auth.getUser after", { ok: !error, authenticated: Boolean(data.user), error: diagnosticError(error) });
  const user = error ? null : data.user;
  if (!user) {
    console.info("[BORALOG_DIAG_044] J getCurrentIdentity return unauthenticated");
    return { userId: null, email: null, profile: null, organization: null as CurrentOrganization | null, hasOrganization: false };
  }
  console.info("[BORALOG_DIAG_044] E profile query before");
  const profileResult = await supabase.from("profiles").select("id, display_name, professional_email, professional_phone").eq("id", user.id).maybeSingle();
  console.info("[BORALOG_DIAG_044] F profile query after", { ok: !profileResult.error, error: diagnosticError(profileResult.error) });
  console.info("[BORALOG_DIAG_044] G membership query before");
  const membershipResult = await supabase.from("organization_memberships").select("organization_id, access_level, organizations(id, name)").eq("user_id", user.id).eq("status", "active").limit(1);
  console.info("[BORALOG_DIAG_044] H membership query after", { ok: !membershipResult.error, rowCount: membershipResult.data?.length ?? 0, error: diagnosticError(membershipResult.error) });
  console.info("[BORALOG_DIAG_044] I identity construction", { hasMembership: Boolean(membershipResult.data?.[0]) });
  const identity = buildAuthenticatedIdentity({
    userId: user.id,
    email: user.email ?? null,
    profile: profileResult.data,
    membershipRows: membershipResult.data as Parameters<typeof buildAuthenticatedIdentity>[0]["membershipRows"],
  });
  console.info("[BORALOG_DIAG_044] J getCurrentIdentity return authenticated", { hasOrganization: identity.hasOrganization });
  return identity;
}
