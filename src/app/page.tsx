import { CalendarDays, MessageCircle, FolderKanban, Search, UserRound, ArrowRight, CircleAlert, TrainFront } from "lucide-react";

const nav = [
  [CalendarDays, "Aujourd’hui"], [MessageCircle, "Messages"], [FolderKanban, "Projets"], [Search, "Recherche"], [UserRound, "Moi"]
] as const;

export default function Home() {
  return <main className="app-shell">
    <aside className="side-nav">
      <div className="brand"><span>B</span><strong>Boralog</strong></div>
      <nav>{nav.map(([Icon,label],i)=><button className={i===0?"active":""} key={label}><Icon size={20}/><span>{label}</span></button>)}</nav>
      <div className="org"><small>Organisation</small><strong>Bora Bora Productions</strong><span>Production</span></div>
    </aside>
    <section className="workspace">
      <header><div><p className="eyebrow">JEUDI 24 SEPTEMBRE</p><h1>Bonjour Marion</h1><p className="subtitle">Voici uniquement ce qui demande ton attention.</p></div><button className="search"><Search size={19}/><span>Rechercher</span><kbd>⌘ K</kbd></button></header>
      <div className="content">
        <section className="attention"><div className="section-title"><div><h2>À faire maintenant</h2><p>3 éléments</p></div><button>Tout voir <ArrowRight size={16}/></button></div>
          <article className="task urgent"><div className="task-icon"><CircleAlert size={20}/></div><div className="task-copy"><span className="tag">INFORMATION MANQUANTE</span><h3>Train retour de Pierre</h3><p><strong>XXX · Brest</strong> · 28 septembre</p></div><div className="task-meta"><span>Aujourd’hui</span><ArrowRight size={18}/></div></article>
          <article className="task"><div className="task-icon"><MessageCircle size={20}/></div><div className="task-copy"><span className="tag">MESSAGE</span><h3>Jeanne attend une réponse</h3><p><strong>Phantasia · Nantes</strong> · Logistique</p></div><div className="task-meta"><span>Il y a 32 min</span><ArrowRight size={18}/></div></article>
          <article className="task"><div className="task-icon"><TrainFront size={20}/></div><div className="task-copy"><span className="tag">CHANGEMENT</span><h3>Nouvelle heure d’arrivée : 18 h 12</h3><p><strong>Dame Jument · Lorient</strong> · Transport mis à jour</p></div><div className="task-meta"><span>À vérifier</span><ArrowRight size={18}/></div></article>
        </section>
        <section className="upcoming"><div className="section-title"><div><h2>Prochaines dates</h2><p>Les 7 prochains jours</p></div></div><div className="dates"><article><div className="datebox"><b>28</b><span>SEP</span></div><div><h3>XXX</h3><p>Brest · Le Quartz</p></div><span className="status warn">1 info manque</span></article><article><div className="datebox"><b>30</b><span>SEP</span></div><div><h3>Phantasia</h3><p>Nantes · TU-Nantes</p></div><span className="status">Complet</span></article></div></section>
      </div>
    </section>
    <nav className="bottom-nav">{nav.map(([Icon,label],i)=><button className={i===0?"active":""} key={label}><Icon size={21}/><span>{label}</span></button>)}</nav>
  </main>;
}
