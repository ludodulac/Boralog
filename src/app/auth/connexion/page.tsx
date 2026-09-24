import { AuthForm } from "../../../components/AuthForm";

export default function LoginPage() {
  return <main className="auth-page"><div className="auth-card"><div className="brand auth-brand"><span>B</span><strong>Boralog</strong></div><p className="eyebrow">IDENTITÉ BORALOG</p><h1>Connexion</h1><p className="auth-intro">Retrouvez votre espace Boralog.</p><AuthForm mode="connexion"/></div></main>;
}
