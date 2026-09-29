"use client";

import { useActionState, useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { createMessage } from "./actions";
import { initialCreateMessageState } from "./state";

type MessageProjectOption = {
  id: string;
  name: string;
};

type MessageEventOption = {
  id: string;
  projectId: string;
  projectName: string;
  eventDate: string;
  startsAt: string | null;
  city: string | null;
  venueName: string | null;
};

function displayDate(value: string) {
  const [year, month, day] = value.split("-");
  return `${day}/${month}/${year}`;
}

function displayEventLabel(event: MessageEventOption, includeProject: boolean) {
  const context = [displayDate(event.eventDate), event.city, event.venueName].filter(Boolean).join(" · ");
  return includeProject ? `${event.projectName} — ${context}` : context;
}

export function CreateMessageForm({
  projects,
  events,
}: {
  projects: MessageProjectOption[];
  events: MessageEventOption[];
}) {
  const router = useRouter();
  const formRef = useRef<HTMLFormElement>(null);
  const [state, action, pending] = useActionState(createMessage, initialCreateMessageState);
  const [projectId, setProjectId] = useState(initialCreateMessageState.values.projectId);
  const [eventId, setEventId] = useState(initialCreateMessageState.values.eventId);

  useEffect(() => {
    if (state.status === "success") {
      formRef.current?.reset();
      setProjectId("");
      setEventId("");
      router.refresh();
      return;
    }

    if (state.status === "error") {
      setProjectId(state.values.projectId);
      setEventId(state.values.eventId);
    }
  }, [router, state]);

  const visibleEvents = projectId
    ? events.filter((event) => event.projectId === projectId)
    : events;

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

    <label htmlFor="message-project">Projet — facultatif
      <select
        id="message-project"
        name="project_id"
        disabled={pending}
        value={projectId}
        onChange={(event) => {
          const nextProjectId = event.target.value;
          setProjectId(nextProjectId);
          const selectedEvent = events.find((item) => item.id === eventId);
          if (nextProjectId && selectedEvent && selectedEvent.projectId !== nextProjectId) {
            setEventId("");
          }
        }}
      >
        <option value="">Aucun projet</option>
        {projects.map((project) => <option value={project.id} key={project.id}>{project.name}</option>)}
      </select>
    </label>

    <label htmlFor="message-event">Date — facultative
      <select
        id="message-event"
        name="event_id"
        disabled={pending}
        value={eventId}
        onChange={(event) => setEventId(event.target.value)}
      >
        <option value="">Aucune date</option>
        {visibleEvents.map((event) => (
          <option value={event.id} key={event.id}>
            {displayEventLabel(event, !projectId)}
          </option>
        ))}
      </select>
    </label>

    {state.status === "error" && <p className="project-create-feedback error" role="alert">{state.message}</p>}
    {state.status === "success" && <p className="project-create-feedback" role="status">{state.message}</p>}
    <button className="project-create-submit" type="submit" disabled={pending}>
      {pending ? "Enregistrement…" : "Créer le message"}
    </button>
  </form>;
}
