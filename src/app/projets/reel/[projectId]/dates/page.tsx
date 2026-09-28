import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { createClient } from "../../../../../lib/supabase/server";

export default async function ProjectDatesPage({ params }: { params: Promise<{ projectId: string }> }) {
  const { projectId } = await params;
  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError || !authData.user) redirect("/auth/connexion");
  const { data: project } = await supabase.from("projects").select("id, name").eq("id", projectId).maybeSingle();
  if (!project) notFound();

  return <main className="entity-page"><div className="entity-wrap">
    <Link className="entity-back" href={`/projets/reel/${project.id}`}>← {project.name}</Link>
    <header className="entity-header"><p className="eyebrow">PROJET · DATES</p><h1>Dates</h1><p>Retrouvez ici les dates du projet.</p></header>
    <section className="date-ui-empty"><p>Aucune date pour le moment.</p><Link className="project-create-cta" href={`/projets/reel/${project.id}/dates/nouvelle`}>Créer une date</Link></section>
  </div></main>;
}
