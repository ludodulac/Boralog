"use client";

import { useActionState, useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { createMessage } from "./actions";
import { initialCreateMessageState } from "./state";

type MessageRecipientOption = {
  user_id: string;
  display_name: string | null;
};

type MessageVisibility = "ORGANIZATION" | "RESTRICTED";

export function CreateMessageForm({
  recipients,
  canCreateOrganization,
  canCreateRestricted,
}: {
  recipients: MessageRecipientOption[];
  canCreateOrganization: boolean;
  canCreateRestricted: boolean;
}) {
  const router = useRouter();
  const formRef = useRef<HTMLFormElement>(null);
  const [visibility, setVisibility] = useState<MessageVisibility>(
    canCreateOrganization ? "ORGANIZATION" : "RESTRICTED"
  );
  const [state, action, pending] = useActionState(createMessage, initialCreateMessageState);

  useEffect(() => {
    if (state.status === "success") {
      formRef.current?.reset();
      setVisibility(canCreateOrganization ? "ORGANIZATION" : "RESTRICTED");
      router.refresh();
    }
  }, [canCreateOrganization, router, state]);

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
          disabled={pending || !canCreateOrganization}
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

    {state.status === "error" && <p className="project-create-feedback error" role="alert">{state.message}</p>}
    {state.status === "success" && <p className="project-create-feedback" role="status">{state.message}</p>}

    <button className="project-create-submit" type="submit" disabled={pending}>
      {pending ? "Enregistrement…" : "Enregistrer"}
    </button>
  </form>;
}
