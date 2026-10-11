"use client";

import { useActionState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { renameCurrentOrganization } from "./actions";
import { initialStructureRenameState } from "./state";

export function RenameStructureForm({ currentName }: { currentName: string }) {
  const router = useRouter();
  const [state, action, pending] = useActionState(
    renameCurrentOrganization,
    initialStructureRenameState,
  );

  useEffect(() => {
    if (state.status === "success") router.refresh();
  }, [router, state.status]);

  return <form className="project-create-form" action={action}>
    <label htmlFor="structure-name">Nom de la Structure
      <input
        id="structure-name"
        name="name"
        type="text"
        required
        maxLength={160}
        defaultValue={currentName}
        disabled={pending}
      />
    </label>
    {state.status === "error" && (
      <p className="project-create-feedback error" role="alert">{state.message}</p>
    )}
    {state.status === "success" && (
      <p className="project-create-feedback" role="status">{state.message}</p>
    )}
    <button className="project-create-submit" type="submit" disabled={pending}>
      {pending ? "Enregistrement…" : "Renommer la Structure"}
    </button>
  </form>;
}
