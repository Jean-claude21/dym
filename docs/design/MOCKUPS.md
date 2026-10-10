# DYM — Maquettes clés

> Format : prototypes HTML cliquables au format mobile (360 × 640, Android d'entrée de gamme),
> partagés par lien et ouverts sur le téléphone des testeuses. Admin : 1280 × 800.
> Chaque parcours inclut les états **vide, chargement, erreur et hors ligne**, et deux pays
> (Togo en XOF, Ghana en GHS) pour vérifier que l'interface reste générique.
> Une fois validées, les maquettes deviennent les critères d'acceptation des specs.

## Avancement

Direction validée le 2026-10-01 ([DESIGN_DIRECTION.md](DESIGN_DIRECTION.md)). Écrans déjà rendus
dans [`screens/`](screens/) : parcours 2, 3, 4, 5, 7, 9 (étape « Où vends-tu ? ») et 12. Spec 005 :
parcours 1 complet, « Moi » (parcours 8, suppression du compte), connexion vendeuse et admin
(écrans 09 à 15, à valider). Spec 006 : parcours 9 complet (onboarding de la boutique en 7
étapes, écrans 16 à 22) et ouverture ou fermeture en un geste (parcours 13, écran 23), à valider.
Spec 007 : parcours 10 (publier un produit par photo, écrans 24 à 27), à valider.
Spec 008 : parcours 2 et 3 construits (écrans validés 02, 03, 04 ; nouveaux écrans 28 à 30, à valider).
Spec 009 : parcours 4 et 5 (panier validé 05 ; livraison 34, mes adresses 35, nouvelle adresse 36,
commande envoyée 37, à valider).
Spec 010 : parcours 6 et 12 (paiement en cours 39, paiement échoué 40, commandes de la vendeuse 41,
détail du paiement 42, à valider).
Spec 011 : parcours 7, 8 et 12 (suivi validé 06, commande reçue validée 08 ; mes commandes 43,
notifications 44, refus 45, réglages des notifications 46, à valider).
Spec 012 : litiges (signaler un problème 49, suivi du signalement 50, litige côté vendeuse 51,
à valider ; écrans de décision de l'équipe dans la spec admin-ops).
Spec 013 : parcours 14 à 17 de l'admin, format bureau (commandes 52, détail d'une commande 53,
litiges 54, boutiques 55, réglages 56, finances 57, journal d'audit 58, à valider). Aucun nom de
ville ou de quartier : les lieux du pays hôte sont saisis par l'équipe. Correction terrain du 2026-10-02 : aucune liste de quartiers
affichée d'avance (position ou recherche), écran 12 compris.
Les autres parcours sont produits spec par spec dans la même direction.

## Ordre de production

Spec 014 : parcours 11, [maquette 59 — tableau de bord vendeuse](screens/59-vendeuse-tableau-de-bord.webp),
produite en image dans la direction validée ; à valider avant fusion.

Spec 015 : messagerie cliente ↔ vendeuse ([60 — conversation côté cliente](screens/60-cliente-conversation.webp),
[61 — messages de la vendeuse](screens/61-vendeuse-messages.webp),
[62 — conversation et partage de produit](screens/62-vendeuse-conversation.webp)), à valider avant fusion.

Les trois parcours qui portent les hypothèses les plus risquées passent en premier : **4, 10, 12**.

## Parcours

| # | Surface | Parcours | IDs | Tâche de test | Critère |
|---|---|---|---|---|---|
| 1 | Cliente | Arrivée : pays et zone, connexion Google ou OTP email | C-AUTH-01..05 | « Crée ton compte. » | Sans aide, < 45 s |
| 2 | Cliente | Découverte : allée des boutiques proches, catégories, recherche, filtres, page boutique | C-HOME-01/02, C-SEARCH-01..03, C-CAT-01/02 | « Trouve du tissu wax bleu près de chez toi. » | < 60 s |
| 3 | Cliente | Fiche produit : galerie, variantes, délai, rupture | C-CAT-03..07 | « Choisis la taille M et ajoute au panier. » | Sans erreur |
| 4 | Cliente | **Panier multi-boutiques** : sous-paniers par boutique, frais de chacune | C-CART-01..09 | « Ajoute un article d'une 2e boutique et dis combien tu paies au total. » | Combinaison spontanée (H2), total compris |
| 5 | Cliente | Checkout : adresse, livraison par boutique, cash ou MoMo, récapitulatif | C-CHECK-01..05, C-ADDR | « Commande, paiement à la livraison. » | < 90 s |
| 6 | Cliente | Paiement MoMo : redirection, attente, échec, succès | C-PAY-01/02 | « Paie par MoMo. Que se passe-t-il si ça échoue ? » | État compris à chaque étape |
| 7 | Cliente | Mes commandes : course du zem, statuts, annuler, signaler un problème | C-ORD-01..04/07/08 | « Où est ta commande ? Signale qu'il manque un article. » | Réponse sans DM |
| 8 | Cliente | Centre de notifications, profil, adresses | C-NOTIF-09, C-PROF | « Ajoute l'adresse de ton bureau. » | Sans aide |
| 9 | Vendeuse | Onboarding boutique en 7 étapes, dont **« Où vends-tu ? »** (au marché, fait maison, boutique) | V-AUTH-03/04 | « Ouvre ta boutique. » | < 10 min, origine choisie sans hésiter |
| 10 | Vendeuse | **Publier un produit par photo** : nom, catégorie, description proposés ; variantes, stock | V-PROD-01..09 | « Mets en vente ce pagne. » | < 60 s (H1, H8) |
| 11 | Vendeuse | Tableau de bord du jour, caisse du soir | V-DASH-01..05/08 | « Combien as-tu vendu aujourd'hui ? » | < 5 s |
| 12 | Vendeuse | **Commande reçue** : son, accepter ou refuser, statuts, paiement confirmé, encaissement cash | V-ORD-01..09, V-PAY-01..05 | « Une commande arrive : traite-la jusqu'à livrée. » | Sans aide (H9) |
| 13 | Vendeuse | Réglages : ouvrir/fermer, horaires, zones, frais, moyens de paiement | V-SET-01..05, V-DEL-01..03 | « Ferme ta boutique jusqu'à demain. » | 1 geste |
| 14 | Admin | Commande bloquée : chronologie, forcer un statut, annuler et rembourser, assigner une livraison | A-ORD-01..08, A-LIV-04 | « Débloque cette commande. » | < 5 min |
| 15 | Admin | Litige : preuves, décision, remboursement | A-LIT-01..06 | « Tranche ce litige. » | < 5 min |
| 16 | Admin | Vendeuses : liste, profil, suspendre ou activer | A-VEN-01..09 | « Suspends cette vendeuse. » | Avec raison et trace |
| 17 | Admin | Configuration : pays, devises, moyens de paiement, commission, catégories | A-CFG-01..06 | « Active le Ghana. » | Sans développeur |
| 18 | Vision | IA d'intention : « anniversaire pour 20 personnes » → panier proposé | C-SEARCH-06 | Test d'envie | 3/5 l'utiliseraient (H10) |
| 19 | Vision | Fil vidéo et stories shoppables | C-HOME-06/07 | Test d'envie | 3/5 l'utiliseraient (H10) |

## Protocole de test

- 5 vendeuses et 5 clientes de la ville pilote, sur leur propre téléphone.
- Tâches lues à voix haute, chronométrées, **sans aide**. On note les mots exacts et les hésitations.
- Gate : 4 testeurs sur 5 réussissent chaque tâche selon le critère. Sinon : on corrige et on reteste.
- Résultats consignés dans `docs/design/research/AAAA-MM-JJ-<parcours>.md` et reportés dans
  `docs/product/HYPOTHESES.md`.
