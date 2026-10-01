# 0003 — Stacked pour l'architecture Flutter

**Statut :** Acceptée · 2026-10-01

## Contexte

L'équipe maîtrise Stacked (MVVM, routes et injection générées). `stacked` 3.5.0 date d'août 2025 ;
`stacked_generator` 2.0.4 (juin 2026) est compatible avec `analyzer` 14, comme freezed 4 et
json_serializable 6.14.

## Décision

Stacked (`stacked`, `stacked_services`, `stacked_generator`) pour les apps et les packages de feature.
Les vues ne contiennent aucune logique ; les viewmodels orchestrent ; les règles métier sont en SQL.

## Conséquences

- Risque : rythme de publication de `stacked` plus lent. Atténuation : seuls les packages de
  feature et les apps dépendent de Stacked ; `foundation`, `domain`, `infra` et `data` en sont
  indépendants, donc un changement de framework reste circonscrit.
- La génération de code est validée sur la version Flutter retenue (spec `foundation`).

## Alternatives écartées

Riverpod 3 (plus actif, mais choix de l'équipe), Bloc.
