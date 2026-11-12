# 0016 — Design « Épuré, formes tenues »

**Statut :** Acceptée · 2026-11-11 · Remplace 0009 (direction de design) et 0011 (couleur de marque)

## Contexte

La direction 0009 (« Le marché de Lomé, livré chez toi ») et son vert 0011 ont porté les phases 1 à 13.
Construites écran par écran, les apps ont fini par empiler cartes ombrées, pilules et rayons de 20 à
24 px, avec quatre navigations différentes. Le 2026-11-11, le porteur produit a comparé plusieurs
directions sur planches et validé « Épuré, formes tenues » pour toutes les apps, strictement.

## Décision

- **Habillage** : fond blanc cassé `#FAFAF7`, filets `#E6E7E2` plutôt que cartes ombrées, aucune ombre
  sauf les éléments flottants, aucun dégradé, aucun flou.
- **Couleur** : un seul vert `#145C43` pour l'action principale et l'onglet actif ; menthe `#E8F2EC`
  derrière les produits ; tomate pour promo, rupture et erreur ; soleil `#F6C343` réservé au cash à
  encaisser et aux notes.
- **Typographie** : Inter (variable, OFL), embarquée dans `dym_ui` ; titres et prix SemiBold à Bold,
  chiffres tabulaires ; 14 px minimum.
- **Formes** : 12 px pour cartes, boutons, puces et filtres ; 10 px pour champs et images ; ronds
  seulement pour avatars, interrupteurs, petits « + » et indicateur d'onglet.
- **Navigation** : barre plate à filet, icône + libellé, indicateur au-dessus de l'onglet actif ; rail
  sur grand écran (0012 inchangée).
- **Mode vidéo** : seule exception sombre, pendant la lecture plein écran.
- Références : [`docs/design/PARCOURS.md`](../../design/PARCOURS.md) et
  [`docs/design/screens/epure/`](../../design/screens/epure/).

## Conséquences

- Les noms des tokens restent par rôle (`brand.primary`, `tint.vert-tendre`…) : les apps héritent du
  nouveau design en régénérant le thème ; seuls les composants et les écrans aux valeurs codées en dur
  sont repris, spec par spec (phase 14).
- Nouveaux tokens : `line.hairline`, `line.strong`, `surface.muted`, `radius.field`, `radius.image`,
  `size.button-height`, `size.field-height`, `shadow.floating`.
- Contrastes mesurés : blanc sur vert 7,7:1 ; texte secondaire sur fond 7,0:1 ; badges d'origine ≥ 5,7:1.
- Les thèmes de composants Material sont réglés dans `DymTheme` pour que toute page suive le design,
  y compris les widgets Material utilisés directement.
- Nunito et Nunito Sans sont retirées du dépôt.
