import { demoToday } from "../data/demo";

type UpcomingDatesListProps = {
  dates?: typeof demoToday.upcoming.dates;
};

export function UpcomingDatesList({ dates = demoToday.upcoming.dates }: UpcomingDatesListProps) {
  return <div className="dates">
    {dates.map((date) => <article key={date.day + date.title}>
      <div className="datebox"><b>{date.day}</b><span>{date.month}</span></div>
      <div><h3>{date.title}</h3><p>{date.detail}</p></div>
      <span className={date.warning ? "status warn" : "status"}>{date.status}</span>
    </article>)}
  </div>;
}
