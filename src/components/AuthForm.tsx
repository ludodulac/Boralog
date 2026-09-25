"use client";

import Link from "next/link";
import { useRef, useState, type FormEvent, type KeyboardEvent, type MouseEvent } from "react";
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
  const traceSeq = useRef(0);
  const [runtimeTrace, setRuntimeTrace] = useState<string[]>([]);

  function trace(event: string) {
    traceSeq.current += 1;
    setRuntimeTrace((current) => [...current, `${traceSeq.current} ${event}`]);
  }
  const [feedback, setFeedback] = useState<{ type: "success" | "error"; text: string } | null>(initialFeedback ? { type: "success", text: initialFeedback } : null);

  async function submit(formData: FormData) {
    trace("submit_entered");
    setPending(true);
    setFeedback(null);
    const supabase = createClient();
    const email = String(formData.get("email") ?? "").trim();
    const password = String(formData.get("password") ?? "");

    if (mode === "connexion") {
      trace("sign_in_call_reached");
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

  function loginFromButton(event: MouseEvent<HTMLButtonElement>) {
    trace("login_button_click");
    if (signup || pending || !event.nativeEvent.isTrusted) return;
    const form = event.currentTarget.form;
    if (!form || !form.reportValidity()) return;
    void submit(new FormData(form));
  }

  function loginFromEnter(event: KeyboardEvent<HTMLFormElement>) {
    trace(`form_keydown_${event.key === "Enter" ? "enter" : "other"}`);
    if (signup || pending || event.key !== "Enter" || !event.nativeEvent.isTrusted) return;
    const target = event.target;
    if (!(target instanceof HTMLInputElement) || (target.name !== "email" && target.name !== "password")) return;

    const form = event.currentTarget;
    const email = form.elements.namedItem("email");
    const password = form.elements.namedItem("password");
    if (!(email instanceof HTMLInputElement) || !(password instanceof HTMLInputElement)) return;

    // Only treat Enter as login intent when both credentials were already
    // present before the key's default behavior. This prevents an Enter used
    // to choose an autofill suggestion from simultaneously becoming login.
    if (!email.value.trim() || !password.value) return;

    event.preventDefault();
    if (!form.reportValidity()) return;
    void submit(new FormData(form));
  }

  function blockGenericLoginSubmit(event: FormEvent<HTMLFormElement>) {
    trace("generic_submit_event");
    if (!signup) event.preventDefault();
  }

  return <form
    className="auth-form"
    action={signup ? submit : undefined}
    onSubmit={signup ? undefined : blockGenericLoginSubmit}
    onKeyDown={signup ? undefined : loginFromEnter}
    aria-busy={pending}
  >
    {signup && <div className="auth-name-grid">
      <label>Prénom<input name="firstName" autoComplete="given-name" required disabled={pending}/></label>
      <label>Nom<input name="lastName" autoComplete="family-name" required disabled={pending}/></label>
    </div>}
    <label>Email<input name="email" type="email" autoComplete="email" required disabled={pending}/></label>
    <PasswordField autoComplete={signup ? "new-password" : "current-password"} disabled={pending}/>
    {!signup && <Link className="auth-forgot" href="/auth/mot-de-passe-oublie">Mot de passe oublié ?</Link>}
    {feedback && <p className={feedback.type === "error" ? "auth-feedback error" : "auth-feedback"} role={feedback.type === "error" ? "alert" : "status"}>{feedback.text}</p>}
    {!signup && <pre data-runtime-trace="boralog-auth-018" aria-label="Trace technique temporaire">{runtimeTrace.length ? runtimeTrace.join("\\n") : "0 trace_ready"}</pre>}
    <button className="auth-submit" type={signup ? "submit" : "button"} disabled={pending} onClick={signup ? undefined : loginFromButton}>{pending ? (signup ? "Création…" : "Connexion…") : (signup ? "Créer mon compte" : "Se connecter")}</button>
    <p className="auth-switch">{signup ? <>Déjà un compte ? <Link href="/auth/connexion">Se connecter</Link></> : <>Nouveau sur Boralog ? <Link href="/auth/inscription">Créer un compte</Link></>}</p>
  </form>;
}
