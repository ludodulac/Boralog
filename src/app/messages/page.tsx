import { redirect } from "next/navigation";
import { getCurrentIdentity } from "../../lib/auth";
import { createClient } from "../../lib/supabase/server";
import { CreateMessageForm } from "./CreateMessageForm";

function displayCreatedAt(value: string) {
  return new Intl.DateTimeFormat("fr-FR", {
    dateStyle: "short",
    timeStyle: "short",
  }).format(new Date(value));
}

function displayStatus(value: string) {
  if (value === "TO_PROCESS") return "À traiter";
  if (value === "PROCESSED") return "Traité";
  return value;
}

export default async function MessagesPage() {
  const identity = await getCurrentIdentity();
  if (!identity.userId) redirect("/auth/connexion");
  if (!identity.organization) return null;

  const supabase = await createClient();
  const { data: messages, error } = await supabase
    .from("messages")
    .select("id, content, status, created_at")
    .eq("organization_id", identity.organization.id)
    .order("created_at", { ascending: false });

  const realMessages = messages ?? [];
  const canCreateStructureMessage =
    identity.organization.accessLevel === "owner" ||
    identity.organization.accessLevel === "full";

  return <main className="entity-page"><div className="entity-wrap">
    <header className="entity-header">
      <p className="eyebrow">MESSAGES</p>
      <h1>Messages</h1>
      <p>Les messages entrants restent à traiter tant qu’un humain ne décide pas de la suite.</p>
    </header>

    {canCreateStructureMessage && <section aria-labelledby="new-message-title">
      <h2 id="new-message-title">Nouveau message</h2>
      <CreateMessageForm />
    </section>}

    <section aria-labelledby="message-list-title">
      <h2 id="message-list-title">Messages à traiter</h2>
      {error ? (
        <p role="alert">Les messages n’ont pas pu être chargés.</p>
      ) : realMessages.length === 0 ? (
        <p className="work-empty">Aucun message pour le moment.</p>
      ) : (
        <div className="real-date-list">
          {realMessages.map((message) => <article className="real-date-row" key={message.id}>
            <strong>{message.content}</strong>
            <span>{displayStatus(message.status)}</span>
            <small>{displayCreatedAt(message.created_at)}</small>
          </article>)}
        </div>
      )}
    </section>
  </div></main>;
}
