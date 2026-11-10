# Implementation Plan: Argent des espaces

**Branch**: `feat/032-spaces-money` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Versements et financements en transactions du grand livre ; soldes lus en base | OK |
| IV. Générique | Devise de l'espace ; aucun montant en dur | OK |
| V. Sécurité | Rôle vérifié en `SECURITY DEFINER` ; verrous par wallet et par espace ; clés d'idempotence | OK |
| VII. Qualité | pgTAP (soldes, idempotence, refus, équilibre du grand livre) ; Neon propre ; essai sur staging | OK |
| IX. Mesure | `space_contributed`, `space_funded` (serveur) | OK |

## Décisions

- Migration 0039 : compte `space_pocket` (colonne `space_id`), transactions `space_contribution`
  et `space_payout` ; `space_validations.funded_minor` ; espaces supprimés logiquement quand le
  grand livre les référence (`deleted_at`).
- `validate_space(p_space, p_use_pocket)` remplace la version à un paramètre (recopiée, financement
  ajouté) ; `space_json` recopiée avec la poche et les versements du mois par membre.
- App : carte « Poche commune » (solde, « Verser »), versements par membre, interrupteur « Payer
  avec la poche commune » ; mouvements du wallet « Versé à un espace » et « Reçu d'un espace ».
