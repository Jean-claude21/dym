# Quickstart — découverte côté cliente

```bash
node db/scripts/dym-db.mjs local start && node db/scripts/dym-db.mjs migrate && node db/scripts/dym-db.mjs test
fvm dart run melos run test
cd apps/dym_gallery && fvm flutter run -d chrome   # écrans 28 à 33, « Comparer » avec les maquettes
cd apps/dym_client && fvm flutter run -d chrome --dart-define=DYM_ENV=dev
```

## Résultats (2026-10-02, local)

| Contrôle | Résultat |
|---|---|
| pgTAP | 263/263, dont 32 nouveaux :<br>• accueil : boutiques qui livrent le quartier, ouvertes d'abord, ouverture selon les horaires et le fuseau, estimation ;<br>• quartier le plus proche (Ghana inactif exclu, position invalide refusée) ;<br>• recherche sans accents et par préfixe, filtres (origine, rayon et sous-rayons, prix, disponibilité, quartier), tris, pagination, boutiques trouvées ;<br>• pages boutique et produit sans propriétaire, adresse ni proposition ; boutique suspendue invisible partout |
| Dart | `neon_kit` 24 (Data API anonyme sans session, jamais de rétrogradation d'une session expirée), `dym_data` 31, `dym_models` 13 |
| App cliente | 135 :<br>• viewmodels : ordre des boutiques, estimation, position proposée puis confirmée ou refusée, rayon, recherche, filtres, tris, fiche (variante, prix, disponibilité, événement) ;<br>• écrans 02, 03, 04, 28, 29 et 30 × 7 tailles × fr/en à 130 % ;<br>• parcours au toucher : quartier par la position, recherche → fiche → variante, reprise hors ligne |
| Galerie | 918 tests ; captures des écrans 28 à 33. Les captures précédentes sont **inchangées** |
| `melos run analyze` | aucun problème |
| Compilation web de l'app vendeuse | réussie |
| Essai réel sur Neon | en attente (décision 0013) |

Comparaison maquette / rendu : [`validation/compare-28-33.jpg`](validation/compare-28-33.jpg). Les écrans 31
à 33 sont les vrais écrans 02, 03 et 04.

Défaut trouvé et corrigé : une visiteuse sans session ne pouvait rien lire par la Data API
(`neon_kit` exigeait un jeton) ; elle lit maintenant sous le rôle anonyme.
