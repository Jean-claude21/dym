# Feature Specification: Livraison suivie

**Feature Branch**: `feat/096-livraison-suivie`

**Created**: 2026-11-16

**Status**: Done

**Input**: Décisions du porteur (2026-11-16) : frais selon la distance, suivi en direct, codes de
récupération et de livraison, lien de suivi partagé par n'importe quelle messagerie, outils du
livreur, livreurs propres à la boutique, validation des comptes ; puis « rayon souple » et prix de la
livraison au km configurable par l'admin comme dans une grande app. Phase 15.

## User Scenarios & Testing *(mandatory)*

### US1 — Frais justes, rayon souple (P1)

Les frais dépendent de la distance de la boutique à la porte (position exacte de l'adresse). L'admin
règle par pays (ou ville) : mode au km (prise en charge, distance incluse, prix du km) ou par
tranches, minimum, plafond, arrondi, supplément longue distance, majorations horaires (soir,
week-end, heures de pointe), et voit le résultat dans un simulateur. Au-delà du rayon de la
boutique, la livraison reste possible jusqu'à la distance maximale du pays (« longue distance · à
confirmer ») ; au-delà, retrait seul. Les nouvelles boutiques reçoivent le rayon proposé par leur
ville ; le curseur de la vendeuse va jusqu'au maximum du pays. Les frais propres de la boutique
priment toujours.

### US2 — Suivi en direct et partage (P1)

La cliente voit la boutique, sa porte et le livreur sur la carte, avec les minutes restantes, relus
toutes les 15 s. « Partager le suivi » crée un lien de 24 h (WhatsApp, sinon copié) qui s'ouvre
dans n'importe quel navigateur sans compte : porte arrondie à ~100 m, prénom du livreur seulement.

### US3 — Codes et outils du livreur (P1)

Le livreur montre un QR à 6 chiffres ; la vendeuse le scanne (ou le tape) et la commande part avec
lui (5 essais). La remise à la cliente garde son code (spec 042). Pendant une course, la position
est envoyée toutes les 30 s (jamais d'historique). « Cliente injoignable » prévient la cliente et
conseille 10 min d'attente ; « SOS » alerte l'équipe avec la position.

### US4 — Livreurs de la boutique (P2)

La vendeuse ajoute ses livreurs DYM par leur numéro et leur confie une commande ; la course apparaît
chez le livreur.

### US5 — Validation des comptes (P2)

Avec le drapeau `account_review` (par pays), une boutique publiée passe « en validation » et un
nouveau livreur « en attente » (pas de mise en ligne). L'admin valide ou refuse (motif obligatoire,
envoyé au compte), audité et notifié.

## Requirements *(mandatory)*

- **FR-001** Migration 0089 : `delivery_pricing`, `delivery_surcharges`, `delivery_fee_bands`,
  `delivery_settings`, `cities.default_delivery_radius_m`, `app.distance_fee`, `app.store_reaches_point` ;
  `cart_quote`, `my_cart`, `place_order`, `discover_stores`, `update_store` à jour (la position de la
  porte décide quand elle est connue).
- **FR-002** Suivi : `courier_positions`, `courier_ping`, `order_tracking`, `share_tracking`,
  `tracking_by_token` ; page publique `GET /t/:token` (Functions, MapLibre, OpenFreeMap).
- **FR-003** Récupération : `my_pickup_code`, `store_confirm_pickup` ; `courier_transition` refuse
  `out_for_delivery` sans scan.
- **FR-004** Incidents : `delivery_incidents`, `courier_report_unreachable`, `courier_sos`,
  `admin_delivery_incidents`, `admin_resolve_incident`.
- **FR-005** Livreurs de la boutique : `store_couriers`, `store_add_courier`, `store_remove_courier`,
  `store_assign_courier` (permission d'équipe `orders`).
- **FR-006** Validation : statuts `review`/`rejected` (boutique), `pending`/`rejected` (livreur),
  `admin_pending_accounts`, `admin_review_account`.
- **FR-007** Admin : écrans Livraison (tarif, majorations, distance max, rayon par ville,
  simulateur), Comptes à valider, Incidents ; chaque réglage audité et protégé par permission.
- **FR-008** Événements : `tracking_shared`, `courier_unreachable_reported`, `courier_sos`.
