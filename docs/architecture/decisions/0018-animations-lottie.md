# 0018 — Animations de la marque en Lottie

**Statut** : Acceptée (2026-11-13)

## Contexte

Le porteur a validé le logo (sac DoYourMarket redessiné aux couleurs « Épuré »), un splash animé et
des écrans d'accueil animés (2026-11-13). `PACKAGES.md` prévoyait `rive` pour l'illustration animée,
jamais ajouté. Les animations sont produites par script (`docs/design/marque/`) et doivent rester
légères (Android 11, 2 Go de RAM) et désactivables.

## Décision

- `lottie` (^3.8.2, pur Dart, rendu par `Canvas`) dans `dym_ui` seulement, derrière `DymSplash` et
  `DymBrandSceneView`. Les apps ne dépendent pas de `lottie`.
- Fichiers JSON dans `dym_ui/assets/brand/` : splash (150 Ko, légumes en WebP intégrés) et cinq
  scènes vectorielles (11 à 35 Ko).
- Animations réduites : dernière image (scène) ou pose finale du logo (splash), sans mouvement.
- `rive` retiré de `PACKAGES.md`.

## Conséquences

- Une animation se modifie en régénérant son JSON (scripts de `docs/design/marque/`), sans code.
- Les tests de widgets n'attendent pas la fin d'un splash qui boucle (`pump`, pas `pumpAndSettle`).

## Alternatives écartées

- `rive` : éditeur propriétaire, fichiers binaires, moteur natif plus lourd.
- Animations codées avec `flutter_animate` : longues à régler, impossibles à prévisualiser hors app.
