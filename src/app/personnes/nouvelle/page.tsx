import Link from "next/link";
import { redirect } from "next/navigation";
import { getCurrentIdentity } from "../../../lib/auth";
import { CreatePersonForm } from "./CreatePersonForm";

export default async function NewPersonPage() {
  const identity = await getCurrentIdentity();
  if (!identity.userId) redirect("/auth/connexion");
  if (!identity.organization) return null;

  const canManage = identity.organization.accessLevel === "owner" || identity.organization.accessLevel === "full";

  return <main className="entity-page"><div className="entity-wrap person-detail-page">
    <Link className="entity-back" href="/personnes">← Personnes</Link>
    <header className="entity-header"><p className="eyebrow">PERSONNES</p><h1>Nouvelle personne</h1></header>
    {canManage ? <CreatePersonForm /> : <p className="work-empty">Vous n’avez pas accès à la création de Personnes.</p>}
  </div></main>;
}
