import { createClient } from "./supabase/server";

export async function getCurrentIdentity() {
  const supabase = await createClient();
  const { data: claimsData } = await supabase.auth.getClaims();
  const userId = claimsData?.claims?.sub;

  if (!userId) return { userId: null, email: null, profile: null, hasOrganization: false };

  const [{ data: profile }, { data: memberships }] = await Promise.all([
    supabase.from("profiles").select("id, display_name, professional_email").eq("id", userId).maybeSingle(),
    supabase.from("organization_memberships").select("id").eq("user_id", userId).eq("status", "active").limit(1),
  ]);

  return {
    userId,
    email: typeof claimsData.claims.email === "string" ? claimsData.claims.email : null,
    profile,
    hasOrganization: Boolean(memberships?.length),
  };
}
