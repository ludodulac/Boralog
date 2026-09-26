import { createClient } from "./supabase/server";

export type CurrentOrganization = {
  id: string;
  name: string;
  accessLevel: "owner" | "full" | "limited";
};

export async function getCurrentIdentity() {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.getUser();
  const user = error ? null : data.user;

  if (!user) return { userId: null, email: null, profile: null, organization: null as CurrentOrganization | null, hasOrganization: false };

  const [{ data: profile }, { data: memberships }] = await Promise.all([
    supabase.from("profiles").select("id, display_name, professional_email, professional_phone").eq("id", user.id).maybeSingle(),
    supabase
      .from("organization_memberships")
      .select("organization_id, access_level, organizations(id, name)")
      .eq("user_id", user.id)
      .eq("status", "active")
      .limit(1),
  ]);

  const membership = memberships?.[0] as { organization_id: string; access_level: CurrentOrganization["accessLevel"]; organizations: { id: string; name: string } | { id: string; name: string }[] | null } | undefined;
  const joined = Array.isArray(membership?.organizations) ? membership?.organizations[0] : membership?.organizations;
  const organization = membership && joined ? { id: joined.id, name: joined.name, accessLevel: membership.access_level } : null;

  return {
    userId: user.id,
    email: user.email ?? null,
    profile,
    organization,
    hasOrganization: Boolean(organization),
  };
}
