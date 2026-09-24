import Link from "next/link";
import { ArrowRight, CalendarDays, UsersRound } from "lucide-react";
import { notFound } from "next/navigation";
import { demoProjects } from "../../../data/demo";

export function generateStaticParams() { return demoProjects.map((project) => ({ projectSlug: project.slug })); }

export default async function ProjectPage({ params }: { params: Promise<{ projectSlug: string }> }) {
  const { projectSlug } = await params;
  const project = demoProjects.find((item) => item.slug === projectSlug);
  if (!project) notFound();
  return <main className="entity-page"><div className="entity-wrap">
    <Link className="entity-back" href="/projets">← Projets</Link>
    <header className="entity-header"><p className="eyebrow">{project.structure.toUpperCase()}</p><h1>{project.name}</h1><p>{project.status}</p></header>
    <section className="entity-section"><div className="entity-section-title"><div><h2>Prochaines dates</h2><p>Ouvrir une date pour retrouver ses informations.</p></div></div>
      <div className="date-links">{project.dates.map((date) => <Link className="date-link" href={`/projets/${project.slug}/dates/${date.slug}`} key={date.slug}>
        <CalendarDays size={20} aria-hidden="true"/><div><strong>{date.dateLabel}</strong><span>{date.city} · {date.venue}</span></div><ArrowRight size={18} aria-hidden="true"/>
      </Link>)}</div>
    </section>
    <section className="entity-section"><div className="entity-section-title"><div><h2>Équipe</h2><p>Repères utiles pour ce projet.</p></div><UsersRound size={20} aria-hidden="true"/></div><div className="team-list">{project.team.map((person) => <span key={person}>{person}</span>)}</div></section>
    <section className="entity-section entity-placeholder"><h2>Autour du projet</h2><p>Les informations, conversations et documents appartiendront à ce contexte. Ces modules ne sont pas encore construits.</p></section>
  </div></main>;
}
