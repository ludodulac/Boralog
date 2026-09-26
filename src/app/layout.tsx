import type { Metadata } from "next";
import { AppShell } from "../components/AppShell";
import { getCurrentIdentity } from "../lib/auth";
import "./globals.css";

export const metadata: Metadata = { title: "Boralog", description: "La mémoire opérationnelle partagée du spectacle vivant." };

export default async function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  console.info("[BORALOG_DIAG_044] layout before getCurrentIdentity");
  const identity = await getCurrentIdentity();
  console.info("[BORALOG_DIAG_044] K layout received identity", { authenticated: Boolean(identity.userId), hasOrganization: identity.hasOrganization });
  console.info("[BORALOG_DIAG_044] L layout render AppShell");
  return <html lang="fr"><body><AppShell identity={identity}>{children}</AppShell></body></html>;
}
