# Feature Specification: Assainissement

**Feature Branch**: `feat/023-foundation-fixes`

**Created**: 2026-11-09

**Status**: Draft

**Input**: Spec `foundation-fixes` de la roadmap (Phase 6, décision 0015). Corrige ce qu'ont relevé
l'audit et les tests de parcours du 2026-11-09, et régularise le lot de préparation des tests
(comptes de démonstration, pays ouverts, connexion par mot de passe) fusionné sans spec.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Une base de vérification fiable (Priority: P1)

L'équipe voit la vérification automatique réussir sur la branche d'intégration et sait qu'un échec
signale un vrai problème.

**Why this priority**: tant que la vérification échoue, aucun changement suivant n'est fiable.

**Independent Test**: lancer la vérification complète sur la branche ; tout passe, y compris avec
plusieurs pays ouverts.

**Acceptance Scenarios**:

1. **Given** plusieurs pays ouverts, **When** la vérification tourne, **Then** les règles sur les
   pays inactifs sont toujours prouvées, sur un pays rendu inactif pour l'essai.
2. **Given** les composants serveur, **When** on contrôle leurs dépendances, **Then** aucune faille
   de gravité élevée ne subsiste.

---

### User Story 2 - Les outils de test restent des outils de test (Priority: P1)

En production finale, personne ne voit la connexion par mot de passe ni un moyen de paiement simulé.
En test, ces outils restent disponibles et signalés.

**Why this priority**: une cliente réelle ne doit jamais payer avec un moyen fictif.

**Independent Test**: lancer les apps en configuration de production finale, puis de test, et
comparer les écrans de connexion et de paiement.

**Acceptance Scenarios**:

1. **Given** l'environnement de production finale, **When** on ouvre la connexion, **Then** le lien
   « J'ai un mot de passe » est absent.
2. **Given** l'environnement de test, **When** on ouvre la connexion, **Then** le lien est présent.
3. **Given** la production finale, **When** une cliente ou une vendeuse consulte les moyens de
   paiement, **Then** aucun moyen simulé n'apparaît et aucune commande ne peut en utiliser un.
4. **Given** l'environnement de test, **When** on consulte les moyens de paiement, **Then** les
   moyens simulés apparaissent, signalés comme tels.
5. **Given** l'écran de connexion admin, **When** on le lit, **Then** il ne promet aucune protection
   qui n'existe pas.

---

### User Story 3 - La cliente sait où elle en est (Priority: P2)

La cliente apprend qu'une boutique est fermée avant de remplir son panier, voit que son ajout a
réussi et n'a pas à ressaisir son quartier.

**Why this priority**: ce sont les frictions constatées sur le parcours d'achat.

**Independent Test**: refaire un achat en web, depuis un compte neuf, chez une boutique fermée puis
ouverte.

**Acceptance Scenarios**:

1. **Given** une boutique fermée selon ses horaires, **When** la cliente ouvre une fiche produit,
   **Then** la fermeture et l'heure de réouverture connue sont indiquées, et l'ajout au panier reste
   possible avec cette information visible.
2. **Given** une fiche produit, **When** la cliente ajoute au panier, **Then** une confirmation
   visible apparaît.
3. **Given** un compte qui a choisi un quartier à l'inscription et n'a aucune adresse, **When** il
   ouvre l'ajout d'adresse, **Then** ce quartier est présélectionné.
4. **Given** aucune adresse choisie, **When** la cliente consulte son panier en livraison, **Then**
   le manque est signalé avant d'appuyer sur « Commander ».
5. **Given** une première adresse enregistrée, **When** elle est créée, **Then** elle devient
   l'adresse par défaut.

---

### User Story 4 - La vendeuse voit l'état réel de sa boutique (Priority: P2)

La vendeuse ne lit plus « les clientes peuvent commander » quand ses horaires l'interdisent.

**Why this priority**: une information fausse fait perdre des ventes et la confiance.

**Independent Test**: ouvrir l'écran boutique hors des horaires, puis pendant.

**Acceptance Scenarios**:

1. **Given** une boutique active hors de ses horaires, **When** la vendeuse ouvre « Ma boutique »,
   **Then** elle voit qu'elle est fermée pour l'instant et quand elle rouvre.
2. **Given** une boutique active pendant ses horaires, **When** elle ouvre l'écran, **Then** elle
   voit qu'elle est ouverte.
3. **Given** la boutique fermée manuellement, **When** elle ouvre l'écran, **Then** elle voit
   qu'elle l'a fermée elle-même.

---

### User Story 5 - Pas d'achat chez soi (Priority: P2)

Une vendeuse ne peut pas commander dans sa propre boutique, ce qui protège les chiffres et, plus
tard, les commissions.

**Why this priority**: règle de confiance dont dépendent les phases suivantes.

**Independent Test**: tenter la commande depuis le compte propriétaire de la boutique.

**Acceptance Scenarios**:

1. **Given** un panier contenant un article de sa propre boutique, **When** la propriétaire
   commande, **Then** la commande est refusée avec un message clair, quelle que soit l'app.

### Edge Cases

- Une boutique sans horaire à venir connu : la fermeture est indiquée sans heure de réouverture.
- Un panier multi-boutiques dont une seule est la sienne : toute la commande est refusée, et la
  boutique concernée est nommée.
- Un quartier d'inscription devenu inactif : aucune présélection.
- Une commande simulée créée en test n'est pas concernée par le retrait en production finale.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: La vérification automatique DOIT réussir avec plusieurs pays ouverts et continuer de
  prouver les règles sur les pays inactifs.
- **FR-002**: Les composants serveur NE DOIVENT comporter aucune faille de gravité élevée connue.
- **FR-003**: La connexion par mot de passe NE DOIT être proposée que hors production finale.
- **FR-004**: En production finale, les moyens de paiement simulés NE DOIVENT être ni visibles ni
  utilisables, et ce contrôle DOIT être appliqué par le serveur.
- **FR-005**: Les moyens simulés DOIVENT rester disponibles et signalés dans les environnements de
  test.
- **FR-006**: L'écran de connexion admin NE DOIT mentionner que des protections réellement actives.
- **FR-007**: La fiche produit DOIT indiquer qu'une boutique est fermée et, si elle est connue,
  l'heure de réouverture.
- **FR-008**: Tout ajout au panier depuis la fiche produit DOIT être confirmé visiblement.
- **FR-009**: Le quartier choisi à l'inscription DOIT être présélectionné à la création d'une
  adresse, s'il est encore actif.
- **FR-010**: L'absence d'adresse DOIT être signalée dans le panier avant la validation.
- **FR-011**: La première adresse d'un compte DOIT devenir son adresse par défaut.
- **FR-012**: L'écran « Ma boutique » DOIT distinguer : ouverte, fermée selon les horaires, fermée
  manuellement.
- **FR-013**: Le serveur DOIT refuser toute commande contenant un article d'une boutique appartenant
  à l'acheteur.
- **FR-014**: Le lot de préparation des tests DOIT être documenté dans cette spec, et ses scripts de
  démonstration NE DOIVENT pas pouvoir viser la production finale.
- **FR-015**: Tout nouveau texte visible DOIT exister dans chaque langue de l'app.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100 % des vérifications automatiques réussissent sur la branche d'intégration.
- **SC-002**: En configuration de production finale, 0 écran affiche un moyen simulé ou le lien par
  mot de passe.
- **SC-003**: 0 commande acceptée par un serveur de production finale avec un moyen simulé.
- **SC-004**: 100 % des tentatives d'achat dans sa propre boutique sont refusées.
- **SC-005**: Depuis un compte neuf, une commande se termine sans saisir deux fois son quartier.

## Assumptions

- « Production finale » désigne l'environnement configuré comme production ; le test web actuel sur
  staging reste un environnement de test.
- L'ajout au panier d'une boutique fermée reste possible : la commande reste bloquée par le serveur
  tant que la boutique n'a pas rouvert, ce qui est le comportement déjà en place.
- Le lot de préparation documenté comprend les pays ouverts, les admins par défaut, la connexion par
  mot de passe et les données de démonstration (décision 0014).
- Dépendances : décisions 0014 et 0015.
