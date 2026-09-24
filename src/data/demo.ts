export const demoProjects = [
  {
    slug: "xxx",
    name: "XXX",
    structure: "Bora Bora Productions",
    status: "En tournée",
    team: ["Marion — production", "Paul — technique", "Léa — logistique"],
    dates: [
      {
        slug: "brest-2026-09-28",
        dateLabel: "28 septembre 2026",
        shortDate: "28 septembre",
        city: "Brest",
        venue: "Le Quartz",
        status: "Confirmée",
        informations: [
          { id: "xxx-brest-transport", domain: "Transport", title: "Train de Paul — arrivée 18 h 12", freshness: "Modifié", source: "Information confirmée par l’équipe", updatedAt: "Il y a 45 min", needsAttention: true },
          { id: "xxx-brest-hotel", domain: "Hébergement", title: "Hôtel confirmé — Hôtel des Embruns", freshness: "À jour", source: "Production", updatedAt: "Hier", needsAttention: false },
          { id: "xxx-brest-schedule", domain: "Horaires", title: "Balance — 17 h 30", freshness: "À jour", source: "Feuille de route", updatedAt: "Hier", needsAttention: false },
          { id: "xxx-brest-team", domain: "Équipe", title: "6 personnes prévues sur cette date", freshness: "À jour", source: "Distribution", updatedAt: "20 septembre", needsAttention: false },
          { id: "xxx-brest-contract", domain: "Contrat", title: "Contrat envoyé — en attente de retour", freshness: "Nouveau", source: "Administration", updatedAt: "Il y a 2 h", needsAttention: false },
        ],
      },
    ],
  },
  {
    slug: "phantasia",
    name: "Phantasia",
    structure: "Bora Bora Productions",
    status: "En préparation",
    team: ["Camille — production", "Léa — logistique"],
    dates: [{ slug: "nantes-2026-09-30", dateLabel: "30 septembre 2026", shortDate: "30 septembre", city: "Nantes", venue: "TU-Nantes", status: "Confirmée", informations: [
      { id: "phantasia-nantes-schedule", domain: "Horaires", title: "Répétition — 14 h", freshness: "À jour", source: "Planning", updatedAt: "22 septembre", needsAttention: false },
      { id: "phantasia-nantes-tech", domain: "Technique", title: "Plateau disponible à partir de 13 h 30", freshness: "Nouveau", source: "Régie", updatedAt: "Ce matin", needsAttention: false },
    ] }],
  },
  {
    slug: "equinoxe",
    name: "Équinoxe",
    structure: "Atelier des Lucioles",
    status: "En préparation",
    team: ["Marion — production", "Paul — technique"],
    dates: [{ slug: "rennes-2026-10-02", dateLabel: "2 octobre 2026", shortDate: "2 octobre", city: "Rennes", venue: "Le Passage", status: "À vérifier", informations: [
      { id: "equinoxe-rennes-schedule", domain: "Horaires", title: "Représentation — 19 h 30", freshness: "À jour", source: "Planning", updatedAt: "21 septembre", needsAttention: false },
      { id: "equinoxe-rennes-admin", domain: "Administration", title: "Feuille de route à vérifier", freshness: "Modifié", source: "Production", updatedAt: "Ce matin", needsAttention: true },
    ] }],
  },
  {
    slug: "les-lucioles",
    name: "Les Lucioles",
    structure: "Atelier des Lucioles",
    status: "Confirmé",
    team: ["Camille — production", "Paul — technique"],
    dates: [{ slug: "angers-2026-10-04", dateLabel: "4 octobre 2026", shortDate: "4 octobre", city: "Angers", venue: "Théâtre du Parc", status: "Confirmée", informations: [
      { id: "lucioles-angers-hotel", domain: "Hébergement", title: "Hébergement confirmé pour l’équipe", freshness: "Nouveau", source: "Production", updatedAt: "Il y a 3 h", needsAttention: false },
      { id: "lucioles-angers-schedule", domain: "Horaires", title: "Représentation — 20 h 30", freshness: "À jour", source: "Planning", updatedAt: "20 septembre", needsAttention: false },
    ] }],
  },
] as const;

export const demoRecentActivity = demoProjects.flatMap((project) =>
  project.dates.flatMap((date) =>
    date.informations
      .filter((information) => information.freshness === "Nouveau" || information.freshness === "Modifié")
      .map((information) => ({
        information,
        project,
        date,
        href: `/projets/${project.slug}/dates/${date.slug}`,
      }))
  )
);

export const demoToday = {
  dateLabel: "JEUDI 24 SEPTEMBRE",
  firstName: "Marion",
  subtitle: "L’essentiel pour reprendre le fil rapidement.",
  organization: { name: "Bora Bora Productions", role: "Production" },
  attention: {
    countLabel: "4 éléments",
    items: [
      { kind: "alert", tag: "INFORMATION MANQUANTE", title: "Train retour de Pierre", project: "XXX · Brest", detail: "28 septembre", meta: "Aujourd’hui", urgent: true },
      { kind: "message", tag: "MESSAGE", title: "Jeanne attend une réponse", project: "Phantasia · Nantes", detail: "Logistique", meta: "Il y a 32 min", urgent: false },
      { kind: "alert", tag: "DOCUMENT", title: "Feuille de route à vérifier", project: "Équinoxe · Rennes", detail: "Document de tournée", meta: "Demain", urgent: false },
      { kind: "message", tag: "RÉPONSE ATTENDUE", title: "Camille confirme l’hébergement", project: "Les Lucioles · Angers", detail: "Hébergement", meta: "Cette semaine", urgent: false },
    ],
  },
  upcoming: {
    rangeLabel: "Les 7 prochains jours · 4 dates",
    dates: demoProjects.map((project) => {
      const date = project.dates[0];
      const [day, month] = date.shortDate.split(" ");
      return { day, month: month.slice(0, 3).toUpperCase(), title: project.name, detail: `${date.city} · ${date.venue}`, status: date.status, warning: date.status !== "Confirmée" };
    }),
  },
  work: {
    tasks: [
      { id: "task-hotel", title: "Réserver l’hôtel", projectSlug: "xxx", dateSlug: "brest-2026-09-28", project: "XXX", eventLabel: "Brest · 28 septembre", assignee: "Léa", deadline: "25 septembre", deadlineSort: "2026-09-25", status: "À faire", group: "todo", priority: "À faire aujourd’hui" },
      { id: "task-contract", title: "Envoyer le contrat", projectSlug: "phantasia", dateSlug: "nantes-2026-09-30", project: "Phantasia", eventLabel: "Nantes · 30 septembre", assignee: "Camille", deadline: "27 septembre", deadlineSort: "2026-09-27", status: "À faire", group: "soon", priority: "Bientôt" },
      { id: "task-roadbook", title: "Transmettre la feuille de route", projectSlug: "equinoxe", dateSlug: "rennes-2026-10-02", project: "Équinoxe", eventLabel: "Rennes · 2 octobre", assignee: "Marion", deadline: "30 septembre", deadlineSort: "2026-09-30", status: "À faire", group: "soon", priority: "Bientôt" },
      { id: "task-tech", title: "Confirmer l’horaire technique", projectSlug: "les-lucioles", dateSlug: null, project: "Les Lucioles", eventLabel: null, assignee: "Paul", deadline: "3 octobre", deadlineSort: "2026-10-03", status: "À faire", group: "soon", priority: "Sans urgence immédiate" },
      { id: "task-rooming", title: "Envoyer la liste des chambres", projectSlug: "les-lucioles", dateSlug: "angers-2026-10-04", project: "Les Lucioles", eventLabel: "Angers · 4 octobre", assignee: "Léa", deadline: "22 septembre", deadlineSort: "2026-09-22", status: "Terminé", group: "done", priority: "Terminé" },
    ],
    events: [
      { id: "event-brest", date: demoProjects[0].dates[0].shortDate, sort: "2026-09-28T20:00", time: "20 h", title: demoProjects[0].name, detail: `${demoProjects[0].dates[0].city} · ${demoProjects[0].dates[0].venue}`, kind: "Représentation" },
      { id: "event-nantes", date: demoProjects[1].dates[0].shortDate, sort: "2026-09-30T14:00", time: "14 h", title: demoProjects[1].name, detail: `${demoProjects[1].dates[0].city} · ${demoProjects[1].dates[0].venue}`, kind: "Répétition" },
      { id: "event-rennes", date: demoProjects[2].dates[0].shortDate, sort: "2026-10-02T19:30", time: "19 h 30", title: demoProjects[2].name, detail: `${demoProjects[2].dates[0].city} · ${demoProjects[2].dates[0].venue}`, kind: "Représentation" },
      { id: "event-angers", date: demoProjects[3].dates[0].shortDate, sort: "2026-10-04T20:30", time: "20 h 30", title: demoProjects[3].name, detail: `${demoProjects[3].dates[0].city} · ${demoProjects[3].dates[0].venue}`, kind: "Représentation" },
    ],
  },
} as const;

// Prototype-only content. Replace identity and business data with authenticated
// product data when the corresponding Boralog foundation is implemented.
