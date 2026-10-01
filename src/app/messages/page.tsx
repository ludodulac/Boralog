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
  const [
    { data: projects },
    { data: messages, error: messageError },
    { data: recipientDirectory, error: recipientDirectoryError },
  ] = await Promise.all([
    supabase
      .from("projects")
      .select("id, name, archived_at")
      .eq("organization_id", identity.organization.id)
      .order("name", { ascending: true }),
    supabase
      .from("messages")
      .select("id, project_id, content, status, created_at")
      .eq("organization_id", identity.organization.id)
      .order("created_at", { ascending: false }),
    supabase.rpc("boralog_message_recipient_directory", {
      p_organization_id: identity.organization.id,
    }),
  ]);

  const accessibleProjects = projects ?? [];
  const projectNames = new Map(accessibleProjects.map((project) => [project.id, project.name]));
  const realMessages = messages ?? [];
  const recipients = (recipientDirectory ?? []).map((recipient) => ({
    user_id: recipient.user_id,
    display_name: recipient.display_name,
  }));

  const canCreateOrganization = identity.organization.accessLevel !== "limited";
  const canCreateRestricted = !recipientDirectoryError && recipients.length > 0;
  const canCreateMessage = canCreateOrganization || canCreateRestricted;

  return <main className="entity-page"><div className="entity-wrap">
    <header className="entity-header">
      <p className="eyebrow">MESSAGES</p>
      <h1>Messages</h1>
      <p>Les messages entrants restent à traiter tant qu’un humain ne décide pas de la suite.</p>
    </header>

    <section aria-labelledby="new-message-title">
      <h2 id="new-message-title">Nouveau message</h2>
      {canCreateMessage ? (
        <CreateMessageForm
          recipients={recipients}
          canCreateOrganization={canCreateOrganization}
          canCreateRestricted={canCreateRestricted}
        />
      ) : (
        <p className="work-empty">
          {recipientDirectoryError ? "L’annuaire n’a pas pu être chargé." : "Aucune personne disponible."}
        </p>
      )}
    </section>

    <section aria-labelledby="message-list-title">
      <h2 id="message-list-title">Messages à traiter</h2>
      {messageError ? (
        <p role="alert">Les messages n’ont pas pu être chargés.</p>
      ) : realMessages.length === 0 ? (
        <p className="work-empty">Aucun message pour le moment.</p>
      ) : (
        <div className="real-date-list">
          {realMessages.map((message) => {
            const projectName = message.project_id ? projectNames.get(message.project_id) : null;
            return <article className="real-date-row" key={message.id}>
              <strong>{message.content}</strong>
              <span>{displayStatus(message.status)}</span>
              {projectName && <small>{projectName}</small>}
              <small>{displayCreatedAt(message.created_at)}</small>
            </article>;
          })}
        </div>
      )}
    </section>
  </div></main>;
}
