import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { formatBoralogDateTime } from "../../../lib/date-time";
import { createClient } from "../../../lib/supabase/server";
import { MessageDetailActions } from "./MessageDetailActions";

function displayBusinessDate(value: string) {
  const [year, month, day] = value.split("-");
  return `${day}/${month}/${year}`;
}

function displaySourceKind(value: string | null) {
  if (value === "WHATSAPP") return "WhatsApp";
  if (value === "EMAIL") return "E-mail";
  if (value === "SMS") return "SMS";
  if (value === "PHONE") return "Téléphone";
  if (value === "OTHER") return "Autre source";
  return "Boralog";
}

export default async function MessageDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError || !authData.user) redirect("/auth/connexion");

  const { data: message, error: messageError } = await supabase
    .from("messages")
    .select(
      "id, organization_id, project_id, event_id, content, status, created_by, created_at, processed_at, processed_by, origin_type, author_user_id, external_author_label, source_kind, source_occurred_at, visibility"
    )
    .eq("id", id)
    .maybeSingle();

  if (messageError || !message) notFound();

  const [
    { data: notes, error: notesError },
    { data: recipients },
    { data: authorProfile },
    projectResult,
    eventResult,
  ] = await Promise.all([
    supabase
      .from("message_notes")
      .select("id, content, created_by, created_at")
      .eq("message_id", message.id)
      .order("created_at", { ascending: true }),
    message.visibility === "RESTRICTED"
      ? supabase.from("message_recipients").select("user_id").eq("message_id", message.id)
      : Promise.resolve({ data: [] as { user_id: string }[], error: null }),
    message.author_user_id
      ? supabase.from("profiles").select("id, display_name").eq("id", message.author_user_id).maybeSingle()
      : Promise.resolve({ data: null, error: null }),
    message.project_id
      ? supabase.from("projects").select("id, name").eq("id", message.project_id).maybeSingle()
      : Promise.resolve({ data: null, error: null }),
    message.event_id
      ? supabase
          .from("events")
          .select("id, project_id, event_date, venue_name, city, title")
          .eq("id", message.event_id)
          .maybeSingle()
      : Promise.resolve({ data: null, error: null }),
  ]);

  let businessPerson: { id: string; name: string } | null = null;
  let businessCompanies: string[] = [];

  if (message.origin_type === "INTERNAL" && message.author_user_id) {
    const { data: authorMembership } = await supabase
      .from("organization_memberships")
      .select("id")
      .eq("organization_id", message.organization_id)
      .eq("user_id", message.author_user_id)
      .maybeSingle();

    if (authorMembership) {
      const { data: person } = await supabase
        .from("people")
        .select("id, name")
        .eq("organization_id", message.organization_id)
        .eq("organization_membership_id", authorMembership.id)
        .maybeSingle();

      if (person) {
        businessPerson = person;
        const { data: companyLinks } = await supabase
          .from("person_companies")
          .select("company_id")
          .eq("person_id", person.id);
        const companyIds = [...new Set((companyLinks ?? []).map((link) => link.company_id))];
        if (companyIds.length > 0) {
          const { data: companies } = await supabase
            .from("companies")
            .select("id, name")
            .in("id", companyIds)
            .order("name", { ascending: true });
          businessCompanies = (companies ?? []).map((company) => company.name);
        }
      }
    }
  }

  const project = projectResult.data;
  const event = eventResult.data;
  const status = message.status === "PROCESSED" ? "PROCESSED" : "TO_PROCESS";
  const sourceAuthor = message.origin_type === "INTERNAL"
    ? businessPerson?.name
      || authorProfile?.display_name
      || (message.author_user_id === authData.user.id ? "Vous" : null)
    : message.external_author_label
      || authorProfile?.display_name
      || (message.author_user_id === authData.user.id ? "Vous" : null);
  const sourceDate = message.source_occurred_at || message.created_at;
  const contextParts = [
    project?.name || null,
    event?.event_date ? displayBusinessDate(event.event_date) : null,
    event?.title || null,
    [event?.venue_name, event?.city].filter(Boolean).join(" · ") || null,
  ].filter(Boolean);
  const audience =
    message.visibility === "RESTRICTED"
      ? `Accès restreint${recipients?.length ? ` · ${recipients.length} personne${recipients.length > 1 ? "s" : ""}` : ""}`
      : "Toute l’organisation";

  return <main className="entity-page"><div className="entity-wrap message-detail-page">
    <Link className="entity-back" href="/messages">← Messages</Link>

    <header className="entity-header message-detail-header">
      <div>
        <p className="eyebrow">MESSAGE</p>
        <h1>Fiche Message</h1>
      </div>
      <span className={`message-status-badge ${status === "PROCESSED" ? "is-processed" : "is-to-process"}`}>
        {status === "PROCESSED" ? "Traité" : "À traiter"}
      </span>
    </header>

    <section className="message-source-readonly" aria-labelledby="message-source-title">
      <h2 id="message-source-title">Source originale</h2>
      <p>{message.content}</p>
      <div className="message-source-meta">
        <span>{displaySourceKind(message.source_kind)}</span>
        {sourceAuthor && <span>{sourceAuthor}</span>}
        {message.origin_type === "INTERNAL" && businessCompanies.length > 0 && <span>{businessCompanies.join(" · ")}</span>}
        <time dateTime={sourceDate}>{formatBoralogDateTime(sourceDate)}</time>
      </div>
    </section>

    <section className="message-detail-summary" aria-label="Contexte et audience">
      <article>
        <h2>Contexte</h2>
        <p>{contextParts.length > 0 ? contextParts.join(" · ") : "Aucun contexte rattaché"}</p>
      </article>
      <article>
        <h2>Audience</h2>
        <p>{audience}</p>
      </article>
    </section>

    <section className="message-notes" aria-labelledby="message-notes-title">
      <h2 id="message-notes-title">Notes</h2>
      {notesError ? (
        <p role="alert">Les Notes ne sont pas encore disponibles sur cet environnement.</p>
      ) : (notes ?? []).length === 0 ? (
        <p className="work-empty">Aucune note pour le moment.</p>
      ) : (
        <div className="message-note-list">
          {(notes ?? []).map((note) => (
            <article className="message-note" key={note.id}>
              <p>{note.content}</p>
              <small>
                {note.created_by === authData.user.id ? "Vous" : "Membre"}
                {" · "}
                <time dateTime={note.created_at}>{formatBoralogDateTime(note.created_at)}</time>
              </small>
            </article>
          ))}
        </div>
      )}
    </section>

    <MessageDetailActions messageId={message.id} status={status} />
  </div></main>;
}
