import { getCurrentIdentity } from "../../lib/auth";
import { ProfileForm } from "./ProfileForm";

export default async function MePage() {
  const identity = await getCurrentIdentity();
  const profileComplete = Boolean(identity.profile?.display_name);

  return <main className="destination-page"><div className="destination-wrap profile-page">
    <p className="eyebrow">MON IDENTITÉ</p>
    <h1>{identity.profile?.display_name || "Profil à compléter"}</h1>
    <p className="profile-intro">{profileComplete ? "Votre profil Boralog est enregistré. Vous pouvez le modifier ici." : "Votre profil Boralog existe. Complétez-le avec les informations professionnelles que vous souhaitez utiliser dans Boralog."}</p>

    <section className="profile-account" aria-labelledby="account-title">
      <div>
        <p className="eyebrow" id="account-title">COMPTE DE CONNEXION</p>
        <strong>{identity.email || "Email indisponible"}</strong>
      </div>
      <p>Cet email identifie votre compte Auth. Modifier l’email professionnel ci-dessous ne change pas votre adresse de connexion.</p>
    </section>

    <section className="profile-editor" aria-labelledby="profile-title">
      <div className="profile-section-heading">
        <p className="eyebrow">PROFIL BORALOG</p>
        <h2 id="profile-title">Informations professionnelles</h2>
      </div>
      <ProfileForm
        displayName={identity.profile?.display_name ?? ""}
        professionalEmail={identity.profile?.professional_email ?? ""}
        professionalPhone={identity.profile?.professional_phone ?? ""}
      />
    </section>

    {!identity.hasOrganization && <div className="identity-membership"><strong>Aucune structure</strong><p>Votre compte et votre profil existent indépendamment de toute appartenance métier.</p></div>}
  </div></main>;
}
