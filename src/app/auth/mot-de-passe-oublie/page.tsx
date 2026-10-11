import { PasswordRecoveryRequestForm } from "../../../components/PasswordRecoveryRequestForm";

export default function ForgotPasswordPage() {
  return <main className="auth-page"><div className="auth-card"><div className="brand auth-brand"><span>B</span><strong>Boralog</strong></div><p className="eyebrow">IDENTITÉ BORALOG</p><h1>Mot de passe oublié</h1><p className="auth-intro">Indiquez votre adresse email. Nous vous enverrons un lien pour choisir un nouveau mot de passe.</p><PasswordRecoveryRequestForm/></div></main>;
}
