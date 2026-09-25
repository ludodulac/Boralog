# Boralog — Vision produit vivante

> Statut : document de travail évolutif.
>
> Ce fichier conserve les meilleures idées, décisions, hypothèses et principes du projet. Il n'est pas figé : toute nouvelle connaissance du métier peut conduire à le modifier.

## 1. Le problème que Boralog veut résoudre

Dans une petite structure du spectacle vivant, beaucoup d'informations passent par une ou quelques personnes centrales.

Les artistes, techniciens, lieux, programmateurs, responsables de production, administration et logistique communiquent par téléphone, WhatsApp, email et oralement. Une information peut donc être connue par une personne sans devenir réellement connue de l'organisation.

Le problème n'est pas seulement la quantité de travail. C'est aussi :

- l'information dispersée ;
- l'information enfermée dans les conversations individuelles ;
- les personnes qui ne savent pas qu'une information les concerne ;
- la ressaisie ;
- les changements non propagés ;
- la difficulté à déléguer sans continuer à tout surveiller mentalement ;
- les documents et versions difficiles à retrouver ;
- les mêmes données recopiées dans plusieurs outils ;
- la dépendance excessive envers la personne qui « sait tout ».

Boralog doit diminuer cette dépendance.

## 2. La promesse fondamentale

**Une information professionnelle importante doit pouvoir entrer une seule fois dans Boralog, être retrouvée facilement et devenir accessible aux bonnes personnes et aux bons usages.**

Boralog ne cherche pas à remplacer les relations humaines.

Il cherche à faire en sorte que :

**« Marion le sait » ne soit plus équivalent à « seule Marion le sait ».**

## 3. Deux espaces humains différents

### 3.1 Hors Boralog : le privé

Les utilisateurs restent libres d'utiliser WhatsApp, téléphone, SMS, email personnel ou une conversation physique pour ce qui est personnel, confidentiel ou informel.

Boralog ne doit pas aspirer les conversations privées.

### 3.2 Dans Boralog : l'espace professionnel

Quand une personne écrit dans Boralog, elle sait qu'elle se trouve dans le cadre professionnel du projet.

Elle peut néanmoins écrire :

- à une personne ;
- à plusieurs personnes ;
- à une équipe fonctionnelle ;
- à toute l'équipe d'un spectacle ;
- à toute une structure.

Les permissions et destinataires doivent rester explicites.

Un message adressé à Marion n'a pas besoin de devenir une conversation collective. En revanche, l'environnement professionnel permet de conserver et retrouver l'information selon les règles d'accès du projet.

## 4. Le cœur : Messages → Information → Organisation

Boralog doit distinguer trois niveaux.

### Messages

Ce que les personnes se disent.

Exemple :

> Pour Brest, j'arrive finalement mardi à 18 h.

### Information structurée

Ce que l'organisation considère comme la donnée opérationnelle de référence.

Exemple :

- personne : artiste X ;
- événement : Brest ;
- arrivée : mardi, 18 h.

### Organisation

Les usages qui reposent sur cette information.

Exemple :

- transport ;
- hébergement ;
- accueil ;
- feuille de route ;
- planning.

La V1 n'a pas besoin de comprendre automatiquement le langage humain.

Une personne autorisée peut lire le message puis utiliser une action simple comme **« Ajouter à la logistique »** ou **« Transformer en information »**.

Cette simplicité est préférable à une pseudo-intelligence fragile.

## 5. Source unique de vérité

Une représentation ne doit pas exister séparément dans cinq modules.

Il existe un seul événement :

**Spectacle → Date / lieu**

Et autour de cet événement se rattachent :

- conversations ;
- personnes et distribution ;
- disponibilités ;
- transports ;
- hébergements ;
- repas ;
- horaires ;
- contacts du lieu ;
- technique ;
- documents ;
- contrat ;
- budget ;
- devis ;
- facture ;
- paiement ;
- tâches ;
- feuille de route.

Si une donnée de référence change, les parties concernées doivent être mises à jour ou signalées.

## 6. Multi-structures et multi-projets

Boralog doit être conçu dès le départ pour une personne qui peut travailler :

- pour plusieurs compagnies ;
- sur plusieurs spectacles ;
- avec des responsabilités différentes selon le projet.

Exemple conceptuel :

- Compagnie A : logistique → Jeanne ;
- Compagnie B : logistique → Marion ;
- Compagnie C : logistique → autre personne.

Le logiciel ne doit donc pas coder le fonctionnement autour d'une personne précise, mais autour de **rôles et responsabilités configurables**.

## 7. Rôles, permissions et confidentialité

Ne pas se limiter à « administrateur » et « utilisateur ».

Rôles possibles :

- responsable de structure ;
- production ;
- administration ;
- diffusion ;
- logistique ;
- technique ;
- communication ;
- artiste ;
- technicien ;
- paie ;
- comptabilité.

Une personne peut cumuler plusieurs rôles.

Les permissions doivent pouvoir s'appliquer à :

- structure ;
- compagnie ;
- spectacle ;
- événement/date ;
- conversation ;
- document ;
- catégorie d'information.

Exemples :

- un artiste voit son voyage sans voir le salaire d'un collègue ;
- la logistique voit les informations nécessaires à la tournée ;
- le comptable voit les pièces financières utiles ;
- certaines conversations restent limitées à leurs participants.

## 8. Les cinq grands espaces envisagés

### 8.1 Messages

Messagerie professionnelle reliée aux projets.

Fonctions envisagées :

- conversation directe ;
- conversation de groupe ;
- conversation par spectacle ;
- conversation par date ;
- conversation par fonction ;
- pièces jointes ;
- mentions ;
- recherche plein texte ;
- filtres par personne, spectacle, compagnie, date et mot-clé ;
- lien entre un message et une donnée structurée.

### 8.2 Projets

Hiérarchie centrale :

**Structure / compagnie → spectacle → événements / dates**

Chaque date devient un dossier vivant.

### 8.3 Tournées

Pour chaque date :

- distribution ;
- personnes présentes ;
- disponibilités ;
- transport aller/retour ;
- véhicules ;
- hébergement ;
- repas ;
- horaires ;
- montage ;
- balance/répétition si applicable ;
- représentation ;
- démontage ;
- contact du lieu ;
- régie ;
- feuille de route ;
- informations manquantes.

### 8.4 Administration

À terme :

- contrats de cession ;
- conventions ;
- contrats artistes/techniciens ;
- devis ;
- factures ;
- règlements ;
- relances ;
- budgets prévisionnels ;
- budgets réels ;
- dépenses et recettes ;
- notes de frais ;
- éléments de paie ;
- subventions ;
- échéances ;
- documents administratifs ;
- droits et déclarations lorsque pertinents.

Boralog ne doit pas nécessairement remplacer dès la V1 les logiciels spécialisés de paie ou comptabilité. Il peut d'abord préparer, centraliser et transmettre les éléments.

### 8.5 À faire

Chaque personne doit voir principalement ce qui nécessite son intervention.

États conceptuels :

- à moi ;
- délégué / chez quelqu'un d'autre ;
- en attente ;
- bloqué ;
- terminé ;
- aucune action nécessaire.

Principe important : **la délégation par exception**.

Quand une responsabilité a été correctement confiée, le responsable principal ne devrait pas avoir à la surveiller en permanence. Elle remonte lorsqu'une échéance est dépassée, qu'un blocage est déclaré ou qu'une décision est requise.

## 9. Diffusion et développement

Module envisagé :

- contacts de lieux et programmateurs ;
- prospects ;
- historique des échanges ;
- spectacles proposés ;
- invitations ;
- relances ;
- propositions de dates ;
- négociations ;
- statut d'une opportunité ;
- documents de diffusion.

À articuler avec Messages et Projets pour éviter une base CRM isolée.

## 10. Communication et documents

À terme :

- photos ;
- biographies ;
- dossiers artistiques ;
- dossiers techniques ;
- fiches techniques ;
- RIB ;
- conventions ;
- contrats ;
- versions de documents ;
- documents publics/privés ;
- accès par rôle ;
- rattachement aux spectacles et dates.

Objectif : retrouver la bonne version sans demander « qui a le document ? ».

## 11. Recherche comme fonction essentielle

Avant toute IA sophistiquée, Boralog doit avoir une excellente recherche classique.

On doit pouvoir rechercher :

- une personne ;
- une compagnie ;
- un spectacle ;
- une ville ;
- une date ;
- un mot comme « train », « hôtel », « arrivée » ;
- un document ;
- un message.

La personne chargée de la logistique doit pouvoir ouvrir un projet ou une date et retrouver les communications professionnelles pertinentes sans dépendre de la mémoire d'une autre personne.

## 12. Propagation des changements

À terme, des règles déterministes peuvent signaler les conséquences d'un changement.

Exemples :

**Horaire d'arrivée modifié**
- transport ;
- hébergement ;
- accueil ;
- feuille de route.

**Distribution modifiée**
- production ;
- logistique ;
- contrats/paie ;
- feuille de route ;
- éventuellement technique.

**Date ou lieu modifié**
- planning ;
- équipe ;
- logistique ;
- documents ;
- contrat ;
- facturation.

Ces règles doivent être explicables et configurables. Elles ne nécessitent pas d'IA.

## 13. Sans IA par défaut

Le cœur de Boralog doit fonctionner sans appel à un modèle d'IA.

Doivent être déterministes :

- authentification ;
- permissions ;
- messagerie ;
- recherche classique ;
- projets ;
- événements ;
- données de tournée ;
- tâches ;
- délégation ;
- notifications ;
- documents ;
- budgets ;
- facturation ;
- règles métier ;
- alertes.

Une IA pourra éventuellement, plus tard :

- proposer d'extraire une information d'un message ;
- résumer un fil ;
- proposer une réponse ;
- suggérer un classement.

Mais l'utilisateur doit pouvoir confirmer les données importantes et Boralog doit rester opérationnel sans IA.

## 14. Expérience selon le rôle

La même date est une seule réalité, présentée différemment.

### Artiste

Voit par exemple :

- lieu ;
- horaire ;
- son transport ;
- son hébergement ;
- ses informations utiles ;
- feuille de route ;
- messages auxquels il a accès.

### Logistique

Voit par exemple :

- toutes les personnes attendues ;
- transports complets/manquants ;
- hébergements ;
- repas ;
- changements récents ;
- informations manquantes ;
- feuille de route.

### Production / responsable

Voit par exemple :

- état global ;
- équipe ;
- administration ;
- logistique ;
- budget ;
- contrat ;
- facturation ;
- décisions et blocages.

## 15. Principe UX : très peu de friction

Si transformer une information en donnée officielle demande quinze champs, les utilisateurs contourneront le système.

Les actions fréquentes doivent demander très peu d'étapes.

Exemples :

- + INFO ;
- transformer en information ;
- ajouter à la logistique ;
- rattacher à une date ;
- assigner ;
- marquer comme information manquante.

Le système doit accepter que toutes les données ne soient pas connues immédiatement.

## 16. Notifications

Ne pas reproduire le bruit de WhatsApp.

Une notification doit avoir une raison :

- quelqu'un m'adresse un message ;
- une information dont je suis responsable a changé ;
- une action m'est attribuée ;
- une échéance approche ;
- une information indispensable manque ;
- une tâche déléguée est bloquée.

Le responsable ne doit pas recevoir toutes les notifications de tout le monde.

## 17. Ce que Boralog ne doit pas devenir

Éviter :

- un clone générique de Slack ;
- un clone d'Orfeo/Bob Booking/STAR sans différenciation ;
- une gigantesque to-do list ;
- un logiciel où chaque information doit être saisie plusieurs fois ;
- un système obligeant à partager les conversations personnelles ;
- un outil où l'IA décide silencieusement des données métier ;
- une usine à gaz avant d'avoir validé les usages réels.

## 18. Différenciation à explorer

Hypothèse de différenciation :

**Boralog est d'abord la mémoire opérationnelle partagée du spectacle vivant.**

La gestion administrative vient se brancher sur cette mémoire commune.

Axes à tester :

1. communication directement reliée aux objets métier ;
2. transformation simple d'un message en information officielle ;
3. recherche transversale ;
4. visibilité adaptée au rôle ;
5. propagation des changements ;
6. délégation par exception ;
7. multi-compagnies naturel ;
8. réduction de la dépendance à la personne qui « sait tout ».

## 19. Ordre de construction envisagé

### Socle

- comptes ;
- structures ;
- membres ;
- rôles et permissions ;
- spectacles ;
- événements/dates.

### Collaboration

- conversations ;
- messages ;
- pièces jointes ;
- recherche ;
- rattachement messages ↔ projets/dates/personnes.

### Information opérationnelle

- distribution ;
- horaires ;
- transport ;
- hébergement ;
- contacts ;
- informations manquantes ;
- historique des changements.

### Organisation

- tâches ;
- responsabilités ;
- délégation ;
- échéances ;
- notifications ;
- vue « ce qui nécessite mon intervention ».

### Métier avancé

- feuilles de route ;
- documents ;
- diffusion/CRM ;
- contrats ;
- devis/factures/paiements ;
- budgets ;
- notes de frais ;
- préparation paie ;
- subventions et autres besoins vérifiés.

Cet ordre reste une hypothèse à tester avec les utilisateurs.

## 20. Questions à valider sur le terrain

Avant de figer la V1 :

- Quelles informations sont aujourd'hui le plus souvent perdues ou mal transmises ?
- Qui saisit réellement les informations ?
- Quels canaux sont utilisés selon les situations ?
- Quelles données doivent absolument rester confidentielles ?
- Quelles informations une personne de logistique recherche le plus souvent ?
- Combien de compagnies une administratrice gère-t-elle simultanément ?
- Quels outils actuels sont incontournables ?
- Quelles doubles saisies font perdre le plus de temps ?
- Qu'est-ce qu'un artiste accepterait réellement de renseigner lui-même ?
- À quel moment une date devient-elle suffisamment confirmée pour déclencher le workflow ?
- Quels documents doivent être générés ?
- Quelles intégrations sont indispensables et lesquelles peuvent attendre ?

## 21. Règle de conception

Pour toute nouvelle fonction, poser quatre questions :

1. Quel problème métier réel résout-elle ?
2. Qui en a besoin ?
3. Quelle donnée de référence utilise-t-elle ?
4. Peut-on éviter une saisie supplémentaire ?

Si la fonction ne réduit ni la dispersion de l'information, ni la ressaisie, ni la charge de coordination, elle n'est probablement pas prioritaire.


## 22. Organisation du travail : objets distincts

Boralog ne doit pas devenir une gigantesque liste de tâches. Quatre notions restent distinctes :

- **Événement / date** : représentation, répétition, rendez-vous professionnel ou autre événement planifié. Il possède une date/heure et appartient au contexte réel du projet.
- **Tâche** : travail qui doit réellement être accompli. Elle peut être liée à un projet et éventuellement à un événement, avoir un responsable, une échéance, un état et une priorité raisonnable.
- **Attention** : signal présenté à une personne parce qu'une situation mérite son attention. Une attention peut venir d'une tâche, mais aussi d'une information manquante, d'un changement, d'une réponse attendue ou d'un problème sur une date. Elle n'est donc pas nécessairement une tâche créée manuellement.
- **Échéance** : date avant laquelle une action doit être accomplie. Elle ne doit jamais être confondue avec la date de l'événement concerné.

Principe : **les données vivent dans leur contexte → Boralog détermine ce qui demande de l'attention → Aujourd'hui le fait remonter.** L'utilisateur ne doit pas transformer chaque information en tâche pour que Boralog reste utile.

Une future vue calendrier réunira événements, répétitions/rendez-vous et échéances utiles sans les fusionner. Le calendrier est une représentation temporelle de ces objets, jamais leur stockage métier principal.


## 23. Information contextualisée et entrée depuis l'extérieur

Une information Boralog n'est pas un texte isolé : elle appartient à un **contexte**. Selon le cas, ce contexte comprend notamment la structure, le projet/spectacle, la date, le domaine et les personnes concernées. Une information de référence peut ensuite être représentée dans plusieurs vues sans être dupliquée comme plusieurs vérités incompatibles.

Une information nouvelle ou modifiée qui concerne une personne peut être portée à sa connaissance dans **Aujourd'hui** avec son projet, sa date éventuelle, son domaine et sa fraîcheur. Cela ne transforme pas automatiquement cette information en tâche. **Information ≠ attention ≠ tâche** : l'information décrit la réalité ; l'attention signale qu'elle mérite explicitement la vigilance de la personne ; la tâche existe lorsqu'un travail doit réellement être accompli.

### Futur point d'entrée par partage mobile

Boralog devra pouvoir recevoir du texte, des liens ou des fichiers partagés depuis des applications extérieures, par exemple un SMS ou WhatsApp : **contenu reçu → choix/confirmation du projet → date éventuelle → domaine → confirmation → information Boralog**.

Cette capacité n'est pas encore implémentée. Boralog ne doit pas aspirer silencieusement les conversations extérieures ni transformer une suggestion de classement en vérité. Une classification automatique future peut proposer un contexte avec un niveau de confiance approprié ; lorsque le contexte est incertain, la confirmation humaine reste la référence.


## 24. Confiance dans les actions et confidentialité de l'information

### 24.1 Aucune action importante ne doit être silencieuse

Lorsqu'une action déclenche réellement une mutation ou un traitement perceptible, Boralog doit rendre son état compréhensible : **pending → succès ou erreur**. Selon le contexte, cela peut prendre la forme d'un libellé temporaire (« Enregistrement… »), d'une désactivation raisonnable empêchant le double envoi, d'un chargement de contenu, puis d'une confirmation sobre. Une erreur doit être explicite, proposer une nouvelle tentative lorsque c'est pertinent et conserver la saisie lorsque cela est raisonnablement possible.

Ce principe ne justifie pas d'ajouter artificiellement un spinner à une navigation instantanée : le feedback doit correspondre à une attente ou une mutation réelle.

### 24.2 Confidentialité au niveau de chaque information

Le stockage d'une information dans Boralog ne lui donne jamais une visibilité implicite auprès de tous les membres d'une même structure ou d'un même projet. Chaque information doit pouvoir porter une politique de visibilité explicite, adaptée au besoin réel. Le modèle cible doit pouvoir exprimer des accès tels que membres concernés, équipe/rôle, personnes choisies, administration ou accès restreint, sans figer cette liste comme schéma définitif.

Lorsque la confidentialité est pertinente, l'utilisateur doit comprendre **avant l'enregistrement** qui pourra voir l'information, par exemple « Visible par : équipe Logistique » ou « Visible par : Camille et Léa ».

Les informations sensibles suivent un principe **deny-by-default** : aucun accès ne doit être déduit de la seule appartenance à la même structure. La confidentialité doit être garantie côté serveur et base de données par les permissions appropriées ; masquer une donnée dans l'interface n'est jamais une protection suffisante.

Le futur formulaire de création d'information prévoit au minimum **contenu, contexte, domaine, visibilité**. Responsable et échéance ne s'ajoutent que si le contenu devient réellement une tâche. Le futur flux de partage externe doit lui aussi faire confirmer la visibilité lorsque nécessaire avant l'enregistrement.


## 25. Place de référence et vues contextuelles

Chaque objet métier possède une **place de référence** et n'existe qu'une fois. Une tâche, une information, une date, un document ou une conversation peut être relié à une structure, un projet/spectacle et, lorsque pertinent, une date. Ces relations déterminent les endroits où l'objet peut être présenté ; elles ne créent pas de copies.

La hiérarchie **structure → projet → date → objets pertinents** décrit le contexte métier, pas un parcours de navigation obligatoire. L'utilisateur peut atteindre les mêmes objets depuis les vues transversales : Aujourd'hui, Recherche, Toutes les tâches, Calendrier ou Messages.

Principe : **chaque chose a une place de référence ; chaque écran montre ce qui est utile dans son contexte ; la Recherche permet de retrouver le reste ; Aujourd'hui fait remonter ce qui mérite l'attention.**

Ainsi, une tâche « Réserver l'hôtel » rattachée à un projet, une date, un responsable et une échéance reste un objet unique même si elle est représentée dans Aujourd'hui, Toutes les tâches, le projet, la date et le Calendrier. Les pages Projet et Date privilégient un résumé compact et un approfondissement volontaire plutôt que la répétition de gros modules.
