import { AttentionList } from "./AttentionList";
import { SectionPreview } from "./SectionPreview";
import { demoToday } from "../data/demo";

const previewCount = 3;

export function AttentionSection() {
  const items = demoToday.attention.items;
  return <SectionPreview
    className="attention"
    title="À faire maintenant"
    hint={demoToday.attention.countLabel}
    href="/aujourdhui/a-faire"
    hasMore={items.length > previewCount}
  >
    <AttentionList items={items.slice(0, previewCount)} />
  </SectionPreview>;
}
