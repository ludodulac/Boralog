import Link from "next/link";
import { CalendarClock, MapPin } from "lucide-react";
import { demoToday } from "../../data/demo";

const timeline = [
  ...demoToday.work.events.map((event) => ({ sort: event.sort, type: "event" as const, title: event.title, date: event.date, meta: `${event.kind} · ${event.time}`, detail: event.detail })),
  ...demoToday.work.tasks.filter((task) => task.status !== "Terminé").map((task) => ({ sort: task.deadlineSort, type: "deadline" as const, title: task.title, date: task.deadline, meta: "Échéance de tâche", detail: task.project })),
].sort((a, b) => a.sort.localeCompare(b.sort));

export default function CalendarPage() {
  return <main className="calendar-page">
    <div className="calendar-wrap">
      <Link className="list-back" href="/">← Retour à Boralog</Link>
      <header className="calendar-header"><p className="eyebrow">CALENDRIER</p><h1>Dates et échéances</h1><p>Une vue chronologique des prochains événements et du travail à terminer.</p></header>
      <div className="calendar-legend" aria-label="Légende"><span><MapPin size={16} aria-hidden="true"/> Événement / date</span><span><CalendarClock size={16} aria-hidden="true"/> Échéance de tâche</span></div>
      <div className="timeline">
        {timeline.map((item) => <article className={`timeline-item ${item.type}`} key={item.sort + item.title}>
          <div className="timeline-date">{item.date}</div>
          <div className="timeline-marker" aria-hidden="true">{item.type === "event" ? <MapPin size={18}/> : <CalendarClock size={18}/>}</div>
          <div className="timeline-copy"><span className="tag">{item.meta}</span><h2>{item.title}</h2><p>{item.detail}</p></div>
        </article>)}
      </div>
    </div>
  </main>;
}
