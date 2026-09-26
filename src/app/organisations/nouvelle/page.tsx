import { redirect } from "next/navigation";
import { getCurrentIdentity } from "../../../lib/auth";
import { CreateOrganizationForm } from "./CreateOrganizationForm";

export default async function NewOrganizationPage() {
  const identity = await getCurrentIdentity();
  if (!identity.userId) redirect("/auth/connexion");
  if (identity.organization) redirect("/");

  return <main className="organization-create-page"><div className="organization-create-card">
    <p className="eyebrow">BORALOG</p>
    <h1>Créer une structure</h1>
    <p>Donnez simplement le nom de votre structure. Vous pourrez compléter le reste plus tard.</p>
    <CreateOrganizationForm />
  </div></main>;
}
