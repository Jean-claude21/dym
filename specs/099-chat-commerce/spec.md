# Feature Specification: Chat de commerce

**Feature Branch**: `feat/099-chat-commerce`

**Created**: 2026-11-16

**Status**: Done

**Input**: Décisions du porteur (2026-11-16) : vidéo enregistrée ou partagée, vocal avec
transcription, position ponctuelle ou en direct, fiches produit avec ajout au panier, devis accepté
en un geste, demande de paiement, coupons, appels vidéo. Phase 15.

## User Scenarios & Testing *(mandatory)*

### US1 — Montrer et se retrouver (P1)

Cliente et vendeuse envoient une vidéo (filmée ou choisie, une minute au plus) et leur position,
ponctuelle ou en direct pendant 15 min (arrêtable). La position s'affiche sur une petite carte DYM,
ouvrable dans une carte externe.

### US2 — Vendre dans le chat (P1)

La vendeuse fait un devis à partir de son catalogue (quantités, prix jamais au-dessus du prix
affiché) ; la cliente l'accepte en un geste et les articles arrivent au panier aux prix du devis
(48 h pour accepter, 24 h dans le panier). La vendeuse demande un paiement (montant, motif) ; la
cliente paie avec son wallet. La vendeuse offre un coupon (5 à 50 %, 1 à 30 jours) ; gardé, il
s'applique à la prochaine commande dans la boutique puis est consommé.

### US3 — Vocal transcrit (P2)

« Transcrire » sous un vocal affiche son texte (modèle d'IA configuré en base, drapeau
`chat_transcription`) ; sans fournisseur, « Transcription simulée : service à brancher. »

### US4 — Appels vidéo (P2)

Les appels vidéo existent (spec 035) derrière le drapeau `calls_video` ; ouverts sur staging.

## Requirements *(mandatory)*

- **FR-001** Migration 0092 : messages `video`, `location`, `quote`, `payment_request`, `coupon`
  (contenu structuré, état relu en base), position en direct, `quotes`, `coupons`,
  `coupon_claims`, prix « coupon » dans `cart_line_price`, consommation à la commande,
  transcription (`app.set_transcript`).
- **FR-002** Functions : vidéos dans l'espace privé de la conversation, `POST /v1/chat-media/transcribe`.
- **FR-003** `dym_chat` : capacité `ChatCommerce`, bulles, menu « + », transcription ; montants
  saisis convertis en unités mineures sans flottant.
- **FR-004** Événements : `quote_accepted`, `coupon_claimed` ; `chat_message_sent` porte le type.
