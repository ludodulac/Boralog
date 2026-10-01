import Link from "next/link";
import { TaskList } from "../../../components/TaskList";
import { demoProjects, demoToday } from "../../../data/demo";

const groups = [
  { key: "todo", title: "À faire", note: "Ce qui demande une action maintenant." },
  { key: "soon", title: "Bientôt", note: "Travail prévu, sans urgence immédiate." },
  { key: "done", title: "Terminé", note: "Travail déjà accompli." },
] as const;

export default async function AllTasksPage({ searchParams }: { searchParams: Promise<{ projet?: string; date?: string }> }) {
  const { projet, date } = await searchParams;
  const project = projet ? demoProjects.find((item) => item.slug === projet) : undefined;
  const projectDate = project && date ? project.dates.find((item) => item.slug === date) : undefined;
  const contextual = Boolean(project);
  const tasks = demoToday.work.tasks.filter((task) => (!project || task.projectSlug === project.slug) && (!projectDate || task.dateSlug === projectDate.slug));
  const title = projectDate ? `Tâches — ${project!.name} · ${projectDate.city} · ${projectDate.shortDate}` : project ? `Tâches — ${project.name}` : "Toutes les tâches";
  const returnHref = projectDate ? `/projets/${project!.slug}/dates/${projectDate.slug}` : project ? `/projets/${project.slug}` : "/";
  const returnLabel = projectDate ? `Retour à la date de ${projectDate.city}` : project ? `Retour au projet ${project.name}` : "Retour à Aujourd’hui";
  return <main className="list-page work-page">
    <div className="list-page-wrap">
      <Link className="list-back" href={returnHref}>← {returnLabel}</Link>
      <header className="list-page-header"><p className="eyebrow">{contextual ? "TRAVAIL CONTEXTUALISÉ" : "TRAVAIL"}</p><h1>{title}</h1><p>{contextual ? "Uniquement les tâches rattachées à ce contexte." : "Les actions à accomplir, avec leur contexte et leur échéance."}</p></header>
      <p className="work-note">Une tâche correspond à un travail à faire. Les informations manquantes, changements ou réponses attendues peuvent apparaître dans Aujourd’hui sans devenir automatiquement des tâches.</p>
      {groups.map((group) => {
        const groupTasks = tasks.filter((task) => task.group === group.key);
        if (contextual && groupTasks.length === 0) return null;
        return <section className="work-group" key={group.key}>
          <div className="work-group-title"><div><h2>{group.title}</h2><p>{group.note}</p></div><span>{groupTasks.length}</span></div>
          <TaskList tasks={groupTasks}/>
        </section>;
      })}
      {contextual && tasks.length === 0 && <p className="work-empty">Aucune tâche n’est rattachée à ce contexte.</p>}
    </div>
  </main>;
}
