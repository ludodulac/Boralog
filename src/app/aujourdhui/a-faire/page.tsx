import Link from "next/link";
import { AttentionList } from "../../../components/AttentionList";
import { demoToday } from "../../../data/demo";

export default function AllAttentionPage() {
  return <main className="list-page">
    <div className="list-page-wrap">
      <Link className="list-back" href="/">← Retour à Aujourd’hui</Link>
      <header className="list-page-header"><p className="eyebrow">AUJOURD’HUI</p><h1>À faire maintenant</h1><p>{demoToday.attention.countLabel}</p></header>
      <AttentionList />
    </div>
  </main>;
}
