# Feature Specification: Livreurs relancés, alerte « prête », refus automatique

**Feature Branch**: `feat/066-courier-dispatch`

**Created**: 2026-11-12

**Status**: Draft

**Input**: Choix validés le 2026-11-12 après l'analyse des flux : une seule alerte part aux livreurs
à l'acceptation ; personne n'est relancé ; le livreur assigné n'apprend pas que la commande est prête ;
une commande ignorée par la vendeuse reste en attente sans fin.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Personne ne prend la course (Priority: P1)

Toutes les `courier_relaunch_minutes` (5 par défaut) sans livreur, la course est reproposée, au plus
`courier_relaunch_max` fois (3). La première relance vise les mêmes quartiers ; dès la deuxième, toute la
ville de la boutique, qui voit alors aussi la course dans « Courses proposées ».

### User Story 2 - Commande prête (Priority: P1)

Quand la vendeuse passe la commande à « prête », le livreur assigné reçoit « Commande prête ».

### User Story 3 - Vendeuse qui ne répond pas (Priority: P1)

Après `order_auto_refuse_minutes` (20 par défaut) en attente, la commande est refusée par le système
avec le motif « La boutique n'a pas répondu à temps » : stock rendu, remboursement dû si payée,
cliente et vendeuse prévenues. Une commande en attente de paiement n'est pas concernée.

### User Story 4 - Suivi par l'équipe (Priority: P2)

Les trois délais se règlent par pays (Opérations, Configuration). Le tableau de bord affiche : livreurs
en ligne sur actifs, courses sans livreur, délai médian de prise, relances (dont élargies), refus
faute de réponse, alertes « prête ».

## Requirements *(mandatory)*

- **FR-001**: règles en SQL (`app.run_dispatch_watch`), tâche planifiée toutes les 5 minutes.
- **FR-002**: refus automatique avec l'acteur `system`, journalisé dans l'historique des statuts.
- **FR-003**: aucun délai en dur : colonnes du pays.
- **FR-004**: événements serveur sans donnée personnelle.

## Success Criteria *(mandatory)*

- **SC-001**: pgTAP `550_courier_dispatch.sql` (17) ; parcours livreur existant inchangé (370).
- **SC-002**: test de la tâche (Functions) ; analyse et tests verts.
