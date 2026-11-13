# Feature Specification: Marque (logo, icônes, splash animé)

**Feature Branch**: `feat/082-marque`

**Created**: 2026-11-13

**Status**: Draft

**Input**: Demande du porteur (2026-11-13) : « Intègre le logo en utilisant les nouvelles couleurs
actuelles, fais le splashscreen » ; signature « Réalisé par Kete »
(Kete a réalisé l'application). Features C-ONB-01, V-ONB-01, L-ONB-01 (accueil des trois apps).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reconnaître DYM au premier regard (Priority: P1)

Sur le téléphone, chaque app a son icône (sac DYM ; fond vert pour la cliente, clair pour la
vendeuse, plantain pour le livreur). Au lancement, exactement `splash-anime.gif` à sa vitesse
(4 s) : le sac se dessine, les légumes arrivent des coins, « DoYourMarket » monte, l'accroche de
l'app et « Réalisé par Kete » apparaissent en fondu. L'écran système avant l'app n'a que le fond
clair ; si l'app charge encore après 4 s, le logo respire.

### User Story 2 - Un accueil parlant, sans lieu propre à un pays (Priority: P1)

Les accueils gardent leurs photos, jugées plus parlantes que des scènes animées par le porteur
(2026-11-13). Le monument visible derrière la vendeuse et le livreur est effacé.

### Edge Cases

- Animations réduites : pose finale affichée, aucun mouvement.
- Paysage : splash contenu (logo à taille raisonnable).
- Hors ligne au démarrage : écran de reprise inchangé.

## Requirements *(mandatory)*

- **FR-001**: `DymSplash`, `DymMadeBy` dans `dym_ui` (Lottie, décision 0018).
- **FR-002**: textes par `dym_l10n` (`brandMadeByPrefix`, `brandMakerName`).
- **FR-003**: icônes Android (héritées, adaptatives, monochromes) et iOS ; splash natif Android
  (avant et après Android 12) et iOS, fond `#FAFAF7`.

## Success Criteria *(mandatory)*

- **SC-001**: analyse et tests verts ; captures relues ; vidéos du lancement et de l'accueil sur le
  téléphone de test pour les trois apps.
