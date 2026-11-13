# Feature Specification: Rôles et permissions des admins

**Feature Branch**: `feat/085-roles-admin`

**Created**: 2026-11-13

**Status**: Draft

**Input**: Demande du porteur (2026-11-13) : « comment ajouter des admins ? comment limiter leurs
champs ? » ; rôles proposés validés (« Tout est ok, go »). Features A-ADM-01 (équipe admin).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Donner à chacun ce dont il a besoin (Priority: P1)

Le super-admin invite une personne avec un rôle : Opérations, Support, Finance, Contenu ou
Analyste (par défaut, le plus restreint). Il change le rôle d'un admin depuis Configuration →
Admins ; jamais le sien. Chaque changement est journalisé.

### User Story 2 - Ne voir que son travail (Priority: P1)

L'admin ne voit dans le menu que les domaines de son rôle (le support ne voit ni les finances ni
le journal) ; l'analyste lit tout sans rien modifier. Toute action hors rôle est refusée par la
base, même appelée directement.

### Edge Cases

- Admins existants : super-admins (aucun accès perdu).
- Invitation d'un email sans compte : le rôle s'applique à sa première connexion.
- Les périmètres de pays (spec 053) s'ajoutent au rôle.

## Requirements *(mandatory)*

- **FR-001**: rôles, permissions (`domaine.read` / `domaine.write`) et attribution en données de
  référence (`admin_roles`, `admin_role_permissions`, `admin_members`).
- **FR-002**: la garde commune (`app.require_admin`, `app.assert_admin`) exige la permission de la
  fonction admin appelante (`admin_function_permissions`) ; non déclarée : super-admin seulement ;
  un test pgTAP vérifie qu'aucune fonction admin n'est oubliée.
- **FR-003**: `admin_me`, `admin_set_role`, `admin_invite_admin(email, rôle)` ; audit
  `admin_role_set`.
- **FR-004**: menu et réglages de l'app admin filtrés ; textes par `dym_l10n`.

## Success Criteria *(mandatory)*

- **SC-001**: pgTAP 690 (17) ; tests du menu et des réglages selon le rôle.
