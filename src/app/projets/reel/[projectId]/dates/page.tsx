import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { createClient } from "../../../../../lib/supabase/server";

function formatCivilDate(value: string) {
  const [year, month, day] = value.split("-").map(Number);
  return new Intl.DateTimeFormat("fr-FR", { dateStyle: "long", timeZone: "UTC" }).format(new Date(Date.UTC(year, month - 1, day)));
}

export default async function ProjectDatesPage({ params, searchParams }: { params: Promise<{ projectId: string }>; searchParams: Promise<{ created?: string }> }) {
  const { projectId } = await params;
  const query = await searchParams;
  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError || !authData.user) redirect("/auth/connexion");

  const { data: project } = await supabase.from("projects").select("id, name").eq("id", projectId).maybeSingle();
  if (!project) notFound();

  const { data: events } = await supabase
    .from("events")
    .select("id, event_date, starts_at, city, venue_name, status")
    .eq("project_id", project.id)
    .order("event_date", { ascending: true })
    .order("starts_at", { ascending: true, nullsFirst: true });

  const realDates = events ?? [];

  return <main className="entity-page"><div className="entity-wrap">
    <Link className="entity-back" href={`/projets/reel/${project.id}`}>← {project.name}</Link>
    <header className="entity-header"><p className="eyebrow">PROJET · DATES</p><h1>Dates</h1><p>Retrouvez ici les dates du projet.</p></header>
    {query.created === "1" && <p className="date-success" role="status">Date créée et enregistrée.</p>}
    {realDates.length === 0 ? <section className="date-ui-empty"><p>Aucune date pour le moment.</p></section> :
      <section className="real-date-list" aria-label="Dates enregistrées">
        {realDates.map((event) => <article className="real-date-row" key={event.id}>
          <strong>{formatCivilDate(event.event_date)}</strong>
          {(event.city || event.venue_name) && <span>{[event.city, event.venue_name].filter(Boolean).join(" · ")}</span>}
        </article>)}
      </section>}
    <Link className="project-create-cta" href={`/projets/reel/${project.id}/dates/nouvelle`}>Créer une date</Link>
  </div></main>;
}
