# Implementation Plan: Découverte côté cliente

**Branch**: `feat/008-discovery` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

- **Migration `0008_discovery.sql`** :
  - extension `unaccent` (schéma `extensions`, hors Data API) ;
  - `app.normalize(text)` (immuable) ; colonnes générées `search` (tsvector) sur `products` et
    `stores`, avec index GIN ;
  - centres approximatifs des quartiers et `cities.delivery_minutes` (données de référence) ;
  - fonctions de lecture `SECURITY DEFINER` à filtres explicites (actif, publié), sans données
    privées :
    - `discover_stores` : boutiques qui livrent un quartier, ouvertes maintenant, et estimation ;
    - `nearest_zone` ;
    - `search_catalog` : recherche, rayon, filtres, tris, pagination ;
    - `store_page` et `product_page`.

  L'instant est un paramètre (`p_at`) : les tests sont déterministes.
- **Dart** :
  - `dym_models` : `StoreSummary`, `CatalogItem`, `SearchResults`, `StorePage`,
    `ProductPage`, `ZoneMatch`, `DiscoverResult` ;
  - `dym_data` : `DiscoveryRepository` ;
  - `dym_platform` : `LocationProvider` (`geolocator`, position ponctuelle, précision réduite).
- **App cliente**, feature `discovery` :
  - écrans : accueil (02), rayon (03), boutique (04), fiche produit (28), recherche (29),
    filtres (30), choix du quartier ;
  - onglets Accueil, Rayons, Moi ;
  - `search_performed` et `product_viewed` envoyés par `EventsRepository`.
- **Galerie** : écrans 28 à 30, plus les vrais écrans 02, 03 et 04 (31 à 33) comparés aux
  maquettes validées.

## Constitution Check

| Principe | Vérification | Statut |
|---|---|---|
| I | Spec `discovery` (Phase 2), IDs cités | ✅ |
| II | 02, 03 et 04 validés ; 28 à 30 générés, à valider | ⚠️ validation |
| III | Ouverture, estimation, filtres et disponibilité calculés en SQL ; l'app n'affiche que ce qu'elle reçoit | ✅ |
| IV | Délai de livraison et centres des quartiers en données de référence ; aucune ville en dur | ✅ |
| V | Fonctions à filtres explicites, sans adresse, propriétaire ni proposition ; extensions hors `public` ; pgTAP | ✅ |
| VI | Feature dans l'app cliente ; `LocationProvider` dans `dym_platform` | ✅ |
| VII | pgTAP, tests Flutter ; essai réel en attente (0013) | ⚠️ comme 003 |
| VIII | Vide, chargement, erreur, hors ligne ; 7 tailles ; position facultative | ✅ |
| IX | `search_performed` (sans texte), `product_viewed` | ✅ |

## Decisions

| # | Décision | Pourquoi |
|---|---|---|
| D1 | Recherche Postgres (`tsvector` 'simple' + `unaccent` + préfixes), sans moteur externe | Volume du pilote ; une seule vérité ; Neon propose `unaccent` |
| D2 | Une fonction par écran (`store_page`, `product_page`) | Un aller-retour en 3G |
| D3 | Centres de quartier approximatifs ; la position propose, la cliente confirme | Pas de données géographiques fiables ; pas de PostGIS pour 16 quartiers |
| D4 | Disponible = produit non en rupture et (stock non suivi ou une variante en stock) | Une seule définition pour la recherche, le rayon et la fiche |
| D5 | Fonctions `SECURITY DEFINER` à filtres explicites plutôt que la RLS seule | Les jointures (photos, horaires, quartiers) restent rapides et la sortie est contrôlée champ par champ |
| D6 | `neon_kit` : sans session, la Data API est appelée sans jeton (rôle anonyme) | Défaut découvert ici : toute lecture d'une visiteuse échouait. Une session dont le renouvellement échoue n'est jamais rétrogradée |
| D7 | Quartier choisi gardé en mémoire pour la session, sans modifier le profil | La cliente peut regarder un autre quartier sans changer son adresse |
| D8 | La galerie montre les vrais écrans 02, 03 et 04 (31 à 33) à côté des écrans figés validés | Les captures validées ne bougent pas ; l'écart réel reste visible |
