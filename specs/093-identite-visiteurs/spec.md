# Feature Specification: Identité par app et visiteuses

**Feature Branch**: `feat/093-identite-visiteurs`

**Created**: 2026-11-16

**Status**: Done

**Input**: Retours des premiers essais (porteur, 2026-11-16) : chaque app a sa couleur (fond vert
pour la vendeuse, clair pour la cliente), le splash suit ; on découvre l'app sans s'inscrire ;
message trompeur « Enregistrement impossible » sur une page qui ne charge pas. Phase 15.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reconnaître son app (Priority: P1)

Icône et splash aux couleurs de l'app : cliente fond clair (sac vert), vendeuse fond vert (sac
blanc, anse plantain), livreur fond plantain, admin vert profond (web).

**Acceptance**: splash natif et animé de la couleur de l'app ; icônes Android et web régénérées.

### User Story 2 - Découvrir sans compte (Priority: P1)

« Découvrir sans compte » sur la bienvenue cliente : choix du quartier (position ou liste), puis
accueil, marché, Cuisine, boutiques et produits sans session. Le panier, le compte, les
notifications et l'ajout au panier ouvrent la connexion (retour possible). La visiteuse revenue
arrive directement à l'accueil.

**Acceptance**: visiteuse connue → accueil au démarrage ; ajout au panier → connexion, sans
message d'erreur.

### User Story 3 - Message juste (Priority: P2)

Page qui ne charge pas : « La page n'a pas pu se charger », distinct de l'échec d'enregistrement.

## Requirements *(mandatory)*

- **FR-001**: `DymSplashTone` (light, brand, plantain), animation recolorée en mémoire.
- **FR-002**: `icons.py` génère icônes Android, splash natif et icônes web des quatre apps.
- **FR-003**: `VisitorPlaceStore` (dym_platform) : lieu gardé sur l'appareil.
- **FR-004**: parcours `onBrowse` dans `dym_auth` ; lectures publiques déjà permises par la base
  (rôle anonyme).
