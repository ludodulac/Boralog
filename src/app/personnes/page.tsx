import Link from "next/link";
import { redirect } from "next/navigation";
import { getCurrentIdentity } from "../../lib/auth";
import { createClient } from "../../lib/supabase/server";

export default async function PeoplePage() {
  const identity = await getCurrentIdentity();
  if (!identity.userId) redirect("/auth/connexion");
  if (!identity.organization) return null;

  const canManage = identity.organization.accessLevel === "owner" || identity.organization.accessLevel === "full";
  if (!canManage) {
    return <main className="entity-page"><div className="entity-wrap">
      <header className="entity-header"><p className="eyebrow">PERSONNES</p><h1>Personnes</h1></header>
      <p className="work-empty">Vous n’avez pas accès à l’annuaire des Personnes.</p>
    </div></main>;
  }

  const supabase = await createClient();
  const { data: people, error } = await supabase
    .from("people")
    .select("id, name, role_label, organization_membership_id")
    .eq("organization_id", identity.organization.id)
    .order("name", { ascending: true });

  const personIds = (people ?? []).map((person) => person.id);
  const { data: links } = personIds.length
    ? await supabase.from("person_companies").select("person_id, company_id").in("person_id", personIds)
    : { data: [] as { person_id: string; company_id: string }[] };

  const companyIds = [...new Set((links ?? []).map((link) => link.company_id))];
  const { data: companies } = companyIds.length
    ? await supabase.from("companies").select("id, name").in("id", companyIds)
    : { data: [] as { id: string; name: string }[] };

  const companyNames = new Map((companies ?? []).map((company) => [company.id, company.name]));
  const companiesByPerson = new Map<string, string[]>();
  for (const link of links ?? []) {
    const name = companyNames.get(link.company_id);
    if (!name) continue;
    companiesByPerson.set(link.person_id, [...(companiesByPerson.get(link.person_id) ?? []), name]);
  }

  return <main className="entity-page"><div className="entity-wrap">
    <header className="entity-header person-header">
      <div><p className="eyebrow">PERSONNES</p><h1>Personnes</h1><p>Les contacts métier de votre Structure.</p></div>
      <Link className="person-primary-link" href="/personnes/nouvelle">Nouvelle personne</Link>
    </header>

    {error ? <p role="alert">Les Personnes n’ont pas pu être chargées.</p> : (people ?? []).length === 0 ? (
      <p className="work-empty">Aucune Personne pour le moment.</p>
    ) : (
      <div className="person-list">{(people ?? []).map((person) => {
        const personCompanies = companiesByPerson.get(person.id) ?? [];
        return <Link className="person-row" href={`/personnes/${person.id}`} key={person.id}>
          <div>
            <h2>{person.name}</h2>
            <p>{person.role_label || "Rôle non renseigné"}</p>
            <small>{personCompanies.length ? personCompanies.join(" · ") : "Aucune Compagnie"}</small>
          </div>
          <span className="person-account-state">{person.organization_membership_id ? "Compte lié" : "Aucun compte lié"}</span>
        </Link>;
      })}</div>
    )}
  </div></main>;
}
