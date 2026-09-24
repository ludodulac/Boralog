import Link from "next/link";
import { TaskList } from "../../../components/TaskList";
import { demoToday } from "../../../data/demo";

const groups = [
  { key: "todo", title: "À faire", note: "Ce qui demande une action maintenant." },
  { key: "soon", title: "Bientôt", note: "Travail prévu, sans urgence immédiate." },
  { key: "done", title: "Terminé", note: "Travail déjà accompli." },
] as const;

export default function AllTasksPage() {
  return <main className="list-page work-page">
    <div className="list-page-wrap">
      <Link className="list-back" href="/">← Retour à Aujourd’hui</Link>
      <header className="list-page-header"><p className="eyebrow">TRAVAIL</p><h1>Toutes les tâches</h1><p>Les actions à accomplir, avec leur contexte et leur échéance.</p></header>
      <p className="work-note">Une tâche correspond à un travail à faire. Les informations manquantes, changements ou réponses attendues peuvent apparaître dans Aujourd’hui sans devenir automatiquement des tâches.</p>
      {groups.map((group) => {
        const tasks = demoToday.work.tasks.filter((task) => task.group === group.key);
        return <section className="work-group" key={group.key}>
          <div className="work-group-title"><div><h2>{group.title}</h2><p>{group.note}</p></div><span>{tasks.length}</span></div>
          <TaskList tasks={tasks}/>
        </section>;
      })}
    </div>
  </main>;
}
