import type { Metadata } from "next";
import { headers } from "next/headers";
import { AppShell } from "../components/AppShell";
import { getCurrentIdentity } from "../lib/auth";
import "./globals.css";

export const metadata: Metadata = { title: "Boralog", description: "La mémoire opérationnelle partagée du spectacle vivant." };

export default async function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  const isDemoRoute = (await headers()).get("x-boralog-internal-demo-route") === "organisation";
  const identity = isDemoRoute
    ? {
        userId: "00000000-0000-4000-8000-000000000001",
        email: null,
        profile: { id: "00000000-0000-4000-8000-000000000001", display_name: "Démonstrateur", professional_email: null },
        organization: { id: "00000000-0000-4000-8000-000000000002", name: "Compagnie Horizon", accessLevel: "owner" as const },
        hasOrganization: true,
      }
    : await getCurrentIdentity();
  return <html lang="fr"><body><AppShell identity={identity}>{children}</AppShell></body></html>;
}
