import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { createClient } from "../../../../../../lib/supabase/server";
import { CreateDateForm } from "./CreateDateForm";

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
    <CreateDateForm projectId={project.id}/>
  </div></main>;
}
