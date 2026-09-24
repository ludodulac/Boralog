import { demoToday } from "../data/demo";

export function UpcomingDatesSection() {
  return <section className="upcoming">
    <div className="section-title"><div><h2>Prochaines dates</h2><p>{demoToday.upcoming.rangeLabel}</p></div></div>
    <div className="dates">
      {demoToday.upcoming.dates.map((date) => <article key={date.day}>
        <div className="datebox"><b>{date.day}</b><span>{date.month}</span></div>
        <div><h3>{date.title}</h3><p>{date.detail}</p></div>
        <span className={date.warning ? "status warn" : "status"}>{date.status}</span>
      </article>)}
    </div>
  </section>;
}
