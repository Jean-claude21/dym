# Contrat d'interface — composants dym_ui

Règles communes :

- Aucun texte en dur : tous les libellés sont des paramètres (`String` ou `Widget`).
- Couleurs, typographies, espacements et rayons viennent exclusivement de `context.dym` (tokens).
- Toute cible tactile ≥ 48 dp ; tout élément interactif a une `Semantics` avec libellé.
- Toute animation passe par `DymMotion` (durée nulle si « réduire les animations »).
- Les montants sont reçus sous forme de `Money` (dym_core) et formatés par le composant.

| Composant | Rôle | Entrées principales | États |
|---|---|---|---|
| `DymButton` | Bouton pleine largeur | `label`, `onPressed`, `variant` (`primary` vert gombo, `secondary` contour, `plantain`), `trailing` (ex. montant) | normal, désactivé, chargement |
| `DymFilterChip` | Puce de filtre / sous-rayon | `label`, `selected`, `onTap` | sélectionnée, non sélectionnée |
| `DymOriginBadge` | Badge d'origine de boutique | `origin` (`StoreOrigin`), `label`, `dense` | marché, maison, magasin |
| `DymPromoBadge` | Badge promo / arrivage | `label`, `tone` (`promo`, `highlight`) | — |
| `DymSearchBar` | Barre de recherche | `hint`, `onTap`, `onMic`, `onCamera` | — |
| `DymDeliveryPill` | Pastille de délai avec zem | `label`, `zemImage` | — |
| `DymProductCard` | Carte produit | `image`, `name`, `unit`, `price`, `store` (nom + origine), `badge`, `quantity`, `onAdd`, `onQuantityChanged`, `layout` (`grid`, `compact`) | quantité 0 (bouton « + ») ↔ quantité ≥ 1 (compteur animé) |
| `DymQuantityStepper` | Compteur − n + | `quantity`, `onChanged`, `min`, `max` | min atteint, max atteint |
| `DymMiniCartBar` | Mini-panier flottant | `itemCount`, `storeCount`, `total`, `label`, `actionLabel`, `onTap`, `thumbnail` | caché (0 article, glisse vers le bas), visible (glisse vers le haut), mise à jour (rebond du compteur) |
| `DymStoreCard` | Carte boutique | `cover`, `avatar`, `name`, `origin`, `originLabel`, `meta` | — |
| `DymAisleTile` | Tuile de rayon | `image`, `label`, `tint`, `badge` | — |
| `DymFreeDeliveryGauge` | Jauge de livraison offerte | `remaining`, `progress` (0–1), `label` | progression animée |
| `DymPaymentOption` | Option de paiement | `icon`, `title`, `subtitle`, `selected`, `onTap` | sélectionnée |
| `DymTimeline` | Frise d'étapes horizontale | `steps` (libellé, état `done` / `current` / `todo`) | — |
| `DymBottomNav` | Navigation basse | `items` (icône, libellé), `currentIndex`, `onTap` | élément actif |
| `DymSelectableCard` | Carte de sélection (ex. « Où vends-tu ? ») | `image`, `title`, `description`, `selected`, `footer`, `onTap` | sélectionnée |
| `DymAvatar` | Avatar rond | `image`, `size`, `presenceDot` | avec / sans pastille |
| `DymSectionHeader` | Titre de section | `title`, `actionLabel`, `onAction` | avec / sans action |

Briques transverses exposées : `DymTheme.light()`, `context.dym` (couleurs, styles, espacements,
rayons), `DymMotion`, `StoreOrigin`, `MoneyText` (affichage d'un `Money` avec style de prix).
