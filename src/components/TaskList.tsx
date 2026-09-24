import { CalendarClock, CheckCircle2 } from "lucide-react";
import { demoToday } from "../data/demo";

type WorkTask = (typeof demoToday.work.tasks)[number];

export function TaskList({ tasks }: { tasks: readonly WorkTask[] }) {
  return <div className="work-list">
    {tasks.map((task) => <article className="work-task" key={task.id}>
      <div className="work-task-icon">{task.status === "Terminé" ? <CheckCircle2 size={19} aria-hidden="true"/> : <CalendarClock size={19} aria-hidden="true"/>}</div>
      <div className="work-task-copy">
        <div className="work-task-top"><span className="tag">{task.status}</span><span className="work-priority">{task.priority}</span></div>
        <h3>{task.title}</h3>
        <p><strong>{task.project}</strong>{task.eventLabel ? ` · ${task.eventLabel}` : ""}</p>
        <p className="work-details">Échéance : <strong>{task.deadline}</strong> · Responsable : {task.assignee}</p>
      </div>
    </article>)}
  </div>;
}
