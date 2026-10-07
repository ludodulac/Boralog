import Link from "next/link";
import { redirect } from "next/navigation";
import { CalendarDays, CheckCircle2, MessageCircle } from "lucide-react";
import { getCurrentIdentity } from "../lib/auth";
import { formatBoralogDateTime, getBoralogCivilDate } from "../lib/date-time";
import { createClient } from "../lib/supabase/server";

function displayCivilDate(value: string) {
  const [year, month, day] = value.split("-");
  return `${day}/${month}/${year}`;
}

function displayEventTime(value: string | null) {
  if (!value) return null;
  const match = value.match(/T(\d{2}):(\d{2})/);
  return match ? `${match[1]}:${match[2]}` : null;
}

function preview(value: string, max = 150) {
  return value.length > max ? `${value.slice(0, max - 1)}…` : value;
}

export default async function Home() {
  const identity = await getCurrentIdentity();
  if (!identity.userId) redirect("/auth/connexion");
  if (!identity.organization) return null;

  const supabase = await createClient();
  const today = getBoralogCivilDate();

  const [
    { data: projects },
    { data: messages },
    { data: todoTasks },
  ] = await Promise.all([
    supabase
      .from("projects")
      .select("id, name")
      .eq("organization_id", identity.organization.id)
      .is("archived_at", null),
    supabase
      .from("messages")
      .select("id, project_id, content, created_at")
      .eq("organization_id", identity.organization.id)
      .eq("status", "TO_PROCESS")
      .order("created_at", { ascending: false })
      .limit(5),
    supabase
      .from("tasks")
      .select("id, project_id, event_id, content, created_at")
      .eq("organization_id", identity.organization.id)
      .eq("status", "TO_DO")
      .order("created_at", { ascending: false })
      .limit(5),
  ]);

  const realProjects = projects ?? [];
  const projectIds = realProjects.map((project) => project.id);
  const projectNames = new Map(realProjects.map((project) => [project.id, project.name]));

  const taskEventIds = [...new Set((todoTasks ?? []).map((task) => task.event_id).filter(Boolean) as string[])];
  const { data: taskEvents } = taskEventIds.length > 0
    ? await supabase
        .from("events")
        .select("id, event_date, starts_at, venue_name, city")
        .in("id", taskEventIds)
    : { data: [] as { id: string; event_date: string; starts_at: string | null; venue_name: string | null; city: string | null }[] };

  const taskEventsById = new Map((taskEvents ?? []).map((event) => [event.id, event]));

  const { data: upcomingEvents } = projectIds.length > 0
    ? await supabase
        .from("events")
        .select("id, project_id, event_date, starts_at, venue_name, city")
        .in("project_id", projectIds)
        .gte("event_date", today)
        .order("event_date", { ascending: true })
        .order("starts_at", { ascending: true, nullsFirst: true })
        .limit(5)
    : { data: [] as { id: string; project_id: string; event_date: string; starts_at: string | null; venue_name: string | null; city: string | null }[] };

  const realMessages = messages ?? [];
  const realTodoTasks = todoTasks ?? [];
  const realUpcomingEvents = upcomingEvents ?? [];
  const nothingPending = realMessages.length === 0 && realTodoTasks.length === 0 && realUpcomingEvents.length === 0;

  return <main className="entity-page"><div className="entity-wrap today-page">
    <header className="entity-header today-header">
      <p className="eyebrow">AUJOURD’HUI</p>
      <h1>Aujourd’hui</h1>
      <p>{identity.organization.name}</p>
    </header>

    {nothingPending && <p className="work-note">Rien ne demande votre attention pour le moment.</p>}

    <section className="today-section" aria-labelledby="today-messages-title">
      <div className="section-title">
        <div><h2 id="today-messages-title">Messages à traiter</h2><p>Les derniers Messages encore ouverts.</p></div>
        <Link className="section-more" href="/messages?etat=to-process">Voir tous</Link>
      </div>
      {realMessages.length === 0 ? <p className="work-empty">Aucun Message à traiter.</p> : (
        <div className="message-list">
          {realMessages.map((message) => (
            <Link className="message-card" href={`/messages/${message.id}`} key={message.id}>
              <MessageCircle size={18} aria-hidden="true" />
              <strong>{preview(message.content)}</strong>
              <small>{message.project_id ? `${projectNames.get(message.project_id) ?? "Projet"} · ` : ""}{formatBoralogDateTime(message.created_at, "short")}</small>
            </Link>
          ))}
        </div>
      )}
    </section>

    <section className="today-section" aria-labelledby="today-tasks-title">
      <div className="section-title">
        <div><h2 id="today-tasks-title">Tâches à faire</h2><p>Le travail encore ouvert dans votre Structure.</p></div>
        <Link className="section-more" href="/aujourdhui/a-faire">Voir toutes</Link>
      </div>
      {realTodoTasks.length === 0 ? <p className="work-empty">Aucune tâche à faire.</p> : (
        <div className="work-list">
          {realTodoTasks.map((task) => {
            const event = task.event_id ? taskEventsById.get(task.event_id) : null;
            const context = [
              task.project_id ? projectNames.get(task.project_id) : null,
              event?.event_date ? displayCivilDate(event.event_date) : null,
              event ? [event.venue_name, event.city].filter(Boolean).join(" · ") : null,
            ].filter(Boolean).join(" · ");
            return <article className="work-task" key={task.id}>
              <div className="work-task-icon"><CheckCircle2 size={19} aria-hidden="true" /></div>
              <div className="work-task-copy">
                <span className="tag">À FAIRE</span>
                <h3>{task.content}</h3>
                {context && <p>{context}</p>}
              </div>
            </article>;
          })}
        </div>
      )}
    </section>

    <section className="today-section" aria-labelledby="today-dates-title">
      <div className="section-title">
        <div><h2 id="today-dates-title">Prochaines Dates</h2><p>Les prochaines Dates de vos Projets.</p></div>
        <Link className="section-more" href="/calendrier">Voir toutes</Link>
      </div>
      {realUpcomingEvents.length === 0 ? <p className="work-empty">Aucune Date à venir.</p> : (
        <div className="dates">
          {realUpcomingEvents.map((event) => {
            const time = displayEventTime(event.starts_at);
            const place = [event.venue_name, event.city].filter(Boolean).join(" · ");
            return <article key={event.id}>
              <div className="datebox"><CalendarDays size={18} aria-hidden="true" /></div>
              <div>
                <h3>{projectNames.get(event.project_id) ?? "Projet"}</h3>
                <p>{displayCivilDate(event.event_date)}{time ? ` · ${time}` : ""}{place ? ` · ${place}` : ""}</p>
              </div>
            </article>;
          })}
        </div>
      )}
    </section>
  </div></main>;
}
