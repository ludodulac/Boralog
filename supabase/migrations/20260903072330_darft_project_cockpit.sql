-- Mirrored from the existing Supabase migration history for the shared Boralog/Wikignose project.
-- Source version: 20260903072330; source name: darft_project_cockpit
-- Added locally so Supabase CLI history comparison matches the already-applied remote history.

create table if not exists public.darft_project_tasks (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  section text not null,
  title text not null,
  brief text not null,
  why_it_matters text,
  priority text not null default 'next' check (priority in ('now','next','later')),
  status text not null default 'todo' check (status in ('todo','in_progress','waiting','done')),
  owner_answer text not null default '',
  assistant_note text not null default '',
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id)
);

create table if not exists public.darft_project_journal (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null default '',
  kind text not null default 'note' check (kind in ('note','decision','question','idea')),
  is_resolved boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id)
);

create or replace function public.darft_touch_project_updated_at()
returns trigger language plpgsql set search_path = public as $$
begin
  new.updated_at = now();
  new.updated_by = (select auth.uid());
  return new;
end;
$$;

drop trigger if exists darft_project_tasks_touch on public.darft_project_tasks;
create trigger darft_project_tasks_touch before update on public.darft_project_tasks
for each row execute function public.darft_touch_project_updated_at();

drop trigger if exists darft_project_journal_touch on public.darft_project_journal;
create trigger darft_project_journal_touch before update on public.darft_project_journal
for each row execute function public.darft_touch_project_updated_at();

alter table public.darft_project_tasks enable row level security;
alter table public.darft_project_journal enable row level security;

revoke all on public.darft_project_tasks from anon;
revoke all on public.darft_project_journal from anon;
grant select, insert, update on public.darft_project_tasks to authenticated;
grant select, insert, update on public.darft_project_journal to authenticated;

drop policy if exists darft_team_manage_project_tasks on public.darft_project_tasks;
create policy darft_team_manage_project_tasks on public.darft_project_tasks
for all to authenticated
using (public.is_darft_admin())
with check (public.is_darft_admin());

drop policy if exists darft_team_manage_project_journal on public.darft_project_journal;
create policy darft_team_manage_project_journal on public.darft_project_journal
for all to authenticated
using (public.is_darft_admin())
with check (public.is_darft_admin());

insert into public.darft_project_tasks(code,section,title,brief,why_it_matters,priority,status,sort_order) values
('REAL-001','Catalogue réel','Remplacer progressivement les œuvres fictives','Constituer une première sélection de 5 à 12 œuvres réelles avec photographies exploitables, informations fiables, disponibilité et accord de publication. Ne pas supprimer les prototypes tant qu’un remplacement réel n’est pas prêt.','DARFT doit prouver son regard par des décisions réelles, pas par la quantité de fonctionnalités.','now','todo',10),
('CUR-001','Regard DARFT','Écrire « Pourquoi DARFT l’a choisie »','Pour chaque œuvre réelle, écrire 3 à 5 phrases concrètes sur ce qui a arrêté le regard, sans jargon de galerie et sans promesse financière.','Cette justification publique peut devenir la signature éditoriale de DARFT.','now','todo',20),
('PHOTO-001','Documentation','Définir le protocole photo des œuvres','Pour chaque œuvre : vue principale, détail matière, vue de côté ou d’épaisseur si utile, dos, signature/marque, échelle ou mise en situation lorsque pertinent.','Un langage documentaire cohérent rend DARFT identifiable sans dépendre d’effets graphiques.','now','todo',30),
('SEL-001','Sélections dans le temps','Préparer DARFT Selection 01','Définir la première sélection datée (par exemple Automne 2026), son nombre d’œuvres, son texte d’ouverture et sa date de clôture éditoriale. Les sélections passées devront rester consultables.','Le temps transforme le goût en historique vérifiable et donne du risque aux décisions curatoriales.','now','todo',40),
('REV-001','DARFT Review','Tester le refus utile sur de vrais dossiers','Rédiger les premiers retours avec : point remarqué, réserve éventuelle, décision et possibilité de revenir. Éviter les scores.','Même un refus doit montrer qu’une personne a réellement regardé l’œuvre.','now','todo',50),
('VOICE-001','Voix éditoriale','Réduire les maximes automatiques','Relire les pages publiques et décider quelles phrases-signatures méritent de rester. Dans les autres sections, préférer une écriture factuelle, précise et moins systématiquement aphoristique.','Trop de formules parfaites peuvent donner une impression de texte généré et affaiblir les meilleures phrases.','next','todo',60),
('VIS-001','Identité visuelle','Créer une grammaire documentaire DARFT','Choisir un système récurrent : numéro d’inventaire, fiche matière/dimensions, cachet ou marque de sélection, provenance, détails, date de sélection et état de disponibilité.','Le site doit devenir reconnaissable sans logo, au-delà du style galerie crème + serif.','next','todo',70),
('ACQ-001','Acquisition','Définir le parcours « Demander l’œuvre »','Décider ce qu’il se passe après une demande : réponse, réservation, paiement/acompte, contrat, transport, certificat et suivi.','La vente doit ressembler à une acquisition accompagnée plutôt qu’à un panier e-commerce.','next','todo',80),
('PROV-001','Provenance','Définir le dossier d’œuvre DARFT','Lister les documents remis à l’acquéreur : certificat, facture, provenance, fiche artiste, histoire de sélection, photos d’état, transport et historique utile.','La documentation et la transmission font partie du produit collection.','next','todo',90),
('COM-001','Comité','Former les premiers regards humains','Identifier jusqu’à trois personnes ou profils complémentaires : art contemporain, matière/fabrication, collectionneur/espace réel. Définir comment une conviction minoritaire peut déclencher une discussion.','DARFT doit pouvoir assumer un goût humain identifiable plutôt qu’une moyenne.','next','todo',100),
('ARCH-001','Archive invisible','Définir les règles d’archivage','Décider ce qui peut être conservé après non-sélection, avec quel consentement, quelles métadonnées, combien de temps et dans quels cas une œuvre peut réapparaître pour un collectionneur.','L’archive invisible peut devenir un actif stratégique sans gonfler le catalogue public.','next','todo',110),
('MATCH-001','Archive invisible','Préparer le brief de recherche collectionneur','Créer un questionnaire simple : espace, dimensions, budget, médium, tonalité, contraintes, délai et intention. L’IA pourra assister la recherche, la proposition finale restera humaine.','Cela permet à DARFT de tirer parti d’une base plus grande que la sélection publique.','later','todo',120),
('PRIVATE-001','DARFT Private','Valider le besoin avant de développer','Ne pas construire davantage de fonctionnalités Private avant d’avoir observé des demandes réelles de recherche, d’accompagnement ou de commandes. Noter les demandes reçues et leur contexte.','Évite de sur-concevoir une activité avant d’avoir confirmé le besoin.','later','todo',130),
('PROJECTS-001','DARFT Projects','Valider le besoin professionnel avant de développer','Documenter les demandes éventuelles d’architectes, décorateurs, hôtels, restaurants ou entreprises avant de construire un produit dédié.','Le regard DARFT doit précéder l’offre de services.','later','todo',140),
('LEGAL-001','Cadre commercial','Faire valider le cadre juridique et commercial','Préparer puis faire vérifier par un professionnel : CGV/mandat, commissions, droits de reproduction, authenticité, retours, transport, assurance, fiscalité et responsabilités.','La vente d’art et la gestion d’œuvres exigent un cadre fiable qui ne doit pas être improvisé.','next','todo',150),
('METRIC-001','Pilotage','Choisir les métriques qui ne déforment pas le goût','Suivre des métriques opérationnelles privées : candidatures examinées, délai de réponse, demandes d’acquisition, ventes, retours collectionneurs. Éviter de transformer popularité publique et vues en critères curatoriaux.','Le pilotage business ne doit pas contaminer la sélection éditoriale.','later','todo',160),
('HISTORY-001','Mémoire','Documenter les décisions importantes','À chaque décision structurante, noter le pourquoi dans la doctrine ou le journal du cockpit, y compris les choix abandonnés.','Une mémoire imparfaite mais réelle rend le projet moins artificiellement lisse et facilite la reprise du travail.','now','in_progress',170),
('LAUNCH-001','Lancement','Définir le seuil de lancement réel','Décider le minimum avant communication publique : nombre d’œuvres réelles, qualité photo, textes de sélection, parcours de demande, délais de réponse et premiers membres du comité.','Un seuil clair empêche d’accumuler des fonctions secondaires avant d’avoir un produit crédible.','now','todo',180)
on conflict (code) do update set
  section=excluded.section,title=excluded.title,brief=excluded.brief,why_it_matters=excluded.why_it_matters,priority=excluded.priority,sort_order=excluded.sort_order;

insert into public.darft_project_journal(title,body,kind,is_resolved)
select 'Règle de pilotage — 03 septembre 2026','DARFT doit accumuler du goût, pas des fonctionnalités. Les éléments existants ne sont pas supprimés simplement parce qu’ils sont futurs : ils restent documentés, mais le travail public est priorisé sur les œuvres réelles, le regard, la documentation et le parcours d’acquisition.','decision',false
where not exists (select 1 from public.darft_project_journal where title='Règle de pilotage — 03 septembre 2026');
