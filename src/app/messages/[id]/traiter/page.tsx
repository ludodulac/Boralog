import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { createClient } from "../../../lib/supabase/server";
import { ProcessMessageForm } from "./ProcessMessageForm";

export default async function ProcessMessagePage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError || !authData.user) redirect("/auth/connexion");

  const { data: message } = await supabase
    .from("messages")
    .select("id, content, status, project_id, event_id")
    .eq("id", id)
    .eq("status", "TO_PROCESS")
    .maybeSingle();

  if (!message) notFound();

  return <main className="entity-page"><div className="entity-wrap message-process-page">
    <Link className="entity-back" href="/messages">← Messages</Link>

    <header className="entity-header">
      <p className="eyebrow">MESSAGES</p>
      <h1>Traiter ce message</h1>
    </header>

    <section className="message-source-readonly" aria-labelledby="message-source-title">
      <h2 id="message-source-title">Message source</h2>
      <p>{message.content}</p>
    </section>

    <ProcessMessageForm messageId={message.id} />
  </div></main>;
}
