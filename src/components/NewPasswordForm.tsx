"use client";

import Link from "next/link";
import { useState } from "react";
import { createClient } from "../lib/supabase/client";
import { PasswordField } from "./PasswordField";

export function NewPasswordForm() {
  const [pending, setPending] = useState(false);
  const [complete, setComplete] = useState(false);
  const [feedback, setFeedback] = useState<{ type: "success" | "error"; text: string } | null>(null);

  async function submit(formData: FormData) {
    setFeedback(null);
    const password = String(formData.get("newPassword") ?? "");
    const confirmation = String(formData.get("confirmPassword") ?? "");

    if (password !== confirmation) {
      setFeedback({ type: "error", text: "Les deux mots de passe ne correspondent pas." });
      return;
    }

    setPending(true);
    const supabase = createClient();
    const { error } = await supabase.auth.updateUser({ password });

    if (error) {
      setFeedback({ type: "error", text: "Le mot de passe n’a pas pu être modifié. Le lien peut être invalide ou expiré." });
      setPending(false);
      return;
    }

    await supabase.auth.signOut();
    setComplete(true);
    setFeedback({ type: "success", text: "Votre mot de passe a été modifié. Vous pouvez maintenant vous connecter." });
    setPending(false);
  }

  if (complete) {
    return <div className="auth-form"><p className="auth-feedback" role="status">{feedback?.text}</p><Link className="auth-submit auth-submit-link" href="/auth/connexion">Revenir à la connexion</Link></div>;
  }

  return <form className="auth-form" action={submit} aria-busy={pending}>
    <PasswordField name="newPassword" label="Nouveau mot de passe" autoComplete="new-password" disabled={pending}/>
    <PasswordField name="confirmPassword" label="Confirmation du nouveau mot de passe" autoComplete="new-password" disabled={pending}/>
    {feedback && <p className={feedback.type === "error" ? "auth-feedback error" : "auth-feedback"} role={feedback.type === "error" ? "alert" : "status"}>{feedback.text}</p>}
    <button className="auth-submit" type="submit" disabled={pending}>{pending ? "Modification…" : "Modifier le mot de passe"}</button>
  </form>;
}
