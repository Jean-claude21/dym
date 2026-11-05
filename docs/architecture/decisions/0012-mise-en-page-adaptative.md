# 0012 — Mise en page adaptative

**Statut :** Acceptée · 2026-10-01 · Spec 002

## Contexte

Les écrans validés (0009, 0011) sont conçus pour le téléphone en portrait. Les apps DYM tourneront
aussi :

- en paysage ;
- sur tablette, pour les vendeuses au comptoir ;
- dans un navigateur, pour l'admin Flutter Web.

Sans règles communes, chaque app réinventerait ses dispositions larges.

## Décision

- **Classes de fenêtre Material 3**, selon la largeur seulement :
  - compacte : < 600 ;
  - moyenne : 600 à 839 ;
  - étendue : 840 à 1 199 ;
  - large : ≥ 1 200.

  Un seuil appartient à la classe supérieure.
- **Tokens de mise en page** dans `dym.tokens.json`, groupes `breakpoint` et `layout` :
  - marges 16 / 24 / 32 / 32 ;
  - contenu ≤ 1 200, formulaire ≤ 600, élément flottant ≤ 560 ;
  - rail 88 ou 220.
- **Deux niveaux de décision** :
  - la classe de fenêtre (`MediaQuery.sizeOf`) choisit la navigation et les marges ;
  - l'espace réellement disponible (`LayoutBuilder`) choisit les colonnes et les largeurs.
- **Navigation** via `DymAdaptiveScaffold` :
  - barre basse en compacte ;
  - `DymNavRail` en moyenne et étendue ;
  - rail étendu en large.

  Le corps garde son état au changement de classe.
- **Contenus défilants bornés par marge** (`DymLayout.sideInset`) plutôt qu'enveloppés : la zone de
  défilement garde toute la largeur.
- **Le téléphone portrait reste la référence de design.** Toute adaptation est une identité en
  classe compacte, vérifiée par les goldens 412 × 915 rejoués sans régénération.
- Pas de dépendance :
  - `flutter_adaptive_scaffold` est abandonné ;
  - `NavigationRail` est non conforme à l'élément actif validé ;
  - `device_preview` est lourd.

## Conséquences

- Toute spec qui crée un écran le vérifie aux tailles de référence (constitution VIII, v1.2.0) :
  - téléphone portrait 360 × 640 et 412 × 915 ;
  - téléphone paysage 915 × 412 et 640 × 360 ;
  - tablette 800 × 1 280 et 1 280 × 800 ;
  - bureau 1 440 × 900.
- L'admin (`admin-ops`) et le tableau de bord vendeuse partent de `DymAdaptiveScaffold`.
- Les dispositions larges ne passent pas par de nouvelles maquettes : elles dérivent des écrans
  validés et sont validées sur captures.
