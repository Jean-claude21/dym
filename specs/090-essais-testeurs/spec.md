# Feature Specification: Préparer les essais avec des testeuses

**Feature Branch**: `feat/090-essais-testeurs`

**Created**: 2026-11-14

**Status**: Draft

**Input**: Demande du porteur (2026-11-14) : moins de cinq testeuses en Afrique (Togo, Côte
d'Ivoire), chacune avec les quatre rôles (cliente, vendeuse, livreur, admin), comptes préremplis,
wallets rechargés, APK Android ; admin en ligne. Features A-SET-01 (pays), C-ACC-01, A-ADM-01.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Tester partout en Afrique de l'Ouest (Priority: P1)

La Côte d'Ivoire est ouverte par configuration : Abidjan et ses communes, moyens de paiement
locaux (simulés, Moneroo prêt mais fermé), mêmes réglages que le Togo.

### User Story 2 - Admin accessible en ligne (Priority: P1)

L'admin est publiée sur Firebase Hosting (staging), avec le logo DYM ; la connexion est autorisée
depuis cette adresse (Neon Auth, Functions).

### Edge Cases

- « Recommander » sans article encore en vente : message, pas de panier vide.
- Champ email : exemple traduit selon la langue.

## Requirements *(mandatory)*

- **FR-001**: migration 0086 (Côte d'Ivoire), pgTAP 750.
- **FR-002**: `firebase.json`, `.firebaserc` (cibles admin et cliente) ; domaines autorisés.
- **FR-003**: `DymLogoMark` (dym_ui) dans l'admin ; photo de l'admin sans monument.

## Success Criteria *(mandatory)*

- **SC-001**: pgTAP ; tests dym_ui, dym_auth, cliente, admin ; admin en ligne, connexion vérifiée.
