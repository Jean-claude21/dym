# Feature Specification: Notifications plus utiles

**Feature Branch**: `feat/072-notifications`

**Created**: 2026-11-13

**Status**: Draft

**Input**: Le porteur (2026-11-13) : « Améliorer les notifications. » Suite de la spec 069 (push FCM).
Features C-12 (suivi et notifications), V-05 (commandes vendeuse), L-02 (courses du livreur).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Comprendre sans ouvrir l'app (Priority: P1)

La vendeuse lit « Nouvelle commande · 3 500 F CFA — Awa : Tomates et 1 autre article. Réponds vite. » ;
la cliente lit « Étal de Kodjo a accepté ta commande de 3 500 F CFA. », « … prépare ta commande :
Tomates et 1 autre article. », « Ta commande de 3 500 F CFA arrive bientôt. »

### User Story 2 - Un son et une importance par type (Priority: P1)

Quatre canaux Android, nommés dans la langue du téléphone : « Commandes et paiements », « Messages »,
« Courses à livrer » (livreur, importance maximale), « Infos et offres » (normale). Chacun se règle
dans les paramètres du téléphone.

### User Story 3 - Pas de pile de notifications (Priority: P2)

Les notifications d'une même commande ou d'une même conversation se remplacent (dernier état seul).

### User Story 4 - Nuit calme (Priority: P2)

Réglage « Nuit calme » : de 22 h à 7 h (heure du pays), pas de messages ni d'offres sur le téléphone ;
commandes et paiements passent toujours ; tout reste dans le centre de notifications.

### Edge Cases

- Commande sans articles lisibles : textes sans montant (paramètres d'origine).
- Notification sans commande (course proposée) : texte inchangé.

## Requirements *(mandatory)*

- **FR-001**: montants mis en forme en SQL selon la devise du référentiel (`app.format_money`).
- **FR-002**: paramètres complétés à l'envoi (`app.notification_params`), jamais de donnée personnelle.
- **FR-003**: canal et regroupement (`channel_id`, `tag`) transmis à FCM par la Function.
- **FR-004**: « nuit calme » en base (`quiet_night`), appliquée par `app.push_allowed`.

## Success Criteria *(mandatory)*

- **SC-001**: pgTAP 600 (montants, résumé, textes complets, nuit calme) ; tests Functions (canaux,
  charge FCM) ; tests des réglages.
