"use client";

import { usePathname } from "next/navigation";
import { MainNavigation } from "./MainNavigation";
import { SecondaryMenu } from "./SecondaryMenu";
import { demoToday } from "../data/demo";

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  return <div className="app-shell">
    <MainNavigation
      organizationName={demoToday.organization.name}
      organizationRole={demoToday.organization.role}
      pathname={pathname}
    />
    <section className="workspace">
      <div className="shell-utility"><SecondaryMenu /></div>
      {children}
    </section>
  </div>;
}
