# Feature Specification: Catalogue de la vendeuse

**Feature Branch**: `feat/007-catalog`

**Created**: 2026-10-02

**Status**: Draft

**Input**: User description: "Spec `catalog` de la roadmap (Phase 2 ; V-CAT-01..03, V-PROD-01..09, V-PRIX-01/02) : catégories de boutique, produits, multi-photos, variantes, stock par variante, rupture en un geste, archivage, prix par variante, photo → nom, rayon et description proposés par l'IA."

## Contexte

La boutique de Fatou est ouverte (spec 006). Il lui faut des produits. Le parcours 10 de
`MOCKUPS.md` (« Mets en vente ce produit ») vise moins de 60 secondes, sans aide :
- hypothèse H1 : la vendeuse publie et maintient son catalogue seule ;
- hypothèse H8 : la proposition « photo → fiche » fait gagner du temps sans erreurs gênantes.

**Maquettes** : écrans 24 à 27, produits dans la direction validée, à valider avec cette spec.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fatou publie un produit à partir d'une photo (Priority: P1)

Fatou touche « Ajouter un produit » et prend une photo. DYM propose un nom, un rayon et une
description ; elle corrige si besoin. À l'étape 2, elle saisit le prix et l'unité du marché, puis
le stock. Elle touche « Publier le produit » : le produit apparaît dans « Mes produits ».

**Why this priority**: sans produit publié, aucune commande ; c'est l'hypothèse H1.

**Independent Test**: publier un produit avec une photo, un prix et un stock (serveur simulé côté
app, base réelle côté SQL) ; vérifier le produit publié en base et l'événement `product_published`.

**Acceptance Scenarios**:

1. **Given** une boutique active, **When** Fatou prend une photo, **Then** la photo est envoyée,
   et une proposition (nom, rayon, description) s'affiche si le service est disponible.
2. **Given** le service de proposition indisponible ou en échec, **When** la photo est envoyée,
   **Then** Fatou remplit la fiche elle-même, sans valeur inventée.
3. **Given** une fiche sans photo, nom, rayon ou prix, **When** elle veut publier, **Then** le
   bouton reste inactif (et la base refuse).
4. **Given** un produit publié à partir d'une proposition, **When** il est publié, **Then** la base
   enregistre `ai_product_suggestion_accepted` avec le nombre de champs corrigés.
5. **Given** une interruption réseau pendant la publication, **When** elle réessaie, **Then** le
   produit n'est pas créé deux fois.

---

### User Story 2 - Fatou gère son stock en un geste (Priority: P1)

Dans « Mes produits », chaque produit montre son prix, son stock et un interrupteur « En stock ».
Un geste le met en rupture ou le réactive.

**Why this priority**: V-PROD-05 ; un stock faux est la première cause de commande annulée.

**Independent Test**: basculer l'interrupteur et vérifier en base l'état et `product_stock_changed`.

**Acceptance Scenarios**:

1. **Given** un produit en stock, **When** Fatou touche l'interrupteur, **Then** il est en rupture,
   l'événement est enregistré et l'interrupteur reflète l'état serveur.
2. **Given** un produit avec variantes, **When** elle change le stock d'une variante, **Then** seul
   ce stock change.
3. **Given** un produit, **When** elle l'archive, **Then** il disparaît pour les clientes et reste
   restaurable.

---

### User Story 3 - Fatou ajoute des variantes et des prix différents (Priority: P2)

À l'étape 2, Fatou ajoute des variantes (« 50 cl », « 1 L »). Chacune a son prix (ou le prix de
base) et son stock.

**Why this priority**: V-PROD-08/09, V-PRIX-02 ; courant pour les jus, sauces et pagnes.

**Acceptance Scenarios**:

1. **Given** deux variantes à prix différents, **When** le produit est publié, **Then** chaque
   variante garde son prix et son stock.
2. **Given** une variante sans prix, **When** une cliente la consulte, **Then** le prix de base
   s'applique.

---

### User Story 4 - Fatou range ses produits dans ses catégories (Priority: P2)

Fatou crée ses catégories (« Jus », « Sirops »), les renomme, les ordonne et les archive. Un
produit peut appartenir à plusieurs catégories.

**Why this priority**: V-CAT-01..03, V-PROD-07 ; la page boutique (spec `discovery`) les affiche.

**Acceptance Scenarios**:

1. **Given** une catégorie archivée, **When** une cliente lit la boutique, **Then** elle ne la voit
   pas ; ses produits restent visibles.
2. **Given** deux catégories de même nom (casse ignorée), **When** elle crée la seconde, **Then**
   c'est refusé.

---

### User Story 5 - Le catalogue est protégé (Priority: P1)

Les clientes lisent les produits publiés des boutiques actives : photos, variantes, prix, stock,
catégories non archivées. Elles ne voient ni les brouillons, ni les archives. Une vendeuse ne
modifie que son catalogue.

**Independent Test**: pgTAP sur les lectures publiques et les écritures croisées.

**Acceptance Scenarios**:

1. **Given** une autre vendeuse, **When** elle modifie le produit, le stock ou la catégorie de
   Fatou, **Then** c'est refusé.
2. **Given** une photo dont la clé n'appartient pas à la boutique, **When** elle est rattachée à
   un produit, **Then** c'est refusé.
3. **Given** un prix envoyé avec une devise, **When** le produit est enregistré, **Then** la devise
   est celle de la boutique, quelle que soit la valeur envoyée.

### Edge Cases

- Nom de produit hors 2 à 80 caractères, description au-delà de 500 : refusés.
- Prix nul ou négatif, stock négatif : refusés.
- Au plus 5 photos et 10 variantes par produit ; au plus 30 catégories par boutique.
- Boutique suspendue : le catalogue n'est plus modifiable.
- Unité d'un autre pays : refusée.
- Proposition de rayon inconnue : ignorée (le rayon reste à choisir).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Un produit DOIT porter :
  - un nom (2 à 80) et une description facultative (500 au plus) ;
  - un rayon du référentiel et une unité du marché facultative (référentiel du pays) ;
  - un prix de base en unités mineures, dans la devise de la boutique ;
  - de 1 à 5 photos ;
  - de 1 à 10 variantes : libellé, prix facultatif, stock (entier ≥ 0, ou non suivi).
- **FR-002**: Le produit DOIT avoir un statut :
  - `draft` (brouillon) ;
  - `published` (publié) : il faut une photo, un nom, un rayon, un prix et une variante ;
  - `archived` (archivé).

  Il porte aussi un indicateur « disponible » (rupture). La première publication enregistre
  `product_published`.
- **FR-003**: La création DOIT être idempotente : l'identifiant du produit et de ses variantes
  est fourni par l'app, et une nouvelle tentative ne crée pas de doublon.
- **FR-004**: Mettre en rupture, réactiver ou changer un stock DOIT enregistrer
  `product_stock_changed`.
- **FR-005**: Les photos DOIVENT :
  - être envoyées directement au stockage d'objets, par une URL présignée délivrée par une
    Function à la propriétaire d'une boutique ;
  - porter une clé sous le préfixe de cette boutique ;
  - être compressées sur l'appareil (1 600 px au plus).
- **FR-006**: La proposition DOIT être faite par une Function, avec le modèle configuré dans
  `ai_models` (usage `product_from_photo`). Le rayon proposé est pris parmi les rayons actifs.
  - Si le modèle est inactif ou en échec, la Function répond « indisponible », et l'app passe à
    la saisie manuelle.
  - Chaque proposition est conservée. La base compare la fiche publiée à la proposition :
    `ai_product_suggestion_accepted` avec le nombre de champs corrigés.
  - L'app enregistre `ai_product_suggestion_shown`.
- **FR-007**: Les catégories de boutique DOIVENT :
  - avoir un nom (1 à 40, unique par boutique, casse ignorée) ;
  - être ordonnables, archivables et restaurables ;
  - pouvoir être assignées, plusieurs par produit.
- **FR-008**: Toutes les écritures DOIVENT passer par des fonctions serveur qui vérifient que le
  produit appartient à la boutique active ou en brouillon de la vendeuse (pas suspendue).
- **FR-009**: Les clientes (connectées ou non) DOIVENT lire les produits publiés des boutiques
  actives, avec photos, variantes et catégories non archivées. Elles ne voient ni les brouillons,
  ni les archives, ni les propositions.
- **FR-010**: L'app vendeuse DOIT proposer :
  - « Mes produits » : filtres par catégorie, interrupteur de stock, archivage ;
  - la création ou modification en 2 étapes (photo et fiche, puis prix et stock) ;
  - « Mes catégories ».

  Ces écrans suivent les règles de `dym_ui` : 48 dp, 7 tailles, texte à 130 %, fr et en.

### Key Entities

- **Catégorie de boutique** : nom, ordre, archivée.
- **Produit** :
  - nom, description, rayon, unité, prix de base, devise ;
  - statut, disponibilité ;
  - photos, variantes, catégories de boutique, proposition d'origine.
- **Variante** : libellé, prix facultatif, stock, ordre.
- **Photo** : clé d'objet, ordre.
- **Proposition** : photo, modèle, résultat (nom, rayon, description), date. Elle est privée.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un produit se publie en 2 écrans depuis « Mes produits » (objectif terrain :
  moins de 60 s, H1).
- **SC-002**: La rupture ou la réactivation se fait en 1 geste.
- **SC-003**: 100 % des écritures sur le catalogue d'autrui sont refusées (pgTAP).
- **SC-004**: Une nouvelle tentative de publication ne crée aucun doublon (pgTAP).
- **SC-005**: Les écrans s'affichent sans débordement aux 7 tailles, en fr et en, avec le texte à
  130 %.

## Assumptions

- **Stockage d'objets et modèle d'IA.** Ils sont configurés sur Neon par variables d'environnement
  des Functions. Tant que l'accès Neon manque (décision 0013), ils sont vérifiés par des tests avec
  des fournisseurs simulés, et le modèle reste inactif en base.
- **Miniatures.** Elles sont générées côté serveur plus tard (`ARCHITECTURE.md`). En V1, la photo
  compressée sur l'appareil sert partout.
- **Suppression.** Seul un brouillon se supprime. Un produit publié s'archive, ce qui protège les
  commandes à venir.
- **Unité.** Elle est indicative (« la pièce », « le tas ») ; pas de conversion de quantité.
- **Proposition.** Elle porte sur une seule photo, la première ; une seule langue (fr) pour le
  nom et la description proposés.
