"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { DEMO_ORG_ID, initializeDemo, listRecords, openDemoDatabase } from "@/lib/demo/local-db";
import { initializeDemoProjects } from "@/lib/demo/projects";

type Project = { id: string; name: string; status: string; description?: string };

export default function DemoProjectsPage() {
  const [projects, setProjects] = useState<Project[] | null>(null);
  const [error, setError] = useState(false);

  useEffect(() => {
    let active = true;
    (async () => {
      let db: IDBDatabase | undefined;
      try {
        db = await openDemoDatabase();
        await initializeDemo(db);
        await initializeDemoProjects(db);
        const records = await listRecords(db, "projects");
        const valid = records.filter((record): record is typeof record & { name: string; status: string } =>
          record.organization_id === DEMO_ORG_ID && typeof record.name === "string" && typeof record.status === "string"
        );
        if (active) setProjects(valid.map(record => ({
          id: record.id, name: record.name, status: record.status,
          description: typeof record.description === "string" ? record.description : undefined,
        })));
      } catch {
        if (active) setError(true);
      } finally {
        db?.close();
      }
    })();
    return () => { active = false; };
  }, []);

  return <main className="entity-page"><div className="entity-wrap">
    <Link className="entity-back" href="/demo/organisation">← Retour à Compagnie Horizon</Link>
    <header className="entity-header">
      <p className="eyebrow">PROJETS — DÉMONSTRATION LOCALE</p>
      <h1>Projets</h1>
      <p>Les Projets fictifs de Compagnie Horizon.</p>
    </header>
    {error ? <p role="alert">Les Projets locaux n’ont pas pu être chargés.</p>
      : projects === null ? <p>Chargement des Projets…</p>
      : projects.length === 0 ? <div className="work-empty"><p>Aucun projet pour le moment.</p></div>
      : <div className="project-list" data-testid="demo-project-list">
        {projects.map(project => <article className="project-row" key={project.id}>
          <div><h2>{project.name}</h2>
            <p>Statut : {project.status}</p>
            {project.description && <p>{project.description}</p>}
          </div>
        </article>)}
      </div>}
  </div></main>;
}
