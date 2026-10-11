import Link from "next/link";
import { CheckCircle2, Circle } from "lucide-react";
import { redirect } from "next/navigation";
import { getCurrentIdentity } from "../../../lib/auth";
import { createClient } from "../../../lib/supabase/server";

function displayCivilDate(value: string) {
  const [year, month, day] = value.split("-");
  return `${day}/${month}/${year}`;
}

export default async function AllTasksPage() {
  const identity = await getCurrentIdentity();
  if (!identity.userId) redirect("/auth/connexion");
  if (!identity.organization) return null;

  const supabase = await createClient();
  const { data: tasks, error } = await supabase
    .from("tasks")
    .select("id, project_id, event_id, content, status, created_at, completed_at")
    .eq("organization_id", identity.organization.id)
    .in("status", ["TO_DO", "DONE"])
    .order("created_at", { ascending: false });

  const realTasks = tasks ?? [];
  const projectIds = [...new Set(realTasks.map((task) => task.project_id).filter(Boolean) as string[])];
  const eventIds = [...new Set(realTasks.map((task) => task.event_id).filter(Boolean) as string[])];

  const [{ data: projects }, { data: events }] = await Promise.all([
    projectIds.length > 0
      ? supabase.from("projects").select("id, name").in("id", projectIds)
      : Promise.resolve({ data: [] as { id: string; name: string }[], error: null }),
    eventIds.length > 0
      ? supabase.from("events").select("id, event_date, venue_name, city").in("id", eventIds)
      : Promise.resolve({ data: [] as { id: string; event_date: string; venue_name: string | null; city: string | null }[], error: null }),
  ]);

  const projectNames = new Map((projects ?? []).map((project) => [project.id, project.name]));
  const eventsById = new Map((events ?? []).map((event) => [event.id, event]));
  const todo = realTasks.filter((task) => task.status === "TO_DO");
  const done = realTasks.filter((task) => task.status === "DONE");

  function renderTask(task: (typeof realTasks)[number]) {
    const event = task.event_id ? eventsById.get(task.event_id) : null;
    const context = [
      task.project_id ? projectNames.get(task.project_id) : null,
      event?.event_date ? displayCivilDate(event.event_date) : null,
      event ? [event.venue_name, event.city].filter(Boolean).join(" · ") : null,
    ].filter(Boolean).join(" · ");

    return <article className="work-task" key={task.id}>
      <div className="work-task-icon">
        {task.status === "DONE"
          ? <CheckCircle2 size={19} aria-hidden="true" />
          : <Circle size={19} aria-hidden="true" />}
      </div>
      <div className="work-task-copy">
        <span className="tag">{task.status === "DONE" ? "TERMINÉ" : "À FAIRE"}</span>
        <h3>{task.content}</h3>
        {context && <p>{context}</p>}
      </div>
    </article>;
  }

  return <main className="list-page work-page">
    <div className="list-page-wrap">
      <Link className="list-back" href="/">← Aujourd’hui</Link>
      <header className="list-page-header">
        <p className="eyebrow">TRAVAIL</p>
        <h1>Tâches</h1>
        <p>Les vraies tâches accessibles dans votre Structure.</p>
      </header>

      {error ? <p role="alert">Les tâches n’ont pas pu être chargées.</p> : (
        <>
          <section className="work-group">
            <div className="work-group-title">
              <div><h2>À faire</h2><p>Ce qui demande encore une action.</p></div>
              <span>{todo.length}</span>
            </div>
            {todo.length > 0 ? <div className="work-list">{todo.map(renderTask)}</div> : <p className="work-empty">Aucune tâche à faire.</p>}
          </section>

          <section className="work-group">
            <div className="work-group-title">
              <div><h2>Terminé</h2><p>Le travail déjà accompli.</p></div>
              <span>{done.length}</span>
            </div>
            {done.length > 0 ? <div className="work-list">{done.map(renderTask)}</div> : <p className="work-empty">Aucune tâche terminée.</p>}
          </section>
        </>
      )}
    </div>
  </main>;
}
