# Feature Specification: Notifications du téléphone

**Feature Branch**: `feat/069-push-firebase`

**Created**: 2026-11-13

**Status**: Draft

**Input**: Le serveur savait envoyer (file `notifications`, Function, `push_tokens`) mais aucune app
n'intégrait Firebase et la clé d'envoi était vide : aucune notification n'arrivait. Le porteur a fourni
`google-services.json` et la clé de compte de service (2026-11-13).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Être prévenu app fermée (Priority: P1)

Après la connexion, l'app demande l'autorisation (Android 13+) et enregistre le téléphone. Nouvelle
commande, message, course proposée, commande prête : la notification arrive même app fermée ; app
ouverte, elle s'affiche aussi.

### User Story 2 - Ouvrir le bon écran (Priority: P1)

Toucher la notification ouvre la commande (cliente, vendeuse) ou les courses (livreur).

### Edge Cases

- Sans `google-services.json` (CI, web) : l'app se construit et fonctionne sans push.
- Jeton renouvelé par Firebase : réenregistré.

## Requirements *(mandatory)*

- **FR-001**: `PushNotifications` (`dym_platform`) ; enregistrement par `register_push_token`.
- **FR-002**: aucun secret dans le dépôt (`google-services.json` et clé hors dépôt).

## Success Criteria *(mandatory)*

- **SC-001**: essai réel sur l'émulateur distant : jeton enregistré, notification « Nouveau message »
  affichée chez la vendeuse app en arrière-plan (envoi `sent` côté serveur).
