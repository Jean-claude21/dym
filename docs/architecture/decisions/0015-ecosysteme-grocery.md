# 0015 — Écosystème grocery multi-pays, simulation des services indisponibles

**Statut :** Acceptée (porteur produit, 2026-11-09). Remplace le contrat V1 de `VISION.md` §3, le
déclenchement par volume de l'app livreur (décision 0002) et la liste « hors périmètre définitif »
pour C-CART-11, C-PAY-04 et C-WAL-05.

## Contexte

Le contrat V1 limitait DYM à trois actions par rôle, à une ville et à un pilote. Les specs 001 à 022
sont construites. Le porteur produit veut un écosystème de haut niveau autour du grocery, où les
briques sont reliées (compte, argent, famille, contenu, livraison), sans limite de territoire.

## Décision

1. **Cadre :** produits alimentaires frais et ustensiles de cuisine. Pas de plats préparés, de
   factures, de crédit téléphone ni de colis.
2. **Périmètre :** les fonctionnalités de `VISION.md` §3 sont validées et planifiées par phases dans
   `ROADMAP.md`. Aucune limite à une ville ou un pays.
3. **Simulation :** un service externe indisponible est simulé derrière l'interface du vrai service.
   La fonctionnalité est complète et testable ; le vrai fournisseur se branche avant la production
   finale. Un moyen simulé reste signalé comme tel à l'écran.
4. **App livreur :** construite sans attendre de seuil de volume ; zems indépendants.
5. **Compte unique et grand livre** précèdent le wallet, les espaces, les commissions et le livreur.
6. **Affiliation :** règles de `VISION.md` §3 ; la vendeuse paie la commission, DYM complète pendant
   le lancement.

## Conséquences

- Constitution amendée en 2.0.0 (principes I et VII).
- Le risque principal devient l'étendue : chaque phase garde un gate, et chaque spec reste livrée
  testable en web.
- Wallet, ardoise et affiliation exigent un cadre légal par pays avant la production finale.
- Les migrations, l'argent, la RLS et les statuts restent soumis à relecture humaine avant fusion.

## Alternatives écartées

- Garder le contrat V1 jusqu'au pilote : ne correspond plus à l'ambition du produit.
- Attendre les fournisseurs réels avant de construire : bloquerait des fonctions testables dès
  maintenant.
- Élargir aux services de la vie quotidienne : dilue le positionnement grocery.
