# Feature Specification: Socle et design system DYM, avec galerie de validation

**Feature Branch**: `feat/001-dym-ui-design-system`

**Created**: 2026-10-01

**Status**: Draft

**Input**: User description: "Socle monorepo et design system dym_ui avec une app galerie de validation : thème issu des tokens validés, polices embarquées, composants des écrans validés, galerie qui reproduit les 8 écrans de référence avec animations et sélecteur de pays Togo/Ghana, images de démonstration générées avec ChatGPT ; le porteur produit valide dym_ui en comparant la galerie aux écrans de référence."

## Contexte

La direction de design « Le marché de Lomé, livré chez toi » est validée
(`docs/design/DESIGN_DIRECTION.md`, décision 0009) avec 8 écrans de référence
(`docs/design/screens/`) et des tokens (`docs/design/tokens/dym.tokens.json`). Avant de construire
les apps cliente, vendeuse et admin, le porteur produit veut vérifier que la bibliothèque d'interface
partagée (`dym_ui`) reproduit fidèlement ce design. Cette spec livre le socle du dépôt, cette
bibliothèque, et une app « galerie » qui sert uniquement à la validation.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Valider les écrans de référence dans la galerie (Priority: P1)

Le porteur produit ouvre la galerie sur un téléphone Android ou un navigateur, choisit un des 8
écrans de référence (splash, accueil, rayon, page boutique, panier, suivi, « Où vends-tu ? »,
commande reçue) et le compare à l'image validée correspondante : couleurs, typographie, contenants
du marché, badges d'origine, hiérarchie, espacements, textes.

**Why this priority**: c'est l'objet même de la spec. Tant que les écrans ne sont pas jugés fidèles,
aucune app ne doit être construite sur `dym_ui`.

**Independent Test**: ouvrir chaque écran de la galerie à côté de son image de référence et cocher
la grille de conformité ; l'histoire est réussie si les 8 écrans sont jugés conformes.

**Acceptance Scenarios**:

1. **Given** la galerie ouverte, **When** le porteur produit choisit « Accueil », **Then** il voit la
   pastille « Bè, Lomé », la pastille de délai avec le zem, la recherche, « Racheter », « Boutiques
   ouvertes près de toi » avec les trois badges d'origine, les rayons dans leurs contenants et le
   mini-panier, dans la palette et la typographie validées.
2. **Given** un écran de la galerie, **When** il le compare à son image de référence, **Then** chaque
   élément de la grille de conformité (couleur d'action unique, badges, prix, contenants, textes) est
   identique ou l'écart est consigné.
3. **Given** n'importe quel écran, **When** il est affiché, **Then** une mention discrète indique
   que les données sont des données de démonstration.

---

### User Story 2 - Ressentir les animations clés (Priority: P2)

Le porteur produit déclenche les moments animés : l'apparition du splash, l'ajout d'un produit (le
bouton « + » devient un compteur, le mini-panier apparaît ou se met à jour), la sonnerie visuelle de
nouvelle commande côté vendeuse, et le zem qui avance sur l'écran de suivi.

**Why this priority**: les animations donnent la sensation de qualité attendue, mais les écrans
statiques fidèles priment.

**Independent Test**: déclencher chacune des 4 animations et vérifier qu'elle est fluide, courte et
qu'elle ne bloque jamais l'action suivante.

**Acceptance Scenarios**:

1. **Given** l'écran Rayon, **When** le porteur produit touche « + » sur un produit, **Then** le
   bouton se transforme en compteur « − 1 + », le mini-panier apparaît ou met à jour son nombre
   d'articles, de boutiques et son total, sans saccade.
2. **Given** l'écran Suivi, **When** il s'affiche, **Then** le zem progresse le long de l'itinéraire
   jusqu'à sa position courante.
3. **Given** l'écran Commande reçue, **When** il s'affiche, **Then** l'icône centrale pulse comme une
   sonnerie jusqu'à ce qu'une action soit choisie.
4. **Given** le réglage « réduire les animations » du téléphone activé, **When** un écran animé
   s'affiche, **Then** il apparaît directement dans son état final.

---

### User Story 3 - Prouver que la devise suit la configuration du pays (Priority: P2)

Le porteur produit bascule le pays de démonstration de Togo à Ghana : tous les montants affichés
passent du franc CFA au cedi, avec le bon format et le bon nombre de décimales, et la ville affichée
change.

**Why this priority**: démontre le principe « générique par configuration » de la constitution dès
la première brique d'interface.

**Independent Test**: basculer le pays sur l'écran Panier et vérifier chaque montant et le total.

**Acceptance Scenarios**:

1. **Given** le pays Togo, **When** l'écran Panier s'affiche, **Then** les montants sont au format
   « 4 100 F CFA », sans décimales.
2. **Given** la bascule vers Ghana, **When** l'écran Panier s'affiche, **Then** les montants sont en
   cedis avec deux décimales et la ville affichée est une ville du Ghana ; aucun montant ne reste en
   F CFA.

---

### User Story 4 - Parcourir le catalogue du design system (Priority: P3)

Un développeur ou le porteur produit ouvre le catalogue de la galerie : couleurs (avec le contraste
mesuré), typographies, espacements, rayons d'angle, et chaque composant dans ses états (normal,
désactivé, sélectionné, chargement si applicable).

**Why this priority**: utile pour construire les apps suivantes, mais secondaire par rapport à la
validation des écrans.

**Independent Test**: ouvrir le catalogue et vérifier que chaque composant listé dans les exigences
y apparaît avec ses états.

**Acceptance Scenarios**:

1. **Given** le catalogue, **When** on ouvre « Couleurs », **Then** chaque couleur des tokens
   apparaît avec son nom et, pour les couples texte/fond, son ratio de contraste.
2. **Given** le catalogue, **When** on ouvre un composant, **Then** ses états sont présentés côte
   à côte.

### Edge Cases

- Nom de boutique ou de produit très long : le texte est tronqué proprement sur deux lignes au plus,
  sans casser la mise en page.
- Montant élevé (par exemple 1 250 000 F CFA) : le prix reste lisible et ne déborde pas de sa carte.
- Image de démonstration absente ou illisible : un contenant de remplacement neutre s'affiche à la
  place, sans erreur.
- Petit écran (360 × 640) et grand texte système (taille de police augmentée) : aucun texte n'est
  coupé de façon illisible, les cibles tactiles restent d'au moins 48 points.
- Galerie ouverte hors connexion : tout fonctionne, polices et images étant embarquées.

## Requirements *(mandatory)*

### Functional Requirements

**Socle**

- **FR-001**: Le dépôt MUST permettre à un nouveau développeur d'installer la version d'outillage
  épinglée, de résoudre toutes les dépendances et de lancer la galerie avec les commandes documentées
  dans `AGENTS.md`.
- **FR-002**: Le dépôt MUST exécuter en une commande l'analyse statique et les tests de tous les
  packages et apps.

**Argent**

- **FR-003**: Le système MUST représenter un montant par un entier en unités mineures et un code de
  devise ISO 4217, sans nombre à virgule.
- **FR-004**: Le système MUST formater un montant selon la devise et la langue du pays configuré :
  « 4 100 F CFA » pour le Togo (0 décimale), cedis avec 2 décimales pour le Ghana.

**Design system**

- **FR-005**: La bibliothèque d'interface MUST tirer toutes ses couleurs, typographies, espacements,
  rayons, tailles et ombres des tokens validés, sans valeur codée en dur ailleurs.
- **FR-006**: La bibliothèque MUST embarquer les deux familles de polices validées, utilisables sans
  connexion.
- **FR-007**: La bibliothèque MUST fournir les composants suivants, conformes aux écrans validés :
  bouton principal, bouton secondaire, bouton jaune plantain ; puce de filtre ; badge d'origine (au
  marché, fait maison, boutique) ; badge promo ; barre de recherche avec micro et appareil photo ;
  pastille de délai avec zem ; carte produit avec ajout et compteur ; compteur de quantité ;
  mini-panier flottant ; carte boutique ; tuile de rayon ; jauge de livraison offerte ; option de
  paiement ; frise d'étapes ; barre de navigation ; carte de sélection ; avatar ; en-tête de section.
- **FR-008**: Chaque composant interactif MUST offrir une cible tactile d'au moins 48 points et un
  libellé lisible par les lecteurs d'écran.
- **FR-009**: Tout texte affiché par les composants MUST respecter un contraste d'au moins 4,5:1
  avec son fond, conformément aux valeurs mesurées des tokens.
- **FR-010**: Les animations MUST être courtes (moins d'une demi-seconde pour les micro-interactions),
  interruptibles, et désactivées lorsque le téléphone demande de réduire les animations.

**Galerie de validation**

- **FR-011**: La galerie MUST reproduire les 8 écrans de référence avec les mêmes textes, montants,
  noms de boutiques et origines que les images validées.
- **FR-012**: La galerie MUST permettre d'afficher, pour chaque écran, l'image de référence
  correspondante afin de faciliter la comparaison.
- **FR-013**: La galerie MUST offrir un sélecteur de pays Togo / Ghana qui change la devise, le
  format des montants et la ville affichée sur tous les écrans.
- **FR-014**: La galerie MUST présenter un catalogue des tokens et des composants avec leurs états.
- **FR-015**: La galerie MUST signaler visiblement que ses données sont des données de
  démonstration ; elle n'est pas publiée sur les stores.
- **FR-016**: Les images de démonstration (produits dans leurs contenants, vendeuses, couvertures de
  boutiques) MUST être embarquées et cohérentes avec la direction de design.
- **FR-017**: Les montants affichés dans la galerie MUST être cohérents entre les écrans (par exemple
  le total du panier et le montant à payer au suivi).

### Key Entities *(include if feature involves data)*

- **Montant** : valeur entière en unités mineures et devise ISO 4217.
- **Pays de démonstration** : code, devise, langue de formatage, ville affichée.
- **Boutique de démonstration** : nom, origine (au marché, fait maison, boutique), quartier,
  distance, avatar, couverture.
- **Produit de démonstration** : nom, unité du marché, prix, boutique, image dans son contenant,
  éventuel badge (promo, arrivage du jour).
- **Écran de référence** : identifiant, image validée, écran reproduit correspondant.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Le porteur produit juge conformes les 8 écrans reproduits, en une seule séance de
  comparaison d'au plus 30 minutes.
- **SC-002**: 100 % des couleurs, tailles de texte, espacements et rayons visibles dans la galerie
  proviennent des tokens validés.
- **SC-003**: 100 % des couples texte/fond affichés atteignent au moins 4,5:1 de contraste.
- **SC-004**: La bascule Togo / Ghana met à jour 100 % des montants affichés, sans aucun montant
  restant dans l'ancienne devise.
- **SC-005**: Les écrans s'affichent et s'animent sans saccade visible sur un Android d'entrée de
  gamme (2 Go de RAM).
- **SC-006**: Un nouveau développeur lance la galerie en moins de 15 minutes en suivant uniquement la
  documentation.
- **SC-007**: L'analyse statique et l'ensemble des tests passent sans erreur.

## Assumptions

- La galerie est un outil interne de validation ; ses données de démonstration ne relèvent pas de
  la règle « aucune donnée fictive en production » de la constitution.
- Les personnes et produits des images de démonstration sont générés par IA (ChatGPT via Codex) et
  seront remplacés par de vraies photos dans les apps.
- La validation se fait sur téléphone Android et dans un navigateur ; iOS n'est pas requis pour
  cette spec.
- Thème clair uniquement, conformément à la décision 0009.
- Le backend (Neon), l'authentification et les vraies apps cliente, vendeuse et admin font l'objet
  de specs ultérieures ; cette spec ne crée que ce qui est nécessaire à la validation de `dym_ui`.
- Les polices Nunito et Nunito Sans restent à confirmer sur appareil ; si elles sont jugées
  inadaptées, seul le token de police change.
