# Plan : Pilote, côté apps

**Spec** : [spec.md](spec.md) · **Branche** : `feat/016-pilot-hardening` (empilée sur `feat/015-messaging`)

## Technique

- **Base** (`db/migrations/0018_pilot_hardening.sql`) :
  - `reviews` (une par commande, statut publié ou retiré) ; `app.leave_review`, `app.reply_review`
    (Function, notifications) ; lectures `store_reviews` (publique), `my_store_reviews`,
    `order_review` ; note ajoutée à `app.store_summary` ;
  - `public.reorder` : réutilise `cart_add` article par article, écarte ce qui n'est plus en vente ;
  - `support_tickets`, `support_messages` ; `open_ticket`, `reply_ticket`, `my_tickets` ;
  - modèles de push `review_received`, `review_replied`, `support_replied(_vendor)`.
- **Function** : `POST /v1/orders/:id/review`, `POST /v1/reviews/:id/reply`.
- **Dart** : `pilot_models.dart` ; `ReviewRepository`, `SupportRepository`, `ReorderRepository` ;
  `PublicStore.rating`.
- **Apps** : cliente (63 depuis le suivi, 64 depuis la page boutique, réachat) ; vendeuse (65
  depuis « Ma boutique ») ; aide (66) partagée dans `dym_account` (« Moi »).

## Constitution

- Règles en SQL (qui note, quand, une fois ; qui répond ; réachat au prix serveur).
- Événements serveur sans donnée personnelle.
- Phase 3 construite avant le gate de la phase 2 : **dérogation du porteur produit du
  2026-10-10**, consignée dans la roadmap. Les maquettes 63 à 66 restent à valider.

## Dérogations

Gate de la phase 2 (constitution I) : voir ci-dessus.
