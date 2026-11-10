# Feature Specification: Assistant de courses

**Feature Branch**: `feat/029-shopping-agent`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `shopping-agent` de la roadmap (Phase 8, décision 0015, VISION §3 et §4) : agent de
courses, composition de panier, validation, récurrence.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Mes listes de courses (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une cliente connectée, **When** elle crée une liste nommée librement (« Courses du
   samedi ») avec des articles et leurs quantités, **Then** la liste est enregistrée et retrouvée.
2. **Given** une liste, **When** elle la modifie ou la supprime, **Then** le changement est gardé ;
   personne d'autre ne voit ni ne modifie ses listes.

### User Story 2 - L'assistant propose, la cliente valide (Priority: P1)

**Acceptance Scenarios**:

1. **Given** des commandes passées, **When** elle demande « Ma liste habituelle », **Then**
   l'assistant propose les produits qu'elle achète le plus souvent, avec leurs quantités
   habituelles, qu'elle corrige avant d'enregistrer.
2. **Given** l'IA disponible, **When** elle décrit ses courses (« la semaine pour 4 personnes »),
   **Then** l'assistant propose une liste qu'elle corrige avant d'enregistrer.
3. **Given** une liste, **When** elle l'ouvre, **Then** l'assistant compose le panier chez les
   marchands qui livrent son quartier (règles de classement de la spec 028), chiffré par le serveur,
   avec la raison de chaque choix et ce qui manque ; elle retire ce qu'elle ne veut pas et ajoute
   le reste au panier. **Aucune dépense sans sa validation.**

### User Story 3 - Courses récurrentes (Priority: P2)

**Acceptance Scenarios**:

1. **Given** une liste réglée « chaque semaine » à partir d'une date, **When** le jour arrive
   (8 h, heure du pays), **Then** elle reçoit une notification « Tes courses sont prêtes » qui
   ouvre la liste ; la prochaine date avance d'une période.
2. **Given** le rappel déjà envoyé ce jour-là, **When** la tâche repasse, **Then** aucun doublon.

### Edge Cases

- Aucune commande passée : « Ma liste habituelle » le dit et propose de créer une liste.
- IA coupée ou en échec : création manuelle, rien n'est bloqué.
- Article introuvable dans le quartier : affiché comme manquant, le reste est proposé.
- Date de départ passée : refusée ; période inconnue : refusée.
- Hors ligne : erreur affichée, rien n'est perdu à l'écran.

## Requirements *(mandatory)*

- **FR-001**: Les listes DOIVENT appartenir à une seule personne (RLS) et s'écrire par fonctions.
- **FR-002**: Une liste contient au plus 20 articles (libellé, mot de recherche, quantité 1 à 10) ;
  au plus 20 listes par personne ; nom libre (1 à 40 caractères).
- **FR-003**: La composition du panier DOIT être faite en base (choix, prix, raison) ; l'app
  n'envoie aucun prix.
- **FR-004**: Les périodes possibles (7, 14, 30 jours) et l'heure du rappel sont des règles
  serveur ; le rappel est idempotent.
- **FR-005**: L'IA ne propose que des articles (jamais un prix ni une boutique) ; derrière le flag
  et le modèle du copilote.
- **FR-006**: Événements : `shopping_list_saved` (serveur), `shopping_list_proposed` (serveur),
  `shopping_reminder_sent` (serveur), `shopping_list_cart_added` (app). Aucune donnée personnelle.
- **FR-007**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Une cliente refait ses courses de la semaine en 3 gestes depuis l'accueil (ouvrir,
  vérifier, ajouter au panier).
- **SC-002**: Un rappel par liste et par échéance, jamais deux.

## Assumptions

- Les paniers enregistrés à l'identique (variantes exactes) viennent avec `address-book-favorites`
  (phase 9) ; ici, une liste porte des besoins, résolus à chaque fois au meilleur marchand.
- La commande automatique sans validation (règle réglée par la personne) est hors périmètre.
- Créneaux de livraison : `preorder-slots` (phase 9).
