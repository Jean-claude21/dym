# Feature Specification: Mise en page adaptative du design system et de la galerie

**Feature Branch**: `feat/002-responsive-layout`

**Created**: 2026-10-01

**Status**: Draft

**Input**: User description: "Mise en page adaptative (responsive) du design system dym_ui et de la galerie : classes de fenêtre standard (compacte < 600, moyenne 600-839, étendue 840-1199, large ≥ 1200), tokens de mise en page, navigation adaptative (barre basse, rail, rail étendu), contenu centré et limité, colonnes de grille selon la largeur, mini-panier qui ne s'étire pas ; les 8 écrans de la galerie s'adaptent (grilles, contenu centré, panier en deux colonnes en étendue, aucun débordement en paysage) ; prévisualisation téléphone, paysage, tablette, bureau ; rendu téléphone portrait validé inchangé."

## Contexte

La spec 001 a livré `dym_ui` et une galerie dont les 8 écrans ont été validés par le porteur
produit (2026-10-01). Ces écrans ne sont vérifiés qu'en téléphone portrait. Or les apps DYM
tourneront aussi :

- sur téléphone en paysage (rotation involontaire, téléphones posés sur l'étal) ;
- sur tablette Android, notamment chez les vendeuses qui gèrent les commandes au comptoir ;
- dans un navigateur, pour l'admin (Flutter Web) et une éventuelle vitrine web.

Sans règles communes, chaque app réinventerait sa mise en page large, avec des écrans étirés sur
1 400 px, des grilles à deux colonnes géantes et des barres flottantes de toute la largeur. Cette
spec donne au design system les règles et les briques adaptatives, et les prouve sur les 8 écrans
validés. Elle prépare directement les specs `admin-ops` et `vendor-dashboard` (Phase 2).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Les écrans validés restent utilisables à toutes les tailles (Priority: P1)

Une cliente tourne son téléphone en paysage, une vendeuse ouvre l'app sur sa tablette, un membre
de l'équipe ouvre la vitrine sur un ordinateur : chaque écran validé reste lisible, sans
débordement, sans élément étiré de façon absurde, avec le même design.

**Why this priority**: c'est la garantie de base. Un écran qui déborde ou casse en paysage est un
défaut visible dès le premier jour, quelle que soit l'app.

**Independent Test**: afficher chacun des 8 écrans aux tailles de référence (téléphone portrait,
téléphone paysage, tablette portrait, tablette paysage, bureau), dans les deux pays, et vérifier
l'absence de débordement et le respect des largeurs maximales.

**Acceptance Scenarios**:

1. **Given** un téléphone en paysage (915 × 412), **When** on ouvre n'importe lequel des 8 écrans,
   **Then** aucun contenu ne déborde et tout reste accessible par défilement.
2. **Given** un écran de bureau (1 440 × 900), **When** on ouvre le panier, le suivi, « Où
   vends-tu ? » ou « Commande reçue », **Then** le contenu est centré et ne dépasse pas la largeur
   maximale de formulaire.
3. **Given** n'importe quelle largeur, **When** le mini-panier est visible, **Then** il ne dépasse
   pas sa largeur maximale et reste centré au-dessus du contenu.
4. **Given** un téléphone portrait de 412 × 915, **When** on compare un écran à sa capture validée
   de la spec 001, **Then** le rendu est identique.

---

### User Story 2 - Le contenu profite de la place disponible (Priority: P2)

Sur tablette ou ordinateur, la cliente voit plus de produits et de rayons à la fois, et le panier
présente les articles à gauche et le récapitulatif de paiement à droite.

**Why this priority**: au-delà de « ne pas casser », c'est ce qui rend l'app agréable sur grand
écran, et c'est le modèle que reprendront l'admin et le tableau de bord vendeuse.

**Independent Test**: comparer le nombre de colonnes des grilles et la disposition du panier entre
téléphone, tablette et bureau.

**Acceptance Scenarios**:

1. **Given** le rayon Légumes, **When** la largeur passe de téléphone à tablette puis bureau,
   **Then** la grille passe de 2 colonnes à au moins 3, puis au moins 4, sans que les cartes
   produit dépassent leur largeur maximale.
2. **Given** l'accueil, **When** la largeur augmente, **Then** la grille des rayons affiche plus de
   tuiles par ligne et les cartes « Racheter » gardent une taille proche de celle du téléphone.
3. **Given** le panier en classe étendue ou large, **When** il s'affiche, **Then** les articles par
   boutique sont dans une colonne et la livraison, le paiement et le bouton « Payer » dans une
   autre, toujours visibles.

---

### User Story 3 - La navigation suit la taille de l'écran (Priority: P2)

Sur téléphone, la navigation principale est la barre basse validée. Sur tablette, elle devient un
rail latéral ; sur grand écran, un rail plus large avec les libellés à côté des icônes.

**Why this priority**: une barre basse de 1 400 px de large est inutilisable sur ordinateur, et
l'admin web en a besoin dès sa première spec.

**Independent Test**: afficher l'accueil aux quatre classes de fenêtre et vérifier le type de
navigation, l'élément actif et le changement d'élément au toucher ou au clic.

**Acceptance Scenarios**:

1. **Given** une fenêtre compacte, **When** l'accueil s'affiche, **Then** la barre basse validée est
   présente, identique à la spec 001.
2. **Given** une fenêtre moyenne ou étendue, **When** l'accueil s'affiche, **Then** un rail latéral
   montre les mêmes destinations avec icône et libellé, et l'élément actif est signalé de la même
   façon (vert profond et trait).
3. **Given** une fenêtre large, **When** l'accueil s'affiche, **Then** le rail présente les libellés
   à côté des icônes.
4. **Given** n'importe quelle classe, **When** on active une destination, **Then** elle devient
   active et chaque destination reste une cible d'au moins 48 dp avec un libellé lisible par les
   lecteurs d'écran.

---

### User Story 4 - Le porteur produit prévisualise chaque écran à chaque taille (Priority: P3)

Dans la galerie, le porteur produit choisit un format (téléphone, téléphone paysage, tablette,
bureau) et voit l'écran rendu à cette taille, même depuis un téléphone ou un petit écran.

**Why this priority**: c'est l'outil de validation de cette spec ; il ne sert pas aux utilisateurs
finaux.

**Independent Test**: ouvrir un écran dans la galerie, changer de format et constater le
changement de mise en page.

**Acceptance Scenarios**:

1. **Given** un écran ouvert dans la galerie, **When** on choisit « Tablette », **Then** l'écran est
   rendu à la taille d'une tablette, réduit proportionnellement si la fenêtre est plus petite.
2. **Given** un format autre que « Téléphone », **When** on regarde la barre d'outils, **Then** le
   mode « Comparer » est indisponible (les références n'existent qu'en téléphone portrait).

### Edge Cases

- Fenêtre redimensionnée en direct sur ordinateur : la mise en page change de classe sans perte
  d'état (panier, quantités, filtre sélectionné).
- Largeur exactement égale à un seuil (600, 840, 1 200) : la classe supérieure s'applique.
- Téléphone en paysage avec peu de hauteur (360 de haut) : les en-têtes à hauteur fixe ne masquent
  pas le contenu ; tout reste accessible par défilement.
- Texte agrandi à 130 % sur tablette et bureau : aucun débordement.
- Très grande fenêtre (2 560 px) : le contenu reste limité et centré, le fond remplit le reste.
- Ghana : montants en cedis à 2 décimales, plus longs, sans débordement à toutes les tailles.
- Animations désactivées : les changements de disposition se font sans animation.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le design system DOIT définir quatre classes de fenêtre selon la largeur disponible :
  compacte (< 600), moyenne (600 à 839), étendue (840 à 1 199) et large (≥ 1 200), un seuil
  appartenant à la classe supérieure.
- **FR-002**: Les valeurs de mise en page DOIVENT être des tokens de design, au même titre que les
  couleurs : seuils, marge latérale par classe (16 / 24 / 32 / 32), largeur maximale du contenu
  (1 200), largeur maximale d'un formulaire ou d'une page de lecture (600) et largeur maximale d'un
  élément flottant (560).
- **FR-003**: Le design system DOIT fournir une structure de navigation principale adaptative : barre
  basse en compacte, rail latéral en moyenne et étendue, rail avec libellés à côté des icônes en
  large, avec les mêmes destinations, le même élément actif et les mêmes règles d'accessibilité.
- **FR-004**: Le design system DOIT fournir un conteneur qui limite la largeur du contenu à une
  valeur maximale, le centre et applique la marge latérale de la classe courante.
- **FR-005**: Le design system DOIT fournir un calcul du nombre de colonnes d'une grille à partir de
  la largeur disponible, d'une largeur minimale de tuile et de bornes (minimum, maximum).
- **FR-006**: Le mini-panier flottant NE DOIT PAS dépasser la largeur maximale d'un élément flottant
  ; au-delà, il est centré.
- **FR-007**: L'accueil DOIT adapter le nombre de tuiles de rayon par ligne et garder aux cartes
  « Racheter » une largeur proche de celle du téléphone.
- **FR-008**: Le rayon et la page boutique DOIVENT adapter le nombre de colonnes de produits (2 en
  téléphone portrait, davantage au-delà).
- **FR-009**: Le panier DOIT passer en deux colonnes (articles / livraison, paiement et total) en
  classe étendue et large.
- **FR-010**: Le suivi, « Où vends-tu ? » et « Commande reçue » DOIVENT limiter leur contenu à la
  largeur maximale de formulaire, centré.
- **FR-011**: Aucun des 8 écrans NE DOIT déborder aux tailles de référence (FR-013), dans les deux
  pays, avec le texte à 100 % et à 130 %.
- **FR-012**: En téléphone portrait (classe compacte), le rendu des 8 écrans DOIT rester identique à
  celui validé en spec 001.
- **FR-013**: Tailles de référence : téléphone portrait 360 × 640 et 412 × 915, téléphone paysage
  915 × 412 et 640 × 360, tablette portrait 800 × 1 280, tablette paysage 1 280 × 800, bureau
  1 440 × 900.
- **FR-014**: La galerie DOIT permettre de prévisualiser chaque écran aux formats téléphone,
  téléphone paysage, tablette (portrait et paysage) et bureau, réduits si la fenêtre est trop
  petite, le mode « Comparer » n'étant proposé qu'en téléphone.
- **FR-015**: La galerie DOIT fournir des captures de contrôle des 8 écrans en tablette et en
  bureau, consultables sans lancer l'app.
- **FR-016**: Les règles existantes restent obligatoires à toutes les tailles : cibles tactiles
  ≥ 48 dp, contraste AA, animations désactivables, libellés pour lecteurs d'écran.

### Key Entities

- **Classe de fenêtre**: catégorie de largeur (compacte, moyenne, étendue, large) qui détermine
  navigation, marges et densité.
- **Tokens de mise en page**: seuils, marges latérales, largeurs maximales (contenu, formulaire,
  élément flottant).
- **Format de prévisualisation**: taille logique simulée dans la galerie (nom, largeur, hauteur).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Les 8 écrans s'affichent sans aucun débordement aux 7 tailles de référence, dans les
  2 pays, à 100 % et 130 % de texte (224 combinaisons vérifiées automatiquement).
- **SC-002**: Les 8 captures téléphone portrait validées en spec 001 sont reproduites à
  l'identique.
- **SC-003**: Sur bureau, aucun bloc de contenu de formulaire ne dépasse 600 de large et aucun
  contenu ne dépasse 1 200 ; le mini-panier ne dépasse jamais 560.
- **SC-004**: Le rayon affiche 2 colonnes en téléphone portrait, au moins 3 en tablette portrait
  et au moins 4 en tablette paysage et bureau.
- **SC-005**: Le porteur produit valide les captures tablette et bureau des 8 écrans en moins de
  15 minutes, sans lancer l'app.

## Assumptions

- Les seuils suivent les classes de fenêtre Material 3 (600 / 840 / 1 200), standard reconnu et
  déjà connu des outils Flutter.
- Le téléphone portrait reste la cible principale (constitution VIII) ; la tablette et le bureau
  n'ajoutent pas de nouveaux écrans ni de nouvelles fonctions, seulement des dispositions.
- Aucune nouvelle maquette n'est produite : les dispositions larges dérivent des écrans validés et
  sont validées par les captures de contrôle (constitution II : la maquette de référence reste
  celle du téléphone).
- La classe se détermine par la largeur seulement ; la hauteur réduite du paysage est absorbée par
  le défilement.
- Pas de thème sombre (décision 0009), pas de mode deux volets maître-détail généralisé : seul le
  panier passe en deux colonnes dans cette spec ; l'admin définira ses propres écrans.
- La rotation de l'écran n'est pas bloquée par les apps.
