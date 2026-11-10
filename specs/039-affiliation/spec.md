# Feature Specification: Affiliation des créatrices

**Feature Branch**: `feat/039-affiliation`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `affiliation` de la roadmap (Phase 10, VISION §3 « Affiliation ») : taux,
attribution, commission en attente puis versée, annulation, antifraude, tableau de bord.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - La vendeuse fixe sa commission (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une vendeuse, **When** elle ouvre « Mes contenus », **Then** elle voit la commission
   versée aux créatrices et le minimum du pays, et choisit un palier pour sa boutique.
2. **Given** un produit précis, **When** elle lui donne un taux propre, **Then** il prime sur celui
   de la boutique ; « Comme la boutique » le retire.
3. **Given** un taux sous le minimum du pays, **When** elle le demande, **Then** il est refusé.

### User Story 2 - La créatrice gagne sur les ventes qu'elle amène (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une cliente qui ajoute au panier depuis un post de créatrice (produit tagué, story,
   « Tout pour la faire »), **When** elle commande dans le délai du pays (7 jours par défaut),
   **Then** chaque ligne amenée crée une commission « en attente » : taux du produit, sinon de la
   boutique, jamais sous le minimum ; un ingrédient générique est payé au minimum du pays.
2. **Given** une commande livrée, **When** le délai de réclamation fraîcheur est passé, **Then** la
   commission est versée sur le wallet de la créatrice, une seule fois, et elle est prévenue.
3. **Given** une commande refusée ou annulée, ou une cliente remboursée (ou une ligne rendue)
   avant l'échéance, **Then** la commission est annulée.

### User Story 3 - Tableau de bord et transparence (Priority: P2)

**Acceptance Scenarios**:

1. **Given** une créatrice, **When** elle ouvre son studio, **Then** elle voit ses gains en
   attente, versés, et ses dernières commissions avec leur état.
2. **Given** un post de créatrice avec produits ou ingrédients, **When** il passe dans le fil,
   **Then** il porte la mention « Contenu rémunéré ».

### Edge Cases

- Ses propres achats : aucune commission.
- Même appareil (identifiant d'installation aléatoire) ou même foyer (téléphone ou coordonnées
  d'une adresse de la créatrice) : aucune commission.
- Contenu d'une boutique : pas d'affiliation (la vendeuse vend déjà).
- Plusieurs contenus : le dernier touché avant l'achat l'emporte, article par article.
- Lancement : DYM paie à la place de la vendeuse si le pays l'a activé.

## Requirements *(mandatory)*

- **FR-001**: Taux, attribution, montants, échéance et versement DOIVENT être calculés en base ;
  l'app n'envoie que le contenu et les variantes ajoutées.
- **FR-002**: Le versement DOIT passer par le grand livre (une écriture par commission, équilibrée),
  payé par le solde de la boutique ou par DYM pendant le lancement.
- **FR-003**: Minimum, délai d'attribution et prise en charge du lancement DOIVENT être des
  réglages du pays.
- **FR-004**: Aucune donnée personnelle dans les événements ; l'identifiant d'appareil est aléatoire.
- **FR-005**: Événements serveur : `commission_earned`, `commission_paid`.
- **FR-006**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Gate de la phase 10 : une commission est versée après un achat livré.
- **SC-002**: Le grand livre reste équilibré.

## Assumptions

- Les commissions ne sont pas reprises après versement (le délai de réclamation est passé).
- Les points ou bonus des contenus sans produit (VISION) sont hors de cette spec.
- Le cadre légal de l'affiliation, pays par pays, reste à obtenir (VISION §6).
