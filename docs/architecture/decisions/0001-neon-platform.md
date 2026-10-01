# 0001 — Neon comme plateforme backend complète

**Statut :** Acceptée · 2026-10-01

## Contexte

Les tentatives précédentes (Supabase) ont échoué sur la sécurité (aucun RLS sur 52 tables, prix
envoyés par l'app) et sur le périmètre. On veut éviter d'exploiter un serveur. Depuis le
18/09/2026, Neon propose en GA : Auth (Better Auth managé), Data API (PostgREST), Object Storage
(S3), Functions (Node 24) et AI Gateway, qui suivent tous les branches de la base.

## Décision

Neon porte tout le backend : Postgres pour la vérité métier, Data API pour les lectures et le CRUD
simple, Functions pour les effets externes, Object Storage pour les médias, Auth pour l'identité.
Région : Francfort (la plus proche de l'Afrique de l'Ouest parmi Ohio, Virginie, Francfort, Singapour).
Pas de serveur applicatif ; Coolify n'héberge que l'admin web et le site léger.

## Conséquences

- Pas de SDK Dart officiel : on écrit `neon_kit` (client HTTP générique).
- Pas de temps réel natif : push FCM + SSE via Function pour le chat.
- Pas de MFA Neon pour l'instant : 2FA de l'admin via Google Workspace.
- La branche par PR donne à chaque agent ou PR une copie complète du backend.
- AI Gateway est réservé au plan Pro : on ne l'utilise pas (voir 0005).

## Alternatives écartées

Supabase (historique d'échec, mais surtout : la décision de changer est prise) ; backend maison
sur Coolify (serveur à maintenir sans bénéfice) ; Serverpod (serveur à exploiter).
