import { AttentionSection } from "../components/AttentionSection";
import { RecentActivitySection } from "../components/RecentActivitySection";
import { UpcomingDatesSection } from "../components/UpcomingDatesSection";
import { UserContextHeader } from "../components/UserContextHeader";
import { demoToday } from "../data/demo";
import { getCurrentIdentity } from "../lib/auth";

export default async function Home() {
  const identity = await getCurrentIdentity();
  const firstName = identity.profile?.display_name?.split(/\s+/)[0] || "vous";
  return <>
    <UserContextHeader dateLabel={demoToday.dateLabel} firstName={firstName} subtitle={demoToday.subtitle}/>
    <div className="content">
      <AttentionSection />
      <RecentActivitySection />
      <UpcomingDatesSection />
    </div>
  </>;
}
