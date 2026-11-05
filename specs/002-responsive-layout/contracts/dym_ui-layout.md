# Contrat d'interface — mise en page adaptative de dym_ui

Les règles communes du contrat des composants (`specs/001-dym-ui-design-system/contracts/dym_ui-components.md`)
s'appliquent. Toutes les valeurs viennent des tokens `breakpoint.*` et `layout.*`.

| Brique | Rôle | Entrées principales | Comportement |
|---|---|---|---|
| `DymWindowClass` | Classe de fenêtre (`compact`, `medium`, `expanded`, `large`) | `DymWindowClass.of(context)`, `DymWindowClass.fromWidth(double)` | Seuils 600 / 840 / 1 200, seuil inclus dans la classe supérieure ; comparables (`>=`) |
| `DymLayout.gutter` | Marge latérale de la classe | `DymWindowClass` | 16 / 24 / 32 / 32 |
| `DymLayout.sideInset` | Marge qui borne un contenu défilant et le centre | `availableWidth`, `gutter`, `maxWidth` | `max(gutter, (availableWidth − maxWidth) / 2)` ; la zone de défilement garde toute la largeur |
| `DymLayout.columns` | Nombre de colonnes d'une grille | `width`, `minTileWidth`, `spacing`, `min`, `max`, `itemCount` | `floor((width + spacing) / (minTileWidth + spacing))` borné à `[min, max]` ; avec `itemCount`, lignes équilibrées (8 tuiles sur 7 colonnes → 4 + 4) |
| `DymContentWidth` | Centre et borne un contenu | `child`, `maxWidth` (défaut `layout.content-max`), `padded` (applique la marge de la classe) | Largeur ≤ `maxWidth`, centré ; en compacte sans `padded` : identité |
| `DymAdaptiveScaffold` | Structure de navigation principale | `destinations` (`DymNavItem`), `currentIndex`, `onDestinationSelected`, `body`, `backgroundColor` | compacte : `DymBottomNav` ; moyenne et étendue : `DymNavRail` ; large : `DymNavRail(extended: true)` ; le corps garde son état |
| `DymNavRail` | Rail latéral | `items`, `currentIndex`, `onTap`, `extended`, `leading` | Élément actif vert profond + trait, libellé sous l'icône (ou à côté si `extended`), cibles ≥ 48 dp, `Semantics(button, selected, label)` |
| `DymMiniCartBar` (modifié) | Mini-panier | inchangé | Largeur ≤ `layout.floating-max`, centré |
