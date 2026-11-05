# Feature Specification: Onboarding et réglages de la boutique

**Feature Branch**: `feat/006-store-onboarding`

**Created**: 2026-10-02

**Status**: Draft

**Input**: User description: "Spec `store-onboarding` de la roadmap (Phase 2 ; V-AUTH-03/04, V-SET-01..05, V-DEL-01..04) : onboarding de la boutique en 7 étapes avec reprise, « Où vends-tu ? » (au marché, fait maison, boutique), adresse de ramassage privée, rayon principal, zones desservies et délai de préparation, moyens de paiement acceptés, horaires, ouverture et fermeture en un geste, réglages."

## Contexte

Fatou a un compte vendeuse (spec 005). Elle doit maintenant ouvrir sa boutique, l'unité centrale de
DYM (décision 0010). La boutique a :
- **une origine** : au marché, fait maison ou boutique ;
- **un quartier public** ;
- **une adresse de ramassage privée**, vue seulement par elle, l'équipe et le livreur de la
  commande ;
- **ses conditions** : quartiers desservis, délai de préparation, retrait sur place, moyens de
  paiement et horaires.

Le critère terrain du parcours 9 est « Ouvre ta boutique » en moins de 10 minutes, et
l'origine choisie sans hésiter.

**Maquettes** :
- l'écran 07 (« Où vends-tu ? », étape 2) est validé ;
- les écrans 16 à 23 sont produits dans la même direction, à valider avec cette spec.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fatou ouvre sa boutique en 7 étapes (Priority: P1)

Après sa connexion, Fatou suit 7 étapes avec une barre de progression :
1. le nom et la présentation de sa boutique ;
2. son origine (où elle vend) ;
3. son quartier et son adresse de ramassage ;
4. son rayon principal ;
5. les quartiers où elle livre, son délai de préparation et le retrait sur place ;
6. les moyens de paiement acceptés ;
7. ses horaires.

Elle touche « Ouvrir ma boutique » ; un écran de réussite résume sa boutique.

**Why this priority**: sans boutique ouverte, aucune commande n'est possible ; c'est la première
preuve V1 côté vendeuse.

**Independent Test**: dérouler les 7 étapes (serveur simulé côté app, base réelle côté SQL),
puis vérifier la boutique active et ouverte en base, et l'événement `store_created` avec son
origine.

**Acceptance Scenarios**:

1. **Given** une vendeuse sans boutique, **When** elle ouvre l'app, **Then** elle arrive à
   l'étape 1 ; la barre indique « Étape 1 sur 7 ».
2. **Given** une étape incomplète (nom vide, aucune origine, aucun quartier), **When** elle veut
   continuer, **Then** le bouton reste inactif.
3. **Given** l'origine « Fait maison », **When** elle saisit son adresse, **Then** un message
   l'informe que seul son quartier est visible des clientes.
4. **Given** les 7 étapes remplies, **When** elle touche « Ouvrir ma boutique », **Then** :
   - la boutique devient active et ouverte ;
   - l'écran de réussite résume la boutique ;
   - il propose d'ajouter le premier produit (spec `catalog`).
5. **Given** un moyen de paiement inactif dans son pays (Mobile Money avant le KYC), **When**
   elle voit l'étape 6, **Then** il apparaît « Bientôt », sans pouvoir être choisi.

---

### User Story 2 - Fatou reprend là où elle s'était arrêtée (Priority: P1)

Fatou est interrompue à l'étape 4 (réseau, appel). À la réouverture de l'app, elle reprend à
l'étape 4 avec ses réponses précédentes.

**Why this priority**: V-AUTH-04 ; sur le terrain, l'onboarding est souvent interrompu.

**Independent Test**: enregistrer les étapes 1 à 3, relancer l'app, vérifier l'étape et les
valeurs.

**Acceptance Scenarios**:

1. **Given** une boutique en brouillon à l'étape 4, **When** l'app redémarre, **Then** l'étape
   4 s'affiche, et les étapes précédentes gardent leurs valeurs si elle revient en arrière.
2. **Given** un enregistrement d'étape qui échoue (hors ligne), **When** elle réessaie, **Then**
   rien n'est perdu.

---

### User Story 3 - Les données de la boutique sont protégées (Priority: P1)

Les clientes voient les boutiques actives :
- nom, présentation, origine et quartier ;
- délai de préparation et retrait sur place ;
- ouverte ou fermée.

Elles ne voient jamais l'adresse de ramassage, ni l'identité de la propriétaire. Une vendeuse ne
peut modifier que sa boutique, et jamais son statut d'administration.

**Why this priority**: l'adresse d'une vendeuse « fait maison » est son domicile (décision 0010,
constitution V).

**Independent Test**: pgTAP couvrant :
- la lecture publique ;
- l'adresse inaccessible aux autres ;
- la modification par une autre vendeuse refusée ;
- l'activation d'une boutique incomplète refusée.

**Acceptance Scenarios**:

1. **Given** une boutique active, **When** une cliente ou un visiteur la lit, **Then** il
   obtient les informations publiques, sans adresse ni propriétaire.
2. **Given** une boutique en brouillon, **When** une cliente liste les boutiques, **Then** elle
   ne la voit pas.
3. **Given** deux vendeuses, **When** l'une tente de modifier la boutique de l'autre ou de lire
   son adresse, **Then** c'est refusé.
4. **Given** une boutique incomplète, **When** sa propriétaire demande l'ouverture, **Then** la
   base refuse en indiquant ce qui manque.
5. **Given** une vendeuse, **When** elle tente de passer son statut à « active » sans passer par
   l'ouverture, ou de modifier le statut « suspendue », **Then** c'est refusé.

---

### User Story 4 - Fatou ouvre ou ferme sa boutique en un geste (Priority: P2)

Dans « Ma boutique », un grand interrupteur ouvre ou ferme la boutique. Les autres réglages
reprennent les étapes de l'onboarding (V-SET-01..05).

**Why this priority**: parcours 13, « Ferme ta boutique jusqu'à demain » en 1 geste.

**Independent Test**: basculer l'interrupteur et vérifier en base l'état et les événements
`store_opened` et `store_closed`.

**Acceptance Scenarios**:

1. **Given** une boutique ouverte, **When** Fatou touche l'interrupteur, **Then** elle est fermée
   et l'événement est enregistré ; l'interrupteur reflète l'état serveur.
2. **Given** une boutique suspendue par l'équipe, **When** Fatou veut l'ouvrir, **Then** c'est
   refusé avec un message.
3. **Given** « Ma boutique », **When** Fatou modifie ses horaires ou ses quartiers, **Then** les
   changements sont enregistrés avec les mêmes règles que l'onboarding.

### Edge Cases

- Quartier de la boutique dans une autre ville que les quartiers desservis : refusé.
- Moyen de paiement d'un autre pays : refusé.
- Horaires : l'ouverture doit précéder la fermeture ; au moins un jour ouvert.
- Délai de préparation hors 5 à 240 minutes : refusé.
- Frais de livraison personnalisés négatifs : refusés. Sans valeur, ce sont les frais du pays
  (spec 004).
- Une seule boutique par vendeuse en V1 : une seconde création reprend la première.
- Pays de la boutique : il découle de son quartier et n'est jamais saisi.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Une vendeuse DOIT pouvoir créer une seule boutique en brouillon, puis la compléter
  étape par étape. L'étape atteinte est enregistrée pour la reprise.
- **FR-002**: La boutique DOIT porter :
  - un nom (2 à 60 caractères) et une présentation facultative (280 au plus) ;
  - une origine du référentiel ;
  - un quartier public, dont découlent le pays et la devise ;
  - un rayon principal (de premier niveau) ;
  - un délai de préparation (5 à 240 min) ;
  - le retrait sur place (oui ou non) ;
  - des frais de livraison personnalisés facultatifs, en unités mineures.
- **FR-003**: L'adresse de ramassage DOIT être une donnée à part, avec :
  - une adresse, un repère ;
  - une position et un téléphone de contact, tous deux facultatifs.

  Seules la propriétaire et l'équipe la lisent. L'accès du livreur de la commande arrive avec
  `order-lifecycle`.
- **FR-004**: Les quartiers desservis DOIVENT appartenir à la ville du quartier de la boutique.
  Les moyens de paiement acceptés DOIVENT être actifs dans le pays de la boutique.
- **FR-005**: Les horaires DOIVENT être définis par jour de la semaine (ouverture avant
  fermeture), avec au moins un jour ouvert.
- **FR-006**: L'ouverture DOIT être une fonction serveur qui vérifie que la boutique est
  complète :
  - nom, origine, quartier, rayon, adresse ;
  - au moins un quartier desservi, un moyen de paiement et un jour ouvert.

  Elle rend la boutique active et ouverte, puis enregistre `store_created` (avec l'origine) et
  `store_opened`.
- **FR-007**: Le statut d'administration (`draft`, `active`, `suspended`) NE DOIT être modifié
  que par les fonctions serveur (ouverture) ou par l'équipe (spec `admin-ops`). Une boutique
  suspendue ne peut pas être rouverte par sa propriétaire.
- **FR-008**: Ouvrir ou fermer une boutique active DOIT être un seul geste et enregistrer
  `store_opened` ou `store_closed`.
- **FR-009**: Les clientes (connectées ou non) DOIVENT pouvoir lire les informations publiques
  des boutiques actives, sans l'adresse ni la propriétaire.
- **FR-010**: L'app vendeuse DOIT proposer :
  - l'onboarding en 7 étapes avec barre de progression, retour et reprise ;
  - l'écran de réussite ;
  - « Ma boutique » (interrupteur, réglages par section).

  Ces écrans suivent les règles de `dym_ui` : 48 dp, 7 tailles, texte à 130 %, français par
  défaut.

### Key Entities

- **Boutique** :
  - nom, présentation, origine, quartier, pays et devise, rayon principal ;
  - délai de préparation, retrait sur place, frais personnalisés ;
  - statut d'administration, ouverte ou fermée, étape d'onboarding.
- **Adresse de ramassage** : adresse, repère, position, contact. Elle est privée.
- **Quartier desservi**, **Moyen de paiement accepté**, **Horaire** (jour, ouverture, fermeture).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'onboarding complet demande 7 écrans et se fait en moins de 10 minutes sur le
  terrain (parcours 9).
- **SC-002**: 100 % des tentatives de lecture de l'adresse de ramassage, ou de modification de la
  boutique d'autrui, par une autre personne sont refusées (pgTAP).
- **SC-003**: Une boutique incomplète ne peut jamais devenir active (pgTAP).
- **SC-004**: Ouvrir ou fermer la boutique se fait en 1 geste depuis « Ma boutique ».
- **SC-005**: Les écrans s'affichent sans débordement aux 7 tailles de référence, en français et
  en anglais, avec le texte à 130 %.

## Assumptions

- **Une boutique par vendeuse en V1.** Le co-gérant (V-SET-08) relève de la phase 5.
- **Livraison.** Elle est assurée par DYM (zem). La « livraison propre » de la vendeuse (V-DEL-04)
  est traitée avec `order-lifecycle`. Ici, la vendeuse choisit ses quartiers, son délai et le
  retrait sur place.
- **Photos.** La photo de la boutique arrive avec le stockage d'objets (spec `catalog`). Le
  premier produit guidé est l'objet de cette spec.
- **Notifications.** Leur réglage (V-SET-06) arrive avec `order-lifecycle`, comme le mode
  vacances (V-SET-07, P1).
- **Valeurs par défaut des horaires** : du lundi au samedi, de 7 h à 19 h, pour aller vite.
