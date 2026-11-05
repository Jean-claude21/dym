# Feature Specification: Litiges

**Feature Branch**: `feat/012-disputes`

**Created**: 2026-10-03

**Status**: Draft

**Input**: User description: "Spec `disputes` de la roadmap (Phase 2 ; C-ORD-08, C-NOTIF-06, A-LIT-01..06) : signaler un problème, ouverture de litige, notification de réponse."

## Contexte

Une commande peut mal se passer : article manquant, abîmé, jamais reçu. Awa doit pouvoir le
signaler simplement, la vendeuse y répondre, et l'équipe DYM trancher (clore, rembourser une
partie ou tout, avertir la vendeuse). C'est la base de la preuve V1 « un incident résolu depuis
l'admin en moins d'une heure ». Les écrans de l'équipe sont construits avec l'admin (spec
`admin-ops`) ; cette spec en fournit les règles et les gestes.

**Maquettes** à valider : 49 (signaler un problème), 50 (suivi du signalement), 51 (litige côté
vendeuse).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Awa signale un problème (Priority: P1)

Depuis le suivi d'une commande acceptée, en cours ou livrée depuis moins de 7 jours, Awa touche
« Signaler un problème » (49), choisit ce qui s'est passé et le raconte. La vendeuse et l'équipe
sont prévenues. Awa suit son signalement (50) et peut y répondre.

**Acceptance Scenarios**:

1. **Given** une commande livrée hier, **When** Awa envoie un signalement, **Then** un litige
   ouvert est créé avec son premier message, la vendeuse reçoit une notification et l'événement
   `dispute_opened` est enregistré.
2. **Given** un litige déjà ouvert sur la commande, **When** Awa en ouvre un second, **Then**
   c'est refusé : elle retrouve celui en cours.
3. **Given** une commande en attente, refusée, annulée ou livrée il y a plus de 7 jours,
   **When** Awa veut signaler, **Then** ce n'est pas proposé et la base refuse.

---

### User Story 2 - Fatou répond (Priority: P1)

Sur la commande concernée, Fatou voit le problème signalé (51) et répond. Awa est prévenue de la
réponse (C-NOTIF-06).

**Acceptance Scenarios**:

1. **Given** un litige ouvert, **When** Fatou répond, **Then** le message apparaît dans le
   suivi d'Awa et Awa reçoit « Réponse à ton signalement ».
2. **Given** un litige sur la commande d'une autre boutique, **When** Fatou veut y répondre,
   **Then** c'est refusé.

---

### User Story 3 - L'équipe tranche (Priority: P1)

L'équipe liste les litiges ouverts (les plus anciens d'abord), lit la conversation et la
commande, écrit, puis décide : clore sans suite, rembourser une partie (montant au plus égal au
total de la commande) ou tout, et éventuellement avertir la vendeuse. Chaque décision est
tracée dans le journal d'audit. Awa et Fatou sont prévenues. Un remboursement décidé est créé
à exécuter : par le fournisseur de paiement pour un achat payé en ligne, en cash par l'équipe
sinon (exécution dans `admin-ops`).

**Acceptance Scenarios**:

1. **Given** un litige ouvert, **When** l'équipe rembourse 300 sur une commande de 1 800,
   **Then** le litige est résolu, un remboursement de 300 est créé à exécuter, l'audit garde
   avant et après, Awa et Fatou sont prévenues, `dispute_resolved` est enregistré.
2. **Given** un montant supérieur au total, **When** l'équipe rembourse, **Then** c'est refusé.
3. **Given** une personne sans rôle admin, **When** elle tente de trancher ou de lister,
   **Then** c'est refusé.

### Edge Cases

- Signalement pendant la livraison (« jamais reçue ») : permis dès l'acceptation.
- Litige résolu : plus de messages ; un nouveau signalement reste possible dans les 7 jours.
- Vendeuse avertie : le compte est noté pour l'équipe (réputation), sans effet automatique.

## Requirements *(mandatory)*

- **FR-001**: Une cliente DOIT pouvoir ouvrir un litige sur sa commande acceptée, en cours ou
  livrée depuis 7 jours au plus, avec une raison (`missing_item`, `wrong_item`, `damaged`,
  `quality`, `not_delivered`, `other`) et un texte (3 à 500 caractères). Un seul litige ouvert
  par commande.
- **FR-002**: La cliente, la vendeuse de la commande et l'équipe DOIVENT pouvoir lire le litige
  et y écrire tant qu'il est ouvert ; personne d'autre.
- **FR-003**: Seule l'équipe (rôle admin) DOIT pouvoir lister les litiges et trancher ;
  chaque décision écrit dans `audit_log` (qui, quoi, quand, avant, après).
- **FR-004**: Un remboursement décidé DOIT être créé avec son montant (devise de la commande),
  sa méthode (fournisseur si payé en ligne, cash sinon) et son statut `pending`.
- **FR-005**: Notifications : vendeuse à l'ouverture ; cliente à chaque réponse de la vendeuse
  ou de l'équipe ; cliente et vendeuse à la décision.
- **FR-006**: Événements `dispute_opened` (raison) et `dispute_resolved` (décision, montant),
  sans donnée personnelle.
- **FR-007**: Les gestes passent par une Function (notifications et push).
- **FR-008**: L'app cliente DOIT proposer 49 et 50 depuis le suivi ; l'app vendeuse le bandeau
  et la réponse (51) dans le détail de la commande.

## Success Criteria *(mandatory)*

- **SC-001**: Awa signale un problème en moins de 30 secondes depuis le suivi.
- **SC-002**: Aucune personne hors de la commande ne lit un litige (pgTAP).
- **SC-003**: Toute décision de l'équipe est dans le journal d'audit (pgTAP).

## Assumptions

- **Photos de preuve** : à ajouter avec le stockage des pièces jointes (messagerie).
- **Écrans de l'équipe et exécution des remboursements** : spec `admin-ops`.
- **Délai de 7 jours** : règle de départ, à confirmer au pilote.
