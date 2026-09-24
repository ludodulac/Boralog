import { AttentionSection } from "../components/AttentionSection";
import { RecentActivitySection } from "../components/RecentActivitySection";
import { UpcomingDatesSection } from "../components/UpcomingDatesSection";
import { UserContextHeader } from "../components/UserContextHeader";
import { demoToday } from "../data/demo";

export default function Home() {
  return <>
    <UserContextHeader
      dateLabel={demoToday.dateLabel}
      firstName={demoToday.firstName}
      subtitle={demoToday.subtitle}
    />
    <div className="content">
      <AttentionSection />
      <RecentActivitySection />
      <UpcomingDatesSection />
    </div>
  </>;
}
