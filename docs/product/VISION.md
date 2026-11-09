# DYM — Vision produit

> Document de référence. En cas de conflit avec `sources/`, **ce document et `ROADMAP.md` font foi**.
> Les sources sont conservées pour la traçabilité des identifiants de features (C-\*, V-\*, L-\*, A-\*).
> Refonte du 2026-11-09 : décision [0015](../architecture/decisions/0015-ecosysteme-grocery.md).

## 1. Le problème

Le commerce alimentaire informel vend via DM WhatsApp/Instagram et au marché.
Pour la vendeuse : commandes perdues dans les conversations, fausses captures MoMo, aucun chiffre.
Pour la cliente : 4 vendeuses = 4 DM, 4 négociations, 4 paiements, 4 livraisons sans suivi.
Pour les créateurs de cuisine : ils donnent envie à des milliers de personnes, sans en vivre.

## 2. La promesse

> **« Tu vois, tu as envie, c'est chez toi dans l'heure, et celui qui t'a donné envie est payé. »**

DYM réunit les boutiques alimentaires d'un quartier (étals du marché, vendeuses qui préparent
depuis chez elles, épiceries) dans une app de courses, et relie tout ce qui entoure l'achat : le
contenu qui donne envie, la famille qui remplit et paie, l'argent, la livraison.

### Le cadre : le grocery

- **DYM vend des produits alimentaires frais**, et ce qui permet de les cuisiner : **les ustensiles
  de cuisine**. Une vidéo de cuisine doit donner accès à tout le nécessaire.
- **Hors cadre :** plats préparés et restauration, factures, crédit téléphone, envoi de colis, et
  tout service sans lien avec les courses.
- **La boutique est l'unité centrale.** Chaque vendeuse a la sienne, avec une origine affichée :
  **Au marché**, **Fait maison**, **Boutique** (décision
  [0010](../architecture/decisions/0010-market-groceries-boutiques.md)).
- **Plusieurs pays, plusieurs villes :** les pays, villes et devises sont des données de
  configuration ; DYM n'est limité à aucun territoire (décision
  [0014](../architecture/decisions/0014-admins-par-defaut-et-pays-ouverts.md)).

### Les principes de l'écosystème

1. **Un seul compte DYM** peut être à la fois client, vendeur, livreur et créateur, avec un seul
   wallet.
2. **Tout est relié** : un contenu remplit un panier, un espace le valide, une poche le paie, la
   commission du créateur revient dans son wallet. Comme un compte financier unique, chaque brique
   nourrit les autres.
3. **Tout est configurable par la personne** : espaces et poches sont illimités, à nom libre.
4. **Peu de briques, chacune de très haut niveau** plutôt que beaucoup de fonctions moyennes.
5. **Ce qui est indisponible se simule proprement**, derrière la même interface que le vrai
   service. L'app marche et se teste ; le vrai fournisseur se branche avant la production finale.

| Acteur | Promesse |
|---|---|
| Awa, cliente | « Je dis ce que je veux, DYM compose mes courses ; ma famille remplit, je valide, et je sais où est ma commande. » |
| Fatou, vendeuse | « Je publie en quelques secondes, je reçois des commandes claires, je connais enfin mes vrais chiffres. » |
| Kofi, livreur | « Mes tournées sont claires, mes gains arrivent tout de suite, le cash ne crée plus de dispute. » |
| Créateur | « Je montre ce que je cuisine, et je suis payé quand les gens achètent. » |
| Équipe DYM | « Chaque franc est tracé, tout incident se résout depuis l'admin, sans développeur. » |

## 3. Les fonctionnalités validées

### Cliente

| Fonctionnalité | Avantage |
|---|---|
| Recherche IA (« du riz pour 4 personnes ») | Les bonnes quantités chez les bons marchands |
| Assistant de courses : propose la semaine, la personne valide | Plus besoin de penser à sa liste |
| Paniers enregistrés (petit-déjeuner, déjeuner, mois) | Recommander en un geste |
| Précommande à prix bloqué, arrivages réservés | Le frais du jour sans craindre la hausse |
| Créneaux de livraison, courses récurrentes | Être livré quand on est là |
| Carnet : adresses, boutiques et produits favoris | Plus aucune ressaisie |
| Remplacement validé par photo | Pas de mauvaise surprise |
| Achat groupé entre voisins, départ groupé | Prix de gros, livraison partagée |
| Marchandage dans la limite fixée par la vendeuse | Le geste du marché |
| Garantie fraîcheur | Remboursement immédiat |
| Chat enrichi (vocaux, photo, vidéo, livreur inclus) | Se comprendre, même sans bien écrire |
| Appel audio et vidéo « Montre-moi » | Voir le produit avant de payer |

### Espaces (illimités, nom libre)

Un espace réunit des membres et leurs rôles (qui remplit, qui valide, qui paie), un budget, des
paniers, des adresses et, si on le souhaite, une poche d'argent. Foyer, tontine ou cagnotte ne sont
que des modèles de départ.

| Fonctionnalité | Avantage |
|---|---|
| Remplir à plusieurs, un seul valide et paie | Le payeur garde le contrôle |
| Commander pour quelqu'un, livraison chez un proche, photo à la remise | Nourrir sa famille à distance, y compris depuis l'étranger |
| Payer à plusieurs, budget par personne | Partage clair, dépenses maîtrisées |

### Wallet

| Fonctionnalité | Avantage |
|---|---|
| Poches libres, avec leurs règles (objectif, arrondi, usage réservé) | Mettre de côté pour ses courses |
| Recharge MoMo, ou cash auprès d'une vendeuse ou d'un livreur | Accessible même sans Mobile Money |
| Paiement par QR à l'étal | DYM utile même sans livraison |
| Cashback, paniers à offrir | Une raison de garder son argent sur DYM |

### Contenus et créateurs

- **Publient :** clients, marchands, et personnes inscrites surtout pour créer.
- **Formats :** recette, enseignement, astuce, avis, vie du marché, ou libre.
- **Produits :** on en indexe ou non. **Catégorie :** choisie, sinon classée par l'IA, sinon « Autre ».
- **Vue flexible :** Pour toi, Abonnements, Recettes, Apprendre, Près de moi ; centres d'intérêt
  réglables, contenus masquables.
- **Sous une vidéo de cuisine :** « Tout pour la faire » ajoute ingrédients frais et ustensiles.
- **Algorithme de valorisation :** qualité (vu jusqu'au bout, enregistré, partagé), intention
  (ajouts au panier, achats livrés), fraîcheur, confiance, moins les signalements.
- **Lecture :** plein écran instantanée, préchargement, qualité adaptée à la 3G, profils,
  abonnements, commentaires, modération.
- **Lien avec TikTok dans les deux sens** : import d'une vidéo par son créateur, partage vers TikTok
  avec le lien du panier.

#### Affiliation

| Étape | Règle |
|---|---|
| Inscription | Même compte DYM, profil créateur ; on peut s'inscrire uniquement pour ça |
| Taux | La vendeuse fixe sa commission par produit, au-dessus d'un minimum réglable par pays |
| Indexation | **Produit précis** d'une vendeuse, ou **ingrédient générique** relié à la meilleure vendeuse proche du spectateur |
| Générique sans taux | Minimum du pays, payé par la vendeuse reliée |
| Payeur | La vendeuse ; DYM complète pendant le lancement |
| Attribution | Dernier contenu vu avant l'achat, article par article, délai réglable (7 jours par défaut) |
| Validation | « En attente » jusqu'à livraison payée et fin du délai de réclamation |
| Paiement | Versée dans le wallet ; annulée si la cliente est remboursée |
| Antifraude | Aucune commission sur ses propres achats, ni sur la même adresse ou le même appareil |
| Transparence | Mention « contenu rémunéré », tableau de bord créateur |

Le contenu sans produit gagne des points ou des bonus selon sa valeur.

### Vendeuse

| Fonctionnalité | Avantage |
|---|---|
| Caisse : ventes en app et hors app, à la voix | Ses vrais chiffres |
| « Ma caisse » : gains et versements | Savoir ce qu'elle a et ce qui arrive |
| Studio IA : photo et fiche produit | Publier en quelques secondes |
| Boutique partageable sur WhatsApp | Vendre à ses clientes sans effort |
| Ardoise et relances | Faire crédit sans rien perdre |
| Arrivages, prix de fin de marché | Moins de pertes sur le frais |
| Achat de gros groupé | Meilleures marges |
| Commission fixée pour les créateurs | Des ventes sans publicité |

### Livreur

| Fonctionnalité | Avantage |
|---|---|
| Tournée multi-boutiques, code de remise | Moins de trajets, livraison prouvée |
| Gains en direct, retrait immédiat | Payé tout de suite |
| Gestion du cash | Plus d'erreurs ni de disputes |
| Score, bonus, zones de forte demande | Gagner plus en travaillant mieux |
| Consignes de conservation par produit | Le frais arrive frais |

Modèle : **zems indépendants qui acceptent des missions**.

### DYM

| Fonctionnalité | Avantage |
|---|---|
| Compte unique et grand livre | Chaque franc tracé, socle de tout le reste |
| Commission, DYM+, vendeuse Pro, visibilité sponsorisée | Plusieurs revenus |
| Centre d'opérations, règles par pays | Piloter sans développeur |
| Antifraude et modération par IA | Protéger l'argent et la qualité |

## 4. Les agents IA

Un agent reçoit un objectif et des outils, agit, observe le résultat et recommence jusqu'à finir.

| Agent | Rôle |
|---|---|
| Courses | Recherche, composition de panier, courses récurrentes |
| Vendeuse | Fiches produits, arrivages, conseils |
| Contenus | Classement, repérage des ingrédients dans une vidéo |
| Modération et fraude | Détecter les abus et les envoyer à un humain |
| Support | Répondre, ouvrir un litige ; l'humain tranche les remboursements |

**Recherche :** comprendre (produit ou plat, personnes, budget, délai, préférences, allergies) ;
savoir (recettes, quantités, conversions tas/bol/kilo, noms locaux) ; chercher par le texte et le
sens ; classer selon des règles réglables depuis l'admin (distance, ouverture, stock, fiabilité,
prix, moins d'arrêts, habitudes, marchands mis en avant et signalés) ; expliquer ; apprendre.

**Garde-fous :** l'IA propose, le serveur décide (prix, stock, paiement). Aucune dépense sans
validation, sauf règle réglée par la personne. Échec : retour à la recherche classique, et ce qui
manque est dit clairement. Modèles configurés en base, chaque action tracée. Les tournées, le
classement et les commissions sont des **règles et algorithmes**, pas de l'IA générative.

## 5. Avant la production finale

Tout est construit et testable en simulation. Avant la production finale : brancher les vrais
fournisseurs (Moneroo, FCM, cartographie), retirer les moyens simulés et les comptes de test, et
obtenir le cadre légal du wallet, de l'ardoise et de l'affiliation, pays par pays.

## 6. Ce que DYM n'est pas

| Comparé à | Différence |
|---|---|
| TikTok | TikTok donne envie ; DYM livre les ingrédients et paie le créateur à la vente. On s'en sert comme canal, on ne lui demande pas de disparaître. |
| Jumia / Gozem | Ils couvrent le formel. DYM couvre la vendeuse informelle non référencée. |
| WhatsApp Business | Canal de conversation, pas de transaction. DYM s'y branche (partage). |
| Kidia | Mono-marchand dans WhatsApp. DYM = multi-vendeuses + panier unifié. |

## 7. Principes produit

1. **Profondeur** : chaque brique est finie, puis on élargit.
2. **Générique par défaut** : pays, devise, moyens de paiement, langues, fournisseurs et taux sont
   des données de configuration, jamais du code.
3. **Conçu pour le terrain** : Android d'entrée de gamme (2 Go RAM), réseau instable, plein soleil,
   littératie variable.

## 8. Applications

| App | Utilisateur | Plateforme |
|---|---|---|
| DYM (`dym_client`) | Awa, créateurs | Android, iOS, web de test |
| DYM Vendeur (`dym_vendor`) | Fatou | Android, iOS, web de test |
| DYM Admin (`dym_admin`) | Équipe ops | Flutter Web (Coolify) |
| DYM Livreur (`dym_delivery`) | Kofi | Android, web de test |

Hors apps : Neon Functions (logique serveur) et un site léger sur Coolify (CGU, confidentialité,
deep links, retour de paiement, liens de partage).
