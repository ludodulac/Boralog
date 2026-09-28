import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { createClient } from "../../../../../lib/supabase/server";

function displayDate(startsAt: string) {
  const [datePart, timePart = ""] = startsAt.split("T");
  const [year, month, day] = datePart.split("-");
  const date = new Intl.DateTimeFormat("fr-FR", { day: "numeric", month: "long", year: "numeric", timeZone: "UTC" }).format(new Date(`${datePart}T00:00:00Z`));
  const hhmm = timePart.slice(0, 5);
  return { date, time: hhmm === "00:00" ? null : hhmm, key: `${year}-${month}-${day}` };
}

export default async function ProjectDatesPage({ params }: { params: Promise<{ projectId: string }> }) {
  const { projectId } = await params;
  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError || !authData.user) redirect("/auth/connexion");
  const { data: project } = await supabase.from("projects").select("id, name").eq("id", projectId).maybeSingle();
  if (!project) notFound();
  const { data: events } = await supabase.from("events").select("id, starts_at, city, venue_name, status").eq("project_id", project.id).order("starts_at", { ascending: true });
  const realDates = (events ?? []).filter((event) => event.starts_at);

  return <main className="entity-page"><div className="entity-wrap">
    <Link className="entity-back" href={`/projets/reel/${project.id}`}>← {project.name}</Link>
    <header className="entity-header"><p className="eyebrow">PROJET · DATES</p><h1>Dates</h1><p>Retrouvez ici les dates du projet.</p></header>
    {realDates.length === 0 ? <section className="date-ui-empty"><p>Aucune date pour le moment.</p></section> :
      <section className="real-date-list" aria-label="Dates du projet">{realDates.map((event) => {
        const shown = displayDate(event.starts_at!);
        return <article className="real-date-row" key={event.id}><strong>{shown.date}</strong><span>{shown.time ? `${shown.time} · ` : ""}{[event.venue_name, event.city].filter(Boolean).join(" · ") || "Lieu non renseigné"}</span></article>;
      })}</section>}
    <Link className="project-create-cta" href={`/projets/reel/${project.id}/dates/nouvelle`}>Créer une date</Link>
  </div></main>;
}
