# Data Model — 002 Mise en page adaptative

Pas de données persistées. Les « entités » sont des valeurs de design et de mise en page.

## Classe de fenêtre (`DymWindowClass`)

| Valeur | Largeur (dp) | Navigation | Marge latérale |
|---|---|---|---|
| `compact` | < 600 | barre basse | 16 |
| `medium` | 600 – 839 | rail (libellé sous l'icône) | 24 |
| `expanded` | 840 – 1 199 | rail (libellé sous l'icône) | 32 |
| `large` | ≥ 1 200 | rail étendu (libellé à côté) | 32 |

Règles : un seuil appartient à la classe supérieure (600 → `medium`). Les classes sont ordonnées
(`compact < medium < expanded < large`) pour écrire « à partir de étendue ».

## Tokens de mise en page (`docs/design/tokens/dym.tokens.json`)

| Token | Valeur | Usage |
|---|---|---|
| `breakpoint.medium` | 600 | seuil compacte → moyenne |
| `breakpoint.expanded` | 840 | seuil moyenne → étendue |
| `breakpoint.large` | 1 200 | seuil étendue → large |
| `layout.gutter-compact` | 16 | marge latérale |
| `layout.gutter-medium` | 24 | marge latérale |
| `layout.gutter-expanded` | 32 | marge latérale |
| `layout.gutter-large` | 32 | marge latérale |
| `layout.content-max` | 1 200 | largeur maximale d'un contenu (grilles, accueil) |
| `layout.form-max` | 600 | largeur maximale d'un formulaire ou d'une lecture |
| `layout.floating-max` | 560 | largeur maximale d'un élément flottant (mini-panier) |
| `layout.rail-width` | 88 | largeur du rail |
| `layout.rail-extended-width` | 220 | largeur du rail étendu |

Validation : `breakpoint.medium < breakpoint.expanded < breakpoint.large` ;
`form-max ≤ content-max` (tests de tokens).

## Format de prévisualisation (galerie, `DeviceFormat`)

| Nom | Largeur × hauteur | Classe |
|---|---|---|
| Téléphone | 412 × 915 | compacte |
| Téléphone paysage | 915 × 412 | étendue |
| Tablette | 800 × 1 280 | moyenne |
| Tablette paysage | 1 280 × 800 | large |
| Bureau | 1 440 × 900 | large |

## Tailles de référence des tests (FR-013)

360 × 640, 412 × 915, 915 × 412, 640 × 360, 800 × 1 280, 1 280 × 800, 1 440 × 900 ; textes à
100 % et 130 % ; Togo et Ghana.
