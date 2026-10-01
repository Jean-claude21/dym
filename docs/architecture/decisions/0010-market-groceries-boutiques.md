# 0010 — Courses au marché et boutique comme unité centrale

**Statut :** Acceptée · 2026-10-01

## Contexte

La vision d'origine mettait en avant le textile, la beauté et l'artisanat. Les courses au marché
offrent une fréquence d'achat hebdomadaire et rendent le panier multi-boutiques naturel (une recette
réunit plusieurs vendeuses). Une part importante de l'offre vient aussi de personnes qui vendent
depuis chez elles, sans étal ni vitrine.

## Décision

1. **DYM est orienté courses au marché.** Le textile, la beauté et l'artisanat restent des rayons
   parmi d'autres.
2. **La boutique est l'unité centrale.** Chaque vendeuse a une boutique, avec une **origine** :
   `marche` (étal), `maison` (fait maison), `magasin` (boutique de quartier). Les origines sont une
   donnée de référence, extensible par pays.
3. **Adresse privée pour l'origine `maison`** : seule la zone est publique ; l'adresse exacte est
   transmise au livreur au moment du ramassage.
4. **Unités du marché configurables** (le tas, la botte, la boîte, le litre, le kilo…), par pays,
   en plus du poids ou du volume indicatif.

## Conséquences

- Schéma : `stores.origin`, `stores.zone_id`, adresse de ramassage séparée et protégée par RLS ;
  table de référence `units` par pays ; une commande peut impliquer plusieurs ramassages.
- Produit : rayon « Fait maison », page boutique, étape « Où vends-tu ? » à l'inscription,
  remplacements de produits frais, créneaux alignés sur les horaires du marché.
- Livraison : frais calculés selon le nombre de ramassages.
- Nouvelle hypothèse H11 (part de l'offre fait maison) et H12 (fréquence d'achat).

## Alternatives écartées

Marketplace généraliste centrée sur le textile ; boutique réservée aux vendeuses ayant un local.
