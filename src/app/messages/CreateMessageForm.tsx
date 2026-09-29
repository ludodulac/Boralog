"use client";

import { useActionState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import { createMessage } from "./actions";
import { initialCreateMessageState } from "./state";

type MessageProjectOption = {
  id: string;
  name: string;
};

export function CreateMessageForm({
  projects,
  requiresProject,
}: {
  projects: MessageProjectOption[];
  requiresProject: boolean;
}) {
  const router = useRouter();
  const formRef = useRef<HTMLFormElement>(null);
  const [state, action, pending] = useActionState(createMessage, initialCreateMessageState);

  useEffect(() => {
    if (state.status === "success") {
      formRef.current?.reset();
      router.refresh();
    }
  }, [router, state]);

  return <form ref={formRef} className="project-create-form" action={action} aria-busy={pending}>
    <label htmlFor="message-content">Message à traiter
      <textarea
        id="message-content"
        name="content"
        rows={5}
        required
        disabled={pending}
        defaultValue={state.values.content}
      />
    </label>

    <label htmlFor="message-project">Projet{requiresProject ? "" : " — facultatif"}
      <select
        id="message-project"
        name="project_id"
        required={requiresProject}
        disabled={pending}
        defaultValue={state.values.projectId}
      >
        <option value="">Aucun projet</option>
        {projects.map((project) => <option value={project.id} key={project.id}>{project.name}</option>)}
      </select>
    </label>

    {state.status === "error" && <p className="project-create-feedback error" role="alert">{state.message}</p>}
    {state.status === "success" && <p className="project-create-feedback" role="status">{state.message}</p>}
    <button className="project-create-submit" type="submit" disabled={pending}>
      {pending ? "Enregistrement…" : "Créer le message"}
    </button>
  </form>;
}
