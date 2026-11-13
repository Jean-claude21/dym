# Marque DYM (spec 082)

Logo « sac DoYourMarket » redessiné aux couleurs du design « Épuré » (vert `#145C43`, vert profond
`#0E4632`, feuille `#3FA06B`, plantain `#F6C343`). Les deux feuilles au-dessus de l'anse disent la
fraîcheur et la pousse ; sans elles, `LEAVES = []` dans `sources/brand.py`.

| Fichier | Usage |
|---|---|
| `logo-dym.svg/png` | Logo complet (sac + « DoYourMarket ») |
| `icone-dym*.svg/png` | Icône : fond vert, fond clair, premier plan seul (adaptative) |
| `splash-dym.json`, `splash-anime.gif` | Splash animé (Lottie 390 × 844) et son aperçu |
| `logo-ancien-trouve.png`, `splash-ancien-trouve.png` | Références d'origine retrouvées |

Les fichiers servis aux apps sont dans `packages/ui/dym_ui/assets/brand/` (décision 0018).

## Régénérer

```bash
pip install fonttools pillow
python sources/brand.py    # logo, icônes, splash (police Inter de dym_ui)
python sources/icons.py    # icônes Android et iOS (Edge sans tête)
```

Les fichiers générés arrivent dans `sources/`. Copier ensuite `splash-dym.json` en
`packages/ui/dym_ui/assets/brand/splash.json`. Le splash natif n'affiche que le fond `#FAFAF7` :
le démarrage visible est uniquement `splash-anime.gif`.
