# 0022 — Carte : MapLibre et tuiles OpenFreeMap, derrière une interface

**Statut** : Acceptée (2026-11-16)

## Contexte

La spec 095 demande une carte « impeccable » dans les apps cliente et vendeuse (puis livreur, spec
096), sur Android d'entrée de gamme et sur le web, dans tous les pays. Le porteur demande si Google
Maps est nécessaire.

## Options

| Option | Rendu | Coût | Clé | Style aux couleurs DYM |
|---|---|---|---|---|
| Google Maps (`google_maps_flutter`) | Natif | Gratuit sur mobile, payant sur le web au-delà du quota | Oui, par plateforme | Limité (JSON de style) |
| `flutter_map` + tuiles raster | Widgets Flutter | Selon le fournisseur de tuiles | Selon | Non (images) |
| **`maplibre_gl` + OpenFreeMap** | Vectoriel GPU (Android, iOS, web) | Gratuit, sans quota | Non | Complet (style JSON) |

## Décision

- `maplibre_gl` 0.28 (Flutter ≥ 3.44, Android 7+, web WebGL2) avec les tuiles vectorielles
  OpenFreeMap (schéma OpenMapTiles, données © OpenStreetMap, attribution affichée).
- Le style est construit en Dart depuis les couleurs de `dym_ui` (fond clair, parcs vert tendre,
  routes blanches) ; épingles, regroupement et zones sont des calques du style alimentés par GeoJSON.
- Tout passe par le package `dym_map` : les écrans n'utilisent que `DymMap`, `DymPinPlacer` et les
  types `DymLatLng`, `DymBounds`. Le moteur (`DymMapEngine`) est remplaçable : changer de
  fournisseur (Google, tuiles hébergées) ne modifie aucun écran. Les tests utilisent
  `FakeMapEngine`, sans vue native.
- Google Maps n'est pas nécessaire.

## Conséquences

- Aucun compte ni clé ; si OpenFreeMap devenait insuffisant, les mêmes tuiles peuvent être
  hébergées (Coolify) sans changer le style ni les écrans.
- Le premier affichage télécharge les tuiles : sur 3G, la liste reste disponible à côté de la carte.
