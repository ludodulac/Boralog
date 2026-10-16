# État d'exécution — Cloudflare BORALOG
Dernière vérification : 2026-10-16.

## Ressources vérifiées
- Compte Cloudflare : `60a7b17758a93fe6681ce998e72ddff0`
- D1 créée par l'utilisateur : `boralog-staging` — `5e93b6a0-502f-4e22-ab31-aca64d7eeb75`
- Projet Supabase source : `jwtawyeuyvqjikjvfhri`
- Branche isolée : `feat/cloudflare-exit-001`
- PR : #60 (brouillon)

## Blocages techniques concrets
1. Ce dépôt ne contient pas de `package.json`, `index.html` ou `src/App.tsx` à la racine : ne pas présumer que le frontend BORALOG y est hébergé. Localiser l'application réelle avant de promettre la conservation des fonctionnalités.
2. Le connecteur GitHub disponible ne permet pas de renseigner les secrets Actions ni de lancer manuellement le workflow ; aucun connecteur Cloudflare direct n'est disponible.
3. Le workflow nécessite les secrets `BORALOG_STAGING_CF_API_TOKEN` et la variable `BORALOG_STAGING_CF_ACCOUNT_ID` (valeur `60a7b17758a93fe6681ce998e72ddff0`).
4. Le Worker actuel expose uniquement `/health` et une inspection protégée `/admin/schema-status` : ce n'est pas encore l'application BORALOG.
5. Les tables `wikignose_admins` et `pending_documents` cohabitent dans Supabase ; leurs consommateurs doivent être vérifiés avant fermeture du projet.
6. Les données et l'authentification ne sont pas encore migrées ; aucune sauvegarde exportée n'a été confirmée.

## Règles
- Ne jamais fusionner ni couper Supabase avant validation du frontend, de l'API, des permissions, des sauvegardes et du retour arrière.
- Ne jamais exposer de token API Cloudflare dans le dépôt ou la conversation.
- Ne jamais réutiliser la D1 Célébrations.

## Décision d'architecture confirmée par l'utilisateur (2026-10-16)
- **Conserver** les projets Supabase « La forêt enchantée » et « IN-SECT » (2 projets actifs au total après fermeture de BORALOG).
- **Ne pas migrer** les autres services de La forêt enchantée vers Cloudflare pour le moment.
- La migration des médias de Célébrations est un chantier distinct : ne pas confondre copie de fichiers R2 et bascule complète de Célébrations.
- **Fermer seulement** le projet Supabase BORALOG, après sauvegarde et contrôle des dépendances.
- Le dépôt GitHub `ludodulac/Wikignose` décrit explicitement une application statique autonome sans Supabase ; cela diminue le risque des deux tables Wikignose résiduelles, mais ne prouve pas qu'aucun autre outil ne les utilise.
- Le dépôt `ludodulac/Boralog` est pour l'instant un projet de documentation/prototype : le fichier `docs/ARCHITECTURE_INTERFACE_V0.md` indique que le premier prototype est **encore à construire**. Ne pas annoncer une application complète déjà migrée.
- Passer de trois à deux projets ne résilie **pas automatiquement** l'abonnement Supabase Pro : contrôler les limites Free et demander explicitement la rétrogradation du plan après vérification.
