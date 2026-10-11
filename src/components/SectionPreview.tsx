import Link from "next/link";
import { ArrowRight } from "lucide-react";
import type { ReactNode } from "react";

type SectionPreviewProps = {
  title: string;
  hint: string;
  href: string;
  hasMore: boolean;
  children: ReactNode;
  className?: string;
};

export function SectionPreview({ title, hint, href, hasMore, children, className = "" }: SectionPreviewProps) {
  return <section className={className}>
    <div className="section-title">
      <div><h2>{title}</h2><p>{hint}</p></div>
      <Link className="section-more" href={href}>Tout voir <ArrowRight size={16} aria-hidden="true"/></Link>
    </div>
    <div className={hasMore ? "section-preview has-more" : "section-preview"}>
      {children}
      {hasMore && <div className="section-fade" aria-hidden="true"/>}
    </div>
  </section>;
}
