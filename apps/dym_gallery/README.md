# dym_gallery

Outil interne (non publié) qui reproduit les 8 écrans validés avec `dym_ui`, avec un mode
« Comparer » (superposition de l'image de référence) et un sélecteur Togo/Ghana.
Données et images de démonstration générées par IA (ChatGPT via Codex).

```bash
fvm flutter run -d chrome        # ou un appareil Android
fvm flutter test --exclude-tags golden
fvm flutter test --tags golden --update-goldens   # captures 412×915
```
