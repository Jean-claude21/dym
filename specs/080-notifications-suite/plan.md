# Implementation Plan: Notifications, suite

**Branch**: `feat/080-notifications-suite` | **Date**: 2026-11-13 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres source de vérité | Photo choisie et rappels décidés en SQL | OK |
| V. Sécurité | `MEDIA_PUBLIC_URL` est une adresse publique (pas un secret) | OK |
| IX. Mesure | `cart_reminded` émis côté serveur | OK |

## Décisions

- Rappel classé « commandes » (pas « offres », coupées par défaut), limité aux heures de journée.
