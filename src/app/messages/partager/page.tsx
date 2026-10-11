import { redirect } from "next/navigation";
import { getCurrentIdentity } from "../../../lib/auth";
import { createClient } from "../../../lib/supabase/server";
import { SharedMessageConfirmation } from "./SharedMessageConfirmation";

export default async function SharedMessagePage() {
  const identity = await getCurrentIdentity();
  if (!identity.userId) redirect("/auth/connexion?retour=/messages/partager");
  if (!identity.organization) return null;

  const canCreate = identity.organization.accessLevel === "owner" || identity.organization.accessLevel === "full";
  const supabase = await createClient();
  const { data: people } = canCreate
    ? await supabase
        .from("people")
        .select("id, name, role_label")
        .eq("organization_id", identity.organization.id)
        .order("name", { ascending: true })
    : { data: [] as { id: string; name: string; role_label: string | null }[] };

  return <main className="entity-page"><div className="entity-wrap">
    <header className="entity-header">
      <p className="eyebrow">PARTAGE ANDROID</p>
      <h1>Ajouter ce message</h1>
      <p>Vérifiez le texte, l’expéditeur et la source avant l’enregistrement.</p>
    </header>
    {canCreate
      ? <SharedMessageConfirmation people={people ?? []} />
      : <p className="work-empty">Votre accès ne permet pas de créer un Message pour toute la Structure.</p>}
  </div></main>;
}
