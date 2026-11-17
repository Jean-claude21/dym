# Feature Specification: Surveillance

**Feature Branch**: `feat/106-surveillance`

**Created**: 2026-11-17

**Status**: Done

**Input**: Incident du 2026-11-16 : les Functions de staging ont tourné sans aucune clé (fichier
d'environnement en CRLF) sans que rien ne prévienne. Demande du porteur : que l'app soit « au top ».

## Requirements *(mandatory)*

- **FR-001** `GET /health` : services externes branchés (oui/non, jamais de valeur) ; `?deep=1`
  vérifie aussi la base (`503` et `degraded` si elle ne répond pas).
- **FR-002** GitHub Actions `Surveillance` toutes les 30 minutes : API, base et services attendus
  (google, streams, ai, push, payments, calls, errors, media) ; un échec envoie un e-mail au porteur.
- **FR-003** Les erreurs 5xx restent remontées à Sentry (spec 092).
