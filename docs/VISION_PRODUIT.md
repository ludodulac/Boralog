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
