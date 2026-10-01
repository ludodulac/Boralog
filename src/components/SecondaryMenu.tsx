"use client";

import Link from "next/link";
import { Menu, X } from "lucide-react";
import { useEffect, useId, useRef, useState } from "react";

export function SecondaryMenu() {
  const [open, setOpen] = useState(false);
  const [signingOut, setSigningOut] = useState(false);
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
    <button ref={triggerRef} className="menu-trigger" type="button" aria-label={open ? "Fermer le menu" : "Ouvrir le menu"} aria-expanded={open} aria-controls={panelId} onClick={() => setOpen((value) => !value)}>
      {open ? <X size={22} aria-hidden="true" /> : <Menu size={22} aria-hidden="true" />}
    </button>
    {open && <div className="menu-panel" id={panelId} role="dialog" aria-label="Menu secondaire">
      <Link className="menu-help-link" href="/aide" onClick={() => setOpen(false)}>Comment fonctionne Boralog ?</Link>
      <Link className="menu-help-link menu-calendar-link" href="/calendrier" onClick={() => setOpen(false)}>Calendrier</Link>
      <div className="menu-unavailable" aria-disabled="true"><span>Paramètres</span><small>Bientôt disponible</small></div>
      <form action="/auth/deconnexion" method="post" onSubmit={() => setSigningOut(true)}>
        <button className="menu-signout" type="submit" disabled={signingOut}>{signingOut ? "Déconnexion…" : "Se déconnecter"}</button>
      </form>
    </div>}
  </div>;
}
