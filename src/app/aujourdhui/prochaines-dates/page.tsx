import Link from "next/link";
import { UpcomingDatesList } from "../../../components/UpcomingDatesList";
import { demoToday } from "../../../data/demo";

export default function AllUpcomingDatesPage() {
  return <main className="list-page">
    <div className="list-page-wrap">
      <Link className="list-back" href="/">← Retour à Aujourd’hui</Link>
      <header className="list-page-header"><p className="eyebrow">AUJOURD’HUI</p><h1>Prochaines dates</h1><p>{demoToday.upcoming.rangeLabel}</p></header>
      <UpcomingDatesList />
    </div>
  </main>;
}
