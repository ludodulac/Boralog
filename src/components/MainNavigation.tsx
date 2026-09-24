import { CalendarDays, FolderKanban, MessageCircle, Search, UserRound } from "lucide-react";

const nav = [
  [CalendarDays, "Aujourd’hui"],
  [MessageCircle, "Messages"],
  [FolderKanban, "Projets"],
  [Search, "Recherche"],
  [UserRound, "Moi"],
] as const;

type MainNavigationProps = {
  organizationName: string;
  organizationRole: string;
};

export function MainNavigation({ organizationName, organizationRole }: MainNavigationProps) {
  return <>
    <aside className="side-nav">
      <div className="brand"><span>B</span><strong>Boralog</strong></div>
      <nav>{nav.map(([Icon,label],i)=><button className={i===0?"active":""} key={label}><Icon size={20}/><span>{label}</span></button>)}</nav>
      <div className="org"><small>Organisation</small><strong>{organizationName}</strong><span>{organizationRole}</span></div>
    </aside>
    <nav className="bottom-nav">{nav.map(([Icon,label],i)=><button className={i===0?"active":""} key={label}><Icon size={21}/><span>{label}</span></button>)}</nav>
  </>;
}
