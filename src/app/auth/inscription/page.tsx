import { AuthForm } from "../../../components/AuthForm";

export default function SignupPage() {
  return <main className="auth-page"><div className="auth-card"><div className="brand auth-brand"><span>B</span><strong>Boralog</strong></div><p className="eyebrow">IDENTITÉ BORALOG</p><h1>Créer mon compte</h1><p className="auth-intro">Votre compte représente votre identité. Il ne vous donne accès à aucune structure par lui-même.</p><AuthForm mode="inscription"/></div></main>;
}
