"use client";

import { useActionState, useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { createMessage } from "./actions";
import { initialCreateMessageState } from "./state";

type MessageRecipientOption = {
  user_id: string;
  display_name: string | null;
};

type MessageProjectOption = {
  id: string;
  name: string;
};

type MessageDateOption = {
  id: string;
  label: string;
};

type MessageVisibility = "ORGANIZATION" | "RESTRICTED";
type MessageContextMode = "NONE" | "PROJECT" | "DATE";

export function CreateMessageForm({
  recipients,
  projects,
  dates,
  canCreateOrganization,
  canCreateRestricted,
  organizationRequiresContext,
}: {
  recipients: MessageRecipientOption[];
  projects: MessageProjectOption[];
  dates: MessageDateOption[];
  canCreateOrganization: boolean;
  canCreateRestricted: boolean;
  organizationRequiresContext: boolean;
}) {
  const router = useRouter();
  const formRef = useRef<HTMLFormElement>(null);
  const initialVisibility: MessageVisibility =
    canCreateOrganization && !organizationRequiresContext
      ? "ORGANIZATION"
      : canCreateRestricted
        ? "RESTRICTED"
        : "ORGANIZATION";
  const [visibility, setVisibility] = useState<MessageVisibility>(initialVisibility);
  const [contextMode, setContextMode] = useState<MessageContextMode>("NONE");
  const [state, action, pending] = useActionState(createMessage, initialCreateMessageState);

  useEffect(() => {
    if (state.status === "success") {
      formRef.current?.reset();
      setVisibility(initialVisibility);
      setContextMode("NONE");
      router.refresh();
    }
  }, [initialVisibility, router, state]);

  return <form ref={formRef} className="project-create-form" action={action} aria-busy={pending}>
    <label htmlFor="message-content">Message
      <textarea
        id="message-content"
        name="content"
        rows={5}
        required
        disabled={pending}
        defaultValue={state.values.content}
      />
    </label>

    <fieldset className="message-audience">
      <legend>Qui peut le lire ?</legend>

      <label className="message-audience-choice">
        <input
          type="radio"
          name="visibility"
          value="ORGANIZATION"
          checked={visibility === "ORGANIZATION"}
          onChange={() => setVisibility("ORGANIZATION")}
          disabled={
            pending
            || !canCreateOrganization
            || (organizationRequiresContext && contextMode === "NONE")
          }
        />
        <span>Toute l’organisation</span>
      </label>

      <label className="message-audience-choice">
        <input
          type="radio"
          name="visibility"
          value="RESTRICTED"
          checked={visibility === "RESTRICTED"}
          onChange={() => setVisibility("RESTRICTED")}
          disabled={pending || !canCreateRestricted}
        />
        <span>Personnes choisies</span>
      </label>
    </fieldset>

    {visibility === "RESTRICTED" && (
      <fieldset className="message-recipient-picker">
        <legend>Personnes</legend>
        {recipients.length === 0 ? (
          <p className="work-empty">Aucune personne disponible.</p>
        ) : (
          <div className="message-recipient-list">
            {recipients.map((recipient) => (
              <label className="message-recipient-choice" key={recipient.user_id}>
                <input
                  type="checkbox"
                  name="recipient_user_ids"
                  value={recipient.user_id}
                  disabled={pending}
                />
                <span>{recipient.display_name || "Membre"}</span>
              </label>
            ))}
          </div>
        )}
      </fieldset>
    )}

    <fieldset className="message-audience message-context">
      <legend>Contexte facultatif</legend>

      <label className="message-audience-choice">
        <input
          type="radio"
          name="context_mode"
          value="NONE"
          checked={contextMode === "NONE"}
          onChange={() => setContextMode("NONE")}
          disabled={pending}
        />
        <span>Aucun</span>
      </label>

      <label className="message-audience-choice">
        <input
          type="radio"
          name="context_mode"
          value="PROJECT"
          checked={contextMode === "PROJECT"}
          onChange={() => setContextMode("PROJECT")}
          disabled={pending || projects.length === 0}
        />
        <span>Projet</span>
      </label>

      <label className="message-audience-choice">
        <input
          type="radio"
          name="context_mode"
          value="DATE"
          checked={contextMode === "DATE"}
          onChange={() => setContextMode("DATE")}
          disabled={pending || dates.length === 0}
        />
        <span>Date</span>
      </label>
    </fieldset>

    {contextMode === "PROJECT" && (
      <label htmlFor="message-project">Projet
        <select id="message-project" name="project_id" required disabled={pending} defaultValue="">
          <option value="" disabled>Choisir un projet</option>
          {projects.map((project) => (
            <option key={project.id} value={project.id}>{project.name}</option>
          ))}
        </select>
      </label>
    )}

    {contextMode === "DATE" && (
      <label htmlFor="message-date">Date
        <select id="message-date" name="event_id" required disabled={pending} defaultValue="">
          <option value="" disabled>Choisir une date</option>
          {dates.map((date) => (
            <option key={date.id} value={date.id}>{date.label}</option>
          ))}
        </select>
      </label>
    )}

    {state.status === "error" && <p className="project-create-feedback error" role="alert">{state.message}</p>}
    {state.status === "success" && <p className="project-create-feedback" role="status">{state.message}</p>}

    <button className="project-create-submit" type="submit" disabled={pending}>
      {pending ? "Enregistrement…" : "Enregistrer"}
    </button>
  </form>;
}
