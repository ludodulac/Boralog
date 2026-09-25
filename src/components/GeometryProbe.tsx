"use client";

import { useCallback, useEffect, useState } from "react";

type Offender = { tag: string; technical: string; left: number; right: number; width: number };
type Snapshot = {
  innerWidth: number; clientWidth: number; documentScrollWidth: number; bodyScrollWidth: number;
  scrollX: number; visualWidth: number | null; visualOffsetLeft: number | null;
  visualPageLeft: number | null; visualScale: number | null; offenders: Offender[];
};

const round = (value: number) => Math.round(value * 10) / 10;

export function GeometryProbe() {
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null);
  const [expanded, setExpanded] = useState(false);

  const measure = useCallback(() => {
    const clientWidth = document.documentElement.clientWidth;
    const probe = document.querySelector("[data-geometry-probe]");
    const offenders = Array.from(document.body.querySelectorAll<HTMLElement>("*"))
      .filter((element) => element !== probe && !probe?.contains(element))
      .map((element) => ({ element, rect: element.getBoundingClientRect() }))
      .filter(({ rect }) => rect.left < 0 || rect.right > clientWidth)
      .slice(0, 12)
      .map(({ element, rect }) => ({
        tag: element.tagName.toLowerCase(),
        technical: element.id ? `#${element.id}` : element.classList.length ? `.${Array.from(element.classList).join(".")}` : "(none)",
        left: round(rect.left), right: round(rect.right), width: round(rect.width),
      }));
    const vv = window.visualViewport;
    setSnapshot({
      innerWidth: round(window.innerWidth), clientWidth: round(clientWidth),
      documentScrollWidth: round(document.documentElement.scrollWidth), bodyScrollWidth: round(document.body.scrollWidth),
      scrollX: round(window.scrollX), visualWidth: vv ? round(vv.width) : null,
      visualOffsetLeft: vv ? round(vv.offsetLeft) : null, visualPageLeft: vv ? round(vv.pageLeft) : null,
      visualScale: vv ? round(vv.scale) : null, offenders,
    });
  }, []);

  useEffect(() => {
    measure();
    const vv = window.visualViewport;
    const events: Array<[EventTarget, string]> = [[window, "resize"], [window, "scroll"], [document, "focusin"]];
    if (vv) events.push([vv, "resize"], [vv, "scroll"]);
    for (const [target, event] of events) target.addEventListener(event, measure, { passive: true });
    return () => { for (const [target, event] of events) target.removeEventListener(event, measure); };
  }, [measure]);

  if (!snapshot) return null;
  const delta = Math.max(snapshot.documentScrollWidth, snapshot.bodyScrollWidth) - snapshot.clientWidth;
  const shellStyle = {
    position: "fixed" as const, zIndex: 1000, right: 8, bottom: 8, boxSizing: "border-box" as const,
    maxWidth: "calc(100vw - 16px)", overflowWrap: "anywhere" as const, wordBreak: "break-word" as const,
  };

  if (!expanded) return <div data-geometry-probe="021" style={shellStyle}>
    <button type="button" onClick={() => setExpanded(true)} style={{
      boxSizing: "border-box", maxWidth: "100%", minWidth: 0, padding: "8px 10px",
      border: "1px solid #ccd3d0", borderRadius: 999, background: "rgba(255,255,255,.96)",
      font: "inherit", fontSize: 11, fontWeight: 700, lineHeight: 1, cursor: "pointer",
    }}>PROBE</button>
  </div>;

  return <aside data-geometry-probe="021" style={{
    ...shellStyle, left: 8, maxHeight: "42vh", overflowY: "auto", padding: 10,
    border: "1px solid #ccd3d0", borderRadius: 10, background: "rgba(255,255,255,.96)",
    fontSize: 11, lineHeight: 1.35,
  }}>
    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 8 }}>
      <strong>GEOMETRY PROBE 021</strong>
      <button type="button" onClick={() => setExpanded(false)} style={{
        flex: "0 0 auto", border: "1px solid #ccd3d0", borderRadius: 8, background: "white",
        padding: "5px 8px", font: "inherit", fontSize: 11, cursor: "pointer",
      }}>Fermer</button>
    </div>
    <div>DOCUMENT_OVERFLOW = {delta > 0 ? "YES" : "NO"}</div>
    <div>DOCUMENT_DELTA_PX = {round(delta)}</div>
    <div>WINDOW_INNER_WIDTH = {snapshot.innerWidth}</div>
    <div>DOCUMENT_CLIENT_WIDTH = {snapshot.clientWidth}</div>
    <div>DOCUMENT_SCROLL_WIDTH = {snapshot.documentScrollWidth}</div>
    <div>BODY_SCROLL_WIDTH = {snapshot.bodyScrollWidth}</div>
    <div>WINDOW_SCROLL_X = {snapshot.scrollX}</div>
    <div>VISUAL_VIEWPORT_OFFSET_LEFT = {snapshot.visualOffsetLeft ?? "N/A"}</div>
    <div>VISUAL_VIEWPORT_PAGE_LEFT = {snapshot.visualPageLeft ?? "N/A"}</div>
    <div>VISUAL_VIEWPORT_WIDTH = {snapshot.visualWidth ?? "N/A"}</div>
    <div>VISUAL_VIEWPORT_SCALE = {snapshot.visualScale ?? "N/A"}</div>
    <div>OFFENDING_ELEMENTS = {snapshot.offenders.length}</div>
    {snapshot.offenders.map((item, index) =>
      <div key={index}>#{index + 1} {item.tag} {item.technical} L={item.left} R={item.right} W={item.width}</div>
    )}
  </aside>;
}
