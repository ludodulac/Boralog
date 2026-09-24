import { Search } from "lucide-react";

type UserContextHeaderProps = {
  dateLabel: string;
  firstName: string;
  subtitle: string;
};

export function UserContextHeader({ dateLabel, firstName, subtitle }: UserContextHeaderProps) {
  return <header>
    <div><p className="eyebrow">{dateLabel}</p><h1>Bonjour {firstName}</h1><p className="subtitle">{subtitle}</p></div>
    <button className="search"><Search size={19}/><span>Rechercher</span><kbd>⌘ K</kbd></button>
  </header>;
}
