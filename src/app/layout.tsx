import type { Metadata } from "next";
import { AppShell } from "../components/AppShell";
import { getCurrentIdentity } from "../lib/auth";
import "./globals.css";

export const metadata: Metadata = { title: "Boralog", description: "La mémoire opérationnelle partagée du spectacle vivant." };

export default async function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  const identity = await getCurrentIdentity();
  return <html lang="fr"><body><AppShell identity={identity}>{children}</AppShell></body></html>;
}
