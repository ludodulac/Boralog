import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { demoRecentActivity } from "../data/demo";

type RecentActivityItem = (typeof demoRecentActivity)[number];

export function RecentActivityList({ items = demoRecentActivity }: { items?: readonly RecentActivityItem[] }) {
  return <div className="recent-list">
    {items.map(({ information, project, date, href }) =>
      <Link className="recent-item" href={href} key={information.id}>
        <div className="recent-copy">
          <span className="recent-type">{information.freshness === "Nouveau" ? "NOUVEAU" : "CHANGEMENT"} · {information.domain.toUpperCase()}</span>
          <h3>{information.title}</h3>
          <p><strong>{project.name}</strong> · {date.city} · {date.shortDate}</p>
        </div>
        <div className="recent-meta"><span>{information.updatedAt}</span><ArrowRight size={18} aria-hidden="true"/></div>
      </Link>
    )}
  </div>;
}
