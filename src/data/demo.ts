export const demoToday = {
  dateLabel: "JEUDI 24 SEPTEMBRE",
  firstName: "Marion",
  subtitle: "Voici uniquement ce qui demande ton attention.",
  organization: {
    name: "Bora Bora Productions",
    role: "Production",
  },
  attention: {
    countLabel: "5 éléments",
    items: [
      {
        kind: "alert",
        tag: "INFORMATION MANQUANTE",
        title: "Train retour de Pierre",
        project: "XXX · Brest",
        detail: "28 septembre",
        meta: "Aujourd’hui",
        urgent: true,
      },
      {
        kind: "message",
        tag: "MESSAGE",
        title: "Jeanne attend une réponse",
        project: "Phantasia · Nantes",
        detail: "Logistique",
        meta: "Il y a 32 min",
        urgent: false,
      },
      {
        kind: "train",
        tag: "CHANGEMENT",
        title: "Nouvelle heure d’arrivée : 18 h 12",
        project: "Dame Jument · Lorient",
        detail: "Transport mis à jour",
        meta: "À vérifier",
        urgent: false,
      },
      {
        kind: "alert",
        tag: "DOCUMENT",
        title: "Feuille de route à vérifier",
        project: "Équinoxe · Rennes",
        detail: "Document de tournée",
        meta: "Demain",
        urgent: false,
      },
      {
        kind: "message",
        tag: "RÉPONSE ATTENDUE",
        title: "Camille confirme l’hébergement",
        project: "Les Lucioles · Angers",
        detail: "Hébergement",
        meta: "Cette semaine",
        urgent: false,
      },
    ],
  },
  upcoming: {
    rangeLabel: "Les 7 prochains jours · 4 dates",
    dates: [
      {
        day: "28",
        month: "SEP",
        title: "XXX",
        detail: "Brest · Le Quartz",
        status: "1 info manque",
        warning: true,
      },
      {
        day: "30",
        month: "SEP",
        title: "Phantasia",
        detail: "Nantes · TU-Nantes",
        status: "Complet",
        warning: false,
      },
      {
        day: "02",
        month: "OCT",
        title: "Équinoxe",
        detail: "Rennes · Le Passage",
        status: "À vérifier",
        warning: true,
      },
      {
        day: "04",
        month: "OCT",
        title: "Les Lucioles",
        detail: "Angers · Théâtre du Parc",
        status: "Complet",
        warning: false,
      },
    ],
  },
} as const;

// Prototype-only content. Replace identity and business data with authenticated
// product data when the corresponding Boralog foundation is implemented.
