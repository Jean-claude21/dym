# Feature Specification: Qualité des écrans

**Feature Branch**: `feat/068-screen-quality`

**Created**: 2026-11-13

**Status**: Draft

**Input**: Défauts relevés le 2026-11-12 en jouant une commande complète sur l'émulateur Android
distant, et liste des « points à corriger pour un haut niveau ».

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Qui livre ? (Priority: P1)

Avec un livreur DYM assigné : la vendeuse voit « Livreur DYM : Kofi » et son téléphone, lit « Le
livreur DYM encaisse 800 F CFA et te les remet », et n'a plus « Partir livrer » ni « Livrée » (la base
refuse aussi). La cliente voit « Kofi te livre » et son téléphone dans le suivi. Sans livreur DYM, la
vendeuse livre elle-même comme avant.

### User Story 2 - Formulaires et clavier (Priority: P1)

Clavier ouvert : l'action quitte le bas de l'écran et suit le contenu ; rien n'est caché (résultats de
recherche de quartier compris). Les champs annoncent leur libellé au lecteur d'écran.

### User Story 3 - Après la commande (Priority: P2)

« Commande envoyée » suit l'acceptation des vendeuses en direct (et toutes les 20 s en filet).

### User Story 4 - Langue (Priority: P2)

Le profil prend la langue du pays choisi si l'app la parle (Togo : français, même sur un téléphone en
anglais) ; sinon celle de l'appareil ; modifiable dans « Moi ».

## Requirements *(mandatory)*

- **FR-001**: `order_json` porte `courier` (`is_dym`) ; `transition_order` refuse à la vendeuse
  `out_for_delivery` et `delivered` si un livreur DYM est assigné (`courier_assigned`) ; l'équipe garde
  le statut forcé.
- **FR-002**: aucun texte en dur.

## Success Criteria *(mandatory)*

- **SC-001**: pgTAP `570_courier_roles.sql` (7).
- **SC-002**: tests d'écran : clavier, lecteur d'écran, langue du profil ; analyse et tests verts.
