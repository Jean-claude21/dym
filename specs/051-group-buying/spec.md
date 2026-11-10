# Feature Specification: Achat groupé entre voisins, départ groupé

**Feature Branch**: `feat/051-group-buying`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `group-buying` de la roadmap (Phase 13, VISION §3 « Cliente » : « Achat groupé entre
voisins, départ groupé — prix de gros, livraison partagée »).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - La vendeuse ouvre une offre groupée (Priority: P1)

1. **Given** un produit publié, **When** la vendeuse fixe un prix de groupe (plus bas que le prix du
   jour), une quantité totale minimale, une durée (1 à 7 jours) et, si elle veut, des frais de
   livraison réduits pour les membres, **Then** les clientes des quartiers qu'elle livre la voient.
2. **Given** une offre ouverte, **When** elle l'annule, **Then** les membres sont prévenues.

### User Story 2 - Les voisines se groupent (Priority: P1)

1. **Given** une offre près de chez elle, **When** une cliente rejoint le groupe avec une quantité,
   **Then** la jauge monte (nombre de voisins, jamais leurs noms).
2. **Given** le minimum atteint, **When** le groupe se débloque, **Then** chaque membre est prévenue
   et peut mettre sa part au panier : prix de groupe (au plus sa quantité) et frais de livraison des
   membres, jusqu'au lendemain de la date limite.
3. **Given** sa commande passée, **Then** l'avantage est consommé.

### Edge Cases

- Pas d'inscription à sa propre offre, ni après la date limite ou l'annulation.
- Une fois le groupe débloqué, une membre peut augmenter sa part, pas la réduire.
- Au-delà de sa part, le prix du jour s'applique à la ligne.

## Requirements *(mandatory)*

- **FR-001**: Jauge, déblocage, prix de groupe et frais partagés DOIVENT être décidés en base.
- **FR-002**: Événements serveur : `group_offer_opened`, `group_joined`, `group_unlocked`.
- **FR-003**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Une cliente rejoint un groupe en moins de 3 gestes.

## Assumptions

- Chaque membre passe sa propre commande (paiement et adresse à elle) ; le « départ groupé » est la
  livraison à frais partagés des commandes du groupe. Le regroupement en une seule tournée reste
  celui de la livraison existante.
- Un groupe lancé par une cliente (sans offre de la vendeuse) pourra venir si le terrain le demande.
