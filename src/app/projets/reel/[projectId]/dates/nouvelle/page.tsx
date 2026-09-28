import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { createClient } from "../../../../../../lib/supabase/server";

export default async function NewDatePage({ params }: { params: Promise<{ projectId: string }> }) {
  const { projectId } = await params;
  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError || !authData.user) redirect("/auth/connexion");
  const { data: project } = await supabase.from("projects").select("id, name").eq("id", projectId).maybeSingle();
  if (!project) notFound();

  return <main className="date-create-page"><div className="date-create-card">
    <Link className="project-create-back" href={`/projets/reel/${project.id}/dates`}>← Dates</Link>
    <p className="eyebrow">PROJET · {project.name.toUpperCase()}</p>
    <h1>Créer une date</h1>
    <p>Ajoutez les informations essentielles de cette date.</p>
    <form className="date-create-form">
      <label htmlFor="event-date">Date <span aria-hidden="true">*</span><input id="event-date" name="date" type="date" required /></label>
      <label htmlFor="event-time">Heure <small>Facultative</small><input id="event-time" name="time" type="time" /></label>
      <label htmlFor="event-city">Ville <small>Facultative</small><input id="event-city" name="city" type="text" autoComplete="address-level2" /></label>
      <label htmlFor="event-venue">Lieu <small>Facultatif</small><input id="event-venue" name="venue" type="text" autoComplete="organization" /></label>
      <button className="date-create-submit" type="button" disabled aria-disabled="true">Créer la date</button>
      <p className="project-create-note">L’enregistrement sera activé à l’étape suivante.</p>
    </form>
  </div></main>;
}
