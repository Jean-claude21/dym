# Feature Specification: Navigation de la vendeuse « Épuré »

**Feature Branch**: `feat/059-vendor-navigation`

**Created**: 2026-11-11

**Status**: Draft

**Input**: Spec `vendor-navigation` de la roadmap (Phase 14). Planche
[04](../../docs/design/screens/epure/04-vendeuse.webp), [PARCOURS.md](../../docs/design/PARCOURS.md)
§4.2 et parcours de Fatou et d'Akossiwa. Features V-DASH, V-ORD, V-CAT, V-TILL.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Cinq onglets (Priority: P1)

1. **Given** la vendeuse, **Then** Aujourd'hui · Commandes · Catalogue · Messages · Boutique ; le
   compte (aide, langue, déconnexion) est rangé dans Boutique, « Mon compte ».

### User Story 2 - Encaisser en premier (Priority: P1)

1. **Given** Aujourd'hui, **Then** « Bonjour Fatou », « Encaisser » (QR ou code) et « Vente cash » en
   tête ; ventes de la période ; « À traiter » en lignes à filets avec point rouge si urgent.
2. **Given** Encaisser, **Then** montant en grand et clavier géant (touches de 56 px), libellé
   facultatif, « Afficher le QR ».

### User Story 3 - Un geste par étape, rupture en un geste (Priority: P1)

1. **Given** une nouvelle commande, **Then** bandeau menthe, « Refuser » et « Accepter » (vert).
2. **Given** le Catalogue, **Then** titre, puces, produits en lignes à filets avec interrupteur de stock.

### User Story 4 - Boutique (Priority: P2)

1. **Given** Boutique, **Then** ouverture en un geste, puis groupes Argent, Vendre plus, Réglages et
   Mon compte.

### Edge Cases

- Paysage, texte à 130 % : le rail accepte deux lignes de libellé (« Aujourd'hui »).
- Photo produit illisible : fond menthe, pas d'erreur.

## Requirements *(mandatory)*

- **FR-001**: Aucune règle métier nouvelle ; le montant tapé est relu par la base (`requestPayment`).
- **FR-002**: Jaune réservé au cash ; aucun texte en dur.

## Success Criteria *(mandatory)*

- **SC-001**: Six captures de la vendeuse conformes à la planche 04.
- **SC-002**: Analyse et tests verts.
