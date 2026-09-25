"use client";

import { useCallback, useEffect, useState } from "react";

type Offender = { tag: string; technical: string; left: number; right: number; width: number };
type Snapshot = {
  innerWidth: number;
  clientWidth: number;
  documentScrollWidth: number;
  bodyScrollWidth: number;
  scrollX: number;
  visualWidth: number | null;
  visualOffsetLeft: number | null;
  visualPageLeft: number | null;
  visualScale: number | null;
  offenders: Offender[];
};

const round = (value: number) => Math.round(value * 10) / 10;

export function GeometryProbe() {
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null);

  const measure = useCallback(() => {
    const clientWidth = document.documentElement.clientWidth;
    const panel = document.querySelector("[data-geometry-probe]");
    const offenders = Array.from(document.body.querySelectorAll<HTMLElement>("*"))
      .filter((element) => !panel?.contains(element) && element !== panel)
      .map((element) => ({ element, rect: element.getBoundingClientRect() }))
      .filter(({ rect }) => rect.left < 0 || rect.right > clientWidth)
      .slice(0, 12)
      .map(({ element, rect }) => ({
        tag: element.tagName.toLowerCase(),
        technical: element.id ? `#${element.id}` : element.classList.length ? `.${Array.from(element.classList).join(".")}` : "(none)",
        left: round(rect.left),
        right: round(rect.right),
        width: round(rect.width),
      }));
    const vv = window.visualViewport;
    setSnapshot({
      innerWidth: round(window.innerWidth),
      clientWidth: round(clientWidth),
      documentScrollWidth: round(document.documentElement.scrollWidth),
      bodyScrollWidth: round(document.body.scrollWidth),
      scrollX: round(window.scrollX),
      visualWidth: vv ? round(vv.width) : null,
      visualOffsetLeft: vv ? round(vv.offsetLeft) : null,
      visualPageLeft: vv ? round(vv.pageLeft) : null,
      visualScale: vv ? round(vv.scale) : null,
      offenders,
    });
  }, []);

  useEffect(() => {
    measure();
    const vv = window.visualViewport;
    const events: Array<[EventTarget, string]> = [
      [window, "resize"], [window, "scroll"], [document, "focusin"],
    ];
    if (vv) events.push([vv, "resize"], [vv, "scroll"]);
    for (const [target, event] of events) target.addEventListener(event, measure, { passive: true });
    return () => { for (const [target, event] of events) target.removeEventListener(event, measure); };
  }, [measure]);

  if (!snapshot) return null;
  const delta = Math.max(snapshot.documentScrollWidth, snapshot.bodyScrollWidth) - snapshot.clientWidth;
  return <aside data-geometry-probe="021" style={{
    position: "fixed", zIndex: 1000, left: 8, right: 8, bottom: 8,
    maxWidth: "calc(100vw - 16px)", maxHeight: "42vh", overflowY: "auto",
    boxSizing: "border-box", padding: 10, border: "1px solid #ccd3d0",
    borderRadius: 10, background: "rgba(255,255,255,.96)", fontSize: 11,
    lineHeight: 1.35, overflowWrap: "anywhere", wordBreak: "break-word",
  }}>
    <strong>GEOMETRY PROBE 021</strong>
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
