"use client";

import { useEffect, useState } from "react";
import { DEMO_ORG_ID, getRecord, initializeDemo, openDemoDatabase } from "@/lib/demo/local-db";

export default function DemoOrganizationPage() {
  const [organizationName, setOrganizationName] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    let database: IDBDatabase | undefined;
    (async () => {
      try {
        database = await openDemoDatabase();
        await initializeDemo(database);
        const organization = await getRecord(database, "organizations", DEMO_ORG_ID);
        if (active) {
          if (typeof organization?.name !== "string") throw new Error("Organisation de démonstration introuvable");
          setOrganizationName(organization.name);
        }
      } catch (cause) {
        if (active) setError(cause instanceof Error ? cause.message : "IndexedDB indisponible");
      } finally {
        database?.close();
      }
    })();
    return () => { active = false; };
  }, []);

  return <main className="destination-page"><div className="destination-wrap profile-page">
    <p className="eyebrow">PARAMÈTRES — DÉMONSTRATION LOCALE</p>
    <h1>Paramètres</h1>
    <p className="profile-intro">Gérez votre profil et les informations principales de votre Structure.</p>
    <section className="profile-account" aria-labelledby="demo-profile-title">
      <div><p className="eyebrow" id="demo-profile-title">MON PROFIL / MON COMPTE</p>
        <strong>Démonstrateur</strong><span>Compte fictif local</span></div>
      <div><p>Mode démonstration autonome. Aucune connexion Supabase nécessaire sur cet écran.</p></div>
    </section>
    <section className="profile-editor" aria-labelledby="demo-organization-title">
      <div className="profile-section-heading">
        <p className="eyebrow">MA STRUCTURE</p>
        <h2 id="demo-organization-title" data-testid="demo-organization-name">
          {error ? "Données locales indisponibles" : organizationName ?? "Chargement de la Structure…"}
        </h2>
      </div>
      {error ? <p role="alert">{error}</p> : <p className="profile-intro">La Structure contient vos Projets, Personnes, Messages et Dates.</p>}
    </section>
  </div></main>;
}
