# Feature Specification: Copilote d'intention

**Feature Branch**: `feat/019-intent-copilot`

**Created**: 2026-10-10

**Status**: Draft

**Input**: Spec `intent-copilot` de la roadmap (Phase 4 ; C-SEARCH-06). Elle est construite avant
le gate de la phase 3 (H10 non testée) par décision du porteur produit du 2026-10-10. Elle reste
derrière le flag `intent_copilot`, coupé par défaut.

## Contexte

Awa écrit ou dit « une sauce gombo pour 4 personnes ce soir ». DYM lui propose un panier
multi-boutiques, prix du jour compris. Awa retire ce qu'elle a déjà, puis ajoute le tout au panier.
Ce qui n'a pas été trouvé est dit clairement. Si l'IA ne répond pas, Awa revient à la recherche
habituelle.

**Maquette** à valider : 73 (copilote d'intention).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Proposer un panier (Priority: P1)

Depuis l'accueil, « Dis-moi ce que tu veux cuisiner » ouvre le copilote (73). Awa écrit, parle (voix
de la spec 018) ou photographie un plat. Le copilote affiche :

- les produits proposés, groupés par boutique : nom, quantité, prix ;
- « Je n'ai pas trouvé : … » pour les besoins sans produit ;
- le total, suivi de « + livraison ».

**Acceptance Scenarios**:

1. **Given** le flag actif et des produits en vente dans le quartier, **When** Awa décrit un plat,
   **Then** un panier de 1 à 7 produits est proposé, chiffré par le serveur, en regroupant les
   boutiques autant que possible.
2. **Given** aucune correspondance, **When** Awa décrit une intention, **Then** le copilote dit
   « Je n'ai rien trouvé pour ça » et propose « Chercher moi-même ». Aucun produit n'est inventé.

### User Story 2 - Ajuster puis ajouter (Priority: P1)

Awa retire une ligne (×) : le total est recalculé par le serveur. « Tout ajouter au panier » ajoute
les lignes restantes au panier habituel, avec ses règles (stock, pays), puis ouvre le panier.

### User Story 3 - Revenir à la recherche (Priority: P1)

« Chercher moi-même », ou une IA indisponible, ouvre la recherche habituelle avec le texte d'Awa.

### Edge Cases

- Un produit qui passe en rupture entre la proposition et l'ajout est écarté au rechiffrage ou
  refusé par le panier ; l'écran le signale.
- Hors ligne : message clair, aucune proposition inventée.
- Flag coupé : le point d'entrée n'apparaît pas.

## Requirements *(mandatory)*

- **FR-001**: L'intention est découpée en besoins par une Function :
  - modèle `intent_copilot` lu en base ;
  - 7 besoins au plus, quantité entre 1 et 10 ;
  - jamais de prix produit par l'IA.
- **FR-002**: Le choix et le chiffrage se font en SQL :
  - produits publiés, disponibles et livrés dans le quartier ;
  - d'abord une boutique déjà retenue, puis la pertinence, puis le prix ;
  - variante la moins chère en stock.
- **FR-003**: Le rechiffrage après ajustement passe par la base (`copilot_quote`), 10 lignes au plus.
- **FR-004**: Événements, avec des comptes seulement (jamais le texte de l'intention) :
  - `copilot_proposed` côté serveur : articles, boutiques, manquants, latence ;
  - `copilot_cart_added` côté app.
- **FR-005**: Écran 73 :
  - états vide, chargement, erreur et hors ligne ;
  - sept tailles, texte à 130 %.

## Success Criteria *(mandatory)*

- **SC-001**: Proposition affichée en moins de 3 secondes dans 80 % des cas (latence journalisée).
- **SC-002**: Aucun article proposé hors catalogue publié et disponible (pgTAP).

## Assumptions

- La photo et la voix réutilisent la transcription et la description de la spec 018.
- Substituer un produit par un autre (au lieu de le retirer) : backlog.
