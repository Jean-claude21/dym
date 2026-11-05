# Quickstart — référentiel générique

```bash
node db/scripts/dym-db.mjs local reset && node db/scripts/dym-db.mjs migrate && node db/scripts/dym-db.mjs test
fvm dart run melos run test:dart        # dym_models, dym_data
```

## Résultats (2026-10-02, local)

| Contrôle | Résultat |
|---|---|
| Migrations 0002 à 0004 | appliquées, garde de sécurité verte (RLS sur toutes les tables, aucune écriture anonyme) |
| pgTAP | 89/89. Structure 20, accès 22, cohérence 12, événements et audit 15, valeurs initiales 11 |
| SC-001 : ouvrir le Ghana | une seule mise à jour (`countries.is_active`) rend visibles le pays, Accra, le cash et ses frais en GHS |
| SC-003 : incohérences | 100 % refusées, même pour le propriétaire de la base |
| SC-004 : données personnelles | email (clé et valeur), téléphone imbriqué et propriétés > 4 Ko refusés |
| `dym_core` (dont `LocalizedText`, `Uuid`) · `dym_models` · `dym_data` | 25/25 · 6/6 · 6/6 |
| `melos run analyze` | aucun problème |

## Décisions à prendre (porteur produit)

- **Taux de commission** : à 0 % en attendant.
- **Frais de livraison réels** : ceux de la maquette sont repris, à savoir 500 F CFA de base,
  200 F CFA par ramassage supplémentaire et livraison offerte dès 4 000 F CFA.
- **Liste définitive des quartiers de Lomé.**
