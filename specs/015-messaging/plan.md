# Plan : Messagerie cliente ↔ vendeuse

**Spec** : [spec.md](spec.md) · **Branche** : `feat/015-messaging` (empilée sur `feat/014-vendor-dashboard`)

## Technique

- **Base** (`db/migrations/0017_messaging.sql`) :
  - tables `conversations` (une par cliente et boutique, dates de lecture par rôle) et `messages`
    (texte, image, produit ; clé d'idempotence unique par conversation et rôle) ; RLS sans
    politique : lecture et écriture par fonctions seulement ;
  - `app.start_conversation`, `app.send_message` (participation, contenus contrôlés, rejeu sans
    doublon, notification sans contenu) ; `app.chat_media_keys`, `app.chat_upload_allowed` ;
  - lectures `public.my_conversations`, `public.conversation` (la marque lue),
    `public.unread_messages_count` ;
  - notifications `new_message` (cliente) et `new_message_vendor` (vendeuse) et leurs modèles de
    push.
- **Function** (`functions/src/messaging/routes.ts`) : ouvrir, envoyer (en-tête
  `Idempotency-Key`), envoi d'image par URL présignée dans le bucket privé `chat-media`, liens
  de lecture signés (5 min) pour les participantes.
- **Dart** : modèles `ChatMessage`, `Conversation`, `ConversationThread` ;
  `MessagingRepository` ; package de feature `dym_chat` (prévu par `PACKAGES.md`) : service,
  viewmodels, écrans 60 à 62, feuille de partage, service en mémoire.
- **Apps** :
  - cliente : « Écrire à la boutique » (page boutique), « Poser une question » (fiche produit,
    produit à joindre), « Mes messages » (Moi), notification qui ouvre la conversation, ajout au
    panier d'un produit partagé ;
  - vendeuse : onglet « Messages », conversation avec partage de ses produits publiés, ligne
    « messages non lus » de l'accueil (V-DASH-04).

## Constitution

- Règles en SQL (participation, contenus, idempotence) ; effets externes (stockage, push) par la
  Function.
- Sécurité : images privées et liens signés courts ; aucun contenu de message dans les push ni
  dans les événements.
- Écrans : maquettes 60 à 62 (à valider) ; sept tailles, français et anglais, texte 130 % ;
  états chargement, erreur, hors ligne et vide.

## Écart avec la roadmap

La roadmap cite « SSE via Function ». Le fil se relit toutes les 8 secondes quand il est ouvert,
la liste toutes les 20 secondes, et les nouveaux messages arrivent par push : plus robuste sur un
réseau 3G instable qu'un flux maintenu ouvert, sans dépendance nouvelle. Un flux SSE reste
possible plus tard sans changer la base.

## Dérogations

Aucune.
