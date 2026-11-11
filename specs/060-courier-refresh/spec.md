# Feature Specification: Livreur « Épuré »

**Feature Branch**: `feat/060-courier-refresh`

**Created**: 2026-11-11

**Status**: Draft

**Input**: Spec `courier-refresh` de la roadmap (Phase 14). Planche
[05](../../docs/design/screens/epure/05-livreur.webp), [PARCOURS.md](../../docs/design/PARCOURS.md)
§4.3 et parcours de Komlan. Features L-MIS, L-RUN, L-EARN.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Missions (Priority: P1)

1. **Given** le livreur, **Then** Missions · Historique · Gains · Moi.
2. **Given** Missions, **Then** titre et « En ligne » sur une ligne ; la course en cours au-dessus des
   propositions ; chaque carte : statut, « boutique → cliente · quartier », « Ta course », cash à
   encaisser (jaune, réservé au cash), créneau, consignes, ramassage et remise, action.

### User Story 2 - Remise au clavier géant (Priority: P1)

1. **Given** « Commande remise », **Then** quatre cases, clavier géant, cash à encaisser rappelé ;
   « Valider la remise » actif seulement quand les quatre chiffres sont tapés ; la base vérifie le code.

### User Story 3 - Historique et gains (Priority: P2)

1. **Given** Historique, **Then** les courses livrées seulement.
2. **Given** Gains, **Then** revenus du jour en grand, wallet, cash à remettre boutique par boutique,
   « Retirer mes gains », « Point de recharge ».

### Edge Cases

- Rien en cours : la section disparaît. Course livrée : elle passe dans l'historique.

## Requirements *(mandatory)*

- **FR-001**: Aucune règle métier nouvelle ; code de remise vérifié en base.
- **FR-002**: Clavier `DymKeypad` partagé (dym_ui), aussi utilisé pour encaisser chez la vendeuse.

## Success Criteria *(mandatory)*

- **SC-001**: Missions, remise et gains capturés et conformes à la planche 05.
- **SC-002**: Analyse et tests verts.
