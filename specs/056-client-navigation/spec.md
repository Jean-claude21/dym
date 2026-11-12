# Feature Specification: Navigation de la cliente « Épuré »

**Feature Branch**: `feat/056-client-navigation`

**Created**: 2026-11-11

**Status**: Draft

**Input**: Spec `client-navigation` de la roadmap (Phase 14). Parcours de
[PARCOURS.md](../../docs/design/PARCOURS.md) §3 et §4.1, planches
[01](../../docs/design/screens/epure/01-cliente-accueil-marche-panier.webp) et
[03](../../docs/design/screens/epure/03-cliente-moi-wallet-espaces.webp). Features C-01 à C-12
(découverte, panier, commande, suivi), C-25 (wallet), C-31 (espaces), C-51 (achats groupés).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Cinq onglets clairs (Priority: P1)

1. **Given** la cliente connectée, **When** l'app s'ouvre, **Then** la barre du bas propose Accueil ·
   Marché · Cuisine · Panier · Moi ; « Cuisine » n'apparaît que si les contenus sont activés.
2. **Given** l'onglet Panier, **When** il est vide, **Then** « Parcourir » ouvre le Marché ; sinon le
   panier s'affiche sans bouton retour.
3. **Given** l'onglet Moi, **When** la cliente l'ouvre, **Then** elle voit sa commande en cours, son
   profil, puis des groupes : commandes, wallet, DYM+, espaces, achats groupés, messages ; favoris,
   paniers, adresses, créer, notifications ; langue, aide ; déconnexion, suppression.

### User Story 2 - Accueil qui va droit au but (Priority: P1)

1. **Given** l'Accueil, **Then** l'en-tête montre « Livraison à · Livré en N min », le quartier, la
   cloche ; le titre « Qu'est-ce qu'on mange ? », la recherche avec micro.
2. **Given** une commande en cours, **Then** un bandeau « Commande en cours » (boutique, statut, heure
   prévue) ouvre son suivi, sur l'Accueil et dans Moi.
3. **Given** une commande passée, **Then** « Racheter » remet ses articles au panier.
4. **Given** les boutiques, **Then** elles s'affichent en liste (photo ronde, origine, quartier, horaires),
   ouvertes d'abord.

### User Story 3 - Marché (Priority: P2)

1. **Given** l'onglet Marché, **Then** recherche, rayons en photos, achats groupés, boutiques en liste.

### User Story 4 - Payer en un écran, confirmation qui rappelle le créneau (Priority: P1)

1. **Given** le panier, **Then** il suit la planche : titre à gauche, boutiques à filet, vignettes menthe,
   prix à droite, jauge verte, livraison, « Quand ? », paiement en deux colonnes, total, « Commander ».
2. **Given** une commande programmée, **When** la confirmation s'affiche, **Then** chaque boutique
   rappelle « Prévue <jour>, <début>–<fin> ».

### User Story 5 - Toutes les pages de la cliente au même design (Priority: P1)

1. **Given** n'importe quelle page de la cliente (rayon, boutique, produit, recherche, livraison,
   adresses, confirmation, commandes, suivi, notifications, wallet, favoris, espaces), **Then** titre
   aligné à gauche, cartes blanches à filet, statuts en vert (jamais en jaune), graisses ≤ 700.

### Edge Cases

- Ouverte depuis Moi, « Mes commandes » est une page complète (son propre fond), avec retour.
- Une notification « commande » vide la pile, ouvre Moi puis Mes commandes.
- Boutons d'espaces jamais tronqués (empilés).
- Petit écran, texte à 130 %, paysage : aucune page ne déborde.

## Requirements *(mandatory)*

- **FR-001**: Navigation Accueil · Marché · Cuisine · Panier · Moi (PARCOURS §3).
- **FR-002**: Le créneau de chaque commande est lu depuis la base (`purchase_json`), jamais calculé
  dans l'app.
- **FR-003**: Jaune réservé au cash et aux notes ; statuts en menthe, vert ou gris.
- **FR-004**: Aucun texte en dur ; libellés `navMarket`, `navCuisine`, `navCart`, `homeDeliverTo`,
  `homeActiveOrder`.

## Success Criteria *(mandatory)*

- **SC-001**: Captures de contrôle de 18 pages de la cliente regardées et conformes aux planches.
- **SC-002**: `melos run analyze`, `melos run test` et pgTAP verts.

## Assumptions

- Le flux vidéo de « Cuisine » est repris par la spec 057 ; ici, l'onglet garde le flux existant.
- Les événements de `METRICS.md` existants restent émis ; aucun nouvel événement.
