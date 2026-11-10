# Feature Specification: Recherche et classement réglables

**Feature Branch**: `feat/028-ai-search-ranking`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `ai-search-ranking` de la roadmap (Phase 8, décision 0015, VISION §4) :
compréhension, savoir (noms locaux), règles de classement réglables, explication.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Les noms locaux sont compris (Priority: P1)

**Acceptance Scenarios**:

1. **Given** des épinards en vente, **When** la cliente cherche « gboma », **Then** ils sont
   trouvés.
2. **Given** une recherche sans nom local, **When** elle cherche « tomate », **Then** les résultats
   sont inchangés.

### User Story 2 - L'assistant choisit selon des règles réglables et explique (Priority: P1)

**Acceptance Scenarios**:

1. **Given** plusieurs produits possibles, **When** l'assistant compose le panier, **Then** il
   prend le meilleur score selon les poids du pays (texte, même boutique, ouverture, note, prix,
   quartier) et indique pourquoi (« Le meilleur prix », « Boutique de ton quartier »…).
2. **Given** des poids changés par l'équipe, **When** l'assistant compose à nouveau, **Then** le
   choix suit les nouveaux poids.

### User Story 3 - L'équipe règle sans développeur (Priority: P2)

**Acceptance Scenarios**:

1. **Given** un admin, **When** il ouvre Réglages → Recherche, **Then** il voit et modifie les
   poids du pays choisi, et ajoute ou retire des noms locaux.
2. **Given** une personne qui n'est pas admin, **When** elle tente ces réglages, **Then** c'est
   refusé ; chaque réglage est audité.

### Edge Cases

- Pays sans poids propres : poids par défaut.
- Note absente : compte comme 0 ; prix tous égaux : critère neutre.
- Raison inconnue d'une version future : ignorée par l'app.

## Requirements *(mandatory)*

- **FR-001**: Poids et noms locaux DOIVENT être des données de référence, réglables par pays.
- **FR-002**: La recherche et l'assistant DOIVENT élargir chaque mot à ses noms locaux.
- **FR-003**: Le choix de l'assistant DOIT être calculé en base, avec une raison renvoyée.
- **FR-004**: Seuls les admins DOIVENT pouvoir régler poids et noms locaux, avec audit.
- **FR-005**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Un nom local enregistré trouve ses produits sans changement de code.
- **SC-002**: Un changement de poids modifie le choix de l'assistant immédiatement.

## Assumptions

- La compréhension de l'intention (personnes, quantités) reste faite par l'IA (spec 019) ;
  l'assistant de courses complet est la spec suivante (`shopping-agent`).
- La mise en avant sponsorisée vient avec `memberships` (phase 13).
