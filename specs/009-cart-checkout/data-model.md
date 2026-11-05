# Data Model — Spec 009

Montants : `bigint` en unités mineures, devise du pays (ISO 4217). Toutes les tables ont la
RLS active ; aucune n'accorde `insert`, `update` ou `delete` aux rôles de l'API.

## customer_addresses

| Colonne | Type | Règle |
|---|---|---|
| id | uuid pk | fourni par l'app (rejouable) |
| user_id | uuid → neon_auth.user | propriétaire, `on delete cascade` |
| kind | text | `home`, `work`, `other` |
| label | text null | 1 à 40 caractères |
| zone_id | uuid → zones | quartier actif d'une ville visible |
| landmark | text | 3 à 200 caractères |
| phone | text | `^\+?[0-9 ]{8,20}$` |
| latitude, longitude | numeric(9,6) null | ensemble ou absents |
| is_default | boolean | une seule par cliente (index unique partiel) |
| created_at, updated_at | timestamptz | |

Lecture : propriétaire seulement (RLS). Écriture : `save_address`, `delete_address`,
`set_default_address`. 20 adresses au plus par cliente.

## carts / cart_items

`carts` : `id`, `user_id`, `country_code`, `currency_code`, `updated_at` ; unique
`(user_id, country_code)`.

`cart_items` : `cart_id`, `variant_id` (pk commune), `quantity` 1 à 99,
`unit_price_seen_minor`, `added_at`, `updated_at`.

Lecture et écriture : fonctions seulement (`my_cart`, `cart_add`, `cart_set_quantity`).

## purchases

| Colonne | Type | Règle |
|---|---|---|
| id | uuid pk | |
| user_id | uuid | cliente |
| idempotency_key | uuid | unique avec `user_id` |
| country_code, currency_code | | du panier |
| payment_method_id | uuid → payment_methods | actif, accepté par chaque boutique |
| address | jsonb null | copie : kind, label, zone_id, zone_name, city_name, landmark, phone, latitude, longitude ; nulle si tout est en retrait |
| substitution_allowed | boolean | |
| subtotal_minor, delivery_fee_minor, total_minor | bigint ≥ 0 | total = sous-total + frais |
| created_at | timestamptz | |

## orders

| Colonne | Type | Règle |
|---|---|---|
| id | uuid pk | |
| purchase_id | uuid → purchases | |
| store_id | uuid → stores | |
| fulfillment | text | `delivery`, `pickup` |
| status | text | `pending` (étendu par `order-lifecycle`) |
| currency_code | char(3) | |
| subtotal_minor, delivery_fee_minor, total_minor | bigint ≥ 0 | |
| commission_minor | bigint ≥ 0 | interne, jamais servi à la cliente |
| created_at, updated_at | timestamptz | |

## order_items

`id`, `order_id`, `product_id`, `variant_id`, `product_name`, `variant_label`, `unit_label`
(jsonb), `unit_price_minor`, `quantity`, `amount_minor` (= prix × quantité).

## Lecture (RLS)

- `purchases` : la cliente propriétaire.
- `orders`, `order_items` : la cliente de l'achat ; la propriétaire de la boutique de la
  commande.
- `commission_minor` n'est pas accordé aux rôles de l'API (droits par colonne).

## Calcul (`app.cart_quote`)

Entrées : panier, quartier de livraison (adresse choisie, sinon défaut, sinon profil), modes par
boutique, moyen de paiement, instant.

1. Ligne : prix courant = prix de la variante, sinon du produit. Problèmes : `unavailable`
   (produit non publié, en rupture, variante en stock 0), `stock` (quantité > stock suivi),
   `price_changed` (non bloquant).
2. Boutique : problèmes `suspended`, `closed` (maintenant), `not_delivered` (mode livraison et
   quartier non desservi), `pickup_unavailable`, `payment_not_accepted`.
3. Frais (ville du quartier, sinon pays) : boutiques livrées triées par sous-total décroissant ;
   la première porte la base (ou ses propres frais), les autres le supplément ; tout est
   gratuit si le sous-total livré atteint le seuil.
4. Commission (calculée par `app.place_order`, pas par le devis) : taux du rayon du produit,
   sinon de son rayon parent, sinon du pays ; arrondi à l'unité mineure inférieure, par ligne.
