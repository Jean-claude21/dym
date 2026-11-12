# Comptes de test (Neon staging)

Données créées par `db/scripts/seed-demo.mjs` avec `DEMO_EMAIL=jeanclaude.messan@proton.me`, puis
déplacées au Togo (`db/scripts/demo-to-togo.sql`) : tout se passe à Lomé, en F CFA.
Deux façons de se connecter, sur les quatre apps :

- **Email + mot de passe** (le plus rapide) : « Continuer avec mon email » → « J'ai un mot de passe ».
  Mot de passe commun des comptes ci-dessous : fichier hors dépôt `dev-setup\demo-password.env`
  du poste du porteur produit (variable `DYM_TEST_PASSWORD`). Il a été changé le 2026-11-11.
- **Code par email** : le code arrive dans la boîte **jeanclaude.messan@proton.me** (alias `+xxx` compris).

Apps web locales (une origine autorisée par app dans `ALLOWED_ORIGINS` des Functions) :

| App | Adresse |
|---|---|
| Cliente | http://localhost:5555 |
| Vendeuse | http://localhost:5556 |
| Admin | http://localhost:5557 |
| Livreur | http://localhost:5558 |

Lancement : `fvm flutter build web --release --dart-define-from-file=../../config/staging.json` dans
chaque app, puis servir `build/web` sur son port (ou `fvm flutter run -d web-server --web-port <port>
--dart-define-from-file=../../config/staging.json`).

## Admin (5557)

| Email | Rôle |
|---|---|
| jeanclaude.messan@proton.me | Admin par défaut (`ADMIN_EMAILS`), connexion par code ou par ton mot de passe |
| jeanclaude.messan+admin2@proton.me | Invitation : devient admin à sa première connexion à l'app admin (mot de passe commun) |

## Clientes (5555)

| Email | Quartier | Ce qu'il y a à voir |
|---|---|---|
| jeanclaude.messan+awa@proton.me | Bè | Commandes à chaque statut, avis, litiges, conversations, achat groupé de riz, marchandage |
| jeanclaude.messan+kossi@proton.me | Bè | Commandes, litige ouvert, conversation |
| jeanclaude.messan+moussa@proton.me | Tokoin | Commandes en cours et livrées, litige clos |
| jeanclaude.messan+lea@proton.me | Agoè | Commandes, demande d'aide |

## Vendeuses (5556)

| Email | Boutique | Ce qu'il y a à voir |
|---|---|---|
| jeanclaude.messan+fatou@proton.me | Chez Fatou — Épicerie africaine (Bè) | ~30 produits, file de commandes, caisse et QR, marchandage à 20 %, offre groupée, « À la une » |
| jeanclaude.messan+akossiwa@proton.me | Marché de Bè — Tantie Akossiwa (Bè) | Produits du marché |
| jeanclaude.messan+aminata@proton.me | Les Saveurs d'Aminata (Tokoin) | Produits maison (akassa, bissap séché, kinkeliba…) |
| jeanclaude.messan+marie@proton.me | Primeur d'Agoè (Agoè) | Fruits et légumes |

## Livreur (5558)

| Email | Profil |
|---|---|
| jeanclaude.messan+livreur@proton.me | Komlan, moto, livre à Bè ; se met « En ligne » pour voir les courses |

## Figuration

Une dizaine d'autres boutiques de Lomé et des clientes `clientN@example.test` (commandes sur 30
jours pour les tableaux de bord). Ces adresses ne reçoivent pas d'email.

Nettoyage du 2026-11-11 : boutiques hors périmètre grocery suspendues (« Wax & Pagnes de Bè »,
« Karité & Co ») ainsi que les boutiques de test (« Test automatique », « DYM Boutique ») ; repas et
boissons préparés archivés ; commandes et demandes d'aide des comptes d'essai annulées ou fermées.
Tout est réversible depuis l'admin et inscrit au journal.

## Limites connues

- Photos produits : images de la galerie (`db/scripts/demo-photos.mjs`), une par produit ou par rayon.
- Paiement en ligne = fournisseur **simulé** (T-Money / Mobile Money simulés), wallet rechargé en simulation.
- Stories (statuts 24 h) : à republier après 24 h (`db/scripts/demo-stories.mjs`).
- Vidéos : clips verticaux dans l'onglet Vidéos (`db/scripts/make-demo-videos.ps1` puis `demo-videos.mjs`).
- Créneau affiché dans le fuseau de l'appareil : un navigateur réglé sur Paris montre 1 h de plus
  que l'heure de Lomé.
