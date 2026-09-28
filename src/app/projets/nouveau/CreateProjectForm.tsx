"use client";

import { useActionState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { createProject } from "./actions";
import { initialCreateProjectState } from "./state";

export function CreateProjectForm({ attemptId }: { attemptId: string }) {
  const router = useRouter();
  const [state, action, pending] = useActionState(createProject, initialCreateProjectState);

  useEffect(() => {
    if (state.status === "success") {
      router.replace(`/projets/reel/${state.projectId}`);
      router.refresh();
    }
  }, [router, state]);

  return <form className="project-create-form" action={action} aria-busy={pending}>
    <input type="hidden" name="attempt_id" value={attemptId}/>
    <label htmlFor="project-name">Nom du projet <span aria-hidden="true">*</span>
      <input id="project-name" name="name" type="text" required maxLength={180} autoComplete="off" disabled={pending} defaultValue={state.values.name}/>
    </label>
    <label htmlFor="project-description">Description <small>Optionnelle</small>
      <textarea id="project-description" name="description" rows={5} disabled={pending} defaultValue={state.values.description}/>
    </label>
    {state.status === "error" && <p className="project-create-feedback error" role="alert">{state.message}</p>}
    <button className="project-create-submit" type="submit" disabled={pending}>{pending ? "Création…" : "Créer le projet"}</button>
  </form>;
}
