# Cahier de recette DYM (staging)

Apps : cliente http://localhost:5555 · vendeuse http://localhost:5556 · admin http://localhost:5557.
Connexion : email → « J'ai un mot de passe » → mot de passe de test (fichier
`C:\Users\Jean-Claude\dev-setup\demo-password.env`). Comptes : `docs/COMPTES_DE_TEST.md`.
Raccourcis : **Awa** = `jeanclaude.messan+awa@proton.me` (cliente Paris 18e),
**Fatou** = `jeanclaude.messan+fatou@proton.me` (vendeuse Paris 18e), **Admin** =
`jeanclaude.messan@proton.me`. Cocher chaque ligne : ✅ conforme · ❌ écart (noter ce qui se passe).

## A. Cliente (Awa)

| # | Fonctionnalité | Où / quoi faire | Résultat attendu |
|---|---|---|---|
| A1 | Connexion mot de passe | Continuer avec mon email → J'ai un mot de passe | Accueil, prénom Awa |
| A2 | Stories (statuts 24 h) | Accueil, **rangée de ronds en haut** | 8 boutiques ; toucher → story plein écran, produits liés, « Ajouter » |
| A3 | Boutiques du quartier | Accueil, sous les stories | Boutiques ouvertes (Chez Fatou, Wax & Pagnes…), badge d'origine |
| A4 | Rayons | Onglet Rayons → Légumes | Grille de produits avec photos |
| A5 | Ajout direct | « + » sur une carte produit, puis « + » encore | Quantité 1 → 2 sans ouvrir la fiche ; mini-panier en bas |
| A6 | Fiche produit | Toucher une carte | Photo, prix, unité, quantité, « Ajouter au panier » (barre normale) |
| A7 | Variantes | Fiche « Jus de bissap » | Choix Petit / Grand, prix différents |
| A8 | Recherche + filtres | Loupe → « gombo », filtres origine / prix | Résultats filtrés |
| A9 | Recherche vocale / photo | Loupe → micro ou appareil photo | Transcription / produits reconnus (**clé OpenAI requise**) |
| A10 | Copilote | Accueil → « Que veux-tu cuisiner ? » → « thiéboudienne pour 4 » | Panier proposé (**clé OpenAI requise**) |
| A11 | Page boutique | Chez Fatou | Produits par catégorie, horaires, note, avis |
| A12 | Panier multi-boutiques | Ajouter chez Fatou et chez Wax & Pagnes → panier | 2 sous-paniers, frais de livraison |
| A13 | Commande cash | Panier → adresse « Maison » → Espèces → Commander | « Commande envoyée » |
| A14 | Paiement en ligne simulé | Idem avec « Carte bancaire (simulée) » | Page de paiement simulé → payé / échec |
| A15 | Suivi | Onglet Commandes → une commande | Étapes et heures ; statut à jour |
| A16 | Tous les statuts | Onglet Commandes | En attente, acceptée, en préparation, prête, en livraison, livrée, refusée, annulée, paiement échoué |
| A17 | Annuler | Commande « En attente » → Annuler | Statut « Annulée » |
| A18 | Avis | Commande livrée → Laisser un avis | Note + mots-clés ; visible sur la boutique |
| A19 | Litige | Commande livrée → Signaler un problème | Litige ouvert ; fil avec la boutique |
| A20 | Recommander | Commande livrée → Commander à nouveau | Articles remis au panier |
| A21 | Messages | Moi → Messages → Chez Fatou | Conversation existante ; envoyer un message |
| A22 | Notifications | Onglet Commandes → cloche | Liste des notifications (statuts, réponses) |
| A23 | Vidéos | Onglet Vidéos | Fil vertical (vide tant qu'aucune vidéo n'est publiée, voir V12) |
| A24 | Signaler un contenu | Story ou vidéo → ⋮ → Signaler | Motif ; visible en Modération admin |
| A25 | Adresses, langue, aide | Moi | Ajouter une adresse, passer en anglais, ouvrir un ticket |

## B. Vendeuse (Fatou)

| # | Fonctionnalité | Où / quoi faire | Résultat attendu |
|---|---|---|---|
| V1 | Tableau de bord | Accueil | Ventes du jour / semaine / mois, urgences |
| V2 | File de commandes | Commandes | Commandes à chaque statut ; nouvelle commande d'Awa (A13) en tête |
| V3 | Cycle d'une commande | Commande en attente → Accepter → En préparation → Prête → En livraison → Livrée → Encaissé | Awa voit chaque étape (A15) |
| V4 | Refuser | Commande en attente → Refuser + motif | Awa voit « Refusée » |
| V5 | Produits | Produits | 32 produits avec photos, stock, ruptures |
| V6 | Rupture en un geste | Interrupteur d'un produit | « Rupture » ; Awa ne peut plus l'ajouter |
| V7 | Créer un produit | Ajouter un produit → photo, prix, unité | Publié, visible côté cliente |
| V8 | Fiche par IA | Ajouter un produit → photo | Nom / rayon proposés (**clé OpenAI requise**) |
| V9 | Catégories | Produits → étiquette en haut à droite | Créer / renommer / ordonner |
| V10 | Messages | Messages → Awa | Répondre, partager un produit |
| V11 | Avis et litiges | Boutique → Avis ; commande avec litige | Répondre |
| V12 | Stories et vidéos | Boutique → Mes stories et vidéos → Story / Vidéo | Publier (photo ou vidéo ≤ 60 s), lier des produits ; stats vues / clics / j'aime |
| V13 | Relancer mes clientes | Boutique → Relancer | Message envoyé aux clientes |
| V14 | Réglages boutique | Boutique → Réglages | Horaires, paiement, ouvrir / fermer |
| V15 | Ouverture d'une boutique | Nouveau compte vendeuse (`jeanclaude.messan+test1@proton.me`, code email) | Parcours 7 étapes |

## C. Admin

| # | Fonctionnalité | Où / quoi faire | Résultat attendu |
|---|---|---|---|
| D1 | Connexion | Email admin + mot de passe | Tableau de bord |
| D2 | Tableau de bord | Accueil | Commandes, revenus, alertes ; santé IA et paiements |
| D3 | Commandes | Commandes → une commande | Chronologie ; forcer un statut, annuler + rembourser, assigner un livreur |
| D4 | Litiges | Litiges | 5 litiges (ouvert, répondu, remboursé, clos) ; trancher |
| D5 | Boutiques | Boutiques → Karité & Co | Suspendre / réactiver ; vue vendeuse |
| D6 | Clientes | Clientes → Awa | Commandes, litiges, tickets |
| D7 | Finance | Finance | Revenus, remboursements, paiements en attente |
| D8 | Support | Support | Tickets d'Awa, Fatou, Léa → répondre, clore |
| D9 | Modération | Modération | Signalements (A24) → garder / retirer |
| D10 | Interrupteurs | Réglages → Interrupteurs | Couper « shoppable_content » → plus de stories côté cliente |
| D11 | Admins | Réglages → Admins | Inviter un email, retirer une invitation |
| D12 | Audit | Journal | Chaque action admin tracée |
