# DYM — Contrat Actif V1

> **Ce document est la référence absolue pour tout travail sur DYM jusqu'à la fin du pilote terrain.**
> Toute feature, toute décision, toute session de codage doit pouvoir répondre "oui" à : **Est-ce que ça avance le contrat V1 ?**
> Si la réponse est "non" ou "peut-être" — ce n'est pas le moment.

---

## La phrase de valeur centrale

> **"Un vendeur informel publie ses produits. Un client commande et choisit son mode de paiement (cash à la livraison ou MoMo). Le vendeur reçoit la commande, encaisse, et livre. Le client reçoit ce qu'il a commandé."**

Tout ce qui n'est pas dans cette phrase est hors contrat V1.

---

## Ce qui est autorisé en V1

### Surface Vendeur — 3 actions, rien de plus

1. **Créer sa boutique et publier un produit** (photo + prix + stock).
2. **Recevoir une commande et mettre à jour son statut** (reçue → en préparation → livrée).
3. **Encaisser et confirmer le paiement** selon le mode choisi : cash à la livraison (majoritaire) ou MoMo (webhook automatique).

Tout le reste — analytics, promotions, vidéos, broadcast, bundles, wallet — est **hors contrat V1**.

---

### Surface Client — 3 actions, rien de plus

1. **Trouver un produit** (recherche texte ou navigation boutiques).
2. **Commander depuis plusieurs boutiques en un seul panier** et choisir le paiement : cash à la livraison ou MoMo.
3. **Savoir où en est sa commande** (statuts notifiés, pas de DM nécessaire).

Tout le reste — IA intention, vidéos shoppables, wallet, favoris avancés, avis détaillés — est **hors contrat V1**.

---

### Surface Admin — 1 capacité, rien de plus

1. **Gérer un incident sans intervention technique** : voir une commande bloquée, corriger un statut, déclencher un remboursement, suspendre un vendeur.

Supabase Studio + un script SQL si nécessaire. Pas d'app admin custom en V1.

---

### Surface Livreur — 0 app en V1

La livraison V1 est assurée par les vendeurs eux-mêmes ou des coursiers externes.
L'app dym_delivery **n'est pas dans le contrat V1**.

---

## Ce qui est formellement interdit en V1

| Interdit | Pourquoi |
|---|---|
| Ajout de feature non listée ci-dessus | Nourrit la chair de complexité |
| Refactoring de code fonctionnel | Complexité déguisée en qualité |
| Nouvelles routes non liées aux 3 actions | Construction de la vision finale à la place de l'étape |
| Analytics, dashboard avancé | Mesure ce qui n'existe pas encore |
| App livreur | Volume insuffisant pour justifier |
| Deuxième ville | Profondeur avant volume |
| Features "logiques" non demandées par un utilisateur réel | Signature de la chair intellectuelle |

---

## La preuve que V1 est réussie

V1 est réussie quand ces 3 preuves existent simultanément — pas en métriques, en témoignages réels :

**Preuve 1 — Fatou dit :**
> "J'ai reçu une commande dans l'app. J'ai encaissé sans confusion (cash ou MoMo). J'ai livré. Le lendemain j'en ai eu une autre."

**Preuve 2 — Awa dit :**
> "J'ai trouvé ce que je cherchais, j'ai choisi cash à la livraison, j'ai reçu ma commande. Je vais recommander."

**Preuve 3 — L'équipe DYM dit :**
> "Il y a eu un incident. On l'a résolu depuis l'interface en moins d'une heure sans appeler un développeur."

Si ces 3 preuves existent avec 30 vendeurs et 300 clients — V1 est livrée. Tout le reste est la prochaine étape.

---

## Règle de session

Avant chaque session de travail, une seule question :

> **"Ce que je vais faire aujourd'hui rapproche-t-il directement l'une des 3 preuves ?"**

Si oui → travaille.
Si non → pose l'outil. La session n'est pas le bon moment.

---

*Contrat V1 DYM — Mai 2026. Ne pas modifier sans décision délibérée hors session de codage.*
