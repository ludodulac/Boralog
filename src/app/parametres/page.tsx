import Link from "next/link";
import { redirect } from "next/navigation";
import { getCurrentIdentity } from "../../lib/auth";
import { RenameStructureForm } from "./RenameStructureForm";

export default async function SettingsPage() {
  const identity = await getCurrentIdentity();
  if (!identity.userId) redirect("/auth/connexion");

  return <main className="destination-page"><div className="destination-wrap profile-page">
    <p className="eyebrow">PARAMÈTRES</p>
    <h1>Paramètres</h1>
    <p className="profile-intro">Gérez votre profil et les informations principales de votre Structure.</p>

    <section className="profile-account" aria-labelledby="settings-profile-title">
      <div>
        <p className="eyebrow" id="settings-profile-title">MON PROFIL / MON COMPTE</p>
        <strong>{identity.profile?.display_name || "Profil à compléter"}</strong>
        <span>{identity.email || "Email de connexion indisponible"}</span>
      </div>
      <div>
        <p>Votre compte de connexion reste distinct de votre profil professionnel.</p>
        <Link className="empty-membership-cta" href="/moi">Modifier mon profil</Link>
      </div>
    </section>

    <section className="profile-editor" aria-labelledby="settings-organization-title">
      <div className="profile-section-heading">
        <p className="eyebrow">MA STRUCTURE</p>
        <h2 id="settings-organization-title">{identity.organization?.name || "Aucune Structure"}</h2>
      </div>

      {identity.organization ? (
        <>
          <p className="profile-intro">La Structure est votre organisation principale dans Boralog. Elle contient vos Projets, Personnes, Messages et Dates.</p>
          {identity.organization.accessLevel === "owner" ? (
            <RenameStructureForm currentName={identity.organization.name} />
          ) : (
            <p className="work-empty">Seul un OWNER peut renommer la Structure.</p>
          )}
        </>
      ) : (
        <p className="work-empty">Votre compte n’est rattaché à aucune Structure active.</p>
      )}
    </section>
  </div></main>;
}
