# Comptes de test (Neon staging)

Données créées par `db/scripts/seed-demo.mjs` avec `DEMO_EMAIL=jeanclaude.messan@proton.me`.
Connexion **sans mot de passe** : saisir l'email, le code à 6 chiffres arrive dans la boîte
**jeanclaude.messan@proton.me** (les alias `+xxx` y sont livrés).

Apps web locales : cliente http://localhost:5555 · vendeuse http://localhost:5556 ·
admin http://localhost:5557 (`flutter run -d web-server --web-port <port>
--dart-define-from-file=../../config/staging.json`).

## Admin (http://localhost:5557)

| Email | Rôle |
|---|---|
| jeanclaude.messan@proton.me | Admin par défaut (`ADMIN_EMAILS`) |
| jeanclaude.messan+admin2@proton.me | Invitation en attente (devient admin à sa 1re connexion) |

## Clientes (http://localhost:5555)

| Email | Ville / quartier | Ce qu'il y a à voir |
|---|---|---|
| jeanclaude.messan+awa@proton.me | Paris 18e | Une commande à chaque statut (en attente, acceptée, en préparation, prête, en livraison, livrée cash / en ligne / retrait, refusée, annulée, paiement en attente, paiement échoué), commandes dans 7 boutiques, avis, 3 litiges (ouvert, répondu, remboursé), conversations, demande d'aide, recherches récentes |
| jeanclaude.messan+moussa@proton.me | Paris 11e | Commandes en cours et livrées, litige clos, conversation |
| jeanclaude.messan+lea@proton.me | Lyon, Croix-Rousse | Commandes à Lyon, demande d'aide |
| jeanclaude.messan+kossi@proton.me | Lomé, Bè (Togo, F CFA) | Commandes au Togo, litige ouvert, conversation |

## Vendeuses (http://localhost:5556)

| Email | Boutique | Ce qu'il y a à voir |
|---|---|---|
| jeanclaude.messan+fatou@proton.me | Chez Fatou — Épicerie africaine (Paris 18e) | ~30 produits (ruptures, stock bas, variantes), file de commandes à tous les statuts, avis, litiges, messages, ticket paiement |
| jeanclaude.messan+aminata@proton.me | Les Saveurs d'Aminata (Paris 11e, fait maison) | Plats et jus, commandes, messages |
| jeanclaude.messan+marie@proton.me | Primeur de la Croix-Rousse (Lyon) | Commandes à Lyon |
| jeanclaude.messan+akossiwa@proton.me | Marché de Bè — Tantie Akossiwa (Lomé) | Boutique au Togo, en F CFA |

## Figuration

10 autres boutiques (Paris, Lyon, Marseille, Lomé ; « Karité & Co » est fermée) et 18 clientes
`clientN@example.test` qui ont passé ~80 commandes réparties sur 30 jours (tableaux de bord,
revenus, avis). Ces adresses ne reçoivent pas d'email : elles ne servent pas à se connecter.

## Limites connues

- Les photos produits pointent vers des fichiers non téléversés : l'app affiche l'illustration par
  défaut.
- Paiement en ligne = fournisseur **simulé** (carte simulée en France, T-Money / MTN simulés).
- Pas de contenus (stories, vidéos) : il faut de vrais médias.
