import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = { title: "Boralog", description: "La mémoire opérationnelle partagée du spectacle vivant." };

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="fr"><body>{children}</body></html>;
}
