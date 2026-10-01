# Data Model — 001 dym_ui design system

Aucune persistance. Modèles en mémoire.

## dym_core

### Currency

| Champ | Type | Règle |
|---|---|---|
| `code` | String | ISO 4217, 3 lettres majuscules (`XOF`, `GHS`) |
| `minorUnits` | int | 0 à 3 (`XOF` = 0, `GHS` = 2) |
| `symbol` | String | Affiché (`F CFA`, `GH₵`) |
| `locale` | String | Locale de formatage (`fr`, `en`) |

Constantes fournies pour la démonstration : `Currency.xof`, `Currency.ghs`. En production, les devises
viendront de la table `currencies` (spec `reference-data`).

### Money

| Champ | Type | Règle |
|---|---|---|
| `amountMinor` | int | Entier, peut être 0 ; jamais de flottant |
| `currency` | Currency | Obligatoire |

Opérations : `+` (même devise, sinon `ArgumentError`), `* int` (quantité ≥ 0), comparaisons,
`isZero`, `format()` → chaîne selon `currency`.

Exemples attendus : `Money(4100, xof).format()` → `4 100 F CFA` (espace fine insécable possible) ;
`Money(8815, ghs).format()` → montant en cedis avec 2 décimales.

## dym_gallery (démonstration)

### DemoCountry

`code` (`TG`, `GH`), `currency`, `city` (« Bè, Lomé » / « Osu, Accra »), `demoRate` (facteur appliqué
aux prix de démonstration en F CFA pour produire des prix en cedis ; uniquement pour la démo).

### DemoStore

`id`, `name`, `origin` (`marche` | `maison` | `magasin`), `area` (quartier), `distanceLabel`, `avatar`
(asset), `cover` (asset), `openingLabel`.

Boutiques : Étal d'Akossiwa (marché, Bè), Les jus d'Esi (maison, Tokoin), Alimentation Kodjo
(magasin, Bè Kpota), Le jardin de Yawa (maison, Adakpamé), Épices de Dédé (marché, Bè).

### DemoProduct

`id`, `name`, `unitLabel` (le tas, la botte, la boîte, 1 L…), `priceXof` (int), `storeId`, `image`
(asset), `badge` (`none` | `promo(-20 %)` | `arrivage`).

### DemoCartLine

`productId`, `quantity`. Le panier de démonstration de l'écran 5 doit totaliser 3 400 F CFA + 700 F de
livraison = 4 100 F CFA, montant repris à l'écran 6 (FR-017).

### ReferenceScreen

`id` (01 à 08), `title`, `referenceAsset` (image validée), `builder` (écran reproduit).

## Origine de boutique (dym_ui)

Énumération `StoreOrigin { marche, maison, magasin }` exposée par `dym_ui` pour le badge ; libellés
fournis par l'appelant. Couleurs : `color.origin.*` des tokens.
