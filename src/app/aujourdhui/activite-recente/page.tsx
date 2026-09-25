import Link from "next/link";
import { RecentActivityList } from "../../../components/RecentActivityList";
import { demoRecentActivity } from "../../../data/demo";

export default function RecentActivityPage() {
  return <main className="list-page">
    <div className="list-page-wrap">
      <Link className="list-back" href="/">← Retour à Aujourd’hui</Link>
      <header className="list-page-header">
        <p className="eyebrow">AUJOURD’HUI</p>
        <h1>Depuis votre dernière visite</h1>
        <p>Prototype : changements récents issus des informations de référence. La dernière consultation réelle n’est pas encore suivie.</p>
      </header>
      <RecentActivityList items={demoRecentActivity} />
    </div>
  </main>;
}
