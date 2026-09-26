export type CurrentOrganization = {
  id: string;
  name: string;
  accessLevel: "owner" | "full" | "limited";
};

export type CurrentIdentity = {
  userId: string | null;
  email: string | null;
  profile: { id: string; display_name: string; professional_email: string | null; professional_phone?: string | null } | null;
  organization: CurrentOrganization | null;
  hasOrganization: boolean;
};

type MembershipRow = {
  organization_id: string;
  access_level: CurrentOrganization["accessLevel"];
  organizations: { id: string; name: string } | { id: string; name: string }[] | null;
};

export function buildAuthenticatedIdentity(input: {
  userId: string;
  email: string | null;
  profile: CurrentIdentity["profile"];
  membershipRows: MembershipRow[] | null;
}): CurrentIdentity {
  const membership = input.membershipRows?.[0];
  const joined = Array.isArray(membership?.organizations) ? membership?.organizations[0] : membership?.organizations;
  const organization = membership && joined
    ? { id: joined.id, name: joined.name, accessLevel: membership.access_level }
    : null;
  return {
    userId: input.userId,
    email: input.email,
    profile: input.profile,
    organization,
    hasOrganization: Boolean(organization),
  };
}
