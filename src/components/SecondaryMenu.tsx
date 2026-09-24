"use client";

import Link from "next/link";
import { Menu, X } from "lucide-react";
import { useEffect, useId, useRef, useState } from "react";

export function SecondaryMenu() {
  const [open, setOpen] = useState(false);
  const panelId = useId();
  const triggerRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    if (!open) return;
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        setOpen(false);
        triggerRef.current?.focus();
      }
    };
    document.addEventListener("keydown", onKeyDown);
    return () => document.removeEventListener("keydown", onKeyDown);
  }, [open]);

  return <div className="secondary-menu">
    <button
      ref={triggerRef}
      className="menu-trigger"
      type="button"
      aria-label={open ? "Fermer le menu" : "Ouvrir le menu"}
      aria-expanded={open}
      aria-controls={panelId}
      onClick={() => setOpen((value) => !value)}
    >
      {open ? <X size={22} aria-hidden="true" /> : <Menu size={22} aria-hidden="true" />}
    </button>
    {open && <div className="menu-panel" id={panelId} role="dialog" aria-label="Menu secondaire">
      <div className="menu-panel-head">
        <button type="button" className="menu-close" onClick={() => { setOpen(false); triggerRef.current?.focus(); }}>
          <X size={18} aria-hidden="true" /><span>Fermer</span>
        </button>
      </div>
      <Link className="menu-help-link" href="/aide" onClick={() => setOpen(false)}>Comment fonctionne Boralog ?</Link>
      <Link className="menu-help-link menu-calendar-link" href="/calendrier" onClick={() => setOpen(false)}>Calendrier</Link>
      <div className="menu-unavailable" aria-disabled="true"><span>Paramètres</span><small>Bientôt disponible</small></div>
      <div className="menu-unavailable" aria-disabled="true"><span>Se déconnecter</span><small>Bientôt disponible</small></div>
    </div>}
  </div>;
}
