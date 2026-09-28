"use client";

import { useActionState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import { createDate } from "./actions";
import { initialCreateDateState } from "./state";

export function CreateDateForm({ projectId, attemptId }: { projectId: string; attemptId: string }) {
  const router = useRouter();
  const timezoneOffset = useRef<HTMLInputElement>(null);
  const actionWithProject = createDate.bind(null, projectId);
  const [state, action, pending] = useActionState(actionWithProject, initialCreateDateState);

  useEffect(() => {
    if (state.status === "success") {
      router.replace(`/projets/reel/${projectId}/dates?created=1`);
      router.refresh();
    }
  }, [projectId, router, state.status]);

  return <form className="date-create-form" action={action} aria-busy={pending} onSubmit={(event) => {
    const form = event.currentTarget;
    const date = (form.elements.namedItem("date") as HTMLInputElement).value;
    const time = (form.elements.namedItem("time") as HTMLInputElement).value;
    if (timezoneOffset.current) timezoneOffset.current.value = time ? String(new Date(`${date}T${time}`).getTimezoneOffset()) : "";
  }}>
    <input type="hidden" name="attempt_id" value={attemptId}/>
    <input ref={timezoneOffset} type="hidden" name="timezone_offset" defaultValue=""/>
    <label htmlFor="event-date">Date <span aria-hidden="true">*</span><input id="event-date" name="date" type="date" required disabled={pending} defaultValue={state.values.date}/></label>
    <label htmlFor="event-time">Heure <small>Facultative</small><input id="event-time" name="time" type="time" disabled={pending} defaultValue={state.values.time}/></label>
    <label htmlFor="event-city">Ville <small>Facultative</small><input id="event-city" name="city" type="text" autoComplete="address-level2" disabled={pending} defaultValue={state.values.city}/></label>
    <label htmlFor="event-venue">Lieu <small>Facultatif</small><input id="event-venue" name="venue" type="text" autoComplete="organization" disabled={pending} defaultValue={state.values.venue}/></label>
    {state.status === "error" && <p className="date-create-feedback error" role="alert">{state.message}</p>}
    <button className="date-create-submit" type="submit" disabled={pending}>{pending ? "Enregistrement…" : "Créer la date"}</button>
  </form>;
}
