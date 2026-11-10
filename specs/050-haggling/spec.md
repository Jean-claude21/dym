# Feature Specification: Marchandage dans la limite de la vendeuse

**Feature Branch**: `feat/050-haggling`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `haggling` de la roadmap (Phase 13, VISION §3 « Différence » : « Marchandage dans la
limite fixée par la vendeuse — le geste du marché »).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - La vendeuse fixe sa limite (Priority: P1)

1. **Given** une boutique, **When** la vendeuse choisit une remise maximale (5 à 30 %, ou « pas de
   marchandage »), **Then** ses produits deviennent marchandables.
2. **Given** une limite de boutique, **When** elle fixe pour un produit une autre limite ou « jamais »,
   **Then** ce produit suit son propre réglage.
3. **Given** des marchandages, **When** elle ouvre l'écran, **Then** elle voit les derniers (quantité,
   offre, prix obtenu, statut) et le nombre de marchés conclus de la semaine, sans l'identité de la cliente.

### User Story 2 - La cliente marchande (Priority: P1)

1. **Given** un produit marchandable, **When** la cliente propose un prix à l'unité pour une quantité,
   **Then** la réponse est immédiate : au-dessus du plancher, c'est conclu et la ligne est mise au
   panier à ce prix pour 2 heures ; en dessous, la vendeuse propose un contre-prix valable 15 minutes.
2. **Given** un contre-prix, **When** la cliente l'accepte, **Then** la ligne est au panier à ce prix.
3. **Given** un prix conclu, **When** elle commande, **Then** la commande prend ce prix et le consomme.

### Edge Cases

- La limite de la vendeuse n'est jamais montrée à la cliente.
- Pas de marchandage sur sa propre boutique, ni au prix affiché ou au-dessus.
- 3 propositions par produit et par jour.
- Au-delà de la quantité marchandée, ou après 2 heures, le prix du jour revient (le panier le signale).

## Requirements *(mandatory)*

- **FR-001**: Plancher, contre-prix, durée et prix du panier DOIVENT être décidés en base.
- **FR-002**: Événements serveur : `haggle_proposed`, `haggle_accepted`, `haggle_limit_set`.
- **FR-003**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Une cliente obtient une réponse en un geste après sa saisie.

## Assumptions

- Le contre-prix est calculé (milieu entre l'offre et le prix, jamais sous le plancher) : la vendeuse
  n'a pas à répondre elle-même. Une réponse manuelle pourra venir si le terrain le demande.
- Le marchandage s'applique au panier de la cliente ; les espaces partagés et les commandes
  programmées gardent le prix du jour.
