"use client";

import { useActionState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { createPerson, initialPersonFormState } from "../actions";

export function CreatePersonForm() {
  const router = useRouter();
  const [state, action, pending] = useActionState(createPerson, initialPersonFormState);

  useEffect(() => {
    if (state.status === "success" && state.personId) {
      router.replace(`/personnes/${state.personId}`);
      router.refresh();
    }
  }, [router, state]);

  return <form className="person-form" action={action} aria-busy={pending}>
    <label>Nom <span aria-hidden="true">*</span>
      <input name="name" required maxLength={160} disabled={pending} />
    </label>
    <label>Rôle professionnel <small>Optionnel</small>
      <input name="role_label" maxLength={160} disabled={pending} />
    </label>
    <label>E-mail professionnel <small>Optionnel</small>
      <input name="professional_email" type="email" maxLength={254} disabled={pending} />
    </label>
    <label>Téléphone professionnel <small>Optionnel</small>
      <input name="professional_phone" type="tel" maxLength={80} disabled={pending} />
    </label>
    {state.status === "error" && <p className="person-feedback error" role="alert">{state.message}</p>}
    <button className="person-submit" type="submit" disabled={pending}>{pending ? "Création…" : "Créer la Personne"}</button>
  </form>;
}
