# Quickstart — onboarding et réglages de la boutique

```bash
node db/scripts/dym-db.mjs local start && node db/scripts/dym-db.mjs migrate && node db/scripts/dym-db.mjs test
fvm dart run melos run test
cd apps/dym_gallery && fvm flutter run -d chrome   # écrans 16 à 23, « Comparer » avec les maquettes
cd apps/dym_vendor && fvm flutter run -d chrome --dart-define=DYM_ENV=dev
```

## Résultats (2026-10-02, local)

| Contrôle | Résultat |
|---|---|
| pgTAP | 169/169, dont 43 nouveaux :<br>• onboarding : 23 (brouillon, reprise, pays déduit du quartier, une seule boutique, rôle vendeuse, quartier d'une autre ville refusé, paiement d'un autre pays ou inactif refusé, « Bientôt » listé, horaires inversés refusés, ouverture incomplète refusée, ouverture complète et événements) ;<br>• accès : 20 (lecture publique sans adresse ni propriétaire, brouillon invisible, autre vendeuse refusée, statut non modifiable, suspendue non rouvrable, ouvrir et fermer avec événements) |
| `dym_models`, `dym_data` | 10 et 17 : lecture de `my_store()`, paramètres des fonctions, « Bientôt », incomplète → `ValidationFailure`, sans boutique → `NotFoundFailure` |
| App vendeuse | 184 :<br>• viewmodel : 7 étapes enregistrées une à une, reprise, hors ligne sans perte, Mobile Money non sélectionnable, horaires invalides, ouverture refusée, réglage d'une étape sans publication, interrupteur suivant la base ;<br>• parcours nominal au toucher, des 7 étapes à l'ouverture ;<br>• 7 étapes, écran de réussite et « Ma boutique » × 7 tailles × fr/en à 130 % de texte, sans débordement ;<br>• démarrage : sans boutique ou brouillon → onboarding, ouverte → « Ma boutique » |
| Galerie | 638 tests, dont la matrice des 22 écrans × 7 tailles × 2 pays × 2 tailles de texte ; 66 captures. Les 42 captures précédentes sont **inchangées** |
| `melos run analyze` | aucun problème |
| Compilation web de l'app vendeuse | réussie |
| Essai réel sur Neon | **en attente d'accès** (décision 0013) |

Comparaison maquette / rendu : [`validation/compare-16-23.jpg`](validation/compare-16-23.jpg).

Défauts trouvés et corrigés :
- **Carte de choix** (`dym_ui`) : `AnimatedSize` plantait quand les animations sont désactivées.
- **Horaires** : en anglais (« 7:00 AM »), les heures débordaient ; elles passent sous le jour quand
  la place manque.
- **Bloc « quartiers desservis »** : « Tout sélectionner » débordait à 360 dp avec texte à 130 %.
- **Captures** : les images des écrans chargés de façon asynchrone n'étaient pas décodées.
- **Outil de base locale** : `local start` restait bloqué sous Windows (le serveur héritait des tubes).
