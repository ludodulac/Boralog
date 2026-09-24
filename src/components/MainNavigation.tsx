import Link from "next/link";
import { CalendarDays, FolderKanban, MessageCircle, Search, UserRound } from "lucide-react";

const nav = [
  [CalendarDays, "Aujourd’hui", "/"],
  [MessageCircle, "Messages", null],
  [FolderKanban, "Projets", "/projets"],
  [Search, "Recherche", null],
  [UserRound, "Moi", null],
] as const;

type MainNavigationProps = {
  organizationName: string;
  organizationRole: string;
};

function NavItems({ mobile = false }: { mobile?: boolean }) {
  return <>{nav.map(([Icon, label, href], i) => href
    ? <Link className={i === 0 ? "active" : ""} href={href} key={label}><Icon size={mobile ? 21 : 20} aria-hidden="true"/><span>{label}</span></Link>
    : <button className={i === 0 ? "active" : ""} type="button" key={label}><Icon size={mobile ? 21 : 20} aria-hidden="true"/><span>{label}</span></button>
  )}</>;
}

export function MainNavigation({ organizationName, organizationRole }: MainNavigationProps) {
  return <>
    <aside className="side-nav">
      <div className="brand"><span>B</span><strong>Boralog</strong></div>
      <nav><NavItems /></nav>
      <div className="org"><small>Organisation</small><strong>{organizationName}</strong><span>{organizationRole}</span></div>
    </aside>
    <nav className="bottom-nav" aria-label="Navigation principale"><NavItems mobile /></nav>
  </>;
}
