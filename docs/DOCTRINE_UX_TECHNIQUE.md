# Boralog — Doctrine UX et architecture technique

> Statut : document vivant.
>
> Ce document décrit **comment Boralog doit être construit et se comporter** pour rester extrêmement simple, rapide, lisible et agréable sur téléphone comme sur ordinateur. Il complète `VISION_PRODUIT.md`, qui décrit surtout **quoi** construire et **pourquoi**.

## 1. Ambition d'expérience

Boralog doit donner l'impression d'un logiciel professionnel très simple, pas d'un site administratif.

Les qualités recherchées :

- immédiat ;
- calme ;
- lisible ;
- rapide ;
- prévisible ;
- peu de saisie ;
- très peu de niveaux de navigation ;
- aucune fonction importante cachée derrière une interface obscure ;
- beau par la qualité de la hiérarchie, de l'espace et des détails, pas par des effets décoratifs ;
- utilisable d'une main sur téléphone pour les actions courantes ;
- beaucoup plus dense sur grand écran sans devenir un autre produit.

Le critère ultime n'est pas « combien de fonctions avons-nous ? », mais :

**« Combien d'effort faut-il à quelqu'un pour trouver, comprendre ou modifier l'information dont il a besoin ? »**

## 2. Principes UX non négociables

### 2.1 Reconnaître plutôt que mémoriser

L'utilisateur ne doit pas se souvenir de l'endroit où une information a été rangée.

Le produit doit fournir :

- navigation visible ;
- noms explicites ;
- contexte visible ;
- recherches et suggestions ;
- éléments récents ;
- favoris si cela devient utile ;
- historique des derniers projets/dates consultés.

Éviter les icônes mystérieuses sans libellé pour les fonctions importantes.

### 2.2 Divulgation progressive

Ne pas montrer 40 commandes parce que Boralog sait faire 40 choses.

Montrer d'abord ce qui sert maintenant. Les fonctions rares ou avancées apparaissent ensuite dans un niveau secondaire clairement nommé.

Exemple sur une date :

**État essentiel**
- horaire ;
- équipe ;
- voyage ;
- hébergement ;
- alertes.

Puis :
**Voir administration**, **Voir documents**, **Voir détails techniques**, etc.

### 2.3 Le contexte avant le menu

Quand l'utilisateur est dans « Brest — XXX — 17 octobre », les actions proposées doivent concerner Brest.

Éviter de le renvoyer constamment dans un menu général pour agir.

### 2.4 Une action fréquente doit être courte

Objectif de conception, à tester et non à appliquer aveuglément :

- information courante : visible immédiatement ou en 1 action ;
- action fréquente : 1 à 3 actions simples ;
- action rare/complexe : peut demander davantage d'étapes si cela évite les erreurs.

Ne jamais réduire artificiellement le nombre de clics au prix de la compréhension.

### 2.5 Une page = une intention dominante

Une page peut contenir beaucoup d'informations, mais l'utilisateur doit comprendre immédiatement :

- où il est ;
- ce qui est important ;
- ce qu'il peut faire maintenant.

## 3. Navigation : téléphone

### 3.1 Barre principale basse

Sur petit écran, envisager une barre fixe avec au maximum 4 ou 5 destinations très stables :

- Aujourd'hui ;
- Messages ;
- Projets ;
- Recherche ;
- Moi / Plus.

Le choix définitif devra être testé avec de vrais utilisateurs.

### 3.2 Bouton d'action contextuel

Une action très fréquente peut être accessible immédiatement :

**+ Message**, **+ Info**, **+ Action** ou un bouton contextuel selon l'écran.

Éviter un bouton « + » dont le sens change de façon imprévisible.

### 3.3 Pas de menu hamburger comme unique porte d'entrée

Le menu secondaire peut exister, mais les fonctions quotidiennes doivent rester visibles.

### 3.4 Scroll : oui, labyrinthe : non

Le scroll vertical est naturel sur téléphone. Il ne faut donc pas chercher à tout faire tenir artificiellement sur un écran.

En revanche :

- jamais de scroll horizontal pour lire une page normale ;
- les informations prioritaires restent en haut ;
- les sections longues sont regroupées ;
- possibilité de replier les détails secondaires ;
- en-tête contextuel compact éventuellement collant ;
- retour clair au niveau précédent.

Le problème n'est pas de scroller. Le problème est de scroller sans savoir où l'on va ni où se trouve l'information.

### 3.5 Zones tactiles

Cible interne Boralog : viser environ **44–48 px minimum** pour les commandes tactiles fréquentes, avec suffisamment d'espace entre elles.

Les petites icônes visuelles peuvent exister, mais leur zone réellement cliquable doit être confortable.

### 3.6 Pas d'interaction uniquement par glissement

Un swipe ou drag peut être un raccourci, jamais la seule façon d'accomplir une action essentielle.

## 4. Navigation : ordinateur

Sur grand écran, profiter de la largeur au lieu d'étirer la version mobile.

Structure envisagée :

- colonne de navigation stable à gauche ;
- contenu principal au centre ;
- panneau contextuel facultatif à droite pour détails, participants ou actions.

Exemple :

**gauche** : projets / messages / recherche  
**centre** : conversation ou dossier de date  
**droite** : informations de la date / participants / actions

L'utilisateur peut ainsi lire une conversation tout en gardant son contexte sans ouvrir cinq pages.

## 5. Même produit, deux compositions

Ne pas construire « Boralog mobile » et « Boralog desktop » séparément.

Les mêmes objets, permissions, actions et données existent partout.

Seule la composition change :

- téléphone : une colonne et navigation progressive ;
- tablette : une ou deux colonnes ;
- ordinateur : deux ou trois zones quand cela améliore réellement le travail.

Le responsive doit suivre l'espace réellement disponible, pas seulement des modèles d'appareils.

## 6. Hiérarchie de navigation métier

Chemin conceptuel principal :

**Structure → Spectacle → Date → Information / conversation / action**

Mais l'utilisateur ne doit pas toujours parcourir toute cette hiérarchie.

Des raccourcis doivent permettre d'arriver directement par :

- Aujourd'hui ;
- notification ;
- recherche ;
- message récent ;
- projet récent ;
- personne ;
- date.

Le contexte affiché doit toujours permettre de comprendre où l'on se trouve.

## 7. Recherche universelle

La recherche est une fonction centrale, pas un accessoire.

Une seule recherche doit pouvoir trouver progressivement :

- personne ;
- structure ;
- spectacle ;
- ville ;
- date ;
- message ;
- mot contenu dans un message ;
- document référencé ;
- facture ;
- contrat ;
- tâche.

Les résultats doivent être regroupés par nature et afficher leur contexte.

Exemple :

**« Pierre »**

- Pierre Martin — artiste ;
- 8 messages ;
- 3 dates à venir ;
- 1 information manquante.

L'autocomplétion et les suggestions réduisent l'effort de mémoire.

## 8. Écrans prioritaires envisagés

### Aujourd'hui

Ne pas faire un tableau de bord décoratif.

Afficher ce qui demande une attention réelle :

- mes décisions ;
- mes actions ;
- informations manquantes ;
- changements importants ;
- échéances ;
- messages qui m'attendent.

### Messages

Conversation rapide et sobre.

Toujours afficher clairement :

- qui participe ;
- à quel projet/date la conversation est reliée ;
- niveau d'accès ;
- actions permettant de transformer un message en donnée métier.

### Projet / spectacle

Résumé immédiatement compréhensible :

- prochaines dates ;
- état des sujets importants ;
- équipe ;
- conversations ;
- documents ;
- alertes.

### Date

Écran métier majeur.

Résumé en premier, détails ensuite.

### Recherche

Accessible de presque partout et rapide dès la première frappe.

## 9. Formulaires

Les formulaires sont un risque majeur de lourdeur.

Règles :

- ne demander que ce qui est nécessaire maintenant ;
- préremplir ce qui est déjà connu ;
- ne jamais demander deux fois la même donnée ;
- utiliser le bon clavier mobile (date, téléphone, nombre, email) ;
- proposer des valeurs existantes plutôt que faire retaper ;
- sauvegarde automatique des brouillons lorsque raisonnable ;
- erreurs expliquées près du champ ;
- validation destructrice uniquement quand nécessaire ;
- possibilité d'annuler ou restaurer quand c'est possible.

Préférer :

**Ajouter arrivée**
- personne ;
- jour ;
- heure.

à un formulaire de 15 champs dont 12 sont facultatifs.

## 10. Lisibilité et identité visuelle

Le design « sexy » recherché doit venir de la précision.

Principes :

- typographie très lisible ;
- peu de tailles de texte différentes ;
- contraste élevé ;
- beaucoup d'espace utile ;
- alignements rigoureux ;
- couleurs utilisées pour le sens, jamais comme seul moyen de transmettre le sens ;
- états explicites par mots : « À faire », « En attente », « Bloqué », « Terminé » ;
- animations courtes et fonctionnelles seulement ;
- pas d'effets lourds ou gratuits ;
- composants cohérents partout.

Une interface professionnelle inspire confiance parce qu'elle semble stable et évidente.

## 11. Accessibilité comme qualité générale

Cible : WCAG 2.2 AA au minimum pour le produit web.

Inclure dès le départ :

- navigation clavier ;
- focus clairement visible ;
- ordre de tabulation logique ;
- libellés accessibles ;
- contraste suffisant ;
- zoom texte sans perte de fonction ;
- zones tactiles confortables ;
- alternatives aux gestes de glissement ;
- messages d'erreur compréhensibles ;
- aucune information communiquée uniquement par une couleur.

L'accessibilité ne sera pas ajoutée à la fin.

## 12. Stockage : ne pas confondre « léger » et « tout en texte »

Boralog doit être léger, mais la bonne solution n'est pas de stocker toute la réalité dans de grandes phrases.

### 12.1 Données structurées à stocker en base

Exemples :

- identifiants ;
- noms ;
- emails/téléphones professionnels nécessaires ;
- dates et heures ;
- lieux ;
- rôles ;
- permissions ;
- participants ;
- relations structure/spectacle/date ;
- messages texte ;
- statuts ;
- tâches ;
- échéances ;
- montants ;
- références de factures ;
- métadonnées de documents ;
- historique des changements.

Ces données occupent très peu de place comparées aux médias et permettent recherche, tri, filtres et automatisations fiables.

### 12.2 Types de données

Utiliser des types adaptés :

- texte pour le texte ;
- date/heure pour les dates ;
- nombre décimal pour les montants ;
- booléen pour oui/non ;
- identifiants pour les relations ;
- JSON/JSONB uniquement lorsque la structure flexible le justifie.

Ne pas enregistrer « 12 mai 2027 à 18h, payé oui, 450 euros » dans une seule chaîne de texte si ces valeurs doivent être utilisées séparément.

## 13. Fichiers : stratégie minimaliste

L'objectif n'est pas forcément **zéro fichier**. Un logiciel de production aura probablement besoin de contrats, feuilles de route, fiches techniques, RIB, justificatifs ou photos de communication.

Doctrine :

1. **La base de données ne contient pas les gros fichiers binaires.**
2. Elle conserve leurs métadonnées et références.
3. Les fichiers sont stockés dans un stockage objet séparé ou, lorsque cela convient, référencés depuis le système documentaire existant.
4. Pas de duplication automatique de gros fichiers.
5. Taille maximale et types autorisés définis par usage.
6. Compression/optimisation lorsque pertinente.
7. Les vidéos et gros médias ne sont pas un objectif de la V1.
8. Un document externe peut être représenté par une URL + titre + type + droits + relation au projet.

Cela garde le cœur très léger sans rendre le produit inutilisable.

## 14. Ce qu'il faut probablement stocker en plus du texte

Même avec une philosophie très légère :

- dates/heures ;
- nombres/montants ;
- identifiants ;
- permissions ;
- relations entre objets ;
- états ;
- historique d'audit ;
- préférences minimales ;
- références vers fichiers ;
- éventuellement petites images de profil optimisées, mais elles ne sont pas essentielles.

Les données structurées sont petites. Le poids vient surtout des images, PDF lourds, audio et vidéo.

## 15. Historique et traçabilité

Comme plusieurs personnes peuvent modifier la même information, Boralog doit pouvoir répondre :

- qui a changé quoi ?
- quand ?
- ancienne valeur ?
- nouvelle valeur ?

Cela permet de collaborer sans peur.

Pour les données importantes, préférer un historique append-only ou un journal d'événements plutôt que perdre silencieusement l'ancienne valeur.

## 16. Permissions techniques

Les droits doivent être vérifiés côté serveur, pas seulement cachés dans l'interface.

Principes :

- refus par défaut ;
- privilège minimum ;
- accès accordé explicitement selon structure, rôle, relation ou objet ;
- les contrôles UI améliorent l'expérience mais ne constituent jamais la sécurité ;
- journaliser les opérations sensibles ;
- tester automatiquement les règles d'autorisation.

Les conversations privées professionnelles nécessitent une attention particulière : une personne non autorisée ne doit pas pouvoir les obtenir en modifiant une URL ou une requête.

## 17. Performance

Boralog doit sembler instantané même sur un téléphone moyen et un réseau imparfait.

Principes :

- HTML/CSS/JavaScript aussi sobres que possible ;
- charger d'abord le contenu nécessaire ;
- pagination ou chargement progressif des longues conversations ;
- indexer les recherches et filtres ;
- éviter les bibliothèques lourdes sans bénéfice réel ;
- limiter les animations ;
- mettre en cache intelligemment les ressources stables ;
- afficher immédiatement un état de chargement utile plutôt qu'un écran vide.

Mesurer réellement les performances sur mobile, pas seulement sur ordinateur de développement.

## 18. PWA et réseau imparfait

Boralog devrait être étudié comme **Progressive Web App (PWA)** :

- fonctionne dans le navigateur ;
- peut être installable sur l'écran d'accueil lorsque la plateforme le permet ;
- une seule base de code web ;
- cache de l'interface ;
- possibilité future de consulter certaines informations récentes hors connexion ;
- possibilité future de saisir une action hors connexion puis la synchroniser.

Attention : le hors-ligne complet et la résolution de conflits peuvent devenir complexes. Commencer par une expérience réseau faible robuste, puis ajouter le hors-ligne selon les besoins réels.

Ne jamais mettre en cache local des données sensibles sans stratégie de sécurité explicite.

## 19. Notifications

Préférer des notifications utiles à un flux incessant.

Catégories :

- message direct ;
- changement qui affecte ma responsabilité ;
- tâche assignée ;
- échéance ;
- blocage ;
- information manquante.

Prévoir :

- centre de notifications interne ;
- réglages par catégorie ;
- regroupement ;
- lecture/non lu ;
- liens directs vers le bon contexte.

Push mobile seulement si cela apporte une valeur réelle.

## 20. Architecture de données conceptuelle

Objets fondamentaux probables :

- User
- Organization
- Membership
- Role / Permission
- Project / Show
- Event / Performance / Residency
- Person / Contact
- Conversation
- ConversationParticipant
- Message
- StructuredInfo
- Task
- Assignment
- Travel
- Accommodation
- DocumentReference
- Contract
- Quote
- Invoice
- Payment
- BudgetItem
- Notification
- AuditEvent

Les noms définitifs seront choisis au moment du schéma technique.

Le point important : **les objets doivent être reliés**, pas reproduits dans chaque module.

## 21. Architecture technique envisagée, sans la figer trop tôt

Pour un produit web moderne de ce type :

- frontend responsive ;
- backend/API avec règles métier ;
- base relationnelle PostgreSQL ;
- authentification ;
- autorisations côté serveur ;
- recherche indexée ;
- temps réel pour les messages si nécessaire ;
- stockage objet séparé pour les fichiers ;
- PWA/cache local uniquement là où cela améliore réellement l'usage.

Ne pas choisir une technologie parce qu'elle est à la mode. La priorité est maintenabilité, sécurité, rapidité et coût raisonnable.

## 22. Design system Boralog

Avant de multiplier les pages, définir un petit système commun :

- échelle typographique ;
- espacements ;
- rayons ;
- boutons primaire/secondaire/destructif ;
- champs ;
- cartes ;
- listes ;
- badges d'état ;
- alertes ;
- avatars ;
- panneaux ;
- modales / bottom sheets ;
- navigation ;
- états vides ;
- chargement ;
- erreur.

Chaque composant doit avoir ses états :

- normal ;
- hover si pertinent ;
- focus ;
- pressé ;
- désactivé ;
- chargement ;
- erreur.

Le design system évite que chaque écran devienne une invention différente.

## 23. Bottom sheets et panneaux contextuels

Sur téléphone, une bottom sheet peut être excellente pour quelques actions contextuelles rapides.

Exemple :
**Transformer ce message en…**
- information logistique ;
- tâche ;
- document ;
- autre.

Ne pas empiler plusieurs bottom sheets et toujours offrir une fermeture évidente.

Sur ordinateur, la même fonction peut apparaître dans un panneau latéral.

## 24. Scrolling : doctrine Boralog

Le scroll n'est pas un défaut.

Utiliser le scroll vertical lorsque le contenu forme naturellement une continuité :

- messages ;
- historique ;
- liste de dates ;
- détails d'une fiche.

Préférer navigation/onglets/sections lorsque l'utilisateur change réellement de tâche.

Éviter :

- pages infinies sans repères ;
- dix accordéons imbriqués ;
- scroll horizontal ;
- plusieurs zones de scroll concurrentes sur mobile ;
- header géant qui consomme l'écran.

## 25. Actions destructrices et erreurs

Pour supprimer, annuler ou modifier une information importante :

- expliquer ce qui va arriver ;
- permettre Annuler quand possible ;
- confirmer les actions réellement irréversibles ;
- ne pas demander confirmation pour chaque micro-action ;
- ne jamais afficher seulement « Une erreur est survenue » si on peut dire quoi faire.

## 26. Version mobile : priorité aux conditions réelles

Tester avec :

- une main ;
- écran en extérieur ;
- connexion médiocre ;
- téléphone de milieu de gamme ;
- gros texte / zoom ;
- interruption puis reprise ;
- utilisateur pressé entre deux déplacements.

Une interface parfaite sur une maquette desktop n'est pas suffisante.

## 27. Version ordinateur : priorité à l'efficacité

Prévoir pour les utilisateurs intensifs :

- raccourcis clavier facultatifs ;
- recherche immédiate ;
- multi-panneaux raisonnés ;
- copier/coller ;
- sélection efficace ;
- actions groupées seulement quand elles sont sûres ;
- densité d'information supérieure au mobile.

Le novice doit pouvoir tout faire sans connaître les raccourcis.

## 28. Mesure de qualité UX

Avant de déclarer un écran réussi, tester des scénarios concrets.

Exemples :

- retrouver l'heure d'arrivée de Pierre pour Brest ;
- voir ce qui manque pour une date ;
- envoyer un message à l'équipe logistique ;
- transformer un message en information officielle ;
- savoir qui a changé un horaire ;
- retrouver une facture ;
- comprendre ce qui nécessite mon intervention aujourd'hui.

Mesurer :

- réussite/échec ;
- temps ;
- nombre d'actions ;
- erreurs ;
- hésitations ;
- besoin de demander de l'aide.

## 29. Règle « pas de poids inutile »

Avant d'ajouter une dépendance, média ou fonction :

1. apporte-t-elle une valeur fréquente ?
2. peut-on faire plus simple ?
3. augmente-t-elle le temps de chargement ?
4. ajoute-t-elle une maintenance durable ?
5. crée-t-elle une nouvelle source de vérité ?
6. peut-on la différer ?

Boralog doit rester petit techniquement même s'il devient riche fonctionnellement.

## 30. Références de conception à maintenir

Sources de référence pour les décisions UX et techniques :

- W3C WCAG 2.2 — accessibilité ;
- web.dev — responsive, performance, PWA et offline ;
- Nielsen Norman Group — heuristiques d'utilisabilité, reconnaissance plutôt que rappel, divulgation progressive ;
- OWASP — autorisations, moindre privilège et sécurité ;
- documentation PostgreSQL — stockage structuré et indexation.

Les recommandations externes guident le produit ; les tests avec les vrais utilisateurs de Boralog tranchent les choix d'usage.

## 31. Principe final

**La sophistication doit être dans le système, pas dans l'effort demandé à l'utilisateur.**

Un utilisateur ne doit pas sentir la complexité des permissions, relations, index, règles métier ou synchronisations.

Il doit simplement avoir l'impression :

**« Je sais où je suis. Je vois ce qui compte. Je peux agir tout de suite. »**


## 32. Inscription libre, accès administré

Un utilisateur peut créer seul son compte Boralog. L'inscription crée une identité Boralog, **pas un droit automatique sur les données internes d'une structure**.

Modèle :

**Compte → appartenance à une structure → appartenance à des projets → rôles → permissions**

Lorsqu'une personne rejoint une structure ou un projet :

- un socle d'informations peut être visible par défaut à tous les membres concernés ;
- les informations sensibles restent fermées par défaut ;
- les administrateurs autorisés attribuent les accès supplémentaires ;
- un administrateur ne peut déléguer que les pouvoirs que son niveau d'administration lui permet de déléguer ;
- le propriétaire/responsable principal conserve les pouvoirs critiques.

La messagerie et la consultation sont deux sujets différents : un membre peut être autorisé à contacter les autres membres de son espace professionnel sans pour autant pouvoir consulter leurs données administratives sensibles.

Catégories d'accès envisagées :

- commun aux membres du projet ;
- équipe/rôle concerné ;
- personnes choisies ;
- administrateurs ;
- propriétaire/responsable uniquement.

Ces règles doivent être appliquées dans la base et côté serveur, pas seulement par l'affichage de l'interface.

## 33. Rubriques personnalisables par les administrateurs

Boralog doit avoir un **socle métier standard** pour que le produit soit immédiatement utilisable, sans devenir un système entièrement vide à configurer.

Mais les structures ont des pratiques différentes. Un administrateur autorisé doit donc pouvoir créer des **rubriques types** supplémentaires sans développement informatique.

Exemples :

- Catering ;
- Costumes ;
- Presse ;
- Accueil scolaire ;
- Backline ;
- Invités ;
- Merchandising ;
- besoins particuliers propres à une compagnie.

Une rubrique personnalisée peut définir :

- nom ;
- description courte ;
- icône parmi une bibliothèque contrôlée ;
- type de projet/date auquel elle s'applique ;
- champs nécessaires ;
- ordre des champs ;
- champs obligatoires ou facultatifs ;
- droits de lecture ;
- droits de modification ;
- responsable par défaut ;
- visibilité par défaut ;
- éventuellement modèle réutilisable.

Types de champs autorisés au départ :

- texte court ;
- texte long ;
- nombre ;
- montant ;
- date ;
- heure ;
- oui/non ;
- choix unique ;
- choix multiple ;
- personne ;
- lien ;
- référence à un objet Boralog existant.

Ne pas permettre aux administrateurs de créer arbitrairement du code ou des composants. Ils configurent des briques sûres fournies par Boralog.

Principe essentiel :

**personnalisable sans devenir chaotique.**

Les rubriques personnalisées doivent utiliser exactement le même design system que les rubriques natives. L'utilisateur ne doit pas avoir l'impression d'entrer dans un autre logiciel.

## 34. Modèles de structure

Une structure pourra éventuellement enregistrer un ensemble de rubriques et réglages comme modèle.

Exemple :

**Modèle “Tournée danse”**
- Transport ;
- Hôtel ;
- Catering ;
- Technique ;
- Costumes ;
- Feuille de route.

Lors de la création d'une nouvelle date, ce modèle peut préparer automatiquement les rubriques utiles.

Les modèles doivent éviter la ressaisie, pas créer des centaines de champs inutiles.

## 35. Administration des rubriques : interface

L'écran de configuration doit rester beaucoup plus simple qu'un constructeur de base de données.

Parcours envisagé :

**Administration → Rubriques → Nouvelle rubrique**

Puis :

1. nommer ;
2. choisir les quelques champs nécessaires ;
3. choisir qui voit ;
4. choisir qui peut modifier ;
5. choisir où la rubrique apparaît ;
6. prévisualiser ;
7. publier.

La prévisualisation téléphone et ordinateur doit être disponible avant publication.

## 36. Doctrine de personnalisation

Boralog suit trois niveaux :

**Niveau 1 — Standard Boralog**
Les fonctions communes au spectacle vivant, conçues et maintenues par le produit.

**Niveau 2 — Configuration**
Une structure active/désactive certains modules, définit ses rôles et ses modèles.

**Niveau 3 — Rubriques personnalisées**
La structure ajoute ses besoins spécifiques à partir de briques contrôlées.

Ne pas aller vers un “no-code builder” illimité tant que le besoin n'est pas démontré. Trop de liberté peut détruire la cohérence, la recherche et la simplicité qui constituent précisément la valeur de Boralog.


## 22. Doctrine temporelle et organisation du travail

### 22.1 Ne pas transformer Boralog en gestionnaire de tâches générique

Une tâche n'est créée que lorsqu'un travail doit réellement être accompli. Une information, un changement ou une réponse attendue ne devient pas automatiquement une tâche.

**Aujourd'hui** est une vue d'attention : elle fait remonter ce qui mérite l'intervention ou la vigilance de la personne à partir des objets métier et de leur contexte.

### 22.2 Quatre notions à ne pas confondre

- **Événement / date** : fait planifié dans le temps, lié au projet.
- **Tâche** : action à accomplir, éventuellement liée à un événement.
- **Attention** : signal contextuel destiné à une personne ; il peut être dérivé d'une tâche ou d'une autre situation métier.
- **Échéance** : limite temporelle d'une tâche. La date de l'événement et l'échéance peuvent être différentes.

Exemple : une représentation a lieu le 18 octobre ; « réserver l'hôtel » peut avoir une échéance au 5 octobre.

### 22.3 Calendrier

Le calendrier est une **vue**, pas un stockage métier. Il projette chronologiquement les objets qui possèdent une dimension temporelle et conserve leur nature visible.

Il pourra réunir :
- représentations et autres dates de spectacle ;
- répétitions et rendez-vous ;
- échéances de tâches ;
- autres événements professionnels pertinents.

Sur téléphone, préférer une chronologie verticale claire. Une grille mensuelle ne doit être introduite que si elle apporte une valeur démontrée et reste lisible. Aucun objet ne doit être dupliqué pour apparaître dans le calendrier.


## 23. Entrée, contexte et fraîcheur de l'information

Toute information opérationnelle doit conserver son contexte visible : structure si nécessaire, projet/spectacle, date éventuelle, domaine et personnes concernées. Une vue dérivée ne doit pas recréer une seconde vérité simplement pour son propre affichage.

Lorsqu'une information est nouvelle ou modifiée, l'interface peut indiquer sobrement sa fraîcheur et sa dernière mise à jour. Aujourd'hui peut reprendre cette information lorsqu'elle est pertinente pour la personne. Cette reprise n'implique ni tâche automatique ni notification réelle.

### Préparation au partage externe

Le modèle doit accepter à terme un contenu reçu depuis le mécanisme de partage du téléphone (texte, lien ou fichier) avant son classement. Le parcours UX cible est : réception → choix ou suggestion de contexte → confirmation humaine → enregistrement.

Une suggestion de classement n'est jamais une donnée certaine par elle-même. Toute automatisation future doit conserver la provenance, distinguer suggestion et confirmation, exprimer un niveau de confiance lorsque pertinent et demander une validation humaine lorsque le contexte n'est pas suffisamment certain.

Le prototype actuel ne met en œuvre ni Web Share Target, ni application Android, ni Share Extension iOS, ni intégration WhatsApp/SMS.


## 24. Feedback des mutations et confidentialité avant enregistrement

### 24.1 États d'interaction

Toute mutation ou opération qui demande réellement du temps doit exposer un état perceptible et fidèle :

**prêt → pending → succès ou erreur.**

Pendant le pending, le contrôle peut être désactivé lorsque cela évite raisonnablement un double envoi. Un chargement de contenu peut utiliser un skeleton ou un état loading adapté. Le succès reste sobre mais explicite. L'erreur explique ce qui s'est passé, permet de réessayer lorsque pertinent et conserve la saisie dès que cela est raisonnablement possible.

Ne jamais simuler une attente pour donner l'impression que le système travaille. Une navigation instantanée n'a pas besoin de spinner. **Aucune action importante ne doit être silencieuse, mais aucun feedback ne doit être fictif.**

### 24.2 Visibilité d'une information

La visibilité est une propriété métier de l'information, pas un simple choix d'affichage. Le futur formulaire de création doit rendre compréhensibles avant validation :

- **contenu** ;
- **contexte** ;
- **domaine** ;
- **visibilité**.

Une information transformée en véritable tâche peut en plus recevoir un responsable et une échéance. Ces champs ne doivent pas transformer une simple information en tâche par défaut.

La liste exacte des modes de visibilité reste à concevoir. L'UX doit néanmoins pouvoir exprimer clairement des audiences comme une équipe ou un rôle, des personnes choisies, l'administration ou un accès restreint. Appartenir à la même structure ou au même projet ne confère pas implicitement l'accès à toute information.

Pour une information sensible, appliquer **deny-by-default** : l'absence d'autorisation explicite signifie absence d'accès. Le serveur et la base doivent filtrer et refuser les lectures et mutations non autorisées ; masquer un composant côté client n'est pas une mesure de confidentialité.

Le futur parcours de partage depuis une application extérieure réutilise le même contrat : contenu reçu → contexte → domaine → visibilité lorsque nécessaire → confirmation → enregistrement. La visibilité doit être confirmée avant qu'un contenu confidentiel devienne une information Boralog.


## 25. Référence unique, représentations multiples

Les vues Boralog ne doivent pas posséder leurs propres copies des objets métier. Une donnée de référence est identifiée une fois ; les relations de contexte déterminent ses représentations.

La hiérarchie métier **structure → projet → date → informations/tâches/documents/conversations pertinents** n'impose pas de navigation séquentielle. Aujourd'hui, Recherche, Toutes les tâches, Calendrier et Messages sont des projections transversales permettant un accès direct.

Sur une page Projet ou Date, appliquer la divulgation progressive : montrer un résumé utile (par exemple nombre de tâches en cours et bientôt), puis un lien vers une vue filtrée explicitement contextualisée. Ne pas embarquer le gestionnaire complet de tâches dans chaque page.

Une vue filtrée annonce son contexte dans son titre et fournit un retour clair vers le projet ou la date d'origine. Le filtrage s'appuie sur les identifiants/relations des objets, jamais sur une seconde collection recopiée pour l'écran.


## 26. Navigation globale persistante et contexte local

Une page interne ne doit pas devenir une impasse de navigation. La profondeur métier conserve deux niveaux complémentaires :

- **navigation globale persistante** vers Aujourd'hui, Messages, Projets, Recherche et Moi ;
- **navigation contextuelle** indiquant le projet, la date ou le parent métier courant et permettant d'y revenir.

La navigation contextuelle ne remplace jamais la navigation globale. Aujourd'hui est l'accueil opérationnel ; aucun second bouton « Accueil » n'est nécessaire. Le menu hamburger reste secondaire et ne doit pas absorber les cinq destinations principales.

Sur téléphone, les cinq destinations restent réparties en cinq zones tactiles distinctes, sans défilement horizontal, et respectent la safe area exposée par le navigateur. Sur ordinateur, la même navigation globale reste stable à gauche. L'état actif est annoncé sémantiquement et visuellement ; le contexte précis reste porté par le contenu de la page.


## 27. Aujourd'hui : reprise opérationnelle personnelle

**Aujourd'hui** est le point d'entrée opérationnel personnel. Il rassemble, dans cet ordre de priorité :

1. ce qui exige réellement une action ou une attention maintenant ;
2. les changements pertinents depuis la dernière consultation ;
3. les prochaines dates utiles.

Aujourd'hui n'est ni un journal exhaustif, ni un centre de notifications générique, ni une copie des tâches, messages ou informations sources. **Information ≠ attention ≠ tâche.** Une information nouvelle ou modifiée reste l'information de référence de son projet et de sa date ; Aujourd'hui n'en affiche qu'une représentation contextualisée. Une tâche urgente peut y être représentée sans être recréée.

La section « Depuis votre dernière visite » est DEMO tant que l'authentification et un curseur de dernière consultation n'existent pas. Le système réel devra la calculer à partir de l'identité authentifiée, des permissions, du dernier point de consultation et des informations créées ou modifiées depuis ce point.

Un agrégateur Aujourd'hui ne peut jamais élargir les droits de lecture : il ne présente que des objets que l'utilisateur connecté est autorisé à lire selon les permissions de leur source. L'agrégation est une représentation, jamais un contournement des règles de confidentialité.
