"use client";

import { useActionState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import { addMessageNote, setMessageStatus } from "./actions";
import { initialAddMessageNoteState, initialMessageStatusState } from "./state";

type MessageStatus = "TO_PROCESS" | "PROCESSED";

export function MessageDetailActions({
  messageId,
  status,
}: {
  messageId: string;
  status: MessageStatus;
}) {
  const router = useRouter();
  const noteFormRef = useRef<HTMLFormElement>(null);
  const [noteState, noteAction, notePending] = useActionState(
    addMessageNote,
    initialAddMessageNoteState
  );
  const [statusState, statusAction, statusPending] = useActionState(
    setMessageStatus,
    initialMessageStatusState
  );

  useEffect(() => {
    if (noteState.status === "success") {
      noteFormRef.current?.reset();
      router.refresh();
    }
  }, [noteState.status, router]);

  useEffect(() => {
    if (statusState.status === "success") {
      router.refresh();
    }
  }, [router, statusState.status]);

  const nextStatus: MessageStatus =
    status === "TO_PROCESS" ? "PROCESSED" : "TO_PROCESS";

  return <div className="message-detail-actions">
    <section className="message-note-editor" aria-labelledby="message-note-editor-title">
      <h2 id="message-note-editor-title">Ajouter une note</h2>
      <form ref={noteFormRef} action={noteAction}>
        <input type="hidden" name="message_id" value={messageId} />
        <label htmlFor="message-note-content">Note
          <textarea
            id="message-note-content"
            name="content"
            rows={4}
            required
            readOnly={notePending}
            defaultValue={noteState.values.content}
          />
        </label>
        {noteState.status === "error" && (
          <p className="project-create-feedback error" role="alert">{noteState.message}</p>
        )}
        {noteState.status === "success" && (
          <p className="project-create-feedback" role="status">{noteState.message}</p>
        )}
        <button className="project-create-submit" type="submit" disabled={notePending}>
          {notePending ? "Ajout…" : "Ajouter la note"}
        </button>
      </form>
    </section>

    <section className="message-status-editor" aria-labelledby="message-status-editor-title">
      <h2 id="message-status-editor-title">État</h2>
      <form action={statusAction}>
        <input type="hidden" name="message_id" value={messageId} />
        <input type="hidden" name="status" value={nextStatus} />
        {statusState.status === "error" && (
          <p className="project-create-feedback error" role="alert">{statusState.message}</p>
        )}
        {statusState.status === "success" && (
          <p className="project-create-feedback" role="status">{statusState.message}</p>
        )}
        <button className="message-status-button" type="submit" disabled={statusPending}>
          {statusPending
            ? "Mise à jour…"
            : status === "TO_PROCESS"
              ? "Marquer traité"
              : "Remettre à traiter"}
        </button>
      </form>
    </section>
  </div>;
}
