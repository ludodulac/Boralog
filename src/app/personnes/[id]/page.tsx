import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { getCurrentIdentity } from "../../../lib/auth";
import { createClient } from "../../../lib/supabase/server";
import { AccountLinkControls, CompanyLinkControls, PersonBusinessForm } from "./PersonDetailForms";

export default async function PersonDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const identity = await getCurrentIdentity();
  if (!identity.userId) redirect("/auth/connexion");
  if (!identity.organization) return null;

  const canManage = identity.organization.accessLevel === "owner" || identity.organization.accessLevel === "full";
  if (!canManage) notFound();

  const supabase = await createClient();
  const { data: person, error: personError } = await supabase
    .from("people")
    .select("id, organization_id, name, role_label, professional_email, professional_phone, organization_membership_id")
    .eq("id", id)
    .eq("organization_id", identity.organization.id)
    .maybeSingle();
  if (personError || !person) notFound();

  const [
    { data: companies },
    { data: companyLinks },
    { data: memberships },
    { data: recipientDirectory },
  ] = await Promise.all([
    supabase.from("companies").select("id, name").eq("organization_id", identity.organization.id).order("name"),
    supabase.from("person_companies").select("company_id").eq("person_id", person.id),
    supabase.from("organization_memberships")
      .select("id, user_id")
      .eq("organization_id", identity.organization.id)
      .eq("status", "active"),
    supabase.rpc("boralog_message_recipient_directory", { p_organization_id: identity.organization.id }),
  ]);

  const displayNames = new Map(
    (recipientDirectory ?? []).map((row: { user_id: string; display_name: string | null }) => [row.user_id, row.display_name]),
  );
  const membershipOptions = (memberships ?? []).map((membership) => ({
    id: membership.id,
    label: displayNames.get(membership.user_id) || membership.user_id,
  }));
  const linkedMembership = (memberships ?? []).find((membership) => membership.id === person.organization_membership_id) ?? null;
  const linkedLabel = linkedMembership ? (displayNames.get(linkedMembership.user_id) || linkedMembership.user_id) : null;

  return <main className="entity-page"><div className="entity-wrap person-detail-page">
    <Link className="entity-back" href="/personnes">← Personnes</Link>
    <header className="entity-header"><p className="eyebrow">PERSONNE</p><h1>{person.name}</h1></header>

    <section className="person-section" aria-labelledby="person-business-title">
      <h2 id="person-business-title">Informations métier</h2>
      <PersonBusinessForm person={person} />
    </section>

    <section className="person-section" aria-labelledby="person-companies-title">
      <h2 id="person-companies-title">Compagnies</h2>
      <CompanyLinkControls
        personId={person.id}
        companies={companies ?? []}
        linkedCompanyIds={(companyLinks ?? []).map((link) => link.company_id)}
      />
    </section>

    <section className="person-section" aria-labelledby="person-account-title">
      <h2 id="person-account-title">Compte Boralog</h2>
      <AccountLinkControls
        personId={person.id}
        linkedMembershipId={person.organization_membership_id}
        linkedLabel={linkedLabel}
        memberships={membershipOptions}
      />
    </section>
  </div></main>;
}
