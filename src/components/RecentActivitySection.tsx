import { demoRecentActivity } from "../data/demo";
import { RecentActivityList } from "./RecentActivityList";
import { SectionPreview } from "./SectionPreview";

const previewCount = 2;

export function RecentActivitySection() {
  return <SectionPreview
    className="recent-activity"
    title="Depuis votre dernière visite"
    hint="Changements récents utiles"
    href="/aujourdhui/activite-recente"
    hasMore={demoRecentActivity.length > previewCount}
  >
    <RecentActivityList items={demoRecentActivity.slice(0, previewCount)} />
  </SectionPreview>;
}
