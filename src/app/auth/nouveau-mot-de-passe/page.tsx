import Link from "next/link";
import { NewPasswordForm } from "../../../components/NewPasswordForm";
import { createClient } from "../../../lib/supabase/server";

export default async function NewPasswordPage({ searchParams }: { searchParams: Promise<{ erreur?: string }> }) {
  const params = await searchParams;
  const supabase = await createClient();
  const { data } = await supabase.auth.getClaims();
  const validSession = Boolean(data?.claims?.sub);

  return <main className="auth-page"><div className="auth-card"><div className="brand auth-brand"><span>B</span><strong>Boralog</strong></div><p className="eyebrow">IDENTITÉ BORALOG</p><h1>Nouveau mot de passe</h1>
    {params.erreur || !validSession
      ? <><p className="auth-feedback error" role="alert">Ce lien de récupération est invalide ou a expiré.</p><p className="auth-switch"><Link href="/auth/mot-de-passe-oublie">Demander un nouveau lien</Link></p></>
      : <><p className="auth-intro">Choisissez votre nouveau mot de passe. Il doit contenir au moins 8 caractères.</p><NewPasswordForm/></>}
  </div></main>;
}
