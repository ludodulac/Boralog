import Link from "next/link";
import { redirect } from "next/navigation";
import { getCurrentIdentity } from "../../lib/auth";
import { createClient } from "../../lib/supabase/server";
import { CreateMessageForm } from "./CreateMessageForm";

type MessageFilter = "all" | "to-process" | "processed";

function displayCreatedAt(value: string) {
  return new Intl.DateTimeFormat("fr-FR", {
    dateStyle: "short",
    timeStyle: "short",
  }).format(new Date(value));
}

function displayBusinessDate(value: string) {
  const [year, month, day] = value.split("-");
  return `${day}/${month}/${year}`;
}

function readFilter(value: string | string[] | undefined): MessageFilter {
  if (value === "to-process" || value === "processed") return value;
  return "all";
}

function previewContent(value: string) {
  return value.length > 180 ? `${value.slice(0, 177)}…` : value;
}

export default async function MessagesPage({
  searchParams,
}: {
  searchParams: Promise<{ etat?: string | string[] }>;
}) {
  const identity = await getCurrentIdentity();
  if (!identity.userId) redirect("/auth/connexion");
  if (!identity.organization) return null;

  const { etat } = await searchParams;
  const filter = readFilter(etat);
  const supabase = await createClient();

  const [
    { data: projects, error: projectError },
    { data: recipientDirectory, error: recipientDirectoryError },
  ] = await Promise.all([
    supabase
      .from("projects")
      .select("id, name, archived_at")
      .eq("organization_id", identity.organization.id)
      .order("name", { ascending: true }),
    supabase.rpc("boralog_message_recipient_directory", {
      p_organization_id: identity.organization.id,
    }),
  ]);

  let messageQuery = supabase
    .from("messages")
    .select("id, project_id, content, status, created_at")
    .eq("organization_id", identity.organization.id)
    .order("created_at", { ascending: false });

  if (filter === "to-process") {
    messageQuery = messageQuery.eq("status", "TO_PROCESS");
  } else if (filter === "processed") {
    messageQuery = messageQuery.eq("status", "PROCESSED");
  }

  const { data: messages, error: messageError } = await messageQuery;

  const accessibleProjects = projects ?? [];
  const accessibleProjectIds = accessibleProjects.map((project) => project.id);
  const projectNames = new Map(accessibleProjects.map((project) => [project.id, project.name]));

  const { data: events, error: eventError } = accessibleProjectIds.length > 0
    ? await supabase
        .from("events")
        .select("id, project_id, event_date, venue_name, city")
        .in("project_id", accessibleProjectIds)
        .order("event_date", { ascending: true })
    : { data: [], error: null };

  const realMessages = messages ?? [];
  const messageIds = realMessages.map((message) => message.id);
  const { data: noteRows } = messageIds.length > 0
    ? await supabase
        .from("message_notes")
        .select("message_id")
        .in("message_id", messageIds)
    : { data: [] as { message_id: string }[], error: null };

  const noteCounts = new Map<string, number>();
  for (const note of noteRows ?? []) {
    noteCounts.set(note.message_id, (noteCounts.get(note.message_id) ?? 0) + 1);
  }

  const recipients = (recipientDirectory ?? []).map((recipient: {
    user_id: string;
    display_name: string | null;
  }) => ({
    user_id: recipient.user_id,
    display_name: recipient.display_name,
  }));

  const projectOptions = projectError
    ? []
    : accessibleProjects.map((project) => ({
        id: project.id,
        name: project.name,
      }));

  const dateOptions = eventError
    ? []
    : (events ?? []).map((event) => {
        const projectName = projectNames.get(event.project_id) ?? "Projet";
        const place = [event.venue_name, event.city].filter(Boolean).join(" · ");
        return {
          id: event.id,
          label: [
            displayBusinessDate(event.event_date),
            projectName,
            place || null,
          ].filter(Boolean).join(" · "),
        };
      });

  const organizationRequiresContext = identity.organization.accessLevel === "limited";
  const hasContextOptions = projectOptions.length > 0 || dateOptions.length > 0;
  const canCreateOrganization = !organizationRequiresContext || hasContextOptions;
  const canCreateRestricted = !recipientDirectoryError && recipients.length > 0;
  const canCreateMessage = canCreateOrganization || canCreateRestricted;

  return <main className="entity-page"><div className="entity-wrap">
    <header className="entity-header">
      <p className="eyebrow">MESSAGES</p>
      <h1>Messages</h1>
      <p>Les Messages restent consultables, qu’ils soient à traiter ou déjà traités.</p>
    </header>

    <section aria-labelledby="new-message-title">
      <h2 id="new-message-title">Nouveau message</h2>
      {canCreateMessage ? (
        <CreateMessageForm
          recipients={recipients}
          projects={projectOptions}
          dates={dateOptions}
          canCreateOrganization={canCreateOrganization}
          canCreateRestricted={canCreateRestricted}
          organizationRequiresContext={organizationRequiresContext}
        />
      ) : (
        <p className="work-empty">
          {recipientDirectoryError ? "L’annuaire n’a pas pu être chargé." : "Aucune personne disponible."}
        </p>
      )}
    </section>

    <section className="message-inbox" aria-labelledby="message-list-title">
      <div className="message-inbox-heading">
        <h2 id="message-list-title">Derniers messages</h2>
        <nav className="message-filters" aria-label="Filtrer les Messages">
          <Link className={filter === "all" ? "is-active" : ""} href="/messages">Tous</Link>
          <Link className={filter === "to-process" ? "is-active" : ""} href="/messages?etat=to-process">À traiter</Link>
          <Link className={filter === "processed" ? "is-active" : ""} href="/messages?etat=processed">Traités</Link>
        </nav>
      </div>

      {messageError ? (
        <p role="alert">Les messages n’ont pas pu être chargés.</p>
      ) : realMessages.length === 0 ? (
        <p className="work-empty">Aucun message pour ce filtre.</p>
      ) : (
        <div className="message-list">
          {realMessages.map((message) => {
            const projectName = message.project_id ? projectNames.get(message.project_id) : null;
            const noteCount = noteCounts.get(message.id) ?? 0;
            const processed = message.status === "PROCESSED";

            return <Link className="message-card" href={`/messages/${message.id}`} key={message.id}>
              <span className={`message-status-badge ${processed ? "is-processed" : "is-to-process"}`}>
                {processed ? "Traité" : "À traiter"}
              </span>
              <strong>{previewContent(message.content)}</strong>
              <small>
                {projectName ? `${projectName} · ` : ""}
                {displayCreatedAt(message.created_at)}
                {" · "}
                {noteCount} note{noteCount > 1 ? "s" : ""}
              </small>
            </Link>;
          })}
        </div>
      )}
    </section>
  </div></main>;
}
