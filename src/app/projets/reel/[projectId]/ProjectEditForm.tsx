"use client";

import { useActionState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { updateProject } from "./actions";
import { initialProjectEditState } from "./state";

export function ProjectEditForm({
  projectId,
  name,
  description,
}: {
  projectId: string;
  name: string;
  description: string | null;
}) {
  const router = useRouter();
  const [state, action, pending] = useActionState(updateProject, initialProjectEditState);

  useEffect(() => {
    if (state.status === "success") router.refresh();
  }, [router, state.status]);

  return <details className="project-edit-panel">
    <summary>Modifier le projet</summary>
    <form className="project-create-form" action={action}>
      <input type="hidden" name="project_id" value={projectId} />
      <label>Nom du projet
        <input name="name" required maxLength={180} defaultValue={name} disabled={pending} />
      </label>
      <label>Description <small>Optionnelle</small>
        <textarea name="description" rows={5} defaultValue={description ?? ""} disabled={pending} />
      </label>
      {state.status === "error" && <p className="project-create-feedback error" role="alert">{state.message}</p>}
      {state.status === "success" && <p className="project-create-feedback" role="status">{state.message}</p>}
      <button className="project-create-submit" type="submit" disabled={pending}>
        {pending ? "Enregistrement…" : "Enregistrer les modifications"}
      </button>
    </form>
  </details>;
}
