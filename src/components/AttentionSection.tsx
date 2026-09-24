import { ArrowRight, CircleAlert, MessageCircle, TrainFront } from "lucide-react";
import { demoToday } from "../data/demo";

const icons = {
  alert: CircleAlert,
  message: MessageCircle,
  train: TrainFront,
};

export function AttentionSection() {
  return <section className="attention">
    <div className="section-title"><div><h2>À faire maintenant</h2><p>{demoToday.attention.countLabel}</p></div><button>Tout voir <ArrowRight size={16}/></button></div>
    {demoToday.attention.items.map((item) => {
      const Icon = icons[item.kind];
      return <article className={item.urgent ? "task urgent" : "task"} key={item.title}>
        <div className="task-icon"><Icon size={20}/></div>
        <div className="task-copy"><span className="tag">{item.tag}</span><h3>{item.title}</h3><p><strong>{item.project}</strong> · {item.detail}</p></div>
        <div className="task-meta"><span>{item.meta}</span><ArrowRight size={18}/></div>
      </article>;
    })}
  </section>;
}
