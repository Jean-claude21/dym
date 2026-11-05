# Feature Specification: Panier multi-boutiques, adresses et commande

**Feature Branch**: `feat/009-cart-checkout`

**Created**: 2026-10-02

**Status**: Draft

**Input**: User description: "Spec `cart-checkout` de la roadmap (Phase 2 ; C-CART-01..09, C-CHECK-01..05, C-ADDR-01..03, C-PROF-02) : panier multi-boutiques persistant côté serveur, sous-paniers, frais selon le nombre de ramassages, alertes rupture, adresses (saisie, GPS, sauvegarde), mode de livraison par boutique, récapitulatif, confirmation en un tap ; idempotence."

## Contexte

Awa a trouvé ses produits (spec 008). Elle veut maintenant les commander, chez plusieurs
boutiques à la fois, en un seul panier, et payer en cash à la livraison. C'est l'action 2 du
contrat V1 côté cliente, et le test de l'hypothèse H2 (combiner plusieurs boutiques).

DYM sera déployée dans plusieurs pays, et le pays hôte du pilote n'est pas encore fixé. Aucun
pays, aucune devise et aucun montant ne sont donc écrits dans les apps : tout vient du
référentiel (spec 004) et de la base.

**Maquettes** :
- validée : 05 (panier, avec livraison, paiement et total) ;
- produites dans la même direction, à valider : 34 (livraison : adresse et mode par boutique),
  35 (mes adresses), 36 (nouvelle adresse) et 37 (commande envoyée).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Awa remplit un panier chez deux boutiques (Priority: P1)

Depuis la fiche produit, Awa choisit une variante et une quantité, puis touche « Ajouter au
panier ». Depuis une carte produit (accueil, rayon, recherche), le bouton « + » ajoute la
variante par défaut. Un mini-panier flottant rappelle le nombre d'articles, de boutiques et le
total. Elle ajoute ensuite un article d'une deuxième boutique.

Le panier (maquette 05) groupe les articles par boutique, avec pour chacune son origine et son
quartier. Elle change une quantité ou retire un article. Une jauge indique ce qu'il manque pour
la livraison offerte. Le total sépare sous-total, livraison et total. Le panier est conservé
sur le serveur : elle le retrouve en rouvrant l'app ou sur un autre téléphone.

**Why this priority**: C-CART-01..08 ; le panier multi-boutiques est le différenciateur (H2).

**Independent Test**: avec deux boutiques ouvertes qui livrent son quartier, ajouter deux
articles de chacune, modifier, retirer, rouvrir l'app ; comparer les montants à ceux calculés
par la base.

**Acceptance Scenarios**:

1. **Given** une fiche produit avec deux variantes, **When** Awa choisit « 1 L », 2, puis
   « Ajouter au panier », **Then** le panier contient cette variante en quantité 2 et l'app
   enregistre `cart_item_added`.
2. **Given** la même variante déjà au panier, **When** elle l'ajoute encore, **Then** la
   quantité augmente : aucune ligne en double.
3. **Given** deux boutiques au panier, **When** elle l'ouvre, **Then** elle voit deux
   sous-paniers, les frais de livraison et un total identiques à ceux de la base.
4. **Given** un article au panier, **When** elle met sa quantité à 0 ou le retire, **Then** il
   disparaît, ainsi que le sous-panier s'il était seul.
5. **Given** un panier rempli, **When** elle se reconnecte sur un autre appareil, **Then** elle
   retrouve le même panier.

---

### User Story 2 - Awa enregistre ses adresses (Priority: P1)

Avant de commander, Awa indique où être livrée. Une adresse comprend :
- le quartier, choisi par sa position ou par une recherche (comme au profil) ;
- un repère libre (« portail bleu après la pharmacie ») ;
- un téléphone de contact pour la livraison ;
- un nom (Maison, Bureau ou Autre).

Si elle utilise sa position, celle-ci est conservée avec l'adresse pour guider la livraison.
Elle retrouve ses adresses dans « Moi › Mes adresses », peut en ajouter, en modifier, en
supprimer et en choisir une par défaut. La première adresse devient l'adresse par défaut.

**Why this priority**: C-ADDR-01..03, C-PROF-02 ; sans adresse, pas de livraison.

**Independent Test**: créer une adresse par la position et une par la recherche, en choisir une
par défaut, la modifier, en supprimer une ; une autre cliente ne voit aucune de ces adresses.

**Acceptance Scenarios**:

1. **Given** aucune adresse, **When** Awa en crée une, **Then** elle devient l'adresse par
   défaut.
2. **Given** la position autorisée, **When** elle touche « Utiliser ma position », **Then** le
   quartier le plus proche est choisi et la position est conservée avec l'adresse.
3. **Given** deux adresses, **When** elle choisit « Bureau » par défaut, **Then** une seule
   adresse est par défaut.
4. **Given** l'adresse par défaut supprimée, **When** il en reste une autre, **Then** la plus
   récente devient l'adresse par défaut.
5. **Given** une autre cliente, **When** elle lit ou modifie les adresses d'Awa, **Then** c'est
   refusé.

---

### User Story 3 - Awa commande en un tap, paiement à la livraison (Priority: P1)

Dans le panier, la ligne « Livraison » montre le nombre de ramassages et le délai estimé. En la
touchant (écran 34), Awa choisit son adresse et, pour chaque boutique qui le propose, la
livraison ou le retrait sur place. Elle choisit le paiement parmi les moyens actifs de son pays
et acceptés par toutes les boutiques du panier (cash à la livraison pour le pilote). Elle
indique si la boutique peut remplacer un produit manquant par un équivalent au même prix.

Le bouton « Commander · total » envoie la commande. Une commande est créée par boutique, toutes
rattachées au même achat, en attente d'acceptation par la vendeuse. L'écran 37 confirme l'envoi
et récapitule chaque commande. Le panier est vidé.

**Why this priority**: C-CHECK-01..05 ; c'est la conversion mesurée (H2, H3).

**Independent Test**: commander un panier de deux boutiques en cash ; vérifier deux commandes,
un achat, des montants égaux au panier, le panier vide et l'événement `order_created`. Rejouer
la même confirmation : rien n'est créé en double.

**Acceptance Scenarios**:

1. **Given** un panier valide et une adresse, **When** Awa touche « Commander », **Then** un
   achat et une commande par boutique sont créés, en attente d'acceptation, avec les montants
   calculés par la base, et le panier est vidé.
2. **Given** une perte de réseau au moment de la confirmation, **When** l'app renvoie la même
   demande, **Then** aucun achat n'est créé en double et la même confirmation s'affiche.
3. **Given** une boutique qui propose le retrait, **When** Awa choisit « Je récupère », **Then**
   cette commande ne compte ni ramassage ni frais de livraison.
4. **Given** l'ouverture de l'étape livraison, **When** elle s'affiche, **Then** l'app
   enregistre `checkout_started` ; à la création, la base enregistre `order_created` avec le
   nombre de boutiques, sans donnée personnelle.

---

### User Story 4 - Awa est prévenue de ce qui a changé (Priority: P2)

Entre l'ajout et la commande, un produit peut passer en rupture, une boutique peut fermer, ne
plus livrer son quartier ou changer un prix. Le panier le montre sur la ligne ou le sous-panier
concerné, avec une action (retirer, choisir le retrait, changer d'adresse). La commande est
refusée tant qu'un problème bloquant reste, avec un message qui dit lequel.

**Why this priority**: C-CART-09 ; une commande impossible à honorer coûte la confiance (H3).

**Independent Test**: mettre un article en rupture, fermer une boutique, changer un prix, puis
ouvrir le panier et tenter de commander.

**Acceptance Scenarios**:

1. **Given** un article passé en rupture, **When** Awa ouvre le panier, **Then** la ligne
   porte « Rupture » et la commande est refusée tant qu'elle reste.
2. **Given** une boutique fermée maintenant, **When** elle ouvre le panier, **Then** le
   sous-panier l'indique et la commande est refusée pour cette boutique.
3. **Given** un prix modifié par la vendeuse, **When** elle ouvre le panier, **Then** le
   nouveau prix est affiché et utilisé ; aucun ancien prix n'est facturé.
4. **Given** l'adresse hors des quartiers livrés par une boutique, **When** elle choisit la
   livraison, **Then** le sous-panier l'indique et propose le retrait si la boutique le permet.

### Edge Cases

- Ajout d'un produit d'un autre pays que le panier : refusé (un panier ne mélange ni pays ni
  devises).
- Quantité au-delà du stock suivi d'une variante : plafonnée au stock, avec un message.
- Quantité maximale par ligne : 99.
- Panier vide : état vide avec un lien vers l'accueil.
- Hors ligne : le panier affiché reste le dernier lu, marqué « hors ligne » ; la commande est
  impossible sans réseau.
- Boutique suspendue après l'ajout : ses articles sont signalés et exclus de la commande.
- Visiteuse sans session : l'ajout au panier ouvre la connexion.
- Adresse supprimée alors qu'elle est choisie au checkout : la commande demande une autre
  adresse.
- Retrait choisi pour toutes les boutiques : aucune adresse n'est exigée, aucun frais de
  livraison.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: La base DOIT tenir un panier par cliente et par pays, persistant, dont chaque ligne
  désigne une variante publiée et une quantité (1 à 99). Une variante n'apparaît qu'une fois.
  Le pays et la devise du panier sont ceux de la première boutique ; un article d'un autre pays
  est refusé.
- **FR-002**: Le panier DOIT être servi en un appel, groupé par boutique, avec, calculés en
  base au moment de la lecture :
  - pour chaque ligne : nom, variante, unité, photo, prix unitaire courant et montant ;
  - pour chaque boutique : origine, quartier, ouverture, livraison possible vers l'adresse
    choisie, retrait proposé, sous-total ;
  - pour le panier : sous-total, frais de livraison, total, nombre de ramassages, délai
    estimé, reste à payer pour la livraison offerte ;
  - les problèmes : rupture, stock insuffisant, boutique fermée ou suspendue, quartier non
    livré, prix modifié.
- **FR-003**: Les frais de livraison DOIVENT être calculés en base à partir des données de
  référence de la ville de livraison (sinon du pays) :
  - un ramassage par boutique livrée (le retrait n'en compte pas) ;
  - frais = frais de base + supplément par ramassage au-delà du premier ;
  - la boutique qui porte les frais de base est celle du plus gros sous-total ; si elle a fixé
    ses propres frais, ils remplacent les frais de base ; chaque autre boutique livrée porte un
    supplément ;
  - livraison offerte quand le sous-total des articles livrés atteint le seuil de gratuité.
- **FR-004**: Tout montant envoyé par l'app DOIT être ignoré : prix, frais et totaux sont
  recalculés par la base, en unités mineures, dans la devise du pays.
- **FR-005**: Une cliente DOIT pouvoir créer, modifier, supprimer ses adresses et en choisir une
  par défaut. Une adresse a :
  - un nom (maison, bureau, autre) et un libellé libre facultatif ;
  - un quartier actif ;
  - un repère (200 caractères au plus) et un téléphone de contact ;
  - une position facultative (latitude, longitude), donnée par l'appareil.
  Une seule adresse est par défaut ; la première créée l'est. Personne d'autre ne lit ni ne
  modifie ces adresses ; la position n'est jamais mise dans un événement.
- **FR-006**: La commande DOIT être créée en une seule opération, à partir du panier lu en base,
  avec :
  - une clé d'idempotence fournie par l'app : la même clé rend le même achat, sans rien créer ;
  - l'adresse choisie (copiée dans la commande, pour que la modifier ensuite ne change pas la
    commande) ;
  - le mode par boutique (livraison ou retrait, retrait seulement si proposé) ;
  - le moyen de paiement, actif dans le pays et accepté par chaque boutique ;
  - la préférence de remplacement d'un produit manquant.
  Elle crée un achat et une commande par boutique, au statut « en attente d'acceptation »,
  fige les lignes (nom, variante, prix, quantité), décrémente les stocks suivis, puis vide le
  panier.
- **FR-007**: La création DOIT être refusée, sans rien écrire, si le panier est vide, si un
  problème bloquant reste (FR-002), si l'adresse manque pour une livraison, ou si le moyen de
  paiement n'est pas accepté. Le message dit quel problème.
- **FR-008**: Une cliente DOIT pouvoir lire ses achats et commandes. Une vendeuse lit les
  commandes de sa boutique (sans les autres commandes de l'achat). Aucune autre personne n'y a
  accès. Les statuts et montants ne sont modifiables que par des fonctions de la base.
- **FR-009**: La base DOIT enregistrer `order_created` à la création de l'achat, avec le nombre
  de boutiques, le nombre d'articles, le moyen de paiement et le pays, sans donnée personnelle.
  L'app enregistre `cart_item_added` et `checkout_started`.
- **FR-010**: L'app cliente DOIT proposer :
  - l'ajout au panier depuis la fiche produit (variante, quantité) et les cartes produit ;
  - le mini-panier flottant sur l'accueil, les rayons, la recherche et la page boutique ;
  - le panier (05), la livraison (34), mes adresses (35), la nouvelle adresse (36) et la
    commande envoyée (37) ;
  - « Mes adresses » dans l'onglet Moi.
- **FR-011**: Chaque écran DOIT gérer les états vide, chargement, erreur et hors ligne, et
  rester utilisable aux 7 tailles de référence, en fr et en, avec le texte à 130 %.

### Key Entities

- **Panier** : cliente, pays, devise, date de mise à jour.
- **Ligne de panier** : panier, variante, quantité, date d'ajout.
- **Adresse** : cliente, nom (maison, bureau, autre), libellé, quartier, repère, téléphone,
  position facultative, par défaut.
- **Achat** : cliente, pays, devise, moyen de paiement, adresse copiée, préférence de
  remplacement, clé d'idempotence, sous-total, frais, total, date.
- **Commande** : achat, boutique, mode (livraison ou retrait), statut, sous-total, frais de
  livraison, total, date.
- **Ligne de commande** : commande, produit, variante, nom et variante figés, unité, prix
  unitaire figé, quantité, montant.

## Success Criteria *(mandatory)*

- **SC-001**: Awa commande un panier de deux boutiques, paiement à la livraison, en moins de
  90 secondes depuis le panier (parcours 5).
- **SC-002**: Aucun montant de commande ne diffère de celui calculé par la base ; un montant
  envoyé par l'app n'a aucun effet (pgTAP).
- **SC-003**: Une même confirmation rejouée 3 fois crée un seul achat (pgTAP et test d'app).
- **SC-004**: Ni les adresses, ni les commandes d'une cliente ne sont lisibles ou modifiables
  par une autre personne ; une vendeuse ne voit que les commandes de sa boutique (pgTAP).
- **SC-005**: Ouvrir un nouveau pays ne demande aucune modification des apps : frais, devise et
  moyens de paiement viennent du référentiel.

## Assumptions

- **Paiement.** Seul le cash à la livraison est construit ici. Mobile Money arrive avec la spec
  `payments` ; il est déjà proposé s'il est actif dans le pays, mais une commande ne peut pas
  encore l'utiliser (le choix n'est pas affiché tant que son fournisseur n'est pas construit).
- **Suite de la commande.** Acceptation, refus, préparation, livraison, annulation et
  notifications relèvent de `order-lifecycle`. Ici, la commande est créée en attente.
- **Commission.** Elle est calculée et figée avec la commande, selon les règles du référentiel
  (montant interne, non affiché à la cliente).
- **Délai estimé.** Celui du panier est le plus long des délais des boutiques livrées (délai de
  la ville + préparation), comme sur l'accueil.
- **Racheter.** La rangée « Racheter » de l'accueil arrive avec l'historique des commandes
  (`order-lifecycle`).
- **Pays hôte.** Le pays du pilote n'est pas fixé ; les valeurs de frais du référentiel sont
  initiales et seront fixées par le porteur produit.
- **Stock.** Une variante sans stock suivi (quantité non renseignée) n'est pas plafonnée ; le stock suivi
  est décrémenté à la commande et restauré à l'annulation (`order-lifecycle`).
