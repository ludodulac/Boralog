"use client";

import Link from "next/link";
import { useEffect, useState, type FormEvent } from "react";
import { DEMO_ORG_ID, initializeDemo, listRecords, mutateDemo, openDemoDatabase } from "@/lib/demo/local-db";
import { initializeDemoProjects } from "@/lib/demo/projects";

type Project = { id: string; name: string; status: string; description?: string };

export default function DemoProjectsPage() {
  const [projects, setProjects] = useState<Project[] | null>(null);
  const [error, setError] = useState(false);
  const [formOpen, setFormOpen] = useState(false);
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [status, setStatus] = useState("en préparation");
  const [formError, setFormError] = useState("");
  const [saving, setSaving] = useState(false);

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

  async function createProject(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (saving) return;
    const trimmedName = name.trim();
    if (!trimmedName || trimmedName.length > 180) {
      setFormError("Le nom du projet est obligatoire (180 caractères maximum).");
      return;
    }
    if (!["en préparation", "en cours"].includes(status)) {
      setFormError("Statut invalide.");
      return;
    }
    setSaving(true);
    setFormError("");
    let db: IDBDatabase | undefined;
    try {
      db = await openDemoDatabase();
      const project = {
        id: crypto.randomUUID(), organization_id: DEMO_ORG_ID,
        name: trimmedName, description: description.trim(), status,
      };
      await mutateDemo(db, [{ operation: "create", store: "projects", id: project.id, value: project }]);
      setProjects(previous => previous === null ? [project] : [...previous, project]);
      setName("");
      setDescription("");
      setStatus("en préparation");
      setFormOpen(false);
    } catch {
      setFormError("Impossible d’enregistrer le projet localement. Réessayez.");
    } finally {
      db?.close();
      setSaving(false);
    }
  }

  return <main className="entity-page"><div className="entity-wrap">
    <Link className="entity-back" href="/demo/organisation">← Retour à Compagnie Horizon</Link>
    <header className="entity-header">
      <p className="eyebrow">PROJETS — DÉMONSTRATION LOCALE</p>
      <h1>Projets</h1>
      <p>Les Projets fictifs de Compagnie Horizon.</p>
    </header>
    <button type="button" className="project-create-cta" onClick={() => { setFormOpen(true); setFormError(""); }}>Nouveau projet</button>
    {formOpen && <form className="project-create-form" onSubmit={createProject} aria-busy={saving} data-testid="demo-create-project-form">
      <label htmlFor="demo-project-name">Nom du projet <span aria-hidden="true">*</span>
        <input id="demo-project-name" value={name} onChange={event => setName(event.target.value)} required maxLength={180} disabled={saving}/>
      </label>
      <label htmlFor="demo-project-description">Description <small>Optionnelle</small>
        <textarea id="demo-project-description" rows={5} value={description} onChange={event => setDescription(event.target.value)} disabled={saving}/>
      </label>
      <label htmlFor="demo-project-status">Statut
        <select id="demo-project-status" value={status} onChange={event => setStatus(event.target.value)} disabled={saving}>
          <option value="en préparation">En préparation</option>
          <option value="en cours">En cours</option>
        </select>
      </label>
      {formError && <p role="alert" className="project-create-feedback error">{formError}</p>}
      <button type="submit" className="project-create-submit" disabled={saving}>{saving ? "Enregistrement…" : "Enregistrer"}</button>
      <button type="button" disabled={saving} onClick={() => { setFormOpen(false); setFormError(""); }}>Annuler</button>
    </form>}
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
