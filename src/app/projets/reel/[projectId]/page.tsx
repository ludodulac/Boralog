import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { createClient } from "../../../../lib/supabase/server";

const futureAreas = ["Informations", "Messages", "Équipe", "Documents"];

export default async function RealProjectPage({ params }: { params: Promise<{ projectId: string }> }) {
  const { projectId } = await params;
  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError || !authData.user) redirect("/auth/connexion");

  const { data: project } = await supabase
    .from("projects")
    .select("id, name, description, organization_id, organizations(name)")
    .eq("id", projectId)
    .maybeSingle();
  if (!project) notFound();

  const joined = Array.isArray(project.organizations) ? project.organizations[0] : project.organizations;
  const organizationName = joined?.name ?? "Structure";

  return <main className="entity-page"><div className="entity-wrap project-v1">
    <Link className="entity-back" href="/">← {organizationName}</Link>
    <header className="entity-header project-v1-header">
      <p className="eyebrow">PROJET · {organizationName.toUpperCase()}</p>
      <h1>{project.name}</h1>
      {project.description && <p>{project.description}</p>}
    </header>
    <section className="project-v1-space" aria-labelledby="project-space-title">
      <div className="project-v1-space-heading">
        <h2 id="project-space-title">Espace projet</h2>
        <p>Les espaces de travail seront disponibles progressivement.</p>
      </div>
      <div className="project-v1-areas" aria-label="Espaces du projet">
        <Link className="project-v1-area project-v1-area-link" href={`/projets/reel/${project.id}/dates`}>
          <span>Dates</span>
          <small>Ouvrir →</small>
        </Link>
        {futureAreas.map((area) => <div className="project-v1-area" key={area}>
          <span>{area}</span>
          <small>À venir</small>
        </div>)}
      </div>
    </section>
  </div></main>;
}
