# DYM — Métriques et plan de mesure

## Métrique principale (North Star)

> **Commandes livrées et payées par semaine.**

Elle n'augmente que si les trois preuves V1 avancent ensemble : offre (Fatou), demande (Awa),
fiabilité (ops).

## KPIs de vérité

| KPI | Définition | Seuil | Hypothèse |
|---|---|---|---|
| Conversion | Commandes payées / sessions avec panier non vide | > 25 % | H3 |
| Délai de livraison | Médiane commande créée → livrée | < 4 h | H5 |
| Taux de livraison | Commandes livrées / commandes acceptées | > 90 % | H5 |
| Réachat 30 j | Clientes avec ≥ 2 commandes en 30 jours | > 30 % | H3 |
| Activation vendeuse | Inscription → première commande reçue | < 24 h | H1 |
| Réactivité vendeuse | Médiane commande créée → acceptée | < 15 min | H9 |
| Multi-boutiques | Commandes avec ≥ 2 boutiques | ≥ 15 % | H2 |
| Résolution incident | Médiane ouverture → résolution | < 1 h | Preuve 3 |

## Plan d'instrumentation

- Les événements sont écrits dans la table Postgres `events` (pas d'outil tiers en V1) :
  `id, occurred_at, actor_id, actor_role, app, country_code, name, entity_type, entity_id, props jsonb`.
- Nommage : `objet_verbe_passé` en snake_case (ex. `order_created`, `product_published`).
- Les événements métier critiques sont émis **côté serveur** (SQL/Functions), jamais seulement
  depuis l'app, pour qu'ils ne puissent pas manquer.
- Aucune donnée personnelle dans `props` (pas de téléphone, d'email ni d'adresse).
- Tout événement lié à une boutique porte `store_origin` (`marche`, `maison`, `magasin`) pour suivre
  H11, et tout événement de commande porte `stores_count` pour suivre H2.

### Événements minimum de la phase 1

| Événement | Émis par | Sert à |
|---|---|---|
| `user_signed_up`, `user_signed_in` | Serveur | Activation |
| `store_created`, `store_opened`, `store_closed` | Serveur | Activation vendeuse |
| `product_published`, `product_stock_changed` | Serveur | H1 |
| `ai_product_suggestion_shown`, `ai_product_suggestion_accepted` | App + serveur | H8 |
| `search_performed`, `product_viewed`, `cart_item_added` | App | Conversion |
| `voice_search_used`, `photo_search_used` (résultat, latence ; jamais le contenu) | Serveur | H10 |
| `copilot_proposed` (articles, boutiques, manquants, latence) | Serveur | H10 |
| `copilot_cart_added` (articles ajoutés, refusés) | App | H10 |
| `content_published` (type, produits tagués), `content_product_clicked`, `content_reported` (cible, motif) | Serveur | H10 |
| `vendor_broadcast_sent` (segment, destinataires, produit joint) | Serveur | H12 |
| `checkout_started`, `order_created` | App / serveur | Conversion, H2 |
| `payment_initiated`, `payment_succeeded`, `payment_failed` | Serveur | Paiements |
| `order_accepted`, `order_rejected`, `order_status_changed`, `order_delivered`, `order_cancelled` | Serveur | H5, H9 |
| `dispute_opened`, `dispute_resolved` | Serveur | Preuve 3 |
| `admin_action_performed` | Serveur | Audit |
| `wallet_topped_up` (montant, fournisseur), `wallet_payment_succeeded` (montant), `pocket_created` (objectif, arrondi : oui/non) | Serveur | Wallet (spec 025) |
| `shopping_list_saved` (articles, récurrence), `shopping_list_proposed` (articles, boutiques, manquants), `shopping_reminder_sent` (période) | Serveur | Assistant de courses (spec 029) |
| `shopping_list_cart_added` (articles ajoutés, refusés) | App | Assistant de courses (spec 029) |
| `favorite_added` (type), `basket_saved` (lignes), `basket_reordered` (ajoutés, non ajoutés) | Serveur | Carnet (spec 030) |
