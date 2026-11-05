# Feature Specification: Socle technique (base, client Neon, Functions, squelettes d'apps)

**Feature Branch**: `feat/003-foundation`

**Created**: 2026-10-02

**Status**: Draft

**Input**: User description: "Spec `foundation` de la roadmap (Phase 1) : base de données versionnée et testée qui reproduit Neon en local, client Dart générique pour Neon (Auth, Data API, Functions), projet de Functions, fondations Dart (Result, localisation) et squelettes des apps cliente, vendeuse et admin ; validations techniques sur un vrai projet Neon dès que l'accès est disponible."

## Contexte

Les specs 001 et 002 ont livré le design system. Toutes les specs produit suivantes ont besoin du
même socle :

- une base PostgreSQL versionnée, avec RLS testée par pgTAP ;
- un client Dart qui parle à Neon Auth, à la Data API et aux Functions ;
- un projet de Functions pour les effets externes ;
- des apps qui démarrent.

La décision 0001 confie tout le backend à Neon. L'accès au projet Neon n'est pas encore branché sur
la machine de développement. Le socle reproduit donc fidèlement Neon en local, sans conteneur :

- le schéma d'authentification `neon_auth.user` ;
- les rôles `authenticated` et `anonymous` de la Data API ;
- la fonction `auth.user_id()`.

Les mêmes migrations et tests tournent ensuite sur une branche Neon.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Une base versionnée qui se comporte comme Neon (Priority: P1)

Un développeur (ou un agent) crée une base locale en une commande, applique les migrations et lance
les tests pgTAP. La CI fait de même à chaque pull request. Une règle de sécurité oubliée fait échouer
les tests.

**Why this priority**: toutes les règles métier vivent en SQL (constitution III, V). Sans cette
boucle, aucune spec produit ne peut être livrée ni vérifiée.

**Independent Test**: sur une machine sans base, lancer la commande de création, puis les
migrations et les tests ; tout passe. Retirer une politique RLS dans une branche : un test échoue.

**Acceptance Scenarios**:

1. **Given** une machine avec PostgreSQL 17 installé, **When** le développeur lance la commande de
   création, **Then** une base locale isolée démarre sur un port dédié, sans mot de passe à saisir
   ni conteneur.
2. **Given** la base locale, **When** les migrations sont appliquées deux fois, **Then** la seconde
   application ne fait rien (chaque migration n'est appliquée qu'une fois, et dans l'ordre).
3. **Given** la base migrée, **When** les tests sont lancés, **Then** chaque fichier de test
   s'exécute dans une transaction annulée, et le résultat indique le nombre de tests passés et
   échoués.
4. **Given** une session sous le rôle `authenticated` avec l'identité d'un utilisateur, **When** une
   requête appelle `auth.user_id()`, **Then** elle obtient l'identifiant de cet utilisateur, comme
   sur la Data API de Neon.
5. **Given** une pull request, **When** la CI s'exécute, **Then** les migrations et les tests pgTAP
   tournent sur une base fraîche et bloquent la fusion en cas d'échec.

---

### User Story 2 - Un client Dart unique pour Neon (Priority: P1)

Les apps s'authentifient (OTP email, Google), obtiennent un jeton pour la Data API, le renouvellent
avant expiration, lisent et écrivent sous RLS et appellent les Functions, via un seul client
générique, sans aucune notion propre à DYM.

**Why this priority**: c'est la seule porte des apps vers le backend ; sa politique réseau
(nouvelle tentative, jeton expiré) conditionne la fiabilité terrain (constitution VII, VIII).

**Independent Test**: tests automatisés contre un serveur simulé couvrant connexion, jeton, renouvellement,
lecture sous jeton, appel de Function, erreurs réseau et 4xx.

**Acceptance Scenarios**:

1. **Given** une adresse email, **When** l'app demande un code puis le saisit, **Then** une session
   est ouverte et conservée de façon sécurisée.
2. **Given** un jeton Google obtenu sur l'appareil, **When** l'app le transmet, **Then** une session
   est ouverte.
3. **Given** une session ouverte, **When** l'app interroge la Data API ou une Function, **Then** la
   requête porte le jeton courant.
4. **Given** un jeton qui expire dans moins d'une minute, **When** une requête part, **Then** le jeton
   est renouvelé d'abord. **Given** une réponse 401, **Then** une seule nouvelle tentative a lieu
   après renouvellement.
5. **Given** une erreur réseau ou 5xx, **When** la requête est idempotente, **Then** elle est retentée
   avec un délai croissant (au plus 3 fois). **Given** une réponse 4xx (hors 401), **Then** aucune
   nouvelle tentative.
6. **Given** une erreur, **When** elle remonte à l'app, **Then** elle prend la forme d'un échec typé
   (réseau, non authentifié, interdit, introuvable, conflit, validation, serveur), jamais d'une
   exception brute.

---

### User Story 3 - Un projet de Functions prêt pour les effets externes (Priority: P2)

Un développeur ajoute une Function qui vérifie le jeton de l'utilisateur, valide son entrée, appelle
une fonction SQL et renvoie une réponse normalisée, puis la teste en local.

**Why this priority**: paiements, push, IA et stockage passent par les Functions (constitution
III) ; leur forme commune doit exister avant la première spec qui en a besoin.

**Independent Test**: lancer les tests du projet de Functions : vérification de jeton (valide,
expiré, absent), validation d'entrée, réponse d'erreur normalisée, route de santé.

**Acceptance Scenarios**:

1. **Given** une requête sans jeton ou avec un jeton invalide, **When** elle atteint une route
   protégée, **Then** la réponse est 401 avec un corps d'erreur normalisé.
2. **Given** un corps invalide, **When** il atteint une route, **Then** la réponse est 422 avec la
   liste des champs en cause.
3. **Given** la configuration de déploiement, **When** on la lit, **Then** elle déclare chaque
   Function et ses secrets sans en contenir aucune valeur.

---

### User Story 4 - Des apps qui démarrent sur le design system (Priority: P2)

Les apps cliente, vendeuse et admin démarrent, affichent un premier écran avec `dym_ui`, sont
localisées (français, anglais), choisissent leur environnement à la compilation et suivent
l'architecture MVVM retenue.

**Why this priority**: les specs produit ajoutent des écrans dans ces apps ; leur ossature doit
déjà respecter les couches et la génération de code.

**Independent Test**: lancer chaque app en web et en test : le premier écran s'affiche, en
français par défaut, sans débordement aux tailles de référence.

**Acceptance Scenarios**:

1. **Given** une compilation sans environnement précisé, **When** l'app démarre, **Then** elle
   refuse de démarrer en production sans configuration explicite et affiche l'environnement
   de développement sinon.
2. **Given** un téléphone en anglais, **When** l'app démarre, **Then** les textes sont en anglais ;
   aucun texte visible n'est écrit en dur dans le code.
3. **Given** chaque app, **When** la génération de code est lancée, **Then** elle aboutit (routes,
   injection) et l'analyse stricte passe.

---

### User Story 5 - Validations sur un vrai projet Neon (Priority: P3)

Avec l'accès au projet Neon (région Francfort), l'équipe confirme chaque hypothèse technique de
l'architecture (§7) par un essai réel et consigne un go ou no-go avec un plan B.

**Why this priority**: indispensable avant le pilote, mais ne bloque pas le développement local.

**Independent Test**: la décision consignée liste chaque point, l'essai fait et son résultat.

**Acceptance Scenarios**:

1. **Given** l'accès Neon, **When** les migrations et tests de cette spec tournent sur une branche
   Neon, **Then** ils passent comme en local.
2. **Given** l'accès Neon, **When** les essais sont faits, **Then** chaque point de l'architecture §7
   a un résultat consigné dans une décision.

### Edge Cases

- Port local déjà occupé : la commande de création le signale clairement.
- Migration modifiée après application : le contrôle d'intégrité la détecte et refuse d'avancer.
- Horloge de l'appareil décalée : le renouvellement du jeton se fonde sur l'expiration annoncée
  par le serveur, avec une marge.
- Deux requêtes simultanées avec un jeton expiré : un seul renouvellement a lieu.
- Session révoquée côté serveur : l'app revient à l'état déconnecté proprement.
- Réponse non JSON (page d'erreur d'un proxy) : échec serveur typé, pas de plantage.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Une commande DOIT créer, démarrer, arrêter et réinitialiser une base locale isolée,
  sans conteneur, à partir de PostgreSQL 17 installé.
- **FR-002**: La base locale DOIT reproduire ce que Neon fournit :
  - le schéma `neon_auth` avec la table `user` de Neon Auth (identifiant uuid) ;
  - les rôles `authenticated` et `anonymous` ;
  - les fonctions `auth.user_id()` (texte) et `auth.uid()` (uuid), qui lisent l'identité de la
    requête.

  Ces imitations ne DOIVENT jamais être appliquées sur Neon.
- **FR-003**: Les migrations DOIVENT être des fichiers SQL numérotés, appliqués une seule fois dans
  l'ordre, enregistrés avec une empreinte, et refusés si un fichier déjà appliqué a changé.
- **FR-004**: Les tests pgTAP DOIVENT s'exécuter fichier par fichier dans une transaction annulée
  et produire un résumé exploitable par la CI.
- **FR-005**: Une première migration DOIT poser le socle commun :
  - le schéma applicatif ;
  - l'identifiant de l'utilisateur courant en uuid ;
  - l'horodatage automatique des mises à jour ;
  - les droits par défaut de la Data API, sans aucune table exposée.
- **FR-006**: La CI DOIT appliquer les migrations et lancer pgTAP sur une base fraîche à chaque pull
  request, en plus de l'analyse et des tests existants.
- **FR-007**: Un client Dart générique (sans notion DYM) DOIT fournir :
  - l'envoi et la vérification d'un code email ;
  - la connexion par jeton Google ;
  - la session, la déconnexion et l'obtention du jeton de la Data API ;
  - le renouvellement (anticipé, et unique sur 401) ;
  - les lectures, écritures et appels RPC de la Data API ;
  - les appels de Functions.
- **FR-008**: Le stockage de la session DOIT passer par une interface ; l'implémentation de
  l'appareil est sécurisée et aucune donnée de session n'est journalisée.
- **FR-009**: La politique de nouvelle tentative DOIT respecter la constitution :
  - erreurs réseau ou 5xx seulement ;
  - jamais sur 4xx ;
  - au plus 3 tentatives avec délai croissant ;
  - seulement pour les requêtes idempotentes ou portant une clé d'idempotence.
- **FR-010**: Toute opération DOIT retourner un résultat typé succès ou échec ; les échecs couvrent
  réseau, non authentifié, interdit, introuvable, conflit, validation, limite de débit, serveur
  et inconnu.
- **FR-011**: Le projet de Functions DOIT fournir :
  - une configuration de déploiement Neon, avec les secrets déclarés mais jamais leurs valeurs ;
  - la vérification du jeton par les clés publiques de Neon Auth ;
  - la validation des entrées ;
  - des réponses d'erreur normalisées alignées sur les échecs du client ;
  - une route de santé et des tests.
- **FR-012**: Le socle Dart DOIT fournir le type résultat et les échecs (fondation), et un package de
  localisation français et anglais (français par défaut).
- **FR-013**: Les apps cliente, vendeuse et admin DOIVENT exister :
  - architecture MVVM retenue, avec génération des routes et de l'injection ;
  - premier écran avec `dym_ui` et textes localisés ;
  - choix de l'environnement à la compilation, refus de démarrer en production sans
    configuration.
- **FR-014**: Une décision DOIT consigner les validations sur Neon (§7 de l'architecture) avec un
  go, un no-go ou un « en attente d'accès » et un plan B par point.

### Key Entities

- **Migration**: fichier SQL numéroté, empreinte, date d'application.
- **Session**: jeton de session, jeton d'accès à la Data API et son expiration, utilisateur.
- **Échec**: catégorie, message technique, code HTTP éventuel, champs en cause.
- **Environnement**: nom (dev, staging, production), URL d'Auth, URL de la Data API, URL des
  Functions.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Sur une machine neuve avec PostgreSQL 17, base locale, migrations et tests prêts en
  moins de 2 minutes, en 3 commandes.
- **SC-002**: 100 % des requêtes du client qui reçoivent un 4xx (hors 401) ne sont jamais retentées.
  Celles qui reçoivent une erreur réseau sont retentées au plus 3 fois.
- **SC-003**: Deux requêtes simultanées avec un jeton expiré ne provoquent qu'un seul renouvellement.
- **SC-004**: Les trois apps démarrent et affichent leur premier écran en français et en anglais,
  sans débordement aux 7 tailles de référence.
- **SC-005**: Une pull request qui casse une migration ou un test pgTAP est bloquée par la CI.

## Assumptions

- Les endpoints d'authentification suivent l'API REST de Better Auth (OTP email, connexion sociale
  par jeton, session, jeton JWT). Leur forme exacte sur Neon fait partie des validations (US5).
- Pour le mobile, la session est portée par un jeton et non par un cookie. Le mécanisme exact
  (en-tête de jeton de session) est validé sur Neon (US5) et isolé dans le client.
- La CI utilise le PostgreSQL natif du runner et ajoute pgTAP. La branche Neon éphémère par pull
  request arrive avec l'accès Neon.
- Pas d'écran métier dans cette spec : le premier écran de chaque app est un écran d'accueil
  technique, remplacé par les specs `auth` et suivantes.
- Les modèles de données (`dym_models`) et les repositories (`dym_data`) sont créés avec la première
  spec qui en a l'usage (`reference-data`), pour éviter des packages vides.
