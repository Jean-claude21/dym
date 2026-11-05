# Sitemap et flux des apps DYM

État du code sur `feat/023-pilot-test-setup` (2026-11-05). Les schémas sont en Mermaid (rendus par
GitHub). 🔒 = derrière un interrupteur (Admin → Réglages → Interrupteurs).

## DYM Cliente

```mermaid
flowchart TD
  S[Démarrage] -->|pas de session| W[Bienvenue 3 écrans]
  S -->|session| H
  W --> E[Email] --> C[Code 6 chiffres] --> P[Prénom + quartier]
  E -->|J'ai un mot de passe| H
  C --> H
  P --> H

  subgraph Onglets
    H[Accueil]
    R[Rayons]
    V[Vidéos 🔒]
    O[Commandes]
    M[Moi]
  end

  H --> SR[Recherche + filtres]
  H --> VS[Recherche vocale / photo 🔒]
  H --> CP[Copilote : panier proposé 🔒]
  H --> ST[Stories 🔒] --> SP
  H --> SP[Page boutique]
  H --> RY[Rayon]
  R --> RY
  RY --> FP[Fiche produit]
  SR --> FP
  SP --> FP
  SP --> AV[Avis de la boutique]
  SP --> CH[Conversation avec la boutique]
  FP -->|Ajouter| PA
  RY -->|+ sur la carte| PA[Panier multi-boutiques]
  PA --> AD[Adresses] --> PA
  PA --> PY[Paiement : cash / en ligne simulé] --> OS[Commande envoyée]
  OS --> OD
  O --> OD[Suivi de commande]
  O --> NT[Notifications]
  OD -->|avant préparation| AN[Annuler]
  OD -->|livrée| RV[Laisser un avis]
  OD -->|livrée| PB[Signaler un problème = litige]
  OD --> CH
  OD -->|livrée| RO[Commander à nouveau] --> PA
  M --> AD
  M --> NS[Réglages notifications]
  M --> MS[Messages] --> CH
  M --> HL[Aide / tickets]
  M --> LG[Langue, déconnexion, suppression du compte]
```

## DYM Vendeuse

```mermaid
flowchart TD
  S[Démarrage] -->|pas de session| E[Email → code ou mot de passe]
  E --> P[Prénom + quartier]
  P -->|pas de boutique| OB[Ouverture en 7 étapes : nom, adresse, rayon, livraison, paiement, horaires]
  OB --> OK[Boutique ouverte] --> H
  S -->|session| H

  subgraph Onglets
    H[Accueil : tableau de bord]
    O[Commandes]
    MS[Messages]
    PR[Produits]
    B[Boutique]
    M[Moi]
  end

  H -->|urgences| O
  H --> PR
  H --> MS
  O --> OD[Détail commande] --> T[Accepter / refuser → préparer → prête → en livraison → livrée → encaissé]
  OD --> LT[Répondre à un litige]
  MS --> CV[Conversation : texte, photo, produit]
  PR --> PE[Créer / modifier un produit : photo, prix, unité, variantes, stock]
  PE --> IA[Fiche proposée par l'IA depuis la photo 🔒]
  PR --> CAT[Mes catégories]
  PR -->|interrupteur| STK[Disponible / rupture]
  B --> SET[Réglages : nom, adresse, zones, paiement, horaires, ouvrir/fermer]
  B --> AVI[Avis → répondre]
  B --> CT[Stories / vidéos 🔒]
  B --> BC[Relancer mes clientes 🔒]
  M --> HL[Aide / tickets]
  M --> LG[Langue, déconnexion, suppression]
```

## DYM Admin

```mermaid
flowchart TD
  S[Démarrage] --> L[Connexion : email → code ou mot de passe, ou Google]
  L -->|email dans ADMIN_EMAILS ou invité| D
  L -->|sinon| X[Accès réservé]

  subgraph Menu
    D[Tableau de bord du matin]
    O[Commandes]
    LI[Litiges]
    B[Boutiques]
    CL[Clientes]
    F[Finance]
    SU[Support]
    MO[Modération]
    R[Réglages]
    AU[Journal d'audit]
  end

  D --> AI[Santé IA et paiements]
  O --> OD[Commande : forcer un statut, annuler + rembourser, assigner un livreur]
  LI --> LD[Litige : fil à trois → aucune action / remboursement partiel / total]
  B --> BD[Boutique : corriger, suspendre / réactiver, vue vendeuse, supprimer]
  CL --> CD[Fiche cliente : commandes, litiges, tickets]
  F --> RV[Revenus, remboursements à exécuter, paiements en attente]
  SU --> TK[Ticket : répondre, clore]
  MO --> MD[Signalements : retirer / garder]
  R --> RP[Pays, villes et quartiers, moyens de paiement, commission, frais, catégories, interrupteurs, admins]
```
