# Feature Specification: Performance terrain

**Feature Branch**: `feat/062-field-performance`

**Created**: 2026-11-11

**Status**: Done (le « Reste à faire » est traité par les specs 103 et 107 ; mesures dans la spec 107)

**Input**: Spec `field-performance` de la roadmap (Phase 14). [PARCOURS.md](../../docs/design/PARCOURS.md)
§8 (règles d'implémentation) : Android 11, 2 Go, 3G instable, données chères.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Images légères (Priority: P1)

1. **Given** les images embarquées, **Then** elles sont en WebP, vignettes ≤ 30 Ko et photos plein
   écran ≤ 120 Ko ; un test échoue sinon.
2. **Given** une vignette (produit, boutique, rayon, carte produit), **Then** elle est décodée à sa
   taille d'affichage, jamais plus grande.

### User Story 2 - Gestes optimistes (Priority: P1)

1. **Given** la vendeuse qui met un produit en rupture, **Then** l'interrupteur bascule tout de suite ;
   il revient et l'échec s'affiche si la base refuse.
2. Déjà en place : j'aime (fil), une seule page vidéo construite à la fois, nouvelle tentative seulement
   sur erreur réseau ou 5xx, clé d'idempotence sur toute création.

## Reste à faire (non construit dans cette spec)

- Premier écran depuis un cache local persistant : demande une dépendance de stockage (décision à
  consigner dans `docs/architecture/decisions/` et `PACKAGES.md`).
- File hors ligne des gestes (panier, rupture) rejouée au retour du réseau.
- Qualité vidéo selon le réseau ; aucune vidéo préchargée en économie de données.
- Mesures sur Android d'entrée de gamme (ouverture < 3 s, 60 images/s).
- Les huit parcours de PARCOURS §5 en tests d'intégration bout en bout (les parcours existent en tests
  de widgets par app).

## Requirements *(mandatory)*

- **FR-001**: Budgets d'images vérifiés par `packages/ui/dym_ui/test/asset_budget_test.dart`.
- **FR-002**: `DymSizedImage` (dym_ui) pour décoder à la taille affichée.

## Success Criteria *(mandatory)*

- **SC-001**: Test des budgets vert ; poids des images embarquées réduit (rayons ≈ 95 Ko → ≤ 30 Ko).
- **SC-002**: Analyse et tests verts.
