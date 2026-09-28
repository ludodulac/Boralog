"use client";

import { useActionState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { createDate, initialCreateDateState } from "./actions";

export function CreateDateForm({ projectId }: { projectId: string }) {
  const router = useRouter();
  const boundAction = createDate.bind(null, projectId);
  const [state, action, pending] = useActionState(boundAction, initialCreateDateState);

  useEffect(() => {
    if (state.status === "success") {
      router.replace(`/projets/reel/${projectId}/dates`);
      router.refresh();
    }
  }, [projectId, router, state.status]);

  return <form className="date-create-form" action={action} aria-busy={pending}>
    <label htmlFor="event-date">Date <span aria-hidden="true">*</span><input id="event-date" name="date" type="date" required disabled={pending} defaultValue={state.values.date}/></label>
    <label htmlFor="event-time">Heure <small>Facultative</small><input id="event-time" name="time" type="time" disabled={pending} defaultValue={state.values.time}/></label>
    <label htmlFor="event-city">Ville <small>Facultative</small><input id="event-city" name="city" type="text" autoComplete="address-level2" disabled={pending} defaultValue={state.values.city}/></label>
    <label htmlFor="event-venue">Lieu <small>Facultatif</small><input id="event-venue" name="venue" type="text" autoComplete="organization" disabled={pending} defaultValue={state.values.venue}/></label>
    {state.status === "error" && <p className="project-create-feedback error" role="alert">{state.message}</p>}
    <button className="date-create-submit" type="submit" disabled={pending}>{pending ? "Création…" : "Créer la date"}</button>
  </form>;
}
