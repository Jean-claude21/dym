# Quickstart — catalogue de la vendeuse

```bash
node db/scripts/dym-db.mjs local start && node db/scripts/dym-db.mjs migrate && node db/scripts/dym-db.mjs test
cd functions && npm ci && TEST_DATABASE_URL=postgresql://postgres@localhost:54329/dym npm test
fvm dart run melos run test
cd apps/dym_gallery && fvm flutter run -d chrome   # écrans 24 à 27, « Comparer » avec les maquettes
```

En `staging` et en `production`, les apps exigent `DYM_MEDIA_URL`, la base publique du bucket
`product-photos`. La Function exige `OPENAI_API_KEY` pour proposer des fiches ; sans cette clé,
ou avec le modèle inactif en base, la saisie est manuelle.

## Résultats (2026-10-02, local)

| Contrôle | Résultat |
|---|---|
| pgTAP | 231/231, dont 62 nouveaux :<br>• produits : 34 (création idempotente, devise de la boutique malgré la valeur envoyée, unité d'un autre pays, photos d'une autre boutique ou au-delà de 5, prix nul, nom court, plus de 10 variantes, publication incomplète puis complète, rejouée sans doublon d'événement, rupture, stock d'une variante ou par la fiche avec événements, archivage, restauration, suppression du brouillon seule) ;<br>• accès : 28 (proposition conservée, rayon inconnu ignoré, photo d'autrui refusée, modèle inactif, acceptation avec `fields_changed`, lecture publique des seuls publiés, brouillons, archives et catégories archivées invisibles, proposition illisible, 10 écritures croisées refusées, fonctions des Functions inaccessibles, boutique suspendue figée et masquée) |
| Functions | 26 (vitest) : présignature et clé sous le préfixe de la boutique, 401, 404, 422, 503 stockage ou modèle indisponible, échec du modèle sans trace, photo d'autrui 403, rayon inconnu ignoré, erreurs Postgres traduites, adaptateur Postgres contre la base locale |
| Dart | `dym_core` 29 (`Money.parseMajor`, `DYM_MEDIA_URL`), `neon_kit` 23 (envoi présigné sans jeton, rejoué après coupure, 403 sans nouvelle tentative), `dym_models` 13, `dym_data` 25 |
| App vendeuse | 279 :<br>• éditeur : photo → proposition → publication, saisie manuelle si indisponible, ce qui est saisi n'est jamais écrasé, envoi en échec, publication hors ligne puis réessai sans doublon, variantes, stock non suivi, prix invalides, modification, archivage et suppression depuis la fiche ;<br>• liste : filtres, rupture en un geste, hors ligne ; catégories : ajout, doublon, renommage, ordre, archivage ;<br>• écrans 24 à 27 × 7 tailles × fr/en à 130 % ; parcours nominal au toucher |
| Galerie | 750 tests ; 78 captures. Seule la 23 change (3 onglets), les autres précédentes sont **inchangées** |
| `melos run analyze` | aucun problème |
| Compilation web de l'app vendeuse | réussie |
| Essai réel (stockage Neon, OpenAI, Android) | **en attente d'accès** (décision 0013) |

Comparaison maquette / rendu : [`validation/compare-24-27.jpg`](validation/compare-24-27.jpg).

Défauts trouvés et corrigés :
- **Puces** : un libellé long débordait ; il est maintenant tronqué avec des points de suspension.
- **Formulaires en étapes** : la nouvelle étape gardait le défilement de la précédente (002 à 007).
- **Liste des produits** : à 360 dp, le menu « ⋮ » écrasait les noms ; les actions sont passées
  dans la fiche.
- **Contrainte de la 0006** : une boutique suspendue doit être fermée (test corrigé).
