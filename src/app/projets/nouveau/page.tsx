import Link from "next/link";
import { redirect } from "next/navigation";
import { randomUUID } from "node:crypto";
import { getCurrentIdentity } from "../../../lib/auth";
import { CreateProjectForm } from "./CreateProjectForm";

export default async function NewProjectPage() {
  const identity = await getCurrentIdentity();
  if (!identity.organization) redirect("/");
  if (identity.organization.accessLevel === "limited") redirect("/");

  return <main className="project-create-page"><div className="project-create-card">
    <Link className="project-create-back" href="/">← Annuler et revenir</Link>
    <p className="eyebrow">NOUVEAU PROJET</p>
    <h1>Créer un projet</h1>
    <p>Ajoutez les informations essentielles. Vous pourrez compléter le projet ensuite.</p>
    <CreateProjectForm attemptId={randomUUID()}/>
  </div></main>;
}
