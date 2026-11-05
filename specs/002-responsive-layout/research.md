# Research — 002 Mise en page adaptative

## R1. Seuils des classes de fenêtre

- **Decision**: compacte < 600, moyenne 600-839, étendue 840-1 199, large ≥ 1 200 (et non
  « très large » ≥ 1 600, inutile ici). Un seuil appartient à la classe supérieure.
- **Rationale**: ce sont les window size classes Material 3, utilisées par Android (Jetpack
  WindowSizeClass) et la documentation Flutter « adaptive design ». Elles sont connues des
  développeurs, et les tablettes Android 8 à 11 pouces tombent en moyenne (portrait) ou en étendue
  (paysage).
- **Alternatives considered**: les seuils Bootstrap (576/768/992/1 200), pensés pour le web et non
  alignés sur Android ; des seuils propres à DYM, sans standard à citer et sans bénéfice.

## R2. Source de la classe : fenêtre ou espace disponible

- **Decision**: deux niveaux.
  - La **classe de fenêtre**, via `MediaQuery.sizeOf(context).width`, pilote la navigation et les
    marges.
  - L'**espace disponible**, via `LayoutBuilder`, pilote les colonnes de grille et les largeurs
    bornées.
- **Rationale**:
  - `sizeOf` ne s'abonne qu'à la taille, pas au clavier ni au padding, donc pas de reconstruction
    inutile.
  - La recommandation Flutter est de décider des colonnes à partir des contraintes réelles, qui
    tiennent compte du rail et des marges. C'est aussi ce qui rend la prévisualisation de la
    galerie fidèle : le `MediaQuery` simulé et les contraintes y sont cohérents.
- **Alternatives considered**:
  - `MediaQuery.of(context)`, qui reconstruit à chaque ouverture du clavier ;
  - `OrientationBuilder`, car l'orientation ne suffit pas : une tablette portrait de 800 n'est pas
    un téléphone.

## R3. Navigation adaptative

- **Decision**:
  - un widget `DymAdaptiveScaffold` qui choisit `DymBottomNav` (compacte), `DymNavRail`
    (moyenne et étendue, libellé sous l'icône) ou `DymNavRail` étendu (large, libellé à côté) ;
  - le corps est le même dans les trois cas, et l'état reste dans le corps, donc il est conservé
    au changement de classe.
- **Rationale**:
  - `flutter_adaptive_scaffold` est abandonné par l'équipe Flutter (2025) ;
  - le `NavigationRail` Material impose un indicateur en pilule non conforme au design validé ;
  - un rail maison fait environ 120 lignes, réutilise les règles de `DymBottomNav`, et l'admin
    en aura besoin.
- **Alternatives considered**: `flutter_adaptive_scaffold` (abandonné) ; `NavigationRail` thémé
  (non conforme) ; un `Drawer` en large (navigation cachée, moins efficace sur bureau).

## R4. Colonnes de grille

- **Decision**: `DymLayout.columns(width, minTile, spacing, min, max)` renvoie
  `floor((width + spacing) / (minTile + spacing))`, borné à `[min, max]`.
- **Rationale**:
  - c'est déterministe et testable en Dart pur ;
  - c'est équivalent à `SliverGridDelegateWithMaxCrossAxisExtent`, mais avec un minimum garanti
    (2 colonnes à 360 dp, comme validé) et utilisable hors grille, par exemple pour les cartes
    « Racheter ».
- **Alternatives considered**: `SliverGridDelegateWithMaxCrossAxisExtent` seul, qui ne garantit pas
  2 colonnes à 360 avec une tuile de 168 dp ; un tableau fixe classe → colonnes, qui ignore le rail
  et les marges.

## R5. Prévisualisation des formats dans la galerie

- **Decision**:
  - l'écran est rendu dans un `SizedBox` à la taille logique du format, sous un `MediaQuery`
    surchargé (`size`, `padding` à zéro) ;
  - il est réduit par un `FittedBox(fit: BoxFit.scaleDown)` ;
  - « Comparer » n'est actif qu'en téléphone.
- **Rationale**:
  - le rendu, la classe et les contraintes sont exactement ceux d'un vrai appareil de cette
    taille, puis l'image est réduite ;
  - sans dépendance (pas de `device_preview`).
- **Alternatives considered**: `device_preview` (dépendance lourde, version Flutter incertaine) ;
  une fenêtre redimensionnée à la main (pas utilisable depuis un téléphone).

## R6. Garantir que le téléphone portrait ne change pas

- **Decision**: toutes les adaptations sont des **identités en compacte**.
  - Marge de 16, déjà la valeur codée.
  - Grilles avec un minimum égal à la valeur actuelle (2 produits, 4 rayons).
  - Mini-panier borné à 560, soit plus que 412 − 32.
  - Barre basse inchangée.
  - Vérification par les goldens 412 × 915 de la spec 001 rejoués **sans** `--update-goldens`
    avant toute régénération.
- **Rationale**: c'est une preuve automatique de SC-002.
- **Alternatives considered**: une vérification visuelle seule, non reproductible.

## R7. Matrice de robustesse

- **Decision**: un test par combinaison écran × taille × pays × texte (8 × 7 × 2 × 2 = 224). Il
  échoue sur toute exception de rendu, débordement compris, et vérifie les bornes de largeur sur
  bureau (SC-003).
- **Rationale**: les débordements Flutter lèvent une `FlutterError` en test, donc la détection est
  fiable. Le coût est d'environ 1 à 2 min en CI.
- **Alternatives considered**: des goldens à toutes les tailles (112 images à maintenir) ; garder
  seulement 360 × 640, qui est la situation actuelle et insuffisante.
