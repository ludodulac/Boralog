import Link from "next/link";
import { AttentionList } from "../../../components/AttentionList";
import { demoToday } from "../../../data/demo";

export default function AttentionPage() {
  return <main className="list-page">
    <div className="list-page-wrap">
      <Link className="list-back" href="/">← Retour à Aujourd’hui</Link>
      <header className="list-page-header">
        <p className="eyebrow">AUJOURD’HUI</p>
        <h1>À faire maintenant</h1>
        <p>Uniquement ce qui demande une action ou une attention immédiate. Une attention n’est pas automatiquement une tâche.</p>
      </header>
      <AttentionList items={demoToday.attention.items} />
    </div>
  </main>;
}
