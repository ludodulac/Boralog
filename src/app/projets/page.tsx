import Link from "next/link";
import { redirect } from "next/navigation";
import { getCurrentIdentity } from "../../lib/auth";
import { createClient } from "../../lib/supabase/server";

export default async function ProjectsPage() {
  const identity = await getCurrentIdentity();
  if (!identity.userId) redirect("/auth/connexion");
  if (!identity.organization) return null;

  const supabase = await createClient();
  const { data: projects, error } = await supabase
    .from("projects")
    .select("id, name, description")
    .eq("organization_id", identity.organization.id)
    .is("archived_at", null)
    .order("created_at", { ascending: false });

  const realProjects = projects ?? [];

  return <main className="entity-page"><div className="entity-wrap">
    <Link className="entity-back" href="/">← Retour à Aujourd’hui</Link>
    <header className="entity-header">
      <p className="eyebrow">PROJETS</p>
      <h1>Projets</h1>
      <p>Les Projets réels de votre Structure.</p>
    </header>

    {error ? (
      <p role="alert">Les Projets n’ont pas pu être chargés.</p>
    ) : realProjects.length === 0 ? (
      <div className="work-empty">
        <p>Aucun projet pour le moment.</p>
        <Link className="project-create-cta" href="/projets/nouveau">Créer un projet</Link>
      </div>
    ) : (
      <>
        <div className="project-list">
          {realProjects.map((project) => (
            <Link className="project-row" href={`/projets/reel/${project.id}`} key={project.id}>
              <div>
                <h2>{project.name}</h2>
                {project.description && <p>{project.description}</p>}
              </div>
              <span className="project-next">Ouvrir →</span>
            </Link>
          ))}
        </div>
        <Link className="project-create-cta" href="/projets/nouveau">Créer un projet</Link>
      </>
    )}
  </div></main>;
}
