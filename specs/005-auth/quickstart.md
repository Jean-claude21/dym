# Quickstart — authentification, profils et rôles

```bash
node db/scripts/dym-db.mjs local reset && node db/scripts/dym-db.mjs migrate && node db/scripts/dym-db.mjs test
fvm dart run melos run test
cd apps/dym_gallery && fvm flutter run -d chrome   # écrans 09 à 14, « Comparer » avec les maquettes
cd apps/dym_client && fvm flutter run -d chrome --dart-define=DYM_ENV=dev
```

Google n'apparaît que si `DYM_GOOGLE_SERVER_CLIENT_ID` (Android) ou `DYM_GOOGLE_CLIENT_ID` (web, iOS)
est fourni à la compilation.

## Résultats (2026-10-02, local)

| Contrôle | Résultat |
|---|---|
| pgTAP | 126/126, dont 37 nouveaux :<br>• profils et rôles : 19 (accès croisés refusés, auto-attribution admin refusée, pays non modifiable, complétion rejouable sans doublon d'événement) ;<br>• suppression : 9 (utilisateur, profil et rôles supprimés ; audit sans donnée personnelle ; seconde demande sans effet) ;<br>• admin : 9 (attribution et retrait tracés, connexion admin auditée, non-admin refusé) |
| `dym_auth` | 126 :<br>• viewmodel : email invalide, code faux, réseau coupé, Google annulé ou non configuré, profil incomplet, session expirée, retour ;<br>• 4 étapes × 2 variantes × 7 tailles × fr/en à 130 % de texte, sans débordement ;<br>• puces de quartier ≥ 48 dp |
| `dym_account` | 18 : « Moi » aux 7 tailles, déconnexion, suppression avec confirmation, suppression hors ligne |
| Apps | cliente 36, vendeuse 36, admin 16 :<br>• démarrage vers connexion, profil ou accueil ;<br>• hors ligne : écran de reprise ;<br>• non-admin refusé ;<br>• déconnexion après inactivité |
| Galerie | 414 tests, dont la matrice des 14 écrans × 7 tailles × 2 pays × 2 tailles de texte ; captures 412 × 915, tablette et bureau ; les 8 écrans validés sont **inchangés** |
| `melos run analyze` | aucun problème |
| Compilation web de l'admin (bouton Google web) | réussie |
| Essai OTP réel sur Neon | **en attente d'accès** (décision 0013) |

Comparaisons maquette / rendu :
- [`validation/compare-09-14.jpg`](validation/compare-09-14.jpg) ;
- [`validation/compare-15.jpg`](validation/compare-15.jpg).

Défauts trouvés et corrigés :
- **Puces de `dym_ui`** :
  - la zone tactile ne faisait que 40 dp ;
  - les puces s'étiraient en pleine largeur dans un `Wrap`.
- **Bienvenue** : elle débordait sur un petit téléphone.
- **Écrans courts** : ils étaient construits à la demande, si bien que leurs boutons n'existaient
  pas avant défilement.
- **Image de bienvenue** : un « Passer » était incrusté dans l'image.
- **Typographie française** : espace insécable avant « ! ? : ; ».
- **Outil de migration** : les fins de ligne CRLF étaient mal lues sous Windows.
