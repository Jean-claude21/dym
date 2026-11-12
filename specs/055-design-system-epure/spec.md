# Feature Specification: Design system « Épuré » et pages d'entrée

**Feature Branch**: `feat/055-design-system-epure`

**Created**: 2026-11-11

**Status**: Draft

**Input**: Spec `design-system-epure` de la roadmap (Phase 14). Design « Épuré, formes tenues » validé
par le porteur produit le 2026-11-11 ([PARCOURS.md](../../docs/design/PARCOURS.md), planches de
[`docs/design/screens/epure/`](../../docs/design/screens/epure/)). Le nouveau design s'applique
strictement ; chaque page doit être propre et belle.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Toutes les apps changent d'habillage d'un coup (Priority: P1)

1. **Given** n'importe quelle page des quatre apps, **When** elle s'affiche, **Then** elle suit le
   design « Épuré » : fond `#FAFAF7`, Inter, un seul vert `#145C43`, filets plutôt qu'ombres, rayons de
   10 à 12 px (puces et filtres compris), barre de navigation plate avec indicateur au-dessus de
   l'onglet actif.
2. **Given** une page qui utilise des widgets Material directement (barres, cartes, champs, puces,
   feuilles, onglets, interrupteurs), **When** elle s'affiche, **Then** ces widgets suivent le même
   design, sans modification de la page.

### User Story 2 - De belles pages d'entrée (Priority: P1)

1. **Given** une personne qui ouvre l'app cliente pour la première fois, **When** la bienvenue
   s'affiche, **Then** elle voit trois photos du quotidien de Lomé en pleine largeur, un message par
   écran (jamais posé sur la photo), « Passer », puis « Continuer avec mon email » et Google.
2. **Given** l'app vendeuse ou livreur, **When** la bienvenue s'affiche, **Then** elle voit une photo du
   métier, le nom de l'app, trois promesses avec icône, puis les mêmes boutons, sur fond clair.
3. **Given** l'équipe sur ordinateur, **When** elle ouvre l'admin, **Then** la connexion montre la photo
   du marché en pleine hauteur à gauche et le formulaire posé sur le fond, sans dégradé.
4. **Given** les étapes email, code et profil, **When** elles s'affichent, **Then** le titre fait 30 px,
   le libellé du champ reste visible pendant la saisie, l'astuce du code est discrète (pas de jaune), et
   un bouton désactivé reste lisible (fond discret, texte gris).

### User Story 3 - Accessibilité des composants (Priority: P2)

1. **Given** un lecteur d'écran, **When** il parcourt un bouton, une puce, une ligne de menu ou une
   carte produit, **Then** chacun est un nœud distinct avec son action « toucher ».
2. **Given** une jauge décorative déjà dite en texte, **Then** elle est hors de l'arbre d'accessibilité.

### Edge Cases

- Petit téléphone (360 × 640), texte agrandi à 130 %, téléphone couché : rien ne déborde ; la photo
  de bienvenue se réduit, jamais les boutons.
- Photo absente ou réseau coupé : fond menthe à la place.
- Un appelant passe encore une teinte à une carte produit ou une tuile de rayon : ignorée (menthe).

## Requirements *(mandatory)*

- **FR-001**: Les valeurs DOIVENT venir de `docs/design/tokens/dym.tokens.json` (régénéré dans `dym_ui`).
- **FR-002**: Une seule couleur d'action par écran ; jaune réservé au cash et aux notes.
- **FR-003**: Texte ≥ 14 px (12 px toléré sous une icône de navigation), contraste AA, cibles ≥ 48 px.
- **FR-004**: Aucune ombre sauf les éléments flottants ; aucun dégradé ni flou.
- **FR-005**: Aucun texte en dur ; photos des pages d'entrée ≤ 130 Ko chacune (WebP).
- **FR-006**: Hors périmètre grocery interdit dans les textes (pas de boissons préparées).

## Success Criteria *(mandatory)*

- **SC-001**: Captures de contrôle des pages d'entrée et de la galerie conformes aux planches.
- **SC-002**: `melos run analyze` et `melos run test` verts ; contrastes du thème mesurés ≥ AA.

## Assumptions

- Les écrans des apps sont restructurés par les specs suivantes de la phase 14 ; cette spec fournit le
  thème, les composants et les pages d'entrée.
- Les photos d'ambiance sont générées (sans texte ni logo) et pourront être remplacées par de vraies
  photos du terrain.
