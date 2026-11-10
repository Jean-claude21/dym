# Feature Specification: Antifraude, modération et support assistés

**Feature Branch**: `feat/054-ops-ai`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `ops-center` de la roadmap (Phase 13), seconde partie : « antifraude et modération par
IA, agent support ». VISION §4 : l'agent « Modération et fraude » détecte les abus et les envoie à un
humain ; l'agent « Support » répond, l'humain tranche.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Signaux de fraude (Priority: P1)

1. **Given** des règles par type (seuil réglable en base), **When** le job tourne, **Then** les
   comportements anormaux des dernières 24 h deviennent des signaux, une fois par règle, sujet et jour :
   annulations répétées d'une cliente, refus répétés d'une boutique, appareil partagé par plusieurs
   comptes, codes de remise faux d'un livreur, marchandage en rafale sans achat.
2. **Given** un signal, **When** l'équipe l'écarte ou le confirme, **Then** la décision est auditée ;
   rien n'est suspendu automatiquement.

### User Story 2 - Tri des signalements par l'IA (Priority: P2)

1. **Given** un signalement ouvert et le modèle `moderation_triage` actif, **When** le job tourne,
   **Then** l'IA donne un avis (garder, retirer, incertain) et une raison, affichés dans la modération.

### User Story 3 - Agent support (Priority: P2)

1. **Given** un ticket, **When** l'équipe demande un brouillon, **Then** l'agent rédige une réponse
   courte dans la langue de la personne, sans promesse de remboursement ; l'équipe relit et envoie.

### Edge Cases

- Sans clé ni modèle actif : aucun avis, aucun brouillon ; rien n'est inventé.
- Un échec de l'IA sur un signalement n'arrête pas les autres.

## Requirements *(mandatory)*

- **FR-001**: Les règles de fraude DOIVENT être en SQL, leurs seuils en base.
- **FR-002**: Les modèles d'IA DOIVENT être configurés en base (`ai_models`).
- **FR-003**: Toute décision humaine DOIT être auditée.
- **FR-004**: Événements serveur : `fraud_signals_detected`, `report_triaged`, `support_draft_requested`.

## Success Criteria *(mandatory)*

- **SC-001**: Un signal apparaît dans le centre d'opérations en moins de 15 minutes.

## Assumptions

- L'agent support ne répond pas seul aux personnes : il prépare un brouillon pour l'équipe.
