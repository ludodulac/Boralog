import { ArrowRight, CircleAlert, MessageCircle, TrainFront } from "lucide-react";
import { demoToday } from "../data/demo";

const icons = {
  alert: CircleAlert,
  message: MessageCircle,
  train: TrainFront,
};

type AttentionItem = (typeof demoToday.attention.items)[number];

type AttentionListProps = {
  items?: readonly AttentionItem[];
};

export function AttentionList({ items = demoToday.attention.items }: AttentionListProps) {
  return <div>
    {items.map((item) => {
      const Icon = icons[item.kind];
      return <article className={item.urgent ? "task urgent" : "task"} key={item.title}>
        <div className="task-icon"><Icon size={20} aria-hidden="true"/></div>
        <div className="task-copy"><span className="tag">{item.tag}</span><h3>{item.title}</h3><p><strong>{item.project}</strong> · {item.detail}</p></div>
        <div className="task-meta"><span>{item.meta}</span><ArrowRight size={18} aria-hidden="true"/></div>
      </article>;
    })}
  </div>;
}
