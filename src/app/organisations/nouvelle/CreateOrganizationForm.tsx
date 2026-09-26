"use client";

import { useActionState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import { createOrganization, initialCreateOrganizationState } from "./actions";

export function CreateOrganizationForm() {
  const router = useRouter();
  const attemptId = useRef<string>(crypto.randomUUID());
  const [state, action, pending] = useActionState(createOrganization, initialCreateOrganizationState);

  useEffect(() => {
    if (state.status === "success") {
      router.replace("/");
      router.refresh();
    }
  }, [router, state.status]);

  return <form className="organization-form" action={action} aria-busy={pending}>
    <input type="hidden" name="attempt_id" value={attemptId.current}/>
    <label>
      Nom de la structure
      <input name="name" maxLength={160} autoComplete="organization" required disabled={pending} autoFocus/>
    </label>
    {state.message && state.status !== "success" && <p className="organization-feedback error" role="alert">{state.message}</p>}
    <button className="organization-submit" type="submit" disabled={pending}>{pending ? "Création…" : "Créer ma structure"}</button>
  </form>;
}
