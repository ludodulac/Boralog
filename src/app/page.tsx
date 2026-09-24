import { AttentionSection } from "../components/AttentionSection";
import { MainNavigation } from "../components/MainNavigation";
import { UpcomingDatesSection } from "../components/UpcomingDatesSection";
import { UserContextHeader } from "../components/UserContextHeader";
import { demoToday } from "../data/demo";

export default function Home() {
  return <main className="app-shell">
    <MainNavigation
      organizationName={demoToday.organization.name}
      organizationRole={demoToday.organization.role}
    />
    <section className="workspace">
      <UserContextHeader
        dateLabel={demoToday.dateLabel}
        firstName={demoToday.firstName}
        subtitle={demoToday.subtitle}
      />
      <div className="content">
        <AttentionSection />
        <UpcomingDatesSection />
      </div>
    </section>
  </main>;
}
