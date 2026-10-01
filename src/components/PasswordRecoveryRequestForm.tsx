"use client";

import Link from "next/link";
import { useState } from "react";
import { createClient } from "../lib/supabase/client";

const neutralMessage = "Si un compte correspond à cette adresse, vous recevrez un email pour choisir un nouveau mot de passe.";

export function PasswordRecoveryRequestForm() {
  const [pending, setPending] = useState(false);
  const [feedback, setFeedback] = useState<{ type: "success" | "error"; text: string } | null>(null);

  async function submit(formData: FormData) {
    setPending(true);
    setFeedback(null);
    const email = String(formData.get("email") ?? "").trim();
    const supabase = createClient();
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/auth/recovery/callback`,
    });

    setFeedback(error
      ? { type: "error", text: "La demande n’a pas pu être envoyée. Réessayez dans quelques instants." }
      : { type: "success", text: neutralMessage });
    setPending(false);
  }

  return <form className="auth-form" action={submit} aria-busy={pending}>
    <label>Email<input name="email" type="email" autoComplete="email" required disabled={pending}/></label>
    {feedback && <p className={feedback.type === "error" ? "auth-feedback error" : "auth-feedback"} role={feedback.type === "error" ? "alert" : "status"}>{feedback.text}</p>}
    <button className="auth-submit" type="submit" disabled={pending}>{pending ? "Envoi…" : "Envoyer le lien"}</button>
    <p className="auth-switch"><Link href="/auth/connexion">Retour à la connexion</Link></p>
  </form>;
}
