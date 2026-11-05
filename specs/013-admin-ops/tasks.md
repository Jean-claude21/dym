# Tâches : Admin des opérations

- [X] T001 Maquettes 52 à 58 dans `docs/design/screens/` et `docs/design/MOCKUPS.md`
- [X] T002 Migration `db/migrations/0015_admin_ops.sql` (garde, commandes, gestes, remboursements, boutiques, réglages, journal, notifications)
- [X] T003 pgTAP `db/tests/100_admin_ops.sql` (accès réservé, bloquées, recherche, statut forcé, annulation et remboursement, livreur, exécution, cash, suspension, correction, pays incomplet puis prêt, commission et frais versionnés, catégories, journal)
- [X] T004 Functions : routes admin, `PaymentProvider.refund` (simulateur) ; tests
- [X] T005 Modèles, `AdminRepository`, `ReferenceRepository.currencies`, textes fr et en
- [X] T006 [US1] Commandes 52 et détail 53 (forcer, annuler, livreur)
- [X] T007 [US2] Litiges 54 (conversation, décision) et finances 57 (exécuter, cash, paiements en attente)
- [X] T008 [US3] Boutiques 55 (profil, suspendre, réactiver, corriger)
- [X] T009 [US4] Réglages 56 (pays, villes et quartiers, paiement, commission, frais, catégories)
- [X] T010 [US5] Journal 58 (recherche, filtres, avant et après)
- [X] T011 Accueil à six onglets, galerie 52 à 58, tests de vues aux 7 tailles
- [X] T012 `dym-db grant-admin` ; staging : migration, pgTAP, Function ; bout en bout de l'admin
