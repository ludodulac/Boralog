import { SectionPreview } from "./SectionPreview";
import { UpcomingDatesList } from "./UpcomingDatesList";
import { demoToday } from "../data/demo";

const previewCount = 2;

export function UpcomingDatesSection() {
  const dates = demoToday.upcoming.dates;
  return <SectionPreview
    className="upcoming"
    title="Prochaines dates"
    hint={demoToday.upcoming.rangeLabel}
    href="/aujourdhui/prochaines-dates"
    hasMore={dates.length > previewCount}
  >
    <UpcomingDatesList dates={dates.slice(0, previewCount)} />
  </SectionPreview>;
}
