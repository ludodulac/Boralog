import Link from "next/link";
import { MapPin } from "lucide-react";
import { getCurrentIdentity } from "../../lib/auth";
import { createClient } from "../../lib/supabase/server";

function displayDate(value: string) {
  const [year, month, day] = value.split("-");
  return `${day}/${month}/${year}`;
}

function displayTime(value: string | null) {
  if (!value) return null;
  const match = value.match(/T(\d{2}):(\d{2})/);
  return match ? `${match[1]}:${match[2]}` : null;
}

export default async function CalendarPage() {
  const identity = await getCurrentIdentity();
  if (!identity.organization) return null;

  const supabase = await createClient();
  const { data: projects } = await supabase
    .from("projects")
    .select("id, name")
    .eq("organization_id", identity.organization.id)
    .is("archived_at", null);

  const realProjects = projects ?? [];
  const projectIds = realProjects.map((project) => project.id);
  const projectNames = new Map(realProjects.map((project) => [project.id, project.name]));

  const { data: events } = projectIds.length === 0
    ? { data: [] }
    : await supabase
        .from("events")
        .select("id, project_id, event_date, starts_at, city, venue_name")
        .in("project_id", projectIds)
        .order("event_date", { ascending: true })
        .order("starts_at", { ascending: true, nullsFirst: true });

  const realEvents = events ?? [];

  return <main className="calendar-page">
    <div className="calendar-wrap">
      <Link className="list-back" href="/">← Retour à Boralog</Link>
      <header className="calendar-header"><p className="eyebrow">CALENDRIER</p><h1>Dates</h1><p>Une vue chronologique des dates de vos projets.</p></header>
      <div className="calendar-legend" aria-label="Légende"><span><MapPin size={16} aria-hidden="true"/> Date de projet</span></div>
      {realEvents.length === 0 ? (
        <p className="work-empty">Aucune date enregistrée pour le moment.</p>
      ) : (
        <div className="timeline">
          {realEvents.map((event) => {
            const time = displayTime(event.starts_at);
            const place = [event.venue_name, event.city].filter(Boolean).join(" · ");
            return <article className="timeline-item event" key={event.id}>
              <div className="timeline-date">{displayDate(event.event_date)}</div>
              <div className="timeline-marker" aria-hidden="true"><MapPin size={18}/></div>
              <div className="timeline-copy">
                <span className="tag">{time ?? "Heure non renseignée"}</span>
                <h2>{projectNames.get(event.project_id) ?? "Projet"}</h2>
                {place && <p>{place}</p>}
              </div>
            </article>;
          })}
        </div>
      )}
    </div>
  </main>;
}
