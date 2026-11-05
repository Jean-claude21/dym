# Tâches : Messagerie cliente ↔ vendeuse

- [X] T001 Maquettes 60 à 62 dans `docs/design/screens/` et `docs/design/MOCKUPS.md`
- [X] T002 Migration `db/migrations/0017_messaging.sql` (conversations, messages, envois, lectures, non-lus, notifications)
- [X] T003 pgTAP `db/tests/120_messaging.sql` (une conversation, participantes seules, rejeu, contenus contrôlés, non-lus, notification sans contenu, clés d'image)
- [X] T004 Function : ouvrir, envoyer, envoi d'image privée, liens signés ; bucket `chat-media` ; tests
- [X] T005 Modèles et `MessagingRepository`
- [X] T006 Package `dym_chat` : service, viewmodels, écrans 60 à 62, partage, tests aux 7 tailles
- [X] T007 [US1] App cliente : boutique, fiche produit, Moi, notifications, ajout au panier
- [X] T008 [US2] App vendeuse : onglet Messages, partage de produit, accueil (V-DASH-04)
- [X] T009 Galerie 60 à 62 ; staging : migration, pgTAP, Function ; bout en bout de la messagerie
- [ ] T010 Validation des maquettes, démo Android, push réels (FCM) observés (humain)
