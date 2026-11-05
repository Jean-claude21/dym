# Research — 001 dym_ui design system

## R1 — Polices variables (Nunito, Nunito Sans)

- **Decision** : embarquer les fichiers variables officiels de google/fonts (`Nunito[wght].ttf`,
  `NunitoSans[YTLC,opsz,wdth,wght].ttf`, licence OFL) dans `dym_ui`, déclarés une fois par famille.
- **Rationale** : Google ne publie plus d'instances statiques pour ces familles. Depuis Flutter 3.41,
  `FontWeight` règle aussi l'axe `wght` des polices variables
  ([breaking change officiel](https://docs.flutter.dev/release/breaking-changes/font-weight-variation)),
  donc les poids 400/600/700/800 des tokens s'appliquent sans `FontVariation` manuel. Embarquées,
  elles fonctionnent hors connexion (FR-006).
- **Alternatives** : paquet `google_fonts` (téléchargement à l'exécution, refusé : hors connexion) ;
  instances statiques via services tiers (source non officielle).

## R2 — Des tokens au code

- **Decision** : script Dart `packages/ui/dym_ui/tool/generate_tokens.dart` qui lit
  `docs/design/tokens/dym.tokens.json`, résout les alias `{groupe.token}` et génère
  `lib/src/tokens/dym_tokens.g.dart` (constantes typées). Le thème (`DymTheme.light()`) et deux
  `ThemeExtension` (`DymColors`, `DymTextStyles`) sont construits à partir de ces constantes ;
  les composants lisent `context.dym`. Une commande Melos régénère, et la CI vérifie que le fichier
  généré est à jour (`git diff --exit-code`).
- **Rationale** : une seule source de vérité (FR-005, SC-002), lisible par d'autres outils (format
  W3C DTCG), sans dépendance de génération lourde.
- **Alternatives** : Style Dictionary (Node, outillage supplémentaire) ; recopie manuelle (dérive
  garantie).

## R3 — Animations

- **Decision** : animations implicites Flutter (`AnimatedSwitcher`, `AnimatedSize`,
  `AnimatedSlide`, `TweenAnimationBuilder`) pour les micro-interactions (« + » → compteur, mini-panier,
  jauge) ; `flutter_animate` pour les entrées orchestrées (splash, pulsation de sonnerie) ; trajet du
  zem calculé sur un `Path` (`PathMetric.getTangentForOffset`). Un utilitaire `DymMotion` centralise
  les durées (≤ 450 ms pour les micro-interactions) et renvoie `Duration.zero` quand
  `MediaQuery.disableAnimationsOf(context)` est vrai (FR-010).
- **Rationale** : léger sur Android 2 Go ; aucun asset d'animation à produire.
- **Alternatives** : Rive (assets à concevoir, poids) ; Lottie (même raison).

## R4 — Icônes

- **Decision** : icônes Material arrondies pour l'interface (`storefront_rounded` pour « Boutique »,
  `home_rounded` pour « Fait maison », `beach_access_rounded` pour l'étal sous parasol « Au marché »,
  recherche, micro, appareil photo…) ; le zem est une illustration générée (WebP transparent) car
  aucune icône standard ne le représente fidèlement.
- **Rationale** : `flutter_svg` n'est pas nécessaire dans cette spec (pas de SVG à afficher) ; on ne
  l'ajoute pas (sobriété des dépendances).
- **Alternatives** : dessiner un zem en SVG à la main (qualité incertaine).

## R5 — Images de démonstration

- **Decision** : générées avec ChatGPT (gpt-image-2) via Codex CLI, fond transparent pour les
  produits dans leurs contenants, puis converties en WebP avec alpha (produits 512 px, avatars 256 px,
  couvertures 1024 × 576, tuiles de rayon 512 px). Stockées dans `apps/dym_gallery/assets/demo/`,
  jamais dans `dym_ui`.
- **Rationale** : cohérence avec les écrans validés, poids maîtrisé, séparation nette entre la
  bibliothèque (sans contenu) et la galerie (avec démonstration).
- **Alternatives** : recadrer les écrans de référence (basse définition, incohérent).

## R6 — Tests et comparaison visuelle

- **Decision** : tests unitaires (`dym_core`), tests widget des composants (`dym_ui`), et tests golden
  des 8 écrans de la galerie en 360 × 800, polices réelles chargées dans `flutter_test_config.dart`,
  images préchargées. Les goldens sont étiquetés `golden` et générés sur la machine de développement ;
  la CI les exclut, le rendu des polices variant selon le système.
- **Rationale** : produit des PNG comparables côte à côte aux écrans validés (US1), sans appareil.
- **Alternatives** : `golden_toolkit` (abandonné) ; `alchemist` (dépendance de plus, inutile ici).

## R7 — Melos et FVM

- **Decision** : `melos` 8.9 configuré dans le `pubspec.yaml` racine avec `sdkPath: .fvm/flutter_sdk`
  (lien créé par FVM vers 3.47.5). Toutes les commandes Melos utilisent ainsi le SDK épinglé, même si
  un autre Flutter est installé globalement (cas de la machine actuelle : 3.38.6).
- **Rationale** : impossible d'exécuter par erreur une autre version (décision 0006).

## R8 — Argent

- **Decision** : `Money(amountMinor: int, currency: Currency)` et `Currency(code, minorUnits, symbol,
  locale)` en Dart pur ; formatage par `intl` `NumberFormat.currency` avec les décimales de la devise.
  XOF : 0 décimale, symbole « F CFA », locale `fr` → « 4 100 F CFA ». GHS : 2 décimales, symbole
  « GH₵ », locale `en` → par exemple « GH₵88.15 ». Opérations : addition, multiplication par une
  quantité, comparaison ; refus d'additionner deux devises différentes.
- **Rationale** : constitution IV (entiers, devise ISO, pas de flottant).

## R9 — Analyse statique

- **Decision** : `very_good_analysis` 11 à la racine, avec `public_member_api_docs` désactivée (les
  apps et la galerie ne sont pas des API publiques ; la documentation est exigée sur les composants
  `dym_ui` par revue, pas par le linter).
- **Rationale** : rigueur élevée sans bruit.

## R10 — Galerie : navigation et comparaison

- **Decision** : app Flutter simple (`MaterialApp` + routes nommées), sans Stacked : c'est un outil
  de validation, pas une app produit (constitution VI n'impose Stacked qu'aux apps produit et
  features). Chaque écran a un bouton « Comparer » qui affiche l'image de référence en surimpression
  avec un curseur d'opacité, ou côte à côte sur grand écran (FR-012). Le pays de démonstration est un
  `ValueNotifier` global en haut de l'arbre (FR-013).
