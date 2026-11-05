# Feature Specification: Pilote, côté apps

**Feature Branch**: `feat/016-pilot-hardening`

**Created**: 2026-10-10

**Status**: Draft

**Input**: Spec `pilot-hardening` de la roadmap (Phase 3 ; C-REV-01/03/04, V-REV-01/02/04,
C-ORD-09, A-SUP-01..03 côté apps), construite avant le gate de la phase 2 par décision du porteur
produit du 2026-10-10 (dérogation consignée dans `docs/product/ROADMAP.md`).

## Contexte

Pendant le pilote, la confiance se gagne commande après commande : Awa note sa commande, Fatou
répond, la note de la boutique devient visible. Awa recommande en un tap ce qu'elle achète chaque
semaine. Quand quelque chose coince, Awa ou Fatou écrivent à l'équipe depuis « Moi → Aide ».

**Maquettes** à valider : 63 (laisser un avis), 64 (avis d'une boutique), 65 (avis côté vendeuse),
66 (aide).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Awa note sa commande (Priority: P1)

Après la livraison, le suivi propose « Donner mon avis » (63) : une note de 1 à 5, des étiquettes
(produits frais, bien emballé, livraison rapide, bon accueil) et un commentaire facultatif. La
vendeuse est prévenue. La page boutique montre la note et le nombre d'avis ; « Avis » (64) liste
les avis et les réponses.

**Acceptance Scenarios**:

1. **Given** une commande livrée, **When** Awa publie 4 étoiles, **Then** l'avis est visible sur la
   boutique, la note moyenne est recalculée et la vendeuse est prévenue.
2. **Given** une commande non livrée ou déjà notée, **When** Awa tente de noter, **Then** c'est
   refusé.

### User Story 2 - Fatou répond (Priority: P1)

Dans « Ma boutique → Mes avis » (65), Fatou voit sa note et ses avis et répond (une réponse,
modifiable). Awa est prévenue.

### User Story 3 - Commander à nouveau (Priority: P2)

Sur une commande terminée, « Commander à nouveau » remet au panier les articles encore en vente,
au prix du jour, et ouvre le panier. Les articles retirés sont nommés.

### User Story 4 - Demander de l'aide (Priority: P1)

« Moi → Aide » (66) : sujet, commande concernée facultative, description. La demande apparaît dans
« Mes demandes » avec son état ; Awa ou Fatou peuvent y répondre. L'équipe y répond depuis l'admin
(spec 017).

### Edge Cases

- Avis retiré par l'équipe (modération) : masqué partout.
- Réachat d'une commande d'une autre personne : refusé.
- Hors ligne : erreurs claires, aucune donnée inventée.

## Requirements *(mandatory)*

- **FR-001**: Un avis par commande livrée, par sa cliente seulement ; note 1 à 5, étiquettes
  connues, commentaire de 500 caractères au plus.
- **FR-002**: La vendeuse de la boutique seule répond ; une réponse par avis, modifiable.
- **FR-003**: Note moyenne et nombre d'avis publics sur la boutique (accueil, page boutique).
- **FR-004**: Réachat : articles encore en vente remis au panier (règles du panier), articles
  écartés nommés ; événement `reorder_tapped`.
- **FR-005**: Demandes d'aide : création, liste, message de l'utilisatrice ; commande liée
  seulement si elle la concerne ; événement `support_ticket_opened`.
- **FR-006**: Notifications : `review_received` (vendeuse), `review_replied` (cliente).
- **FR-007**: Écrans 63 à 66 : vide, chargement, erreur, hors ligne ; sept tailles, texte 130 %.

## Success Criteria *(mandatory)*

- **SC-001**: Awa note sa commande en moins de 15 secondes.
- **SC-002**: Aucun avis ni demande d'autrui lisible ou modifiable (pgTAP).

## Assumptions

- Avis avec photo, signalement d'un avis, mes avis côté cliente : hors périmètre (backlog).
- La réponse de l'équipe aux demandes et le suivi des délais sont dans la spec 017.
