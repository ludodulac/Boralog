import Link from "next/link";
import { getCurrentIdentity } from "../lib/auth";
import { createClient } from "../lib/supabase/server";

export default async function Home() {
  const identity = await getCurrentIdentity();
  if (!identity.organization) return null;

  const supabase = await createClient();
  const { data: projects } = await supabase
    .from("projects")
    .select("id, name, description")
    .eq("organization_id", identity.organization.id)
    .is("archived_at", null)
    .order("created_at", { ascending: false });

  const realProjects = projects ?? [];

  return <main className="real-projects-page"><div className="real-projects-card">
    <p className="eyebrow">STRUCTURE</p>
    <h1>{identity.organization.name}</h1>
    <p className="real-projects-intro">Votre structure est prête.</p>
    {realProjects.length === 0 ? (
      <strong className="real-projects-empty">Aucun projet pour le moment.</strong>
    ) : (
      <section className="real-projects-section" aria-labelledby="real-projects-title">
        <h2 id="real-projects-title">Projets</h2>
        <div className="real-project-list">
          {realProjects.map((project) => <Link className="real-project-row" href={`/projets/reel/${project.id}`} key={project.id}>
            <span><strong>{project.name}</strong>{project.description && <small>{project.description}</small>}</span>
            <span className="real-project-open">Ouvrir →</span>
          </Link>)}
        </div>
      </section>
    )}
    <Link className="project-create-cta" href="/projets/nouveau">Créer un projet</Link>
  </div></main>;
}
