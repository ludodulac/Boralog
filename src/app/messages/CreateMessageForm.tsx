"use client";

import { useActionState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import { createMessage } from "./actions";
import { initialCreateMessageState } from "./state";

export function CreateMessageForm() {
  const router = useRouter();
  const formRef = useRef<HTMLFormElement>(null);
  const [state, action, pending] = useActionState(createMessage, initialCreateMessageState);

  useEffect(() => {
    if (state.status === "success") {
      formRef.current?.reset();
      router.refresh();
    }
  }, [router, state.status]);

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
    {state.status === "error" && <p className="project-create-feedback error" role="alert">{state.message}</p>}
    {state.status === "success" && <p className="project-create-feedback" role="status">{state.message}</p>}
    <button className="project-create-submit" type="submit" disabled={pending}>
      {pending ? "Enregistrement…" : "Créer le message"}
    </button>
  </form>;
}
