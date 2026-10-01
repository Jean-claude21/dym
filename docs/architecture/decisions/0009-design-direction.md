# 0009 — Direction de design « Le marché de Lomé, livré chez toi »

**Statut :** Acceptée · 2026-10-01

## Contexte

Dix concepts ont été explorés en images générées (ChatGPT, gpt-image-2), puis une base universelle
d'app de courses 2026 a été déclinée en trois niveaux d'africanisation sur le même écran. DYM est
positionné sur les courses au marché (décision 0010).

## Décision

- Ergonomie de niveau 0 (standard mondial des apps de courses) non négociable.
- Identité au niveau 2 : palette du marché (vert gombo, jaune plantain, rouge piment, crème) et
  produits photographiés dans des contenants du marché.
- Niveau 3 dosé : boutiques avec badge d'origine, zem, kente sur le splash uniquement.
- Aucune monnaie fictive : avantages en F CFA.
- Tokens au format W3C DTCG dans `docs/design/tokens/dym.tokens.json`, source de vérité de `dym_ui`.

Détail : [`docs/design/DESIGN_DIRECTION.md`](../../design/DESIGN_DIRECTION.md).

## Conséquences

- Interface claire uniquement en V1 (lecture en plein soleil) ; un thème sombre n'est pas prévu avant le pilote.
- Besoin de vraies photos de produits et de vendeuses : prévoir l'accompagnement photo à l'onboarding.
- Les typographies (Nunito, Nunito Sans) sont validées sur appareil réel avant de figer `dym_ui`.

## Alternatives écartées

Marché Vivant, Pagne, Voix du Marché, Lagune, Argile, Couverture, Brut : voir la section
« Explorations écartées » de la direction de design.
