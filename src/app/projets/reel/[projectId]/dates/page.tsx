import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { createClient } from "../../../../../lib/supabase/server";

function displayDate(value: string) {
  const [year, month, day] = value.split("-");
  return `${day}/${month}/${year}`;
}

function displayTime(value: string | null) {
  if (!value) return null;
  const match = value.match(/T(\d{2}):(\d{2})/);
  return match ? `${match[1]}:${match[2]}` : null;
}

export default async function ProjectDatesPage({ params }: { params: Promise<{ projectId: string }> }) {
  const { projectId } = await params;
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
  const dates = events ?? [];

  return <main className="entity-page"><div className="entity-wrap">
    <Link className="entity-back" href={`/projets/reel/${project.id}`}>← {project.name}</Link>
    <header className="entity-header"><p className="eyebrow">PROJET · DATES</p><h1>Dates</h1><p>Retrouvez ici les dates du projet.</p></header>
    {dates.length === 0 ? <section className="date-ui-empty"><p>Aucune date pour le moment.</p></section> :
      <section className="real-date-list" aria-label="Dates enregistrées">{dates.map((event) => {
        const time = displayTime(event.starts_at);
        const place = [event.venue_name, event.city].filter(Boolean).join(" · ");
        return <article className="real-date-row" key={event.id}>
          <strong>{displayDate(event.event_date)}</strong>
          <span>{time ?? "Heure non renseignée"}</span>
          {place && <small>{place}</small>}
        </article>;
      })}</section>}
    <Link className="project-create-cta" href={`/projets/reel/${project.id}/dates/nouvelle`}>Créer une date</Link>
  </div></main>;
}
