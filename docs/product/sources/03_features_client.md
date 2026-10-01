# DYM — Features App Client

> **Version :** 1.0 — Mai 2026  
> **Surface :** App mobile Flutter (dym_client)  
> **Lecteur cible :** PM, Développeur, QA

---

## Légende priorité

| Label | Signification |
|---|---|
| 🔴 P0 | Bloquant — sans ça, l'app ne peut pas être déployée |
| 🟠 P1 | Fort impact — priorité post-lancement dès V1.1 |
| 🟡 P2 | Valeur ajoutée — roadmap moyen terme |
| ⚫ OUT | Hors scope — ne pas implémenter, ne pas discuter |

---

## Module 1 — Authentification & Onboarding

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| C-AUTH-01 | Inscription par téléphone + OTP SMS | 🔴 P0 | Pas d'email obligatoire |
| C-AUTH-02 | Connexion par téléphone + OTP | 🔴 P0 | |
| C-AUTH-03 | Profil minimal à l'inscription (prénom, photo optionnelle) | 🔴 P0 | |
| C-AUTH-04 | Onboarding swipeable (3 slides max, skippable) | 🔴 P0 | |
| C-AUTH-05 | Détection automatique de la zone géographique | 🔴 P0 | Pour personnaliser le feed |
| C-AUTH-06 | Connexion sociale (Google) | 🟡 P2 | Pas nécessaire au lancement |
| C-AUTH-07 | Biométrie (FaceID/empreinte) pour reconnexion rapide | 🟠 P1 | |

---

## Module 2 — Découverte & Home

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| C-HOME-01 | Feed personnalisé de boutiques proches | 🔴 P0 | Par zone géographique |
| C-HOME-02 | Catégories navigables (tissu, alimentaire, cosmétique...) | 🔴 P0 | |
| C-HOME-03 | Bannières promotionnelles (deals du moment) | 🟠 P1 | |
| C-HOME-04 | Section "Nouveautés" | 🟠 P1 | |
| C-HOME-05 | Section "Tendances dans ta zone" | 🟠 P1 | |
| C-HOME-06 | Feed de vidéos shoppables (TikTok-like) | 🔴 P0 | Produits tagués, swipe vertical |
| C-HOME-07 | Stories de boutiques (24h) | 🔴 P0 | Swipe horizontal |
| C-HOME-08 | Section "Mes boutiques favorites" | 🟠 P1 | |
| C-HOME-09 | Section "Récemment achetés" | 🟠 P1 | |
| C-HOME-10 | Recommandations personnalisées IA | 🟡 P2 | Nécessite volume de données |

---

## Module 3 — Recherche & Intention

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| C-SEARCH-01 | Recherche textuelle plein texte | 🔴 P0 | Produits + boutiques |
| C-SEARCH-02 | Filtres (prix min/max, zone, catégorie, disponibilité) | 🔴 P0 | |
| C-SEARCH-03 | Tri (pertinence, prix croissant, note) | 🔴 P0 | |
| C-SEARCH-04 | Recherche par image (vision IA) | 🔴 P0 | "J'envoie une photo, je trouve le produit" |
| C-SEARCH-05 | Recherche vocale (NLP) | 🔴 P0 | "Je cherche du tissu wax bleu" |
| C-SEARCH-06 | IA copilote d'intention | 🔴 P0 | Compose panier multi-boutiques depuis une intention |
| C-SEARCH-07 | Historique de recherche | 🟠 P1 | |
| C-SEARCH-08 | Suggestions de recherche temps réel | 🟠 P1 | |
| C-SEARCH-09 | Recherche multimodale combinée (texte + image) | 🟡 P2 | |

### Spécification IA copilote (C-SEARCH-06) — P0

**Entrée possible :**
- Texte libre : "je veux faire un anniversaire pour 20 personnes demain"
- Image : photo d'une tenue, d'un plat, d'un accessoire
- Vocal : message audio jusqu'à 30 secondes

**Comportement attendu :**
1. L'IA décompose l'intention en besoins produits.
2. Elle interroge le catalogue multi-boutiques.
3. Elle compose un panier suggéré avec 3-7 produits.
4. Elle présente la proposition: "Voici ce que j'ai trouvé pour ton anniversaire (3 boutiques, 28 500F total)."
5. Le client ajuste, retire, substitue.
6. Il confirme le panier et passe au checkout.

**Contraintes techniques :**
- Latence perçue < 3 secondes.
- Dégradation gracieuse si IA indisponible → recherche classique.
- Pas de réponse hallucinée — si aucun produit trouvé, dire clairement "Je n'ai rien trouvé pour ça".

---

## Module 4 — Catalogue & Fiches Produits

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| C-CAT-01 | Page boutique (nom, photo, catégories, note, horaires) | 🔴 P0 | |
| C-CAT-02 | Liste produits d'une boutique avec filtre/tri | 🔴 P0 | |
| C-CAT-03 | Fiche produit (photos, description, prix, stock, variantes) | 🔴 P0 | |
| C-CAT-04 | Sélection de variante (taille, couleur, poids) | 🔴 P0 | |
| C-CAT-05 | Galerie photos multi-images (swipe) | 🔴 P0 | |
| C-CAT-06 | Délai de livraison estimé affiché sur la fiche | 🔴 P0 | |
| C-CAT-07 | Badge "Rupture" si stock = 0 | 🔴 P0 | |
| C-CAT-08 | Avis clients sur la fiche produit | 🟠 P1 | |
| C-CAT-09 | "Produits similaires" sur la fiche | 🟠 P1 | |
| C-CAT-10 | Partage produit (lien profond) | 🟠 P1 | |
| C-CAT-11 | Zoom sur image produit | 🟠 P1 | |
| C-CAT-12 | Vidéo produit (depuis feed shoppable) | 🔴 P0 | |

---

## Module 5 — Panier

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| C-CART-01 | Ajout au panier depuis fiche produit | 🔴 P0 | |
| C-CART-02 | Panier multi-boutiques (produits de plusieurs vendeurs) | 🔴 P0 | Différenciateur core |
| C-CART-03 | Modification quantité dans le panier | 🔴 P0 | |
| C-CART-04 | Suppression d'un article | 🔴 P0 | |
| C-CART-05 | Affichage par sous-panier (groupé par boutique) | 🔴 P0 | |
| C-CART-06 | Calcul frais de livraison par boutique | 🔴 P0 | |
| C-CART-07 | Total général affiché clairement | 🔴 P0 | |
| C-CART-08 | Sauvegarde du panier (session persistante) | 🔴 P0 | |
| C-CART-09 | Alerte si article en rupture dans le panier | 🔴 P0 | |
| C-CART-10 | Application d'un code promo | 🟠 P1 | |
| C-CART-11 | Panier partagé / collaboratif | ⚫ OUT | Trop complexe pour V1 |

---

## Module 6 — Checkout

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| C-CHECK-01 | Sélection adresse de livraison (depuis profil ou nouvelle) | 🔴 P0 | |
| C-CHECK-02 | Choix mode livraison par sous-commande (livraison / retrait) | 🔴 P0 | |
| C-CHECK-03 | Résumé commande avant confirmation | 🔴 P0 | |
| C-CHECK-04 | Récapitulatif final (produits, frais, total) | 🔴 P0 | |
| C-CHECK-05 | Confirmation en un tap | 🔴 P0 | |
| C-CHECK-06 | Note optionnelle pour le vendeur | 🟠 P1 | |
| C-CHECK-07 | Créneau de livraison choisi par le client | 🟡 P2 | |

---

## Module 7 — Paiement

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| C-PAY-01 | Paiement Mobile Money (MTN, Orange, T-Money, Wave) | 🔴 P0 | Via Moneroo ou équivalent |
| C-PAY-02 | Confirmation de paiement automatique | 🔴 P0 | Webhook, pas de capture manuelle |
| C-PAY-03 | Fallback capture photo MoMo avec vérification IA | 🔴 P0 | Si API MoMo indisponible |
| C-PAY-04 | Paiement en plusieurs fois | ⚫ OUT | Trop risqué V1 |
| C-PAY-05 | Paiement par wallet DYM | 🟡 P2 | Après setup wallet |
| C-PAY-06 | Paiement à la livraison (cash) | 🟠 P1 | Option vendeur |
| C-PAY-07 | Reçu de paiement téléchargeable / partageable | 🟠 P1 | |
| C-PAY-08 | Historique des paiements | 🟠 P1 | |

---

## Module 8 — Suivi Commande

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| C-ORD-01 | Liste de mes commandes (actives + historique) | 🔴 P0 | |
| C-ORD-02 | Détail commande (produits, statut, paiement, livraison) | 🔴 P0 | |
| C-ORD-03 | Statuts progressifs affichés (confirmée → préparation → livraison → livrée) | 🔴 P0 | |
| C-ORD-04 | ETA de livraison affiché | 🔴 P0 | |
| C-ORD-05 | Tracking temps réel du livreur (carte) | 🟠 P1 | |
| C-ORD-06 | Preuve de livraison visible | 🟠 P1 | |
| C-ORD-07 | Annulation commande (avant préparation) | 🔴 P0 | |
| C-ORD-08 | Signaler un problème / ouvrir un litige | 🔴 P0 | |
| C-ORD-09 | Commander à nouveau (réachat en 1 tap) | 🟠 P1 | |

---

## Module 9 — Adresses

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| C-ADDR-01 | Saisie manuelle adresse | 🔴 P0 | |
| C-ADDR-02 | Détection GPS adresse actuelle | 🔴 P0 | |
| C-ADDR-03 | Sauvegarde adresses (maison, bureau, etc.) | 🔴 P0 | |
| C-ADDR-04 | Carte pour ajuster le pin | 🟠 P1 | |

---

## Module 10 — Avis & Reviews

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| C-REV-01 | Laisser un avis après livraison confirmée | 🔴 P0 | Note + commentaire |
| C-REV-02 | Avis avec photo | 🟠 P1 | |
| C-REV-03 | Voir les avis d'une boutique | 🔴 P0 | |
| C-REV-04 | Voir la réponse du vendeur à un avis | 🔴 P0 | |
| C-REV-05 | Signaler un avis abusif | 🟠 P1 | |

---

## Module 11 — Notifications

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| C-NOTIF-01 | Notification commande confirmée | 🔴 P0 | |
| C-NOTIF-02 | Notification commande en préparation | 🔴 P0 | |
| C-NOTIF-03 | Notification commande en livraison | 🔴 P0 | |
| C-NOTIF-04 | Notification commande livrée | 🔴 P0 | |
| C-NOTIF-05 | Notification paiement confirmé | 🔴 P0 | |
| C-NOTIF-06 | Notification litige répondu | 🔴 P0 | |
| C-NOTIF-07 | Notification promotions boutiques favorites | 🟠 P1 | |
| C-NOTIF-08 | Notification produit favori de retour en stock | 🟠 P1 | |
| C-NOTIF-09 | Centre de notifications in-app | 🔴 P0 | |

---

## Module 12 — Profil Client

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| C-PROF-01 | Voir et modifier son profil (nom, photo) | 🔴 P0 | |
| C-PROF-02 | Mes adresses | 🔴 P0 | |
| C-PROF-03 | Mes commandes | 🔴 P0 | |
| C-PROF-04 | Mes favoris (boutiques + produits) | 🟠 P1 | |
| C-PROF-05 | Mes avis | 🟠 P1 | |
| C-PROF-06 | Paramètres notifications | 🔴 P0 | |
| C-PROF-07 | Langue de l'app | 🟠 P1 | |
| C-PROF-08 | Support / FAQ | 🔴 P0 | |
| C-PROF-09 | Déconnexion / Suppression compte | 🔴 P0 | |

---

## Module 13 — Chat avec Vendeur

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| C-CHAT-01 | Messagerie client ↔ vendeur | 🔴 P0 | Texte + image |
| C-CHAT-02 | Partage de produit dans une conversation | 🔴 P0 | |
| C-CHAT-03 | Indicateur "vu" et horodatage | 🟠 P1 | |
| C-CHAT-04 | Notifications message non lu | 🔴 P0 | |

---

## Module 14 — Wallet (P2)

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| C-WAL-01 | Voir solde wallet | 🟡 P2 | |
| C-WAL-02 | Recharger wallet (MoMo → Wallet) | 🟡 P2 | |
| C-WAL-03 | Payer avec wallet | 🟡 P2 | |
| C-WAL-04 | Historique wallet | 🟡 P2 | |
| C-WAL-05 | Transfert P2P | ⚫ OUT | Risque conformité financière |

---

## Résumé des priorités

| Priorité | Nb features |
|---|---|
| 🔴 P0 | ~52 features |
| 🟠 P1 | ~25 features |
| 🟡 P2 | ~8 features |
| ⚫ OUT | 3 features |

**Pour le lancement V1 : uniquement les P0.**

---

## Routes Flutter associées (dym_client)

Routes P0 actives :
- `startupView`, `onboardingView`, `loginView`, `signupView`
- `shellView`, `homeView`
- `searchView`, `searchResultsView`
- `storeDetailView`, `productDetailView`
- `cartView`
- `checkoutView`, `addressSelectorView`, `paymentSelectorView`, `orderConfirmationView`
- `ordersView`, `orderDetailView`
- `chatListView`, `chatDetailView`
- `notificationsView`
- `profileView`, `editProfileView`
- `addressesView`, `addressFormView`
- `videoFeedView`, `storyViewerView`

Routes P1 (à désactiver en V1 si non prêtes) :
- `walletView`, `topupView`, `transferView`
- `favoritesView`
- `orderTrackingView` (tracking temps réel)
- `reviewFormView`
- `settingsView`, `supportView`, `faqView`

---

*Document Features App Client DYM — Mai 2026*
