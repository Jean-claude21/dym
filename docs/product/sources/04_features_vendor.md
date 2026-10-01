# DYM — Features App Vendor

> **Version :** 1.0 — Mai 2026  
> **Surface :** App mobile Flutter (dym_vendor)  
> **Lecteur cible :** PM, Développeur, QA

---

## Légende priorité

| Label | Signification |
|---|---|
| 🔴 P0 | Bloquant — sans ça, le vendeur ne peut pas opérer |
| 🟠 P1 | Fort impact — priorité post-lancement dès V1.1 |
| 🟡 P2 | Valeur ajoutée — roadmap moyen terme |
| ⚫ OUT | Hors scope — ne pas implémenter |

---

## Module 1 — Authentification & Onboarding Boutique

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| V-AUTH-01 | Inscription téléphone + OTP | 🔴 P0 | |
| V-AUTH-02 | Connexion téléphone + OTP | 🔴 P0 | |
| V-AUTH-03 | Onboarding guidé boutique (< 10 min) | 🔴 P0 | Voir spec ci-dessous |
| V-AUTH-04 | Reprendre un onboarding interrompu | 🔴 P0 | |
| V-AUTH-05 | Vérification d'identité renforcée (CNI) | 🟡 P2 | Si requis par régulateur |

### Spec onboarding boutique (V-AUTH-03)

**Étapes (toutes obligatoires sauf photo) :**
1. Nom de la boutique.
2. Catégorie principale (liste courte : alimentaire, textile, cosmétique, artisanat, électronique, autre).
3. Zone de service (ville + quartiers desservis, multi-sélection).
4. Mode de paiement accepté (MTN, Orange, T-Money, Wave, cash).
5. Mode de livraison proposé (livraison propre, retrait boutique, livreur DYM).
6. Photo de profil boutique (optionnel, peut être complété plus tard).
7. Premier produit guidé (photo + nom + prix).

**Règle UX :** 7 étapes max, progress bar visible, "Compléter plus tard" sur les optionnels.

---

## Module 2 — Tableau de Bord (Home Vendeur)

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| V-DASH-01 | Résumé du jour (CA, nb commandes, paiements en attente) | 🔴 P0 | |
| V-DASH-02 | Commandes actives en attente d'action | 🔴 P0 | |
| V-DASH-03 | Produits en rupture de stock | 🔴 P0 | |
| V-DASH-04 | Messages non lus | 🔴 P0 | |
| V-DASH-05 | Notifications critiques en haut | 🔴 P0 | |
| V-DASH-06 | Résumé de la semaine | 🟠 P1 | |
| V-DASH-07 | Graphique ventes (7j / 30j) | 🟠 P1 | |
| V-DASH-08 | Notification proactive soir "Ton récap du jour" | 🔴 P0 | Via FCM, 19h |

---

## Module 3 — Gestion Catalogue

### Sous-module 3a — Catégories

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| V-CAT-01 | Créer une catégorie de boutique | 🔴 P0 | |
| V-CAT-02 | Modifier une catégorie | 🔴 P0 | |
| V-CAT-03 | Désactiver / archiver une catégorie | 🔴 P0 | |
| V-CAT-04 | Réordonner les catégories | 🟠 P1 | |

### Sous-module 3b — Produits

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| V-PROD-01 | Créer un produit (photo + nom + prix + stock) | 🔴 P0 | |
| V-PROD-02 | Suggestion de nom IA depuis la photo | 🔴 P0 | Gain de temps clé |
| V-PROD-03 | Upload multi-photos par produit | 🔴 P0 | |
| V-PROD-04 | Modifier un produit | 🔴 P0 | |
| V-PROD-05 | Mettre en rupture / réactiver en 1 geste | 🔴 P0 | |
| V-PROD-06 | Archiver / supprimer un produit | 🔴 P0 | |
| V-PROD-07 | Assigner à une ou plusieurs catégories | 🔴 P0 | |
| V-PROD-08 | Créer des variantes (taille, couleur, poids) | 🔴 P0 | |
| V-PROD-09 | Stock par variante | 🔴 P0 | |
| V-PROD-10 | Alerte stock bas configurable | 🟠 P1 | Seuil par produit |
| V-PROD-11 | Import catalogue CSV | 🟡 P2 | |
| V-PROD-12 | Duplication d'un produit | 🟠 P1 | |
| V-PROD-13 | Produit + prix en lots (bundle simple) | 🟠 P1 | |
| V-PROD-14 | Bundles composés (multi-produits avec remise) | 🟡 P2 | |

### Sous-module 3c — Gestion des Prix

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| V-PRIX-01 | Prix de base | 🔴 P0 | |
| V-PRIX-02 | Prix par variante différent du prix de base | 🔴 P0 | |
| V-PRIX-03 | Prix promotionnel temporaire (date début/fin) | 🟠 P1 | |
| V-PRIX-04 | Prix de gros (quantité min) | 🟡 P2 | |

---

## Module 4 — Gestion des Commandes

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| V-ORD-01 | Notification instantanée nouvelle commande (push + son) | 🔴 P0 | |
| V-ORD-02 | Voir le détail d'une commande (client, produits, adresse, paiement) | 🔴 P0 | |
| V-ORD-03 | Accepter une commande | 🔴 P0 | |
| V-ORD-04 | Refuser une commande (avec raison) | 🔴 P0 | |
| V-ORD-05 | Marquer "En préparation" | 🔴 P0 | |
| V-ORD-06 | Marquer "Prête pour livraison/retrait" | 🔴 P0 | |
| V-ORD-07 | Assigner un livreur DYM | 🟠 P1 | Si intégration livreurs activée |
| V-ORD-08 | Marquer "Livrée" (si livraison propre) | 🔴 P0 | |
| V-ORD-09 | Historique commandes (filtrées par statut, date) | 🔴 P0 | |
| V-ORD-10 | Recherche dans les commandes | 🟠 P1 | |
| V-ORD-11 | Imprimer/partager bon de commande | 🟡 P2 | |
| V-ORD-12 | Modifier une commande avant acceptation (sur demande client) | 🟡 P2 | |

---

## Module 5 — Validation Paiement & Anti-fraude

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| V-PAY-01 | Confirmation automatique paiement MoMo (webhook) | 🔴 P0 | Aucun geste manuel requis |
| V-PAY-02 | Badge "Paiement confirmé" sur commande | 🔴 P0 | |
| V-PAY-03 | Alerte capture suspecte (détection IA) | 🔴 P0 | "Vérifiez votre compte avant de livrer" |
| V-PAY-04 | Voir le détail du paiement reçu | 🔴 P0 | Montant, moyen, date, référence |
| V-PAY-05 | Encaissement différé (payer à la livraison) | 🟠 P1 | |
| V-PAY-06 | Remboursement partiel / total | 🟠 P1 | Orchestré via admin |

---

## Module 6 — Livraison

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| V-DEL-01 | Configurer sa zone de livraison | 🔴 P0 | |
| V-DEL-02 | Configurer ses frais de livraison | 🔴 P0 | Fixe ou par zone |
| V-DEL-03 | Configurer délai moyen de préparation | 🔴 P0 | |
| V-DEL-04 | Livraison propre (marquer "parti livrer" → "livré") | 🔴 P0 | |
| V-DEL-05 | Demander un livreur DYM | 🟠 P1 | |
| V-DEL-06 | Voir statut du livreur en temps réel | 🟠 P1 | |
| V-DEL-07 | Preuve de livraison reçue | 🟠 P1 | |

---

## Module 7 — Contenu Shoppable

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| V-CONT-01 | Publier une story boutique (image/vidéo 24h) | 🔴 P0 | |
| V-CONT-02 | Taguer des produits dans une story | 🔴 P0 | |
| V-CONT-03 | Publier une vidéo shoppable | 🔴 P0 | |
| V-CONT-04 | Taguer des produits dans une vidéo | 🔴 P0 | |
| V-CONT-05 | Voir les statistiques d'un contenu (vues, clics) | 🟠 P1 | |
| V-CONT-06 | Archiver/supprimer un contenu | 🔴 P0 | |
| V-CONT-07 | Planifier la publication d'un contenu | 🟡 P2 | |
| V-CONT-08 | Importer depuis la galerie ou filmer directement | 🔴 P0 | |

---

## Module 8 — Messagerie

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| V-MSG-01 | Liste des conversations actives | 🔴 P0 | |
| V-MSG-02 | Répondre à un message client | 🔴 P0 | |
| V-MSG-03 | Partager un produit dans une conversation | 🔴 P0 | |
| V-MSG-04 | Notifications message non lu | 🔴 P0 | |
| V-MSG-05 | Broadcast ciblé (relance clients segmentés) | 🟠 P1 | |
| V-MSG-06 | Réponses rapides prédéfinies | 🟠 P1 | |
| V-MSG-07 | Conversation de groupe / annonce boutique | 🟡 P2 | |

---

## Module 9 — Promotions

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| V-PROMO-01 | Créer une promotion (% ou montant fixe) | 🟠 P1 | |
| V-PROMO-02 | Promotion sur un produit spécifique | 🟠 P1 | |
| V-PROMO-03 | Promotion sur une catégorie | 🟠 P1 | |
| V-PROMO-04 | Promotion avec date début/fin | 🟠 P1 | |
| V-PROMO-05 | Code promo personnalisé | 🟡 P2 | |
| V-PROMO-06 | Offre limitée (X premiers acheteurs) | 🟡 P2 | |

---

## Module 10 — Avis & Réputation

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| V-REV-01 | Voir les avis reçus sur la boutique | 🔴 P0 | |
| V-REV-02 | Répondre à un avis | 🔴 P0 | |
| V-REV-03 | Signaler un avis abusif | 🟠 P1 | |
| V-REV-04 | Note globale boutique visible dans le profil | 🔴 P0 | |

---

## Module 11 — Analytics & Résumés

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| V-ANA-01 | CA du jour / semaine / mois | 🔴 P0 | |
| V-ANA-02 | Nombre de commandes par période | 🔴 P0 | |
| V-ANA-03 | Produits les plus vendus (top 5) | 🟠 P1 | |
| V-ANA-04 | Taux de commandes acceptées vs refusées | 🟠 P1 | |
| V-ANA-05 | Clients réguliers (ont commandé 2+ fois) | 🟠 P1 | |
| V-ANA-06 | Export données (CSV) | 🟡 P2 | |
| V-ANA-07 | Dashboard analytique avancé | 🟡 P2 | |

---

## Module 12 — Paramètres Boutique

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| V-SET-01 | Ouvrir / fermer la boutique (bouton unique) | 🔴 P0 | |
| V-SET-02 | Horaires d'ouverture par jour | 🔴 P0 | |
| V-SET-03 | Modifier les infos boutique (nom, description, photo) | 🔴 P0 | |
| V-SET-04 | Gérer les modes de paiement acceptés | 🔴 P0 | |
| V-SET-05 | Gérer les modes de livraison | 🔴 P0 | |
| V-SET-06 | Paramètres notifications | 🔴 P0 | |
| V-SET-07 | Mode vacances (suspension temporaire commandes) | 🟠 P1 | |
| V-SET-08 | Gestion équipe / co-gérants | 🟡 P2 | |

---

## Module 13 — Wallet Vendeur

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| V-WAL-01 | Solde disponible | 🟠 P1 | |
| V-WAL-02 | Retrait vers MoMo | 🟠 P1 | |
| V-WAL-03 | Historique des revenus | 🟠 P1 | |
| V-WAL-04 | Détail commissions DYM | 🟠 P1 | |

---

## Module 14 — Profil Vendeur

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| V-PROF-01 | Voir et modifier le profil personnel | 🔴 P0 | |
| V-PROF-02 | Support / FAQ vendeur | 🔴 P0 | |
| V-PROF-03 | Contacter le support DYM | 🔴 P0 | |
| V-PROF-04 | Déconnexion | 🔴 P0 | |
| V-PROF-05 | Historique des signalements reçus | 🟡 P2 | |

---

## Résumé des priorités

| Priorité | Nb features |
|---|---|
| 🔴 P0 | ~55 features |
| 🟠 P1 | ~28 features |
| 🟡 P2 | ~14 features |
| ⚫ OUT | 0 (périmètre bien défini) |

---

## Routes Flutter associées (dym_vendor)

Routes P0 actives :
- `SplashFlowWrapper`, `OnboardingFlowWrapper`, `AuthFlowWrapper`
- `ShellView`, `DashboardView`
- `OrdersView`, `OrderDetailView`
- `CatalogView`, `ProductFormView`, `CategoriesView`
- `MessagesView`, `ChatView`
- `ReviewsView`
- `StoreSetupView`, `StoreInfoView`, `StoreHoursView`
- `NotificationsView`
- `StatusView`, `StatusFormView`
- `VideosView`, `VideoFormView`
- `ProfileView`, `ProfileEditView`

Routes P1 (actives en V1 si implémentées) :
- `AnalyticsView`
- `PromotionsView`
- `WalletView`
- `PaymentMethodsView`
- `BundlesView`, `BundleFormView`
- `DeliveryZoneView`

Routes P2 :
- `HelpView` (peut rester)
- `SettingsView`

---

*Document Features App Vendor DYM — Mai 2026*
