import Link from "next/link";
import { ArrowRight, CalendarDays } from "lucide-react";
import { demoProjects } from "../../data/demo";

export default function ProjectsPage() {
  return <main className="entity-page"><div className="entity-wrap">
    <Link className="entity-back" href="/">← Retour à Aujourd’hui</Link>
    <header className="entity-header"><p className="eyebrow">PROJETS</p><h1>Projets et spectacles</h1><p>Les projets auxquels tu as accès et leurs prochaines dates.</p></header>
    <div className="project-list">{demoProjects.map((project) => {
      const nextDate = project.dates[0];
      return <Link className="project-row" href={`/projets/${project.slug}`} key={project.slug}>
        <div><span className="tag">{project.status}</span><h2>{project.name}</h2><p>{project.structure}</p></div>
        <div className="project-next"><CalendarDays size={17} aria-hidden="true"/><span>{nextDate.shortDate} · {nextDate.city}</span><ArrowRight size={18} aria-hidden="true"/></div>
      </Link>;
    })}</div>
  </div></main>;
}
