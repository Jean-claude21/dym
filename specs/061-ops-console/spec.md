# Feature Specification: Console des opérations « Épuré »

**Feature Branch**: `feat/061-ops-console`

**Created**: 2026-11-11

**Status**: Draft

**Input**: Spec `ops-console` de la roadmap (Phase 14). Planche
[06](../../docs/design/screens/epure/06-operations.webp) et [PARCOURS.md](../../docs/design/PARCOURS.md)
§4.4. Features A-OPS, A-ORD, A-SUP, A-FIN, A-CFG, A-AUD.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Sept domaines (Priority: P1)

1. **Given** l'équipe, **Then** la navigation propose sept domaines au lieu de onze onglets : En direct,
   Commandes, Support, Comptes, Finances, Configuration, Journal ; un domaine qui regroupe plusieurs
   écrans les présente en puces (Support : demandes, litiges, modération ; Comptes : boutiques,
   clientes ; En direct : opérations, tableau de bord).

### User Story 2 - En direct (Priority: P1)

1. **Given** En direct, **Then** titre et date ; chiffres-clés des 24 h en ligne (en attente, en
   préparation, prête, en route, livrées, encaissé, livreurs en ligne) ; à surveiller en pastilles ;
   commandes en retard en premier (retard en rouge), signaux de fraude (Écarter, Confirmer), cash des
   livreurs à recevoir.

### Edge Cases

- Téléphone : trois domaines dans la barre, le reste dans « Plus ».
- Pas de centre d'opérations pour le pays : En direct ouvre le tableau de bord.

## Requirements *(mandatory)*

- **FR-001**: Aucune règle nouvelle ; chaque action reste journalisée avec sa raison.
- **FR-002**: Aucun texte en dur.

## Success Criteria *(mandatory)*

- **SC-001**: Capture d'En direct sur ordinateur conforme à la planche 06.
- **SC-002**: Analyse et tests verts.
