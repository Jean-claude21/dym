# DYM — Maquettes clés

> Format : prototypes HTML cliquables au format mobile (360 × 640, Android d'entrée de gamme),
> partagés par lien et ouverts sur le téléphone des testeuses. Admin : 1280 × 800.
> Chaque parcours inclut les états **vide, chargement, erreur et hors ligne**, et deux pays
> (Togo en XOF, Ghana en GHS) pour vérifier que l'interface reste générique.
> Une fois validées, les maquettes deviennent les critères d'acceptation des specs.

## Ordre de production

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
| 9 | Vendeuse | Onboarding boutique en 7 étapes, **choix du motif généré** | V-AUTH-03/04 | « Ouvre ta boutique. » | < 10 min, motif choisi avec plaisir |
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
