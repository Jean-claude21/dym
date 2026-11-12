# Implementation Plan: Design system « Épuré » et pages d'entrée

**Branch**: `feat/055-design-system-epure` | **Date**: 2026-11-11 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| II. Valider avant de construire | Planches validées le 2026-11-11 (`docs/design/screens/epure/`) | OK |
| IV. Générique | Aucun texte en dur ; tokens par rôle | OK |
| VI. Couches | Thème et composants dans `dym_ui` ; pages d'entrée dans `dym_auth` | OK |
| VII. Qualité | Analyse, tests, captures de contrôle regardées | OK |
| VIII. Terrain | Contraste AA, 48 px, 14 px, pas d'animation lourde (ondulation simple) | OK |

## Décisions

- Décision [0016](../../docs/architecture/decisions/0016-design-epure.md) (remplace 0009 et 0011).
- Tokens : nouvelles valeurs, nouveaux rôles (`line.*`, `surface.muted`, `radius.field`,
  `radius.image`, `size.button-height`, `size.field-height`, `shadow.floating`) ; le générateur
  accepte `letterSpacing`.
- Police Inter variable embarquée (OFL) ; Nunito retirée ; captures de test chargées en Inter.
- `DymTheme` : thèmes Material complets (AppBar, Card, ListTile, boutons, champs, puces, feuilles,
  dialogues, SnackBar, interrupteurs, onglets, NavigationBar, Tooltip, PopupMenu, Badge), ondulation
  simple (`InkRipple`).
- Composants repris : bouton (52 px, désactivé lisible), puce (12 px), recherche (52 px, filet), champ
  (10 px, libellé flottant), carte produit (sans cadre, menthe, compacte réorganisée), carte boutique,
  tuile de rayon (cercle menthe), barre et rail de navigation (indicateur au-dessus), mini-panier,
  stepper (cadre fin), en-tête de section, état vide/erreur/hors ligne (icône au trait), squelette,
  carte sélectionnable, moyen de paiement, frise, gabarit de formulaire.
- `dym_auth` : bienvenue cliente (photos plein cadre, diaporama), bienvenue vendeuse et livreur (photo,
  promesses), astuce du code ; photos générées sans texte ni logo, WebP ≤ 130 Ko.
- Admin : connexion avec photo pleine hauteur, formulaire à plat.
- Démarrage des apps : titre allégé.

## Vérification

- Captures de contrôle : `packages/features/dym_auth/test/capture/` (tag `golden`) et galerie.
- `melos run analyze`, `melos run test`.
