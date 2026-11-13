# Feature Specification: Personnel des boutiques et succursales

**Feature Branch**: `feat/087-personnel-boutique`

**Created**: 2026-11-13

**Status**: Draft

**Input**: Point 9 validé par le porteur (2026-11-13, « Tout est ok, go ») : supermarchés —
personnel multiple et succursales. Features V-STO-08 (équipe), V-STO-09 (succursales).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Faire travailler son équipe (Priority: P1)

La propriétaire ouvre Ma boutique → Équipe, invite une personne par email avec un rôle :
Gérante (commandes, catalogue, prix, messages, caisse, offres), Préparatrice (commandes, messages)
ou Caissière (caisse, commandes). La personne se connecte à DYM Vendeuse avec son compte et ne
voit que son travail (onglets et lignes filtrés). L'argent, les réglages et l'équipe restent à la
propriétaire. Retirer une personne coupe son accès.

### User Story 2 - Plusieurs lieux (Priority: P2)

Une enseigne a une boutique par lieu. Une même personne peut travailler pour plusieurs boutiques
et passe de l'une à l'autre (Ma boutique → Changer de boutique).

### Edge Cases

- Email sans compte : invitation acceptée à la première visite.
- Fonction vendeuse non déclarée : réservée à la propriétaire (sûr par défaut).

## Requirements *(mandatory)*

- **FR-001**: `store_members`, `store_invites`, rôles et permissions en données de référence.
- **FR-002**: la garde commune `app.own_store_id` exige la permission de la fonction appelante ;
  commandes et chat (`order_party`, `conversation_role`) acceptent le personnel autorisé.
- **FR-003**: `my_stores`, `set_active_store`, `my_store_staff`, `invite_store_staff`,
  `remove_store_staff` ; `my_store` donne le rôle et les permissions.
- **FR-004**: app vendeuse : onglets, Ma boutique et Équipe selon le rôle ; textes `dym_l10n`.

## Success Criteria *(mandatory)*

- **SC-001**: pgTAP 710 (19) ; tests de l'app vendeuse (rôle, équipe, changement de boutique).
