# 0002 — Trois apps séparées + une conditionnelle

**Statut :** Acceptée · 2026-10-01

## Contexte

Awa (acheteuse) et Fatou (vendeuse) n'ont pas le même travail à faire. L'app de Fatou doit rester
très simple, sur des téléphones d'entrée de gamme. L'équipe ops a besoin d'un outil dès la phase 1.

## Décision

`dym_client`, `dym_vendor`, `dym_admin` (Flutter Web) dès la phase 1 ; `dym_delivery` créée
uniquement quand le déclencheur est atteint (> 50 commandes/jour pendant 14 jours).

## Conséquences

- Le code commun vit dans des packages (`dym_auth`, `dym_ui`, `dym_data`…) : une app de plus coûte
  environ une heure.
- Deux fiches sur les stores ; notifications et sons spécifiques à chaque rôle.
- Une même personne peut être cliente et vendeuse : un compte, des rôles distincts.

## Alternatives écartées

Une app unique avec deux modes : moins de builds, mais une UX de vendeuse polluée par l'achat et
une fiche store ambiguë.
