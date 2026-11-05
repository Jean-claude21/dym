# Feature Specification: Authentification, profils et rôles

**Feature Branch**: `feat/005-auth`

**Created**: 2026-10-02

**Status**: Draft

**Input**: User description: "Spec `auth` de la roadmap (Phase 1 ; C-AUTH-01..05, V-AUTH-01/02, C-PROF-09, A-AUTH-01/02/04/05) : connexion Google et code par email (décision 0007), profil minimal (prénom, quartier, photo facultative), rôles cliente, vendeuse, admin, livreur, suppression de compte, connexion admin réservée et tracée ; écrans partagés par les apps via `dym_auth` et `dym_account`."

## Contexte

Le socle (003) fournit le client Neon et le référentiel (004) les pays et quartiers. Cette spec
ouvre les apps à de vraies personnes :
- **Awa**, cliente, crée son compte en moins de 45 secondes (parcours 1 de `MOCKUPS.md`) ;
- **Fatou**, vendeuse, se connecte dans DYM Vendeuse puis enchaîne sur l'onboarding de sa
  boutique (spec suivante) ;
- **l'équipe** se connecte à l'admin avec son compte Google Workspace.

Conformément à la décision 0007, la connexion se fait avec Google en un geste ou avec un code reçu
par email, sans mot de passe. Le téléphone viendra avec la spec `phone-otp`.

**Maquettes** : les écrans 09 à 15 de `docs/design/screens/` sont produits dans la direction
validée et soumis à la validation du porteur produit avec cette spec, conformément à la dérogation
consignée dans la roadmap.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Awa crée son compte avec un code par email (Priority: P1)

À la première ouverture, Awa voit l'accueil de bienvenue (3 écrans à faire défiler, qu'elle peut
passer). Elle choisit « Continuer avec mon email », saisit son adresse, reçoit un code à 6
chiffres, le saisit, puis indique son prénom et son quartier, détecté ou choisi. Elle arrive sur
l'accueil de l'app. À la réouverture, elle est toujours connectée.

**Why this priority**: c'est la porte d'entrée de toutes les preuves V1 ; le critère terrain est
« sans aide, en moins de 45 s ».

**Independent Test**: dérouler le parcours de bout en bout (serveur simulé côté app, base réelle
côté SQL). Vérifier le profil créé, le rôle cliente, l'événement d'inscription, puis la session
restaurée au redémarrage.

**Acceptance Scenarios**:

1. **Given** une première ouverture, **When** Awa touche « Passer » ou fait défiler les 3 écrans,
   **Then** elle arrive aux choix de connexion.
2. **Given** un email mal formé, **When** Awa veut recevoir le code, **Then** le bouton reste
   inactif et un message clair s'affiche, sans requête.
3. **Given** un code faux, **When** Awa le saisit, **Then** un message lui permet de réessayer
   sans perdre l'email ; après 60 s elle peut renvoyer un code.
4. **Given** un code juste, **When** c'est sa première connexion, **Then** l'écran « Bienvenue sur
   DYM ! » demande son prénom et son quartier. Le quartier est préchoisi si sa position est
   connue, sinon elle le choisit dans la liste des quartiers actifs.
5. **Given** le prénom et le quartier validés, **When** elle touche « C'est parti », **Then**
   plusieurs choses se produisent :
   - son profil est créé dans le pays du quartier ;
   - elle reçoit le rôle cliente ;
   - l'événement « inscription » est enregistré côté serveur ;
   - elle arrive sur l'accueil.
6. **Given** un compte existant, **When** Awa se reconnecte, **Then** elle arrive directement sur
   l'accueil, sans repasser par le profil.
7. **Given** le réseau coupé pendant l'envoi du code, **When** elle réessaie, **Then** un message
   « Pas de connexion » s'affiche et rien n'est perdu.

---

### User Story 2 - Connexion Google en un geste (Priority: P1)

Sur Android, Awa choisit « Continuer avec Google », sélectionne son compte et arrive sur
l'écran de profil, ou sur l'accueil si son compte existe déjà.

**Why this priority**: sur Android, tout le monde a un compte Google ; c'est le chemin le plus
rapide (décision 0007).

**Independent Test**: simuler le fournisseur Google (jeton obtenu, annulation, erreur) et vérifier
chaque issue.

**Acceptance Scenarios**:

1. **Given** Google configuré, **When** Awa le choisit et valide son compte, **Then** une session
   est ouverte.
2. **Given** Awa annule le choix du compte, **When** elle revient, **Then** elle retrouve les choix
   de connexion, sans message d'erreur.
3. **Given** Google non configuré pour l'environnement, **When** l'écran s'affiche, **Then** seul
   le choix par email est proposé.

---

### User Story 3 - Profils et rôles protégés (Priority: P1)

Chaque personne ne voit et ne modifie que son propre profil. Elle ne peut s'attribuer aucun rôle
sensible : admin et livreur ne sont donnés que par un admin, avec trace dans l'audit.

**Why this priority**: les rôles commandent toutes les permissions futures (boutiques, commandes,
admin) ; une faille ici les ouvre toutes (constitution V).

**Independent Test**: pgTAP, avec deux utilisatrices et un admin. Lectures et écritures croisées
refusées, auto-attribution d'un rôle refusée, attribution par un admin tracée.

**Acceptance Scenarios**:

1. **Given** deux utilisatrices, **When** l'une lit ou modifie le profil de l'autre, **Then** elle
   n'obtient rien et ne modifie rien.
2. **Given** une cliente, **When** elle tente de s'ajouter le rôle admin, **Then** c'est refusé.
3. **Given** un admin, **When** il donne le rôle livreur à une personne, **Then** le rôle est actif
   et l'audit enregistre l'auteur, l'action et la cible.
4. **Given** un profil, **When** sa propriétaire modifie son pays directement, **Then** c'est refusé
   (le pays découle du quartier).

---

### User Story 4 - Fatou se connecte dans DYM Vendeuse (Priority: P2)

Fatou ouvre DYM Vendeuse et se connecte (Google ou email). Elle donne son prénom et son quartier,
reçoit le rôle vendeuse et arrive au début de l'onboarding de sa boutique, livré par la spec
suivante.

**Why this priority**: c'est le préalable à l'onboarding des boutiques.

**Independent Test**: parcours de connexion dans l'app vendeuse, puis rôle vendeuse en base.

**Acceptance Scenarios**:

1. **Given** l'app vendeuse, **When** Fatou termine la connexion et le profil, **Then** elle a le
   rôle vendeuse (en plus de cliente si elle l'avait déjà) et arrive sur l'écran d'étape suivante.
2. **Given** un compte cliente existant (même email), **When** il se connecte dans l'app vendeuse,
   **Then** c'est le même compte, enrichi du rôle vendeuse.

---

### User Story 5 - Se déconnecter et supprimer son compte (Priority: P2)

Depuis « Moi », Awa peut se déconnecter. Elle peut aussi supprimer définitivement son compte,
après une confirmation claire. Ses données personnelles sont alors effacées. Une trace
pseudonyme subsiste dans l'audit.

**Why this priority**: exigence des stores et du RGPD-équivalent local ; constitution V.

**Independent Test**: suppression d'un compte en base. Vérifier que le profil, les rôles et
l'utilisateur ont disparu, que l'audit et l'événement existent sans donnée personnelle, et qu'une
seconde tentative ne fait rien.

**Acceptance Scenarios**:

1. **Given** Awa connectée, **When** elle se déconnecte, **Then** la session est fermée sur
   l'appareil et elle revient à la bienvenue.
2. **Given** Awa sur « Supprimer mon compte », **When** elle confirme, **Then** :
   - son utilisateur, son profil et ses rôles sont supprimés ;
   - elle est déconnectée ;
   - l'audit garde « compte supprimé » avec son identifiant seulement.
3. **Given** un obstacle à la suppression (plus tard : commande en cours), **When** elle confirme,
   **Then** la suppression est refusée avec la raison. Cette spec fournit le mécanisme, sans
   obstacle actif pour l'instant.

---

### User Story 6 - Connexion admin réservée et tracée (Priority: P3)

L'équipe se connecte à l'admin web avec Google Workspace. Seuls les comptes qui ont le rôle admin
entrent ; chaque connexion est tracée. L'admin se déconnecte après 30 minutes d'inactivité.

**Why this priority**: l'admin n'a pas encore de fonctions (spec `admin-ops`) ; sa porte doit
cependant être sûre dès qu'elle existe.

**Independent Test**: un compte sans rôle admin est refusé. Un admin entre, et sa connexion apparaît
dans l'audit. L'inactivité simulée déconnecte.

**Acceptance Scenarios**:

1. **Given** un compte sans rôle admin, **When** il se connecte à l'admin, **Then** l'écran
   « Accès réservé » s'affiche et la session est fermée.
2. **Given** un admin, **When** il se connecte, **Then** il entre et la connexion est enregistrée
   dans l'audit.
3. **Given** un admin inactif 30 minutes, **When** le délai expire, **Then** il est déconnecté.

### Edge Cases

- Email avec majuscules ou espaces : normalisé.
- Code demandé plusieurs fois : le dernier est valable. Le bouton de renvoi est bloqué 60 s.
- Session expirée côté serveur pendant le profil : retour à la connexion, email prérempli.
- Quartier devenu inactif : il n'est plus proposé et le profil existant le garde.
- Prénom de plus de 40 caractères ou vide : refusé (application et base).
- Suppression demandée deux fois : la seconde ne fait rien.
- Application hors ligne au démarrage avec une session enregistrée : l'utilisatrice reste
  connectée (spec 003).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Les apps cliente et vendeuse DOIVENT proposer :
  - une bienvenue en 3 écrans, avec « Passer » ;
  - la connexion par code email : saisie de l'email, code à 6 chiffres, renvoi après 60 s ;
  - la connexion Google, quand elle est configurée pour l'environnement.
- **FR-002**: À la première connexion, l'app DOIT demander :
  - le prénom (1 à 40 caractères) ;
  - le quartier, parmi les quartiers actifs, préchoisi si la position est connue ;
  - une photo, facultative et reportée à l'écran profil.
- **FR-003**: La base DOIT tenir un profil par utilisateur et des rôles (`client`, `vendor`,
  `admin`, `courier`). Une utilisatrice :
  - lit et modifie seulement son propre profil (prénom, quartier, langue) ;
  - ne modifie jamais directement son pays ni ses rôles.
- **FR-004**: La complétion du profil DOIT se faire par une fonction serveur qui :
  - déduit le pays du quartier ;
  - donne le rôle de l'app d'où vient la demande (cliente ou vendeuse) ;
  - enregistre l'événement `user_signed_up` une seule fois ;
  - peut être rejouée sans effet de bord.
- **FR-005**: Les rôles `admin` et `courier` NE DOIVENT être donnés ou retirés que par un admin,
  avec une entrée d'audit.
- **FR-006**: Chaque connexion réussie DOIT enregistrer `user_signed_in` (app, rôle). Une connexion
  à l'admin DOIT en plus écrire une entrée d'audit.
- **FR-007**: La suppression de compte DOIT être une fonction serveur, appelée par sa
  propriétaire, qui :
  - vérifie les obstacles ;
  - écrit l'audit et l'événement, sans donnée personnelle ;
  - supprime l'utilisateur, ce qui entraîne la suppression de son profil, de ses rôles et de ses
    sessions.
- **FR-008**: L'admin DOIT :
  - n'accepter que la connexion Google ;
  - refuser tout compte sans rôle admin et fermer sa session ;
  - déconnecter après 30 minutes sans interaction.
- **FR-009**: Les écrans d'authentification et de compte DOIVENT être partagés par les apps (un
  package de feature d'authentification, un package de compte). Ils respectent les règles de
  `dym_ui` (48 dp, AA, 7 tailles de référence, texte 130 %, français par défaut).
- **FR-010**: Chaque écran DOIT gérer les états suivants :
  - chargement ;
  - erreur réseau (« Pas de connexion ») ;
  - erreur de code ;
  - session expirée.

### Key Entities

- **Profil** : utilisateur, prénom, pays (déduit), quartier, langue, photo (clé de stockage,
  facultative), dates.
- **Rôle** : utilisateur, rôle, date, donné par.
- **Moi** : profil et rôles de l'utilisateur connecté, lus en une fois.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Le parcours email complet (bienvenue → accueil) demande au plus 4 écrans et 2 saisies
  (email, code), plus le prénom à la première fois. Il est réalisable en moins de 45 s sur le
  terrain.
- **SC-002**: 100 % des tentatives de lecture ou d'écriture du profil ou des rôles d'autrui, et
  d'auto-attribution d'un rôle sensible, sont refusées (pgTAP).
- **SC-003**: Après suppression d'un compte, aucune donnée personnelle de la personne ne subsiste en
  base (pgTAP).
- **SC-004**: Les écrans d'authentification s'affichent sans débordement aux 7 tailles de référence,
  en français et en anglais, avec le texte à 130 %.
- **SC-005**: Un compte non admin n'entre jamais dans l'admin (test).

## Assumptions

- **Neon Auth** fournit l'OTP email et Google. Les chemins exacts sont validés sur Neon
  (décision 0013, point 1).
- **Google.** La connexion Google exige des identifiants OAuth par plateforme, configurés hors
  dépôt et passés à la compilation. Sans eux, le bouton Google est masqué.
- **Détection du quartier.** Elle se fait sur l'appareil, par la position, avec la permission de
  l'utilisatrice. Sans permission, elle choisit dans la liste.
- **Photo de profil.** Elle arrive avec le stockage d'objets (spec `catalog`). Le champ existe dès
  maintenant.
- **Admin.** La 2FA est imposée par Google Workspace (décision 0007). Les rôles fins de l'admin
  (A-AUTH-03) relèvent de la phase 5.
- **Après la connexion.** L'accueil de l'app cliente est un écran provisoire jusqu'à la spec
  `discovery`. L'écran d'après connexion de la vendeuse est le début de l'onboarding, spec
  `store-onboarding`.
