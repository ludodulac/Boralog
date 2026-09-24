# Boralog — Architecture d'interface V0

> Ce document transforme la vision métier et la doctrine UX en squelette concret avant développement. Il sert de contrat de navigation : on ne crée pas des écrans isolés au hasard.

## 1. Principe de structure

Boralog possède un **shell d'application unique**. Les mêmes objets existent sur téléphone et ordinateur ; seule leur disposition change.

Navigation primaire proposée :

1. **Aujourd'hui** — ce qui demande mon attention ;
2. **Messages** — communication professionnelle ;
3. **Projets** — spectacles et dates ;
4. **Recherche** — retrouver n'importe quelle information ;
5. **Moi** — profil, organisation active, réglages.

Pour les utilisateurs autorisés, **Administration** est accessible depuis l'organisation active et non comme destination quotidienne imposée à tout le monde.

## 2. Inscription et arrivée

### Écran Bienvenue

Actions :
- Se connecter
- Créer mon compte

L'inscription crée uniquement une identité Boralog.

### Après inscription

Trois situations :

**A. Invitation déjà reçue**
L'utilisateur voit l'organisation/projet qui l'invite et accepte.

**B. L'utilisateur possède un code/lien d'invitation**
Il le rejoint.

**C. Aucun rattachement**
Il peut compléter son profil et attendre/rechercher une invitation selon les règles futures. Aucun accès interne n'est accordé automatiquement.

## 3. Aujourd'hui

L'écran ne doit jamais être un tableau de bord décoratif.

Ordre :
- contexte : organisation active ;
- salutation courte / date si utile ;
- « À faire maintenant » ;
- changements qui me concernent ;
- informations manquantes dont je suis responsable ;
- prochains événements ;
- messages nécessitant une réponse.

Si rien ne réclame l'utilisateur, afficher un état calme : « Rien ne demande votre attention ».

## 4. Messages

### Liste
- recherche ;
- conversations récentes ;
- filtre facultatif : Toutes / Directes / Projets ;
- indicateur non lu discret ;
- contexte projet/date visible.

### Conversation
En-tête :
- nom ;
- participants ;
- projet/date ;
- indication claire de visibilité.

Corps :
- messages ;
- séparateurs temporels ;
- pièces jointes/références lorsque permises.

Actions sur message :
- répondre ;
- copier ;
- transformer en information ;
- créer une tâche ;
- rattacher/changer le rattachement si autorisé.

Sur ordinateur, un panneau droit peut afficher le contexte sans quitter la conversation.

## 5. Projets

### Liste projets
Chaque carte/ligne montre seulement :
- nom ;
- structure ;
- prochaine date ;
- état utile éventuel.

Recherche et filtres légers.

### Fiche spectacle
En tête :
- spectacle ;
- structure ;
- état.

Sections :
- prochaines dates ;
- équipe ;
- conversations ;
- informations ;
- documents ;
- administration si autorisée.

### Fiche date — écran central
En tête :
- spectacle ;
- ville/lieu ;
- date ;
- état.

Résumé immédiat :
- horaires ;
- équipe ;
- voyage ;
- hébergement ;
- informations manquantes ;
- changements récents.

Puis rubriques :
- logistique ;
- technique ;
- documents ;
- tâches ;
- conversations ;
- rubriques personnalisées.

Les données sensibles ou non pertinentes ne sont pas rendues visibles par simple présence dans la fiche.

## 6. Recherche universelle

Champ unique.

À mesure de la frappe, résultats regroupés :
- personnes ;
- projets ;
- dates ;
- messages ;
- informations ;
- documents ;
- administration si autorisée.

Chaque résultat montre son contexte avant ouverture.

## 7. Moi

- identité ;
- coordonnées professionnelles ;
- organisations ;
- rôles ;
- préférences de notification ;
- sécurité/session ;
- accessibilité/affichage si nécessaire.

Changer d'organisation ne change jamais silencieusement les droits.

## 8. Administration

Visible seulement aux personnes autorisées.

Sections :
- Membres ;
- Rôles et accès ;
- Invitations ;
- Rubriques ;
- Modèles ;
- Paramètres de structure ;
- Journal d'activité ;
- modules administratifs métier selon droits.

### Membres
Pour chaque membre :
- identité ;
- projets ;
- rôles ;
- accès spécifiques ;
- état invitation/actif.

### Rubriques
- rubriques standard ;
- rubriques personnalisées ;
- créer ;
- dupliquer ;
- archiver ;
- prévisualiser.

## 9. Création d'une rubrique

Parcours guidé :
1. Nom et courte description.
2. Où apparaît-elle ?
3. Champs.
4. Qui peut lire ?
5. Qui peut modifier ?
6. Responsable par défaut éventuel.
7. Prévisualisation téléphone + ordinateur.
8. Publier.

Pas de code, pas de mise en page libre.

## 10. Responsive

### Téléphone
- une seule zone principale ;
- navigation primaire basse ;
- titre/context compact en haut ;
- panneaux secondaires sous forme de page ou bottom sheet ;
- aucun scroll horizontal requis.

### Tablette
- navigation compacte ;
- une ou deux zones selon largeur.

### Ordinateur
- navigation verticale gauche ;
- contenu central ;
- panneau contextuel droit lorsque pertinent ;
- largeur de lecture limitée pour les longs textes.

## 11. Composants fondamentaux avant pages

Construire une seule fois :
- AppShell ;
- PrimaryNav ;
- PageHeader ;
- ContextBreadcrumb ;
- Button ;
- IconButton ;
- SearchField ;
- ListItem ;
- Card ;
- StatusBadge ;
- Tabs/segmented control si nécessaire ;
- EmptyState ;
- Alert ;
- FormField ;
- Select ;
- Date/Time field ;
- PersonPicker ;
- PermissionPicker ;
- BottomSheet ;
- SidePanel ;
- Modal ;
- Toast ;
- Skeleton/loading ;
- ErrorState.

Aucune page ne recrée sa propre version d'un bouton ou d'un champ.

## 12. États obligatoires

Chaque écran de données doit être pensé pour :
- chargement ;
- vide ;
- contenu normal ;
- erreur ;
- hors connexion/réseau faible si pertinent ;
- accès refusé ;
- contenu archivé.

## 13. Premier prototype à construire

Le premier prototype ne connecte pas encore toute la base métier.

Il doit permettre de tester le squelette avec des données fictives cohérentes :
- Aujourd'hui ;
- Messages ;
- Projets ;
- une fiche spectacle ;
- une fiche date ;
- Recherche ;
- Administration ;
- création d'une rubrique.

Objectif : vérifier navigation, densité, lisibilité et responsive **avant** de figer le schéma complet.

## 14. Critères de validation du prototype

Sur téléphone et ordinateur, vérifier :
- sait-on immédiatement où l'on est ?
- les 5 destinations principales sont-elles évidentes ?
- peut-on retrouver une date rapidement ?
- peut-on lire un message et comprendre son contexte ?
- peut-on atteindre une information importante sans mémoriser son emplacement ?
- les actions fréquentes sont-elles visibles ?
- les permissions sont-elles compréhensibles ?
- la création d'une rubrique paraît-elle simple ?
- aucun écran ne semble surchargé ?
- le produit semble-t-il professionnel plutôt que générique ?

Une maquette visuellement jolie mais qui échoue à ces scénarios n'est pas validée.


## 15. Travail, attentions et calendrier

La navigation et les écrans doivent préserver quatre objets conceptuellement différents :

- un **événement/date** appartient au projet et représente quelque chose de planifié ;
- une **tâche** représente un travail à accomplir ;
- une **attention** est une remontée contextuelle dans Aujourd'hui et peut exister sans tâche ;
- une **échéance** appartient à une tâche et indique avant quand agir ; elle est indépendante de la date d'un spectacle.

La vue « Toutes les tâches » peut organiser simplement le travail par état ou horizon, tout en montrant le projet, la date liée lorsqu'elle existe, le responsable et l'échéance.

Le **calendrier** est une projection chronologique. Il peut réunir dates de spectacle, répétitions, rendez-vous, échéances de tâches et autres événements professionnels pertinents, avec une distinction visuelle explicite entre leur nature. Sur téléphone, la forme privilégiée est une chronologie lisible plutôt qu'une grille mensuelle comprimée.

Le calendrier ne devient pas une nouvelle source de vérité : les événements restent des événements et les échéances restent rattachées aux tâches.


## 16. Colonne vertébrale de l'information

Le chemin métier navigable de référence est :

**Projets → spectacle/projet → date → informations par domaine.**

Une information possède un contexte explicite pouvant comprendre : structure, projet, date, domaine et personnes concernées. Les domaines servent à retrouver naturellement l'information (par exemple Horaires, Équipe, Transport, Hébergement, Technique, Administration/Contrat) ; ils ne doivent pas devenir une forêt de modules artificiels.

La même information de référence peut être représentée sur sa page date, dans une synthèse projet, dans la recherche ou dans Aujourd'hui. Ces représentations ne créent pas de copies métier divergentes.

Les informations récentes pertinentes peuvent apparaître dans Aujourd'hui avec leur contexte et leur fraîcheur, sans créer automatiquement une tâche.

Un futur point d'entrée de partage depuis le téléphone devra pouvoir recevoir un contenu externe puis demander à l'utilisateur de confirmer projet, date et domaine avant enregistrement. Aucun partage Android/iOS n'est implémenté dans le prototype actuel.


## 17. Contrat d'interaction et confidentialité des informations

### Feedback des actions

Les composants de mutation doivent être conçus avec des états explicites : **idle, pending, success, error**. Le pending reflète un traitement réel et peut désactiver temporairement l'action pour prévenir un double envoi. Les chargements de contenu disposent d'un état loading/skeleton. Le succès est confirmé sobrement ; l'erreur reste visible, permet une nouvelle tentative lorsque pertinente et ne détruit pas inutilement la saisie.

Les transitions de navigation immédiates ne doivent pas recevoir artificiellement un spinner.

### Contrat futur de création d'une information

Le composant/formulaire de création d'information doit pouvoir recueillir et afficher avant validation :

**CONTENU → CONTEXTE → DOMAINE → VISIBILITÉ**

Puis, uniquement lorsqu'un travail réel est créé :

**RESPONSABLE → ÉCHÉANCE**

La visibilité appartient à l'information elle-même. Son modèle doit pouvoir cibler différentes audiences (par exemple membres concernés, équipe/rôle, personnes sélectionnées, administration ou accès restreint) sans considérer cette liste comme le schéma final.

L'appartenance à une structure ou à un projet n'accorde jamais implicitement la lecture de toutes ses informations. Les informations sensibles sont **deny-by-default**.

L'interface explique l'audience avant enregistrement, mais l'autorisation effective doit être appliquée côté serveur et base de données. La future architecture Supabase/RLS devra empêcher qu'un utilisateur non autorisé puisse récupérer ou modifier l'information, indépendamment de ce que l'interface affiche.

Le futur point d'entrée par partage externe utilise ce même contrat : après choix/confirmation du contexte et du domaine, la visibilité est confirmée lorsque nécessaire avant l'enregistrement. Aucun mécanisme de partage mobile ni aucune règle RLS correspondante n'est implémenté à ce stade.


## 18. Relations contextuelles et projections

Le modèle d'interface distingue **stockage de référence** et **projection UX**. Une tâche ou une information est un objet unique relié par identifiants à son projet et, si nécessaire, à sa date. Les écrans consomment ces relations au lieu de maintenir des collections métier parallèles.

Les pages Projet et Date exposent uniquement un résumé compact des tâches pertinentes et un accès à une vue contextualisée. La vue transversale Toutes les tâches reste la représentation complète du travail ; Aujourd'hui reste la vue d'attention ; Calendrier reste la projection temporelle ; Recherche et Messages restent des accès transversaux.

Convention du prototype : la vue existante /aujourdhui/a-faire accepte un contexte par paramètres projet, puis éventuellement date. Elle affiche explicitement ce contexte et son lien de retour. Cette convention est une représentation UX ; elle ne crée ni nouvelle tâche ni nouveau stockage.

Règle structurante : **une place de référence, plusieurs représentations ; jamais une copie métier par écran.**
