import Link from "next/link";
import { CalendarDays, FolderKanban, MessageCircle, Search, UserRound } from "lucide-react";

const nav = [
  [CalendarDays, "Aujourd’hui", "/"],
  [MessageCircle, "Messages", "/messages"],
  [FolderKanban, "Projets", "/projets"],
  [Search, "Recherche", "/recherche"],
  [UserRound, "Moi", "/moi"],
] as const;

type MainNavigationProps = {
  organizationName: string;
  organizationRole: string;
  pathname: string;
};

function isActive(label: string, pathname: string) {
  if (label === "Projets") return pathname === "/projets" || pathname.startsWith("/projets/");
  if (label === "Aujourd’hui") return pathname === "/" || pathname.startsWith("/aujourdhui/");
  if (label === "Messages") return pathname === "/messages" || pathname.startsWith("/messages/");
  if (label === "Recherche") return pathname === "/recherche" || pathname.startsWith("/recherche/");
  if (label === "Moi") return pathname === "/moi" || pathname.startsWith("/moi/");
  return false;
}

function NavItems({ pathname, mobile = false }: { pathname: string; mobile?: boolean }) {
  return <>{nav.map(([Icon, label, href]) => {
    const active = isActive(label, pathname);
    const className = active ? "active" : undefined;
    const current = active ? "page" as const : undefined;
    return href
      ? <Link className={className} href={href} aria-current={current} key={label}><Icon size={mobile ? 21 : 20} aria-hidden="true"/><span>{label}</span></Link>
      : <button className={className} type="button" key={label} aria-current={current}><Icon size={mobile ? 21 : 20} aria-hidden="true"/><span>{label}</span></button>;
  })}</>;
}

export function MainNavigation({ organizationName, organizationRole, pathname }: MainNavigationProps) {
  return <>
    <aside className="side-nav">
      <div className="brand"><span>B</span><strong>Boralog</strong></div>
      <nav aria-label="Navigation principale"><NavItems pathname={pathname}/></nav>
      <div className="org"><small>Organisation</small><strong>{organizationName}</strong><span>{organizationRole}</span></div>
    </aside>
    <nav className="bottom-nav" aria-label="Navigation principale"><NavItems pathname={pathname} mobile /></nav>
  </>;
}
