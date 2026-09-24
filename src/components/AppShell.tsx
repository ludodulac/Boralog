"use client";

import { usePathname } from "next/navigation";
import { MainNavigation } from "./MainNavigation";
import { SecondaryMenu } from "./SecondaryMenu";

type Identity = {
  userId: string | null;
  email: string | null;
  profile: { id: string; display_name: string; professional_email: string | null } | null;
  hasOrganization: boolean;
};

export function AppShell({ children, identity }: { children: React.ReactNode; identity: Identity }) {
  const pathname = usePathname();
  if (pathname.startsWith("/auth")) return <>{children}</>;

  const displayName = identity.profile?.display_name || identity.email || "Compte Boralog";
  const showBusinessContent = identity.hasOrganization || pathname === "/moi";

  return <div className="app-shell">
    <MainNavigation organizationName={identity.hasOrganization ? "Espace Boralog" : "Aucune structure"} organizationRole={displayName} pathname={pathname}/>
    <section className="workspace">
      <div className="shell-utility"><SecondaryMenu /></div>
      {showBusinessContent ? children : <main className="empty-membership-page"><div className="empty-membership-card"><p className="eyebrow">COMPTE BORALOG</p><h1>Votre compte Boralog est prêt.</h1><p>Vous n’appartenez encore à aucune structure.</p><p>L’invitation, la création ou le rattachement à une structure seront traités dans une prochaine étape.</p></div></main>}
    </section>
  </div>;
}
