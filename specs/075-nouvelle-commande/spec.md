# Feature Specification: Nouvelle commande impossible à manquer

**Feature Branch**: `feat/075-nouvelle-commande`

**Created**: 2026-11-13

**Status**: Draft

**Input**: Point 3 de la liste validée par le porteur (2026-11-13) : « son impossible à manquer, plein
écran, accepter en un geste, compte à rebours visible ». Features V-05 (commandes), V-06 (refus
automatique, spec 066).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Alerte sur tous les onglets (Priority: P1)

Quel que soit l'onglet ouvert, une nouvelle commande ouvre une alerte plein écran : « Nouvelle
commande ! », prénom, articles, mode, montant en grand, « Réponds avant 13:35 · 14 min restantes »,
« Voir la commande » ou « Plus tard ». Son et vibration se répètent jusqu'à la réponse.

### User Story 2 - Compte à rebours partout (Priority: P1)

Chaque commande en attente porte « Réponds avant 13:35 · 14 min restantes » (rouge sous 5 minutes) ;
le détail rappelle l'heure du refus automatique.

### Edge Cases

- Commande traitée ailleurs (autre téléphone) : l'alerte disparaît.
- Plusieurs commandes : la plus récente est annoncée, « 1 autre commande attend ».

## Requirements *(mandatory)*

- **FR-001**: heure limite `respond_by` calculée en SQL (délai du pays), dans la liste et le détail.
- **FR-002**: temps réel d'abord, relecture toutes les 30 s en filet.

## Success Criteria *(mandatory)*

- **SC-001**: pgTAP 630 ; tests du guetteur et de l'alerte ; captures relues.
