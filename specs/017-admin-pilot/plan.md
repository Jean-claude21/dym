# Plan : Admin du pilote

**Spec** : [spec.md](spec.md)

**Branche** : `feat/017-admin-pilot`, empilée sur `feat/016-pilot-hardening`.

## Technique

### Base

Migration `db/migrations/0019_admin_pilot.sql` :

- **Fonctions de calcul** :
  - `app.order_collected` : livrée et encaissée ;
  - `app.period_bounds` : jour, semaine, mois, mois dernier, 30 jours (inclusif).
- **Lectures réservées à l'équipe** (`app.require_admin`) :
  - `admin_dashboard` ;
  - `admin_revenue` ;
  - `admin_feature_flags` ;
  - `admin_tickets` ;
  - `admin_clients`, `admin_client` (journalisé) ;
  - `admin_vendor_view` (journalisé).
- **Gestes** :
  - `admin_set_feature_flag` ;
  - `admin_close_ticket` ;
  - `app.admin_reply_ticket` (Function, notification) ;
  - `app.admin_delete_vendor` (Function, refus `vendor_has_orders`).

  Tous passent par `app.admin_did` (journal et `admin_action_performed`).
- **Amorçage** : les drapeaux de la phase 4, coupés.

### Function

Deux routes, chacune avec ses tests :

- `POST /v1/admin/tickets/:id/reply` ;
- `POST /v1/admin/stores/:id/delete`.

### Dart

- **Modèles** (`admin_models.dart`) :
  - `AdminDashboard`, `AdminRevenue` ;
  - `AdminFeatureFlag` ;
  - `AdminClient` ;
  - `AdminVendorView`.
- **Dépôt et services** : méthodes ajoutées à `AdminRepository` et `AdminService`, avec leurs
  versions Neon et mémoire.

### `dym_ui`

`DymAdaptiveScaffold` gagne `maxBottomItems` et `moreItem` : sur téléphone, les destinations en trop
s'ouvrent dans une feuille.

### Admin

- Onglets dans l'ordre de la maquette 67 : tableau de bord, commandes, litiges, boutiques, clientes,
  finances, support, réglages, journal.
- Nouveaux écrans : 67, 68, 69 et 70 (section de Finances).
- Ajouts dans les écrans existants : onglet Fonctionnalités dans Réglages, « Voir comme elle » et
  « Supprimer le compte » dans Boutiques.

## Constitution

- **Postgres source de vérité** : montants, taux, retards et tops sont calculés en SQL. L'app
  n'additionne rien entre devises.
- **Sécurité** : chaque lecture et chaque geste est réservé à l'équipe et testé par pgTAP. Les
  consultations de profils sont journalisées.
- **Générique** : périodes, devises et drapeaux viennent de la base ; aucun pays dans le code.

## Dérogations

**Gate de la phase 2 (constitution I)** : la phase 3 est construite avant ce gate. Dérogation du
porteur produit du 2026-10-10, consignée dans la roadmap. Les maquettes 67 à 70 restent à valider.
