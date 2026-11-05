# Plan : Admin des opérations

**Spec** : [spec.md](spec.md) · **Branche** : `feat/013-admin-ops` (empilée sur `feat/012-disputes`)

## Technique

- **Base** (`db/migrations/0015_admin_ops.sql`) :
  - garde `app.require_admin()` pour la Data API et `app.assert_admin(user)` pour les Functions ;
  - `app.admin_did` : audit + `admin_action_performed` pour chaque action ;
  - commandes : `public.admin_orders` (filtres, recherche, « bloquée » selon des délais par statut
    en SQL) et `public.admin_order` (chronologie, paiements, remboursements, litige, livreur,
    audit, statuts forçables) ;
  - gestes : `app.admin_force_status`, `app.admin_cancel_order` (remboursement du total si payé
    en ligne) et `app.admin_assign_courier` (table `order_couriers`) ;
  - remboursements : `public.admin_refunds`, `app.refund_claim` (statut `processing`, un seul appel
    au fournisseur), `app.refund_result` et `app.refund_mark_cash` ; événement `refund_completed` ;
  - paiements en attente : `public.admin_pending_payments` ;
  - boutiques : `public.admin_stores`, `public.admin_store` (indicateurs sur 7 jours,
    historique), `app.admin_set_store_status` et `public.admin_update_store` ;
  - réglages : `public.admin_countries` (ce qui manque), `admin_set_country_active` (refus
    `country_not_ready`), `admin_geography`, `admin_save_city`, `admin_save_zone`,
    `admin_payment_methods`, `admin_save_payment_method`, `admin_pricing`, `admin_set_commission`
    et `admin_set_delivery_fee` (versionnés : l'ancienne règle est close), `admin_categories` et
    `admin_save_category` ;
  - journal : `public.admin_audit` (recherche, filtres, pagination) ;
  - notifications : `order_cancelled`, `order_cancelled_vendor`, `order_status_forced`,
    `delivery_assigned`, `store_suspended`, `store_reactivated` et `refund_succeeded`.
- **Functions** (`functions/src/admin/routes.ts`) : statut forcé, annulation, livreur,
  suspension, exécution d'un remboursement (`PaymentProvider.refund`, simulateur compris hors
  production) et cash remis.
- **Dart** :
  - modèles `admin_models.dart` ;
  - `AdminRepository` ;
  - `ReferenceRepository.currencies()`.
- **App admin** :
  - `features/{ops,orders,disputes,stores,finance,settings,audit}` en Stacked ;
  - accueil à six onglets ; `AdminSplit` (liste et détail côte à côte en fenêtre large) ;
  - `MemoryAdminService` pour les tests et la galerie.
- **Outil** : `dym-db grant-admin <email>` (premier admin, comptes de test de bout en bout).

## Constitution

- **Règles en SQL** : rôle, transitions forcées, plafonds, versions et préparation d'un pays.
- **Effets externes par la Function** : notifications et remboursement chez le fournisseur.
- **Générique** :
  - aucune ville ni aucun quartier dans le code ou les migrations : l'équipe les saisit ;
  - les libellés d'origine viennent du référentiel ;
  - les montants restent en `amount_minor`.
- **Sécurité** : chaque lecture et chaque action vérifient le rôle (pgTAP), et chaque action est
  auditée.
- **Écrans** :
  - maquettes 52 à 58 (à valider) ;
  - testés à 7 tailles, en français et en anglais, avec le texte à 130 % ;
  - états chargement, erreur, hors ligne et vide.

## Dérogations

Aucune.
