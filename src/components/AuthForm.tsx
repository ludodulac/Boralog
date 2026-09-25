"use client";

import Link from "next/link";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "../lib/supabase/client";
import { PasswordField } from "./PasswordField";

type Mode = "connexion" | "inscription";

function messageFor(error: string) {
  if (/invalid login credentials/i.test(error)) return "Email ou mot de passe incorrect.";
  if (/email not confirmed/i.test(error)) return "Confirmez d’abord votre adresse email.";
  if (/password/i.test(error)) return "Le mot de passe ne respecte pas les exigences de sécurité.";
  return "L’action n’a pas pu aboutir. Réessayez.";
}

export function AuthForm({ mode, initialFeedback }: { mode: Mode; initialFeedback?: string }) {
  const router = useRouter();
  const [pending, setPending] = useState(false);
  const [feedback, setFeedback] = useState<{ type: "success" | "error"; text: string } | null>(initialFeedback ? { type: "success", text: initialFeedback } : null);

  async function submit(formData: FormData) {
    setPending(true);
    setFeedback(null);
    const supabase = createClient();
    const email = String(formData.get("email") ?? "").trim();
    const password = String(formData.get("password") ?? "");

    if (mode === "connexion") {
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) {
        setFeedback({ type: "error", text: messageFor(error.message) });
        setPending(false);
        return;
      }
      setFeedback({ type: "success", text: "Connecté." });
      router.replace("/");
      router.refresh();
      return;
    }

    const firstName = String(formData.get("firstName") ?? "").trim();
    const lastName = String(formData.get("lastName") ?? "").trim();
    const displayName = [firstName, lastName].filter(Boolean).join(" ");
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: { display_name: displayName },
        emailRedirectTo: `${window.location.origin}/auth/callback`,
      },
    });

    if (error) {
      setFeedback({ type: "error", text: messageFor(error.message) });
      setPending(false);
      return;
    }

    if (data.session && data.user) {
      setFeedback({ type: "success", text: "Compte créé et connecté." });
      router.replace("/");
      router.refresh();
      return;
    }

    setFeedback({ type: "success", text: "Compte créé. Consultez votre email pour confirmer votre adresse, puis connectez-vous." });
    setPending(false);
  }

  const signup = mode === "inscription";
  return <form className="auth-form" action={submit} aria-busy={pending}>
    {signup && <div className="auth-name-grid">
      <label>Prénom<input name="firstName" autoComplete="given-name" required disabled={pending}/></label>
      <label>Nom<input name="lastName" autoComplete="family-name" required disabled={pending}/></label>
    </div>}
    <label>Email<input name="email" type="email" autoComplete="email" required disabled={pending}/></label>
    <PasswordField autoComplete={signup ? "new-password" : "current-password"} disabled={pending}/>
    {!signup && <Link className="auth-forgot" href="/auth/mot-de-passe-oublie">Mot de passe oublié ?</Link>}
    {feedback && <p className={feedback.type === "error" ? "auth-feedback error" : "auth-feedback"} role={feedback.type === "error" ? "alert" : "status"}>{feedback.text}</p>}
    <button className="auth-submit" type="submit" disabled={pending}>{pending ? (signup ? "Création…" : "Connexion…") : (signup ? "Créer mon compte" : "Se connecter")}</button>
    <p className="auth-switch">{signup ? <>Déjà un compte ? <Link href="/auth/connexion">Se connecter</Link></> : <>Nouveau sur Boralog ? <Link href="/auth/inscription">Créer un compte</Link></>}</p>
  </form>;
}
