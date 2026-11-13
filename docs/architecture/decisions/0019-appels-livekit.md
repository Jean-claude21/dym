# 0019 — Appels du chat par LiveKit

**Statut** : Acceptée (2026-11-13)

## Contexte

Les appels audio et vidéo du chat (spec 035) tiennent leur état en base mais leur média était
simulé (décision 0015). `PACKAGES.md` prévoyait WebRTC et un serveur TURN à héberger. Le porteur a
choisi LiveKit et fourni un projet LiveKit Cloud (2026-11-13).

## Décision

- Média des appels par LiveKit (`livekit_client` dans `dym_platform`, derrière `CallProvider`).
- Le fournisseur est choisi par la base à la création de l'appel (flag `calls_livekit`, global ou
  par pays) ; sinon l'appel reste simulé et signalé.
- Le jeton d'accès est émis par la Function (`POST /v1/calls/:id/media`, JWT HS256, 10 min, une
  seule salle), après `app.call_media_access` : les deux personnes de la conversation, appel
  décroché seulement. Aucun secret dans les apps.
- Voix Opus avec pauses non transmises, vidéo 360p adaptée au réseau (3G).
- Projet LiveKit Cloud pour commencer ; un serveur LiveKit auto-hébergé (Coolify) se branche en
  changeant `LIVEKIT_URL`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`, sans toucher aux apps.

## Conséquences

- Les Functions reçoivent `LIVEKIT_URL`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET` (`neon.ts`).
- Les apps cliente et vendeuse demandent micro et caméra au premier appel.
- Aucune conversation n'est enregistrée ; l'historique (qui, quand, durée) reste en base.

## Alternatives écartées

- Numéros masqués par un opérateur : payants à la minute, pays par pays.
- WebRTC seul avec serveur TURN : plus de code et d'exploitation pour le même résultat.
