# Feature Specification: Découverte côté cliente

**Feature Branch**: `feat/008-discovery`

**Created**: 2026-10-02

**Status**: Draft

**Input**: User description: "Spec `discovery` de la roadmap (Phase 2 ; C-AUTH-05, C-HOME-01/02, C-SEARCH-01..03, C-CAT-01..07) : détection de zone, « Boutiques ouvertes près de toi » avec badges d'origine, rayons (dont « Fait maison »), unités du marché, recherche plein texte, filtres (dont par origine), tri, page boutique, fiche produit."

## Contexte

Awa (cliente, spec 005) ouvre DYM. Elle doit trouver, en moins de 60 secondes (parcours 2) :
- les boutiques ouvertes de son quartier ;
- un rayon ;
- un produit par recherche ;
- puis la fiche du produit, avec ses variantes et son délai (parcours 3).

Les boutiques et les produits viennent des specs 006 et 007.

**Maquettes** :
- validées : 02 (accueil), 03 (rayon), 04 (page boutique) ;
- produites dans la même direction, à valider : 28 (fiche produit), 29 (recherche) et 30
  (filtres).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Awa voit les boutiques ouvertes de son quartier (Priority: P1)

L'accueil affiche, en haut, son quartier (« Bè, Lomé ») et une estimation (« Livré en 35 min »).
Viennent ensuite :
- les boutiques ouvertes qui livrent son quartier, avec leur badge d'origine ;
- les rayons du pays.

Elle peut changer de quartier, ou laisser DYM le proposer à partir de sa position.

**Why this priority**: C-HOME-01 ; sans boutique visible, pas de commande.

**Independent Test**: base réelle avec des boutiques ouvertes, fermées, d'autres quartiers ou
suspendues ; vérifier la liste et l'ordre.

**Acceptance Scenarios**:

1. **Given** des boutiques actives qui livrent Bè, **When** Awa ouvre l'accueil, **Then** elle
   voit d'abord celles qui sont ouvertes maintenant (horaires et interrupteur), puis celles de son
   quartier.
2. **Given** une boutique fermée, suspendue ou qui ne livre pas Bè, **When** l'accueil s'affiche,
   **Then** elle n'est pas dans « Boutiques ouvertes près de toi ».
3. **Given** la position autorisée, **When** Awa touche « Utiliser ma position », **Then** DYM
   propose le quartier le plus proche de sa ville. Elle le confirme ou en choisit un autre.
4. **Given** la position refusée ou indisponible, **When** elle veut changer de quartier, **Then**
   elle cherche son quartier par son nom, sans blocage (aucune liste affichée d'avance).

---

### User Story 2 - Awa cherche et filtre (Priority: P1)

Awa tape « bissap ». Les produits et les boutiques correspondants s'affichent, accents et
majuscules ignorés, mots partiels compris. Elle filtre :
- par origine (« Fait maison ») ;
- par rayon ;
- par prix ;
- sur les seuls produits disponibles.

Elle trie par pertinence ou par prix.

**Why this priority**: C-SEARCH-01..03 ; le chemin le plus court vers un produit.

**Acceptance Scenarios**:

1. **Given** « epices », **When** elle cherche, **Then** les produits « Épices… » sont trouvés.
2. **Given** « biss », **When** elle cherche, **Then** « Jus de bissap » est trouvé (préfixe).
3. **Given** le filtre « Fait maison » et « Disponible seulement », **When** les résultats
   s'affichent, **Then** seuls les produits disponibles de boutiques fait maison restent.
4. **Given** le tri par prix croissant, **When** les résultats s'affichent, **Then** ils sont
   ordonnés par prix.
5. **Given** une recherche, **When** elle est lancée, **Then** l'app enregistre
   `search_performed`, sans le texte saisi.

---

### User Story 3 - Awa parcourt un rayon et une boutique (Priority: P1)

Depuis un rayon (« Légumes ») :
- elle voit les produits disponibles de son quartier, avec leur unité du marché, leur boutique
  et son origine ;
- elle filtre par origine ou sous-rayon.

Depuis une boutique, elle voit :
- son nom, son origine, son quartier, son état (ouverte jusqu'à …) et sa présentation ;
- ses produits, filtrés par catégorie de la boutique.

**Why this priority**: C-HOME-02, C-CAT-01/02.

**Acceptance Scenarios**:

1. **Given** le rayon « Légumes », **When** il s'affiche, **Then** il contient les produits de
   ses sous-rayons.
2. **Given** une boutique fait maison avec retrait, **When** sa page s'affiche, **Then** la mention
   « adresse partagée avec le livreur uniquement » apparaît, sans adresse.

---

### User Story 4 - Awa consulte une fiche produit (Priority: P2)

La fiche montre :
- les photos, à faire défiler ;
- le nom, la boutique, le prix et l'unité ;
- les variantes, avec leur prix ;
- la disponibilité (« Rupture » si le stock est épuisé) ;
- le délai estimé : préparation de la boutique et livraison de la ville.

**Why this priority**: C-CAT-03..07 ; parcours 3.

**Acceptance Scenarios**:

1. **Given** une variante sans prix propre, **When** elle est choisie, **Then** le prix de base
   s'affiche.
2. **Given** une variante à stock 0 ou un produit en rupture, **When** la fiche s'affiche,
   **Then** le badge « Rupture » est visible.
3. **Given** une fiche ouverte, **When** elle s'affiche, **Then** l'app enregistre
   `product_viewed`.

### Edge Cases

- Aucun quartier dans le profil (visiteur) : premier quartier de la première ville du pays,
  modifiable.
- Recherche vide ou d'un seul caractère : aucune requête.
- Boutique sans photo de produit : illustration de son origine.
- Aucune boutique ouverte : état vide avec les rayons toujours visibles.
- Hors ligne : écran de reprise, sans résultat inventé.
- Prix min supérieur au prix max : filtre refusé côté app.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Les quartiers DOIVENT porter un centre approximatif (latitude, longitude). Une
  fonction propose le quartier le plus proche d'une position, dans la ville la plus proche.
  La position n'est ni stockée, ni envoyée dans un événement.
- **FR-002**: Une fonction DOIT lister les boutiques actives qui livrent un quartier (ou y sont
  situées), avec :
  - l'origine, le quartier, l'état « ouverte maintenant » (interrupteur et horaires, fuseau du
    pays), l'heure de fermeture du jour ;
  - le délai de préparation, une photo de couverture (premier produit publié) et le nombre de
    produits.
- **FR-003**: Les villes DOIVENT porter un délai de livraison indicatif (minutes), qui est une
  donnée de référence. Le délai estimé d'un produit vaut ce délai ajouté au délai de préparation
  de la boutique. Celui de l'accueil part de la boutique ouverte la plus rapide.
- **FR-004**: La recherche DOIT porter sur le nom et la description des produits publiés, et sur
  le nom et la présentation des boutiques actives :
  - accents et casse ignorés, mots partiels acceptés ;
  - filtres : quartier desservi, rayon (sous-rayons compris), origine, prix minimum et maximum
    (en unités mineures), disponibilité ;
  - tris : pertinence, prix croissant, prix décroissant ;
  - pagination.
- **FR-005**: Un rayon DOIT lister les produits disponibles des boutiques qui livrent le
  quartier, sous-rayons compris, avec le filtre par origine.
- **FR-006**: La page boutique et la fiche produit DOIVENT être servies en un appel chacune (3G),
  sans l'adresse ni la propriétaire.
- **FR-007**: L'app cliente DOIT proposer :
  - l'accueil (02), le rayon (03), la page boutique (04) ;
  - la fiche produit (28), la recherche (29) et les filtres (30) ;
  - les onglets Accueil, Rayons et Moi.

  Les événements `search_performed` (propriétés : nombre de résultats, filtres actifs, sans
  texte) et `product_viewed` sont enregistrés.

## Success Criteria *(mandatory)*

- **SC-001**: Depuis l'accueil, un produit cherché est atteint en 2 écrans (recherche, fiche).
- **SC-002**: Aucune donnée privée (adresse, propriétaire, proposition IA) n'est servie par les
  fonctions de découverte (pgTAP).
- **SC-003**: Les écrans s'affichent sans débordement aux 7 tailles, en fr et en, avec le texte
  à 130 %.

## Assumptions

- **Panier.** L'ajout au panier, le mini-panier et « Racheter » arrivent avec `cart-checkout` et
  l'historique des commandes. Les maquettes validées les montrent ; ils ne sont pas construits
  ici.
- **Notes et ventes.** La note, les ventes et l'ancienneté (écran 04) arrivent avec les avis et
  les commandes.
- **Recherche vocale et par photo.** Les icônes de l'écran 02 sont hors du contrat V1 : elles ne
  sont pas affichées.
- **Distance.** Elle est calculée entre centres de quartiers, approximatifs (à vérifier sur le
  terrain), puis arrondie. Elle n'est affichée que si la position a été donnée.
- **Photos de boutique.** Elles arrivent plus tard : la couverture est la photo du premier
  produit publié, sinon l'illustration de l'origine.

## Correction terrain (2026-10-02)

Retour du porteur produit sur l'app réelle : la liste de quartiers affichée d'emblée ne convient
pas, car DYM sera déployée dans plusieurs pays. Aucun nom de lieu n'est donc affiché d'avance.
La personne choisit son adresse :

- soit par sa position (« Utiliser ma position ») : le quartier le plus proche est choisi, le
  pays suit ;
- soit en cherchant son quartier ou sa ville (recherche sans accents ni casse, 6 résultats au
  plus).

Ce choix est partagé par le profil (`dym_auth`) et le sélecteur de quartier de l'accueil
(`DymPlacePicker` de `dym_ui`). L'adresse complète (repère, GPS conservé, adresses enregistrées)
relève de la spec `cart-checkout` (C-ADDR-01..03).
