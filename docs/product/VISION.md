# DYM — Vision produit

> Document de référence. En cas de conflit avec `sources/`, **ce document et `ROADMAP.md` font foi**.
> Les sources sont conservées pour la traçabilité des identifiants de features (C-\*, V-\*, L-\*, A-\*).

## 1. Le problème

Le commerce informel ouest-africain (80 %+ de l'activité quotidienne) vend via DM WhatsApp/Instagram.
Pour la vendeuse : commandes perdues dans les conversations, fausses captures MoMo, aucun chiffre.
Pour la cliente : 4 vendeuses = 4 DM, 4 négociations, 4 paiements, 4 livraisons sans suivi.

## 2. La promesse

> **DYM transforme le marché informel en marketplace mobile : découvrir, comparer, commander,
> payer, recevoir — simple, local, fiable.**

| Acteur | Promesse |
|---|---|
| Awa, cliente | « Je trouve des vendeuses locales de confiance, je combine plusieurs boutiques dans un panier, je paie une fois (cash ou MoMo) et je sais où est ma commande, sans DM. » |
| Fatou, vendeuse | « Je publie un produit en moins d'une minute, je reçois des commandes structurées, j'encaisse sans ambiguïté et je vois mes chiffres du jour. » |
| Équipe DYM | « Tout incident est résolu en moins d'une heure, depuis l'admin, sans développeur. » |
| Kofi, livreur | Phase 4, sur déclencheur de volume uniquement. |

## 3. Le contrat V1 (non négociable jusqu'à la fin du pilote)

**Phrase de valeur :** une vendeuse publie ses produits ; une cliente commande (plusieurs boutiques,
un panier) et choisit cash à la livraison ou MoMo ; la vendeuse reçoit, encaisse et livre ; la
cliente reçoit ce qu'elle a commandé.

| Surface | Actions autorisées en V1 |
|---|---|
| Vendeuse | 1. Créer sa boutique et publier un produit · 2. Recevoir et traiter une commande · 3. Confirmer l'encaissement |
| Cliente | 1. Trouver un produit · 2. Commander multi-boutiques et choisir le paiement · 3. Suivre sa commande |
| Admin | 1. Résoudre un incident (voir, corriger un statut, rembourser, suspendre) |
| Livreur | Aucune app en V1 |

**Preuves de réussite V1** (témoignages réels, pas des métriques) :
1. Fatou : « J'ai reçu une commande, j'ai encaissé sans confusion, j'ai livré. Le lendemain j'en ai eu une autre. »
2. Awa : « J'ai trouvé, j'ai choisi cash, j'ai reçu. Je vais recommander. »
3. L'équipe : « Un incident a été résolu depuis l'admin en moins d'une heure, sans développeur. »

Avec 30 vendeuses et 300 clientes, dans **une seule ville**.

## 4. Ce que DYM n'est pas

| Comparé à | Différence |
|---|---|
| TikTok Shop | TikTok crée le désir, DYM ferme la transaction. DYM n'exige aucune audience. |
| Jumia / Gozem | Ils couvrent le formel. DYM couvre la vendeuse informelle non référencée. |
| WhatsApp Business | Canal de conversation, pas de transaction. DYM s'y branche (partage) sans le remplacer. |
| Kidia | Mono-marchand dans WhatsApp. DYM = multi-vendeuses + panier unifié dans une app. |

**Règle de frontière :** une feature qui marche mieux dans le WhatsApp d'une seule marchande → Kidia.
Une feature qui exige plusieurs vendeuses ou un catalogue agrégé → DYM.

## 5. Principes produit

1. **Profondeur avant volume** : Fatou traite 10 commandes/semaine avant d'avoir 1 000 vendeuses.
2. **Valider avant de construire** : maquette testée sur le terrain → spec → code.
3. **Sortie de backlog** uniquement si une personne réelle est bloquée par l'absence de la feature
   et que sa résolution rapproche une preuve V1.
4. **Générique par défaut** : pays, devise, moyens de paiement, langues, fournisseurs (paiement, IA,
   SMS) sont des données de configuration, jamais du code.
5. **Conçu pour le terrain** : Android d'entrée de gamme (2 Go RAM), réseau instable, plein soleil,
   littératie variable.

## 6. Applications

| App | Utilisateur | Plateforme | Phase |
|---|---|---|---|
| DYM (`dym_client`) | Awa | Android, iOS | 1 |
| DYM Vendeur (`dym_vendor`) | Fatou | Android, iOS | 1 |
| DYM Admin (`dym_admin`) | Équipe ops | Flutter Web (Coolify) | 1 (minimal) |
| DYM Livreur (`dym_delivery`) | Kofi | Android | 4, déclenchée (> 50 commandes/jour pendant 14 jours) |

Hors apps : Neon Functions (logique serveur) et un site léger sur Coolify (CGU, confidentialité,
deep links, retour de paiement, liens de partage).
