# Contrats — Spec 009

## Data API (RPC, rôle `authenticated`)

| Fonction | Paramètres | Retour |
|---|---|---|
| `my_cart` | `p_address uuid null`, `p_modes jsonb {store_id: "delivery"\|"pickup"}`, `p_payment_method uuid null`, `p_country char(2) null` | vue du panier (ci-dessous) |
| `cart_add` | `p_variant uuid`, `p_quantity int = 1` | vue du panier |
| `cart_set_quantity` | `p_variant uuid`, `p_quantity int` (0 : retire) | vue du panier |
| `my_addresses` | — | `[adresse]`, défaut d'abord |
| `save_address` | `p_address jsonb` (id, kind, label, zone_id, landmark, phone, latitude, longitude, is_default) | `[adresse]` |
| `delete_address` | `p_id uuid` | `[adresse]` |
| `set_default_address` | `p_id uuid` | `[adresse]` |
| `my_purchase` | `p_id uuid` | achat avec ses commandes |

Vue du panier :

```json
{
  "country_code": "TG", "currency_code": "XOF",
  "address_id": "…", "zone_id": "…",
  "stores": [{
    "id": "…", "name": "…", "origin": "marche", "zone_name": "…",
    "fulfillment": "delivery", "offers_pickup": true, "is_open": true,
    "issues": ["closed"], "subtotal_minor": 1300, "delivery_fee_minor": 500,
    "lines": [{
      "variant_id": "…", "product_id": "…", "name": "…", "variant_label": "1 L",
      "unit_label": {"fr": "le tas"}, "photo_key": "…", "quantity": 2,
      "unit_price_minor": 500, "amount_minor": 1000, "stock_quantity": null,
      "issues": ["price_changed"]
    }]
  }],
  "payment_methods": [{"id": "…", "provider_code": "cash", "label": {"fr": "…"}}],
  "payment_method_id": "…",
  "item_count": 4, "pickup_count": 2, "delivery_minutes": 45,
  "subtotal_minor": 3400, "delivery_fee_minor": 700, "total_minor": 4100,
  "free_threshold_minor": 4000, "remaining_for_free_minor": 600,
  "blocking": false
}
```

Erreurs : `22023` entrée invalide (autre pays, quantité), `P0002` variante ou adresse inconnue,
`42501` hors session.

## Function `POST /v1/orders`

En-tête `Idempotency-Key: <uuid>` obligatoire. Corps :

```json
{
  "address_id": "…", "modes": {"<store_id>": "delivery"},
  "payment_method_id": "…", "substitution_allowed": true,
  "expected_total_minor": 4100, "country_code": "TG"
}
```

- `201` : achat (`my_purchase`) ; un rejeu avec la même clé rend `200` et le même achat.
- `422` `validation`, `message` ∈ `cart_empty`, `cart_blocked`, `address_required`,
  `payment_not_accepted`, `payment_unavailable`, `total_changed`.
- `401` sans jeton ; `400` clé absente ou invalide.
