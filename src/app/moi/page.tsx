import { getCurrentIdentity } from "../../lib/auth";

export default async function MePage() {
  const identity = await getCurrentIdentity();
  return <main className="destination-page"><div className="destination-wrap">
    <p className="eyebrow">MON IDENTITÉ</p>
    <h1>{identity.profile?.display_name || "Profil à compléter"}</h1>
    <p>{identity.email || "Email indisponible"}</p>
    {!identity.profile && <p className="identity-warning">Votre session est valide, mais aucun profil Boralog complet n’a encore été trouvé.</p>}
    {!identity.hasOrganization && <div className="identity-membership"><strong>Aucune structure</strong><p>Votre compte existe indépendamment de toute appartenance métier.</p></div>}
  </div></main>;
}
