# Feature Specification: Marque (logo, icônes, splash, accueils animés)

**Feature Branch**: `feat/082-marque`

**Created**: 2026-11-13

**Status**: Draft

**Input**: Demande du porteur (2026-11-13) : « Intègre le logo en utilisant les nouvelles couleurs
actuelles, fais le splashscreen, et fais les onboarding animées » ; signature « Réalisé par Kete »
(Kete a réalisé l'application). Features C-ONB-01, V-ONB-01, L-ONB-01 (accueil des trois apps).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reconnaître DYM au premier regard (Priority: P1)

Sur le téléphone, chaque app a son icône (sac DYM ; fond vert pour la cliente, clair pour la
vendeuse, plantain pour le livreur). Au lancement : écran système clair avec le sac, puis le sac se
dessine, les légumes arrivent des coins, « DoYourMarket » monte, l'accroche de l'app apparaît et
« Réalisé par Kete » en bas ; le logo respire tant que la session se restaure (2 s minimum).

### User Story 2 - Comprendre DYM en trois gestes (Priority: P1)

Accueil de la cliente : trois scènes animées (le sac se remplit ; plusieurs boutiques, un panier ;
paiement validé puis livraison). Vendeuse et livreur : une scène de leur métier. Aucune photo d'un
lieu propre à un pays.

### Edge Cases

- Animations réduites : pose finale affichée, aucun mouvement.
- Paysage : splash contenu (logo à taille raisonnable), scène à gauche du texte.
- Hors ligne au démarrage : écran de reprise inchangé.

## Requirements *(mandatory)*

- **FR-001**: `DymSplash`, `DymBrandSceneView`, `DymMadeBy` dans `dym_ui` (Lottie, décision 0018).
- **FR-002**: textes par `dym_l10n` (`brandMadeByPrefix`, `brandMakerName`).
- **FR-003**: icônes Android (héritées, adaptatives, monochromes) et iOS ; splash natif Android
  (avant et après Android 12) et iOS, fond `#FAFAF7`.

## Success Criteria *(mandatory)*

- **SC-001**: analyse et tests verts ; captures relues ; vidéos du lancement et de l'accueil sur le
  téléphone de test pour les trois apps.
