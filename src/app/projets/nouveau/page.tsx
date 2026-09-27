import Link from "next/link";
import { redirect } from "next/navigation";
import { getCurrentIdentity } from "../../../lib/auth";

export default async function NewProjectPage() {
  const identity = await getCurrentIdentity();
  if (!identity.organization) redirect("/");

  return <main className="project-create-page"><div className="project-create-card">
    <Link className="project-create-back" href="/">← Annuler et revenir</Link>
    <p className="eyebrow">NOUVEAU PROJET</p>
    <h1>Créer un projet</h1>
    <p>Ajoutez les informations essentielles. Vous pourrez compléter le projet ensuite.</p>
    <form className="project-create-form">
      <label htmlFor="project-name">Nom du projet <span aria-hidden="true">*</span>
        <input id="project-name" name="name" type="text" required maxLength={180} autoComplete="off" />
      </label>
      <label htmlFor="project-description">Description <small>Optionnelle</small>
        <textarea id="project-description" name="description" rows={5} />
      </label>
      <button className="project-create-submit" type="button" disabled aria-disabled="true">Créer le projet</button>
      <p className="project-create-note">La création sera activée à l’étape suivante.</p>
    </form>
  </div></main>;
}
