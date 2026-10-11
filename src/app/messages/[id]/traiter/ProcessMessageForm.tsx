"use client";

import { useActionState, useRef, useState } from "react";
import { processMessage } from "./actions";
import { initialProcessMessageState } from "./state";

export function ProcessMessageForm({ messageId }: { messageId: string }) {
  const nextId = useRef(1);
  const [informationFields, setInformationFields] = useState<number[]>([]);
  const [taskFields, setTaskFields] = useState<number[]>([]);
  const [noFollowUp, setNoFollowUp] = useState(false);
  const [state, action, pending] = useActionState(processMessage, initialProcessMessageState);

  function addInformation() {
    setNoFollowUp(false);
    setInformationFields((fields) => [...fields, nextId.current++]);
  }

  function addTask() {
    setNoFollowUp(false);
    setTaskFields((fields) => [...fields, nextId.current++]);
  }

  function chooseNoFollowUp() {
    setNoFollowUp(true);
    setInformationFields([]);
    setTaskFields([]);
  }

  const hasConsequences = informationFields.length + taskFields.length > 0;
  const canSubmit = noFollowUp || hasConsequences;

  return <form className="message-process-form" action={action} aria-busy={pending}>
    <input type="hidden" name="message_id" value={messageId} />
    <input
      type="hidden"
      name="resolution"
      value={noFollowUp ? "NO_FOLLOW_UP" : "CONSEQUENCES_CREATED"}
    />
    <input type="hidden" name="expected_information_count" value={informationFields.length} />
    <input type="hidden" name="expected_task_count" value={taskFields.length} />

    <section className="message-process-choice" aria-labelledby="message-process-question">
      <h2 id="message-process-question">Que faut-il en faire ?</h2>

      <div className="message-process-actions">
        <button type="button" onClick={addInformation} disabled={pending}>
          + Créer une information
        </button>
        <button type="button" onClick={addTask} disabled={pending}>
          + Créer une tâche
        </button>
        <button
          type="button"
          className={noFollowUp ? "is-selected" : ""}
          aria-pressed={noFollowUp}
          onClick={chooseNoFollowUp}
          disabled={pending}
        >
          Sans suite
        </button>
      </div>
    </section>

    {informationFields.length > 0 && <section className="message-process-drafts" aria-labelledby="information-drafts-title">
      <h2 id="information-drafts-title">Informations</h2>
      {informationFields.map((fieldId, index) => <div className="message-process-draft" key={fieldId}>
        <label htmlFor={`information-${fieldId}`}>Information {informationFields.length > 1 ? index + 1 : ""}</label>
        <textarea
          id={`information-${fieldId}`}
          name="information_contents"
          rows={3}
          required
          readOnly={pending}
        />
        <button
          type="button"
          className="message-process-remove"
          onClick={() => setInformationFields((fields) => fields.filter((id) => id !== fieldId))}
          disabled={pending}
        >
          Supprimer
        </button>
      </div>)}
    </section>}

    {taskFields.length > 0 && <section className="message-process-drafts" aria-labelledby="task-drafts-title">
      <h2 id="task-drafts-title">Tâches</h2>
      {taskFields.map((fieldId, index) => <div className="message-process-draft" key={fieldId}>
        <label htmlFor={`task-${fieldId}`}>Tâche {taskFields.length > 1 ? index + 1 : ""}</label>
        <textarea
          id={`task-${fieldId}`}
          name="task_contents"
          rows={3}
          required
          readOnly={pending}
        />
        <button
          type="button"
          className="message-process-remove"
          onClick={() => setTaskFields((fields) => fields.filter((id) => id !== fieldId))}
          disabled={pending}
        >
          Supprimer
        </button>
      </div>)}
    </section>}

    {noFollowUp && <p className="message-process-no-follow-up">Sans suite sélectionné.</p>}

    {state.status === "error" && <p className="project-create-feedback error" role="alert">{state.message}</p>}

    <button
      className="project-create-submit"
      type="submit"
      disabled={pending || !canSubmit}
    >
      {pending ? "Traitement…" : "Terminer le traitement"}
    </button>
  </form>;
}
