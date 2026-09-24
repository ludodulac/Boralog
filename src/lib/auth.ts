import { createClient } from "./supabase/server";

export async function getCurrentIdentity() {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.getUser();
  const user = error ? null : data.user;

  if (!user) return { userId: null, email: null, profile: null, hasOrganization: false };

  const [{ data: profile }, { data: memberships }] = await Promise.all([
    supabase.from("profiles").select("id, display_name, professional_email").eq("id", user.id).maybeSingle(),
    supabase.from("organization_memberships").select("id").eq("user_id", user.id).eq("status", "active").limit(1),
  ]);

  return {
    userId: user.id,
    email: user.email ?? null,
    profile,
    hasOrganization: Boolean(memberships?.length),
  };
}
