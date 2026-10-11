# Supabase Boralog

Projet utilisé : **Boralog** (`jwtawyeuyvqjikjvfhri`, région `eu-west-3`).

## Important

Ce projet Supabase contient un historique antérieur au développement actuel de Boralog. Lors de la reprise du 24 septembre 2026, deux tables héritées étaient encore présentes : `wikignose_admins` et `pending_documents`, avec des migrations historiques Wikignose/Darft.

**Règle : le développement Boralog ne modifie ni ne supprime ces objets hérités sans décision explicite.**

Les migrations Boralog commencent par `foundation_identity_organizations_projects` et sont reproduites dans ce dossier pour que le schéma ne dépende jamais uniquement de l'état distant.

Toutes les tables Boralog exposées utilisent RLS. Les clés secrètes ne doivent jamais être commitées ; seul le project URL et une clé publiable sont destinés au client.
