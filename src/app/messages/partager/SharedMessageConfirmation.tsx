"use client";

import { useActionState, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { SHARED_MESSAGE_STORAGE_KEY } from "../../../lib/android-share";
import { createSharedMessage } from "./actions";
import { initialSharedMessageState } from "./state";

export function SharedMessageConfirmation() {
  const router = useRouter();
  const [content, setContent] = useState("");
  const [loaded, setLoaded] = useState(false);
  const [sourceKind, setSourceKind] = useState<"WHATSAPP" | "OTHER">("WHATSAPP");
  const [state, action, pending] = useActionState(createSharedMessage, initialSharedMessageState);

  useEffect(() => {
    setContent(sessionStorage.getItem(SHARED_MESSAGE_STORAGE_KEY) ?? "");
    setLoaded(true);
  }, []);

  useEffect(() => {
    if (state.status === "success") {
      sessionStorage.removeItem(SHARED_MESSAGE_STORAGE_KEY);
      router.replace("/");
      router.refresh();
    }
  }, [router, state.status]);

  if (!loaded) return <p className="work-empty">Chargement du texte partagé…</p>;
  if (!content) return <p className="work-empty">Aucun texte partagé n’est disponible. Revenez dans l’application source et utilisez Partager → BORALOG.</p>;

  return <form className="project-create-form" action={action} aria-busy={pending}>
    <label htmlFor="shared-content">Texte partagé
      <textarea
        id="shared-content"
        name="content"
        rows={8}
        required
        value={content}
        onChange={(event) => setContent(event.target.value)}
        readOnly={pending}
      />
    </label>

    <fieldset className="message-audience">
      <legend>Source</legend>
      <label className="message-audience-choice">
        <input type="radio" name="source_kind" value="WHATSAPP" checked={sourceKind === "WHATSAPP"} onChange={() => setSourceKind("WHATSAPP")} />
        <span>WhatsApp</span>
      </label>
      <label className="message-audience-choice">
        <input type="radio" name="source_kind" value="OTHER" checked={sourceKind === "OTHER"} onChange={() => setSourceKind("OTHER")} />
        <span>Autre</span>
      </label>
    </fieldset>

    <p className="profile-intro">La source est confirmée par vous ; BORALOG ne la détecte pas automatiquement.</p>
    {state.status === "error" && <p className="project-create-feedback error" role="alert">{state.message}</p>}
    <button className="project-create-submit" type="submit" disabled={pending || !content.trim()}>
      {pending ? "Enregistrement…" : "Enregistrer dans BORALOG"}
    </button>
  </form>;
}
