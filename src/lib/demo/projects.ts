import { DEMO_ORG_ID } from "./local-db";

export const DEMO_PROJECTS = [
  { id: "00000000-0000-4000-8000-000000000101", organization_id: DEMO_ORG_ID, name: "Les Étoiles du soir", status: "en cours", description: "Création fictive de la Compagnie Horizon.", fictitious: true },
  { id: "00000000-0000-4000-8000-000000000102", organization_id: DEMO_ORG_ID, name: "Le Voyage des lucioles", status: "en préparation", description: "Projet de spectacle fictif.", fictitious: true },
] as const;

// Independent, versioned seed: existing local data and user edits remain untouched.
export async function initializeDemoProjects(db: IDBDatabase): Promise<void> {
  await new Promise<void>((resolve, reject) => {
    const tx = db.transaction(["_meta", "projects"], "readwrite");
    const marker = tx.objectStore("_meta").get("demo-projects-v1");
    marker.onsuccess = () => {
      if (marker.result) return;
      const store = tx.objectStore("projects");
      for (const project of DEMO_PROJECTS) store.put(project);
      tx.objectStore("_meta").put({ id: "demo-projects-v1", initialized_at: new Date().toISOString() });
    };
    marker.onerror = () => tx.abort();
    tx.oncomplete = () => resolve();
    tx.onerror = () => reject(tx.error ?? new Error("Impossible d'initialiser les projets"));
    tx.onabort = () => reject(tx.error ?? new Error("Initialisation des projets interrompue"));
  });
}
