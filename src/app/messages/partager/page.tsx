import { redirect } from "next/navigation";
import { getCurrentIdentity } from "../../../lib/auth";
import { SharedMessageConfirmation } from "./SharedMessageConfirmation";

export default async function SharedMessagePage() {
  const identity = await getCurrentIdentity();
  if (!identity.userId) redirect("/auth/connexion?retour=/messages/partager");
  if (!identity.organization) return null;

  const canCreate = identity.organization.accessLevel === "owner" || identity.organization.accessLevel === "full";

  return <main className="entity-page"><div className="entity-wrap">
    <header className="entity-header">
      <p className="eyebrow">PARTAGE ANDROID</p>
      <h1>Ajouter ce message</h1>
      <p>Vérifiez le texte et confirmez sa source avant l’enregistrement.</p>
    </header>
    {canCreate ? <SharedMessageConfirmation /> : <p className="work-empty">Votre accès ne permet pas de créer un Message pour toute la Structure.</p>}
  </div></main>;
}
