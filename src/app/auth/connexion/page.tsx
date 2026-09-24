import { AuthForm } from "../../../components/AuthForm";

export default async function LoginPage({ searchParams }: { searchParams: Promise<{ deconnecte?: string; erreur?: string }> }) {
  const params = await searchParams;
  const feedback = params.deconnecte ? "Vous êtes déconnecté." : params.erreur ? "La confirmation n’a pas pu être finalisée. Réessayez ou reconnectez-vous." : undefined;
  return <main className="auth-page"><div className="auth-card"><div className="brand auth-brand"><span>B</span><strong>Boralog</strong></div><p className="eyebrow">IDENTITÉ BORALOG</p><h1>Connexion</h1><p className="auth-intro">Retrouvez votre espace Boralog.</p><AuthForm mode="connexion" initialFeedback={feedback}/></div></main>;
}
