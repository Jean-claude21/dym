# Feature Specification: Dernières pages et règles de relecture

**Feature Branch**: `feat/064-last-pages`

**Created**: 2026-11-11

**Status**: Draft

**Input**: Retours du porteur (2026-11-11 et 2026-11-12) : espacements à la manière d'Uber Eats,
jaune réintroduit pour les moments forts, cartes produit identiques sur une rangée et politique de
débordement, sous-rayons séparés de « Où acheter », haut de l'accueil resserré ; relire chaque
capture avec des règles écrites et corriger avant de montrer.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Règles de relecture écrites (Priority: P1)

`docs/design/REVUE_CAPTURES.md` fixe les écarts (boutons, champs, sections, gouttière), la règle des
cartes identiques, la politique de débordement, l'usage des couleurs et la hiérarchie. Chaque capture
est relue avec cette grille avant d'annoncer une page terminée.

### User Story 2 - Les cinq retours (Priority: P1)

1. Espacements relevés dans les quatre apps (12 entre boutons empilés, 16 entre champs, écart entre
   rangées de puces).
2. Vert pour les actions ; jaune pour la fin de marché, « Nouveau », la célébration et le badge du
   panier ; menthe pour l'information.
3. Carte produit : nom sur deux lignes réservées, quantité posée sur la photo ; la carte ne grandit plus.
4. Rayon : sous-rayons (« Tous ») et « Où acheter » (« Partout ») sur deux rangées indépendantes.
5. Accueil : composer mon panier et mes listes côte à côte ; un seul raccourci devient une ligne.

### User Story 3 - Défauts relevés à la relecture (Priority: P1)

Cliente : titres qui répétaient le libellé du champ (adresse), barre de saisie collée au bord (litige),
avatars de boutique vides (commandes : initiale), titre « Messages » en vert, bandeau TikTok jaune
(menthe), tuile orpheline du wallet, formulaire d'aide serré, photo de discussion illisible.
Vendeuse : vignettes vides du catalogue, titres en double (éditeur, adresse de ramassage), quartiers
desservis sans titre, carte « Où vends-tu ? » sans fond.

### Edge Cases

- Photo absente ou illisible : fond menthe et icône, jamais un trou blanc ni une icône cassée.
- Nom de produit très long : deux lignes puis « … », prix jamais coupé.

## Requirements *(mandatory)*

- **FR-001**: Aucune règle métier ni migration.
- **FR-002**: Aucun texte en dur (clés `aisleWhere`, `aisleAnywhere`, `homeCopilotShort`,
  `homeCopilotHint`, `storeDeliveryZonesTitle`).

## Success Criteria *(mandatory)*

- **SC-001**: Toutes les captures (cliente 45, vendeuse 26, livreur 4, admin 14, entrée 6) relues avec
  la grille ; défauts corrigés et recapturés.
- **SC-002**: `melos run analyze` et les tests (hors golden) verts.
