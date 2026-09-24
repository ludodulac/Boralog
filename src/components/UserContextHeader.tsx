import { Search } from "lucide-react";
import { SecondaryMenu } from "./SecondaryMenu";

type UserContextHeaderProps = {
  dateLabel: string;
  firstName: string;
  subtitle: string;
};

export function UserContextHeader({ dateLabel, firstName, subtitle }: UserContextHeaderProps) {
  return <header>
    <div className="user-intro"><p className="eyebrow">{dateLabel}</p><h1>Bonjour {firstName}</h1><p className="subtitle">{subtitle}</p></div>
    <div className="header-actions">
      <button className="search"><Search size={19} aria-hidden="true"/><span>Rechercher</span><kbd>⌘ K</kbd></button>
      <SecondaryMenu />
    </div>
  </header>;
}
