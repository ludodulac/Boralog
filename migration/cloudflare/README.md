# BORALOG — Sortie Supabase / Cloudflare (chantier isolé)

## État audité (15 octobre 2026)
- Source : projet Supabase `jwtawyeuyvqjikjvfhri` (Boralog), organisation `ludodulac`.
- 23 tables publiques ; 1 utilisateur Auth ; aucune Edge Function ; aucun objet Storage ; base PostgreSQL 13 Mo (taille technique, pas taille des données métier).
- Quelques données de développement existent (9 messages, 1 organisation, 1 projet, 1 événement, etc.). **Ne pas assimiler faible volume à absence de données.**
- Deux tables étrangères au métier BORALOG cohabitent : `wikignose_admins` et `pending_documents`. Vérifier les dépendances externes avant suppression du projet Supabase.

## Règles de migration
1. Ne pas toucher au projet Supabase, à l'authentification ni au site de production avant une validation de bout en bout.
2. Exporter et conserver une sauvegarde hors Supabase de la structure, des politiques RLS et des données utiles avant toute suppression.
3. Traduire les types PostgreSQL (uuid, enums, timestamptz, arrays) en SQLite D1 avec contraintes et index explicites ; préserver les relations et les invariants métier.
4. Remplacer **tous** les contrôles RLS par des contrôles d'autorisation côté Worker (organisation, projet, rôle, visibilité des messages) et les tester négativement.
5. Migrer l'authentification Supabase Auth vers un système de sessions sûr ; aucune clef de service côté navigateur.
6. Vérifier tous les parcours CRUD et le fonctionnement mobile ; tester les tentatives d'accès inter-organisation.
7. Bascule uniquement après accord explicite et sauvegarde vérifiée ; supprimer le projet Supabase seulement après période de retour arrière et audit des usages Wikignose.

## Livrables à produire
- Inventaire exact du code consommant Supabase et des schémas SQL.
- Migrations D1 versionnées + tests SQLite.
- Worker d'API sécurisé + tests des permissions.
- Frontend de préproduction connecté au Worker.
- Procès-verbal de tests et plan de retour arrière.

**État : migration préparée, NON déployée. Aucune suppression autorisée.**
