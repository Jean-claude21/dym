# Feature Specification: Espaces partagés

**Feature Branch**: `feat/031-spaces`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `spaces` de la roadmap (Phase 9, décision 0015, VISION §3 « Espaces ») : espaces
illimités à nom libre, rôles, budget, validation ; commande pour un proche. La poche commune et le
paiement à plusieurs forment la spec suivante (`spaces-money`).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Créer un espace et inviter (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une cliente, **When** elle crée un espace nommé librement (« Maison », « Tontine du
   quartier »), avec ou sans budget mensuel, **Then** elle en est la responsable et elle valide et
   paie.
2. **Given** un espace, **When** elle partage son code, **Then** une autre personne du même pays le
   rejoint comme membre (elle remplit).
3. **Given** la responsable, **When** elle nomme un membre « valide et paie » ou le retire,
   **Then** le rôle change ; un membre peut quitter l'espace.

### User Story 2 - Remplir à plusieurs, un seul valide (Priority: P1)

**Acceptance Scenarios**:

1. **Given** un membre avec un panier, **When** il l'envoie à l'espace, **Then** ses articles
   rejoignent le panier commun (quantités additionnées) et son panier se vide.
2. **Given** le panier commun, **When** un membre ajuste une quantité ou retire un article,
   **Then** tous les membres voient le même panier, chiffré par le serveur, avec qui l'a ajouté.
3. **Given** une personne qui valide, **When** elle touche « Valider et passer au panier »,
   **Then** les articles disponibles passent dans son panier (règles du panier), le panier commun
   se vide de ces articles, les membres sont prévenus, et elle commande comme d'habitude (adresse de
   son carnet, y compris celle d'un proche).
4. **Given** un membre qui ne valide pas, **When** il tente de valider, **Then** c'est refusé.

### User Story 3 - Budget mensuel (Priority: P2)

**Acceptance Scenarios**:

1. **Given** un budget mensuel, **When** l'espace est ouvert, **Then** chacun voit le dépensé du
   mois et le reste.
2. **Given** une validation qui dépasserait le budget, **When** on valide, **Then** c'est refusé et
   le dépassement est indiqué.

### Edge Cases

- Code inconnu ou espace d'un autre pays : refusé. 20 membres et 20 espaces au plus.
- Article d'un autre pays ou plus en vente : refusé à l'envoi, nommé à la validation.
- La responsable ne peut pas quitter (elle supprime l'espace) ; un espace supprimé disparaît pour
  tous.

## Requirements *(mandatory)*

- **FR-001**: Seuls les membres DOIVENT voir un espace ; les écritures passent par des fonctions
  qui vérifient le rôle.
- **FR-002**: Montants, budget et dépensé DOIVENT être calculés en base (`amount_minor`, devise de
  l'espace) ; le mois suit le fuseau du pays.
- **FR-003**: La validation DOIT passer par les règles de `cart_add` ; aucune dépense sans
  validation par une personne qui valide.
- **FR-004**: Événements serveur : `space_created`, `space_joined`, `space_validated` (articles,
  montant). Aucune donnée personnelle.
- **FR-005**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Deux personnes remplissent un panier commun et une seule le valide, sans ressaisie.
- **SC-002**: Aucun espace ni article visible par une personne qui n'en est pas membre (pgTAP).

## Assumptions

- Commander pour un proche : l'adresse du proche (repère et téléphone) est enregistrée dans le
  carnet de la personne qui paie (spec 009) ; la photo à la remise vient avec l'app livreur.
- Poche commune, contributions et paiement depuis l'espace : spec `spaces-money`.
