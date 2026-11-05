# Feature Specification: Référentiel générique

**Feature Branch**: `feat/004-reference-data`

**Created**: 2026-10-02

**Status**: Draft

**Input**: User description: "Spec `reference-data` de la roadmap (Phase 1, A-CFG-01..06) : pays, devises, villes et zones, catégories, origines de boutique, unités du marché, moyens de paiement par pays et opérateur, règles de commission, frais de livraison par défaut, feature flags, modèles d'IA par usage, journal d'événements et journal d'audit ; RLS et pgTAP ; modèles et lecture côté Dart."

## Contexte

La constitution (IV) exige qu'ouvrir un pays soit une opération de configuration. Les données suivantes
doivent donc être des **données de référence en base**, jamais du code :
- pays, devise, villes et quartiers ;
- rayons, origines de boutique et unités du marché (le tas, la botte, l'olonka) ;
- moyens de paiement et opérateurs Mobile Money ;
- commission, frais de livraison, fonctions activables et modèles d'IA.

Cette spec pose ce référentiel, ses règles d'accès et sa lecture depuis les apps. Elle pose aussi les
deux journaux transverses que toutes les specs suivantes utiliseront :
- les **événements** de mesure (`METRICS.md`) ;
- l'**audit** des actions d'administration.

La modification du référentiel depuis l'admin (A-CFG en écriture) relève de la spec `admin-ops`.
Ici, les valeurs initiales sont posées par migration.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Les apps lisent la configuration du pays (Priority: P1)

À l'ouverture, l'app lit pour le pays de l'utilisatrice :
- la devise et son nombre de décimales ;
- les villes et les quartiers ;
- les rayons, les origines de boutique et les unités du marché ;
- les moyens de paiement disponibles ;
- les fonctions activées.

Tous les libellés sont dans la langue de l'utilisatrice.

**Why this priority**: toutes les specs produit (inscription, boutique, catalogue, panier, paiement)
s'appuient sur ces données ; sans elles, il faudrait coder des listes en dur.

**Independent Test**: lire chaque type de donnée pour le Togo, en français et en anglais, sans
compte (anonyme) et avec un compte, et vérifier valeurs et libellés.

**Acceptance Scenarios**:

1. **Given** le Togo actif, **When** l'app lit sa configuration, **Then** elle obtient le franc CFA
   (0 décimale), Lomé et ses quartiers (dont Bè, Tokoin, Adawlato), les rayons, les trois origines
   (Au marché, Fait maison, Boutique) et les unités (le tas, la botte…).
2. **Given** un pays inactif (Ghana au lancement), **When** une app le demande, **Then** il n'apparaît
   pas, ni ses villes, ni ses moyens de paiement.
3. **Given** une utilisatrice anglophone, **When** les libellés s'affichent, **Then** ils sont en
   anglais ; un libellé sans traduction s'affiche en français.
4. **Given** un moyen de paiement désactivé (Mobile Money avant validation du fournisseur), **When**
   l'app liste les moyens de paiement, **Then** seuls les moyens actifs apparaissent (cash).

---

### User Story 2 - Le référentiel est protégé (Priority: P1)

Personne ne peut modifier le référentiel depuis une app. Les données internes (modèles d'IA, audit)
ne sont lisibles par aucune app.

**Why this priority**: une commission ou un frais modifiable depuis un client serait une faille
financière (constitution V).

**Independent Test**: tenter, en anonyme et avec un compte, de modifier chaque table et de lire les
tables internes ; tout est refusé.

**Acceptance Scenarios**:

1. **Given** un utilisateur connecté, **When** il tente de créer, modifier ou supprimer un pays, une
   commission ou un frais, **Then** l'opération est refusée.
2. **Given** n'importe quel client, **When** il lit les modèles d'IA ou le journal d'audit, **Then**
   il n'obtient rien.

---

### User Story 3 - Les données sont cohérentes par construction (Priority: P1)

Les règles d'argent et de pays sont garanties par la base, quelle que soit la source de
l'écriture (migration, admin, Function) :
- une devise a entre 0 et 3 décimales ;
- un frais de livraison est dans la devise de son pays ;
- une commission est comprise entre 0 et 100 % ;
- un seul taux actif par pays et par rayon ;
- un libellé a toujours sa version française.

**Why this priority**: une erreur de configuration se traduit en erreur d'argent ; la base doit la
refuser.

**Independent Test**: tenter chaque écriture incohérente (en propriétaire) ; chacune est refusée
avec une erreur claire.

**Acceptance Scenarios**:

1. **Given** le Togo en XOF, **When** on enregistre un frais de livraison en GHS pour Lomé,
   **Then** l'écriture est refusée.
2. **Given** une commission active pour le Togo, **When** on en ajoute une seconde active pour le
   même rayon, **Then** l'écriture est refusée.
3. **Given** un libellé sans français, **When** on l'enregistre, **Then** l'écriture est refusée.

---

### User Story 4 - Les événements de mesure et l'audit sont tracés (Priority: P2)

Les apps envoient les événements de parcours prévus (recherche, produit vu, ajout au panier, début
de commande). Le serveur enregistre l'auteur réel, refuse les événements inconnus et toute donnée
personnelle. Les actions d'administration laissent une trace (qui, quoi, quand, avant, après,
pourquoi).

**Why this priority**: c'est la base de la mesure des hypothèses et de la preuve V1 n° 3 ; chaque spec
suivante émettra ses événements par ce chemin.

**Independent Test**: envoyer un événement autorisé, un inconnu et un contenant un email ;
vérifier l'enregistrement et les refus. Écrire une entrée d'audit et vérifier qu'aucune app ne peut
la lire.

**Acceptance Scenarios**:

1. **Given** une utilisatrice connectée, **When** l'app envoie « recherche effectuée », **Then**
   l'événement est enregistré avec son identité réelle (jamais celle fournie par l'app).
2. **Given** un nom d'événement absent de la liste, **When** l'app l'envoie, **Then** il est refusé.
3. **Given** des propriétés contenant un email ou un numéro de téléphone, **When** l'app les envoie,
   **Then** l'événement est refusé.
4. **Given** une action d'administration, **When** elle est enregistrée, **Then** l'audit garde
   l'auteur, l'action, l'objet, l'avant, l'après et la raison ; aucune app ne peut le lire ni le
   modifier.

### Edge Cases

- Ville active dans un pays inactif : invisible (le pays prime).
- Rayon désactivé avec des sous-rayons actifs : les sous-rayons sont invisibles.
- Unité propre à un pays (olonka au Ghana) : n'apparaît pas au Togo.
- Événement envoyé hors connexion puis rejoué : accepté une seule fois grâce à son identifiant
  client.
- Propriétés d'événement trop volumineuses (> 4 Ko) : refusées.
- Commission à 0 % (valeur initiale, à fixer avant le pilote) : valide.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le référentiel DOIT contenir les éléments suivants :

  | Élément | Contenu |
  |---|---|
  | Devises | code ISO 4217, décimales 0 à 3, symbole, locale de format |
  | Pays | code ISO 3166, nom, devise, indicatif, locale, fuseau, actif |
  | Villes et quartiers | par pays, actifs ou non |
  | Rayons | hiérarchie à deux niveaux, ordre, actifs ou non |
  | Origines de boutique | marché, fait maison, boutique ; extensibles |
  | Unités du marché | par pays, nature (pièce, poids, volume, lot), quantité indicative |
  | Fournisseurs de paiement et moyens de paiement | par pays et par opérateur |
  | Règles de commission | par pays et éventuellement par rayon, en points de base, avec période de validité |
  | Frais de livraison par défaut | par pays ou par ville : base, supplément par ramassage, seuil de gratuité, en unités mineures |
  | Fonctions activables | par pays ou globales |
  | Modèles d'IA par usage | fournisseur, modèle, paramètres |

- **FR-002**: Tout libellé visible DOIT être multilingue et comporter au moins le français.
- **FR-003**: Les apps (anonymes ou connectées) DOIVENT pouvoir lire les éléments actifs du
  référentiel public :
  - pays, devises, villes, quartiers, rayons, origines, unités, moyens de paiement, fonctions
    activables, frais de livraison ;
  - un élément dont le parent (pays, ville, rayon) est inactif est invisible.
- **FR-004**: Les règles de commission DOIVENT être lisibles par les utilisateurs connectés seulement.
- **FR-005**: Aucune app ne DOIT pouvoir modifier le référentiel, ni lire les modèles d'IA ou l'audit.
- **FR-006**: La base DOIT refuser :
  - une devise hors 0 à 3 décimales ;
  - un frais de livraison dans une devise autre que celle de son pays ;
  - une commission hors 0 à 10 000 points de base ;
  - deux commissions actives pour le même pays et le même rayon ;
  - un libellé sans français ;
  - un montant négatif.
- **FR-007**: Un journal d'événements DOIT enregistrer :
  - les champs : nom, auteur, rôle, app, pays, objet, propriétés et date ;
  - les événements serveur, par une fonction interne ;
  - les événements client, par une fonction exposée qui :
    - impose l'auteur réel ;
    - n'accepte que les noms autorisés pour les clients ;
    - refuse les propriétés de plus de 4 Ko ou contenant une donnée personnelle (email, téléphone,
      adresse, nom) ;
    - déduplique par identifiant client.
- **FR-008**: Un journal d'audit DOIT enregistrer, par une fonction interne :
  - l'auteur, l'action et l'objet ;
  - l'état avant et après, et la raison.

  Le journal est non modifiable et illisible par les apps.
- **FR-009**: Les valeurs initiales DOIVENT être posées par migration :
  - **Togo** : actif, XOF, Lomé et ses quartiers ;
  - **Ghana** : inactif, GHS, Accra et ses quartiers ;
  - les rayons du design validé ;
  - les trois origines et les unités de chaque pays ;
  - les moyens de paiement suivants :
    - cash actif ;
    - Mobile Money via Moneroo inactif jusqu'au KYC ;
  - les frais de la maquette validée, la commission à 0 % à fixer, les fonctions activables
    désactivées et un modèle d'IA inactif.
- **FR-010**: Côté Dart, les apps DOIVENT disposer :
  - de modèles typés pour chaque élément public ;
  - d'un dépôt de lecture du référentiel qui renvoie des résultats typés ;
  - d'un dépôt d'envoi d'événements avec identifiant client.

### Key Entities

- **Devise**, **Pays**, **Ville**, **Quartier (zone)**, **Rayon (catégorie)**, **Origine de
  boutique**, **Unité**, **Fournisseur de paiement**, **Moyen de paiement**, **Règle de
  commission**, **Frais de livraison par défaut**, **Fonction activable**, **Modèle d'IA**,
  **Événement**, **Entrée d'audit**. Les relations sont détaillées dans le modèle de données.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Ouvrir le Ghana se fait par une seule modification de données (activer le pays), sans
  changement de code ni nouvelle version d'app. Le test pgTAP le démontre.
- **SC-002**: 100 % des tables du référentiel ont RLS activé et des tests d'accès (lecture,
  écriture, données internes) qui passent.
- **SC-003**: 100 % des incohérences listées en FR-006 sont refusées par la base.
- **SC-004**: Un événement client contenant un email ou un téléphone est refusé dans 100 % des cas
  testés.
- **SC-005**: Les apps obtiennent la configuration complète d'un pays en une seule série de
  lectures, sans liste codée en dur.

## Assumptions

- Les écritures du référentiel par l'admin, et le rôle admin qu'elles exigent, arrivent avec les specs
  `auth` (rôles) et `admin-ops` (écrans). Jusque-là, seules les migrations écrivent.
- Les valeurs commerciales (taux de commission, frais) sont initiales et seront fixées par le
  porteur produit. Les frais reprennent ceux de la maquette validée : 500 F CFA de base,
  200 F CFA par ramassage supplémentaire, livraison offerte dès 4 000 F CFA.
- Les noms des quartiers de Lomé et d'Accra sont des noms réels. Leur liste exacte est ajustée sur
  le terrain par l'admin.
- Le modèle d'IA initial est un modèle OpenAI léger. Son nom exact est configurable et activé avec la
  spec `catalog`.
- Les événements serveur de chaque parcours sont ajoutés par les specs concernées. Celle-ci fournit
  le mécanisme et les événements client.
