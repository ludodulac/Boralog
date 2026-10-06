import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { getCurrentIdentity } from "../../../../lib/auth";
import { createClient } from "../../../../lib/supabase/server";
import { ProjectEditForm } from "./ProjectEditForm";

const futureAreas = ["Informations", "Messages", "Équipe", "Documents"];

export default async function RealProjectPage({ params }: { params: Promise<{ projectId: string }> }) {
  const { projectId } = await params;
  const identity = await getCurrentIdentity();
  if (!identity.userId) redirect("/auth/connexion");
  if (!identity.organization) notFound();

  const supabase = await createClient();
  const { data: project } = await supabase
    .from("projects")
    .select("id, name, description, organization_id, organizations(name)")
    .eq("id", projectId)
    .eq("organization_id", identity.organization.id)
    .maybeSingle();
  if (!project) notFound();

  const canEdit = identity.organization.accessLevel === "owner" || identity.organization.accessLevel === "full";

  const joined = Array.isArray(project.organizations) ? project.organizations[0] : project.organizations;
  const organizationName = joined?.name ?? "Structure";

  return <main className="entity-page"><div className="entity-wrap project-v1">
    <Link className="entity-back" href="/">← {organizationName}</Link>
    <header className="entity-header project-v1-header">
      <p className="eyebrow">PROJET · {organizationName.toUpperCase()}</p>
      <h1>{project.name}</h1>
      {project.description && <p>{project.description}</p>}
    </header>
    {canEdit && <ProjectEditForm projectId={project.id} name={project.name} description={project.description} />}
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
