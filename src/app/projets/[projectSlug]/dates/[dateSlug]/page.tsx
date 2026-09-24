import Link from "next/link";
import { notFound } from "next/navigation";
import { demoProjects } from "../../../../../data/demo";

export function generateStaticParams() {
  return demoProjects.flatMap((project) => project.dates.map((date) => ({ projectSlug: project.slug, dateSlug: date.slug })));
}

export default async function DatePage({ params }: { params: Promise<{ projectSlug: string; dateSlug: string }> }) {
  const { projectSlug, dateSlug } = await params;
  const project = demoProjects.find((item) => item.slug === projectSlug);
  const date = project?.dates.find((item) => item.slug === dateSlug);
  if (!project || !date) notFound();
  const domains = [...new Set(date.informations.map((info) => info.domain))];
  return <main className="entity-page"><div className="entity-wrap">
    <nav className="entity-breadcrumb" aria-label="Fil d’Ariane"><Link href="/projets">Projets</Link><span>›</span><Link href={`/projets/${project.slug}`}>{project.name}</Link><span>›</span><span>{date.city}</span></nav>
    <header className="date-header"><p className="eyebrow">{project.name.toUpperCase()}</p><h1>{date.city} · {date.venue}</h1><div className="date-summary"><span><small>Date</small><strong>{date.dateLabel}</strong></span><span><small>État</small><strong>{date.status}</strong></span><span><small>Structure</small><strong>{project.structure}</strong></span></div></header>
    <section className="entity-section"><div className="entity-section-title"><div><h2>Informations de la date</h2><p>Une information de référence, rangée dans son domaine.</p></div></div>
      <div className="domain-stack">{domains.map((domain) => <section className="domain-group" key={domain}><h3>{domain}</h3>{date.informations.filter((info) => info.domain === domain).map((info) => <article className="info-row" key={info.id}>
        <div className="info-main"><div className="info-labels"><span className="tag">{info.domain}</span>{info.freshness !== "À jour" && <span className="freshness">{info.freshness}</span>}</div><h4>{info.title}</h4><p>{info.source}</p></div>
        <div className="info-updated"><span>Mis à jour</span><strong>{info.updatedAt}</strong></div>
      </article>)}</section>)}</div>
    </section>
  </div></main>;
}
