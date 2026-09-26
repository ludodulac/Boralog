"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { MainNavigation } from "./MainNavigation";
import { SecondaryMenu } from "./SecondaryMenu";

export type AppShellIdentity = {
  userId: string | null;
  email: string | null;
  profile: { id: string; display_name: string; professional_email: string | null } | null;
  organization: { id: string; name: string; accessLevel: "owner" | "full" | "limited" } | null;
  hasOrganization: boolean;
};

export function AppShellRender({ children, identity, pathname }: { children: React.ReactNode; identity: AppShellIdentity; pathname: string }) {
  if (pathname.startsWith("/auth")) return <>{children}</>;
  const displayName = identity.profile?.display_name || identity.email || "Compte Boralog";
  const isOnboardingRoute = pathname.startsWith("/organisations/nouvelle");
  const showRequestedContent = pathname === "/moi" || isOnboardingRoute;
  const organizationName = identity.organization?.name ?? "Aucune structure";
  return <div className="app-shell">
    <MainNavigation organizationName={organizationName} organizationRole={displayName} pathname={pathname}/>
    <section className="workspace">
      <div className="shell-utility"><SecondaryMenu /></div>
      {!identity.organization ? (
        showRequestedContent ? children : <main className="empty-membership-page"><div className="empty-membership-card">
          <p className="eyebrow">COMPTE BORALOG</p>
          <h1>Votre compte Boralog est prêt.</h1>
          <p>Vous n&apos;avez pas encore de structure.</p>
          <Link className="empty-membership-cta" href="/organisations/nouvelle">Créer une structure</Link>
        </div></main>
      ) : (
        pathname === "/moi" ? children : <main className="real-empty-page"><div className="real-empty-card">
          <p className="eyebrow">STRUCTURE</p>
          <h1>{identity.organization.name}</h1>
          <p>Votre structure est prête.</p>
          <strong>Aucun projet pour le moment.</strong>
        </div></main>
      )}
    </section>
  </div>;
}

export function AppShell({ children, identity }: { children: React.ReactNode; identity: AppShellIdentity }) {
  return <AppShellRender identity={identity} pathname={usePathname()}>{children}</AppShellRender>;
}
