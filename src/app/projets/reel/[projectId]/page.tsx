import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { createClient } from "../../../../lib/supabase/server";

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
  return <main className="entity-page"><div className="entity-wrap">
    <Link className="entity-back" href="/">← Structure</Link>
    <header className="entity-header">
      <p className="eyebrow">{joined?.name?.toUpperCase() ?? "PROJET"}</p>
      <h1>{project.name}</h1>
      <p>{project.description || "Projet créé. Les détails pourront être ajoutés ensuite."}</p>
    </header>
    <section className="entity-section entity-placeholder"><h2>Projet créé</h2><p>Ce projet est enregistré dans Boralog. Les dates, l’équipe et les messages ne font pas encore partie de cette tranche.</p></section>
  </div></main>;
}
