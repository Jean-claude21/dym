# 0017 — Identifiants d'application panafricains

**Statut** : Acceptée (2026-11-13)

## Contexte

Les apps Android et iOS portaient l'identifiant `tg.dym.*`, issu de l'organisation donnée à
`flutter create` (spec 003). `.tg` désigne le Togo : DYM est conçu pour toute l'Afrique, et un
identifiant d'application devient définitif dès la publication sur le Play Store. Aucune app n'est
encore publiée ni enregistrée dans Firebase.

## Décision

- Android (`applicationId`, `namespace`, paquet Kotlin) et iOS (`PRODUCT_BUNDLE_IDENTIFIER`) :
  `africa.dym.client`, `africa.dym.vendor`, `africa.dym.delivery`.
- Aucun identifiant, texte visible ou mot régional propre à un pays dans le code (« zem » remplacé par
  « livreur ») ; pays, villes et termes locaux vivent dans les données de référence.

## Conséquences

- Les apps Firebase (`google-services.json`) et les clients OAuth Google sont créés avec ces
  identifiants.
- Les installations de test portant `tg.dym.*` sont désinstallées (autres identifiants : autres apps).

## Alternatives écartées

- `com.dym.*` : classique mais probablement déjà pris sur le Play Store (identifiants uniques).
- Garder `tg.dym.*` : contraire à la vision panafricaine, et définitif après publication.
