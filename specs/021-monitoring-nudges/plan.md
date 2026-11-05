# Plan : Suivi de l'IA et relances

**Spec** : [spec.md](spec.md)

**Branche** : `feat/021-monitoring-nudges`, empilée sur `feat/020-shoppable-content`.

## Technique

### Base

Migration `db/migrations/0023_monitoring_nudges.sql` :

- **Journal IA** :
  - `ai_requests.query_text` : gardé seulement en cas d'échec, 80 caractères au plus ;
  - `app.record_ai_request` et `app.copilot_proposed` gagnent le texte.
- **Suivi** : `public.admin_ai_health` (24 h, 1 h, 7 jours, dernières requêtes non comprises).
- **Relance** :
  - table `broadcasts` ;
  - `app.broadcast_recipients` (segments, sans les clientes qui ont coupé les promotions) ;
  - `public.broadcast_audience` ;
  - `app.send_broadcast` (flag, une par jour, produit à soi).
- **Stock bas** :
  - `stores.low_stock_threshold` et `public.set_low_stock_threshold` ;
  - déclencheur sur `product_variants`.
- **Notifications** : modèles `store_broadcast` (cliente) et `low_stock` (vendeuse).

### Function

- `POST /v1/vendor/broadcasts` : le push part avec la file habituelle.
- Le copilote transmet le texte de l'intention.

### Dart

- **Modèles** : `AiHealth`, `BroadcastAudience`, `BroadcastSegment`.
- **Données** : `BroadcastRepository` et `AdminRepository.aiHealth`.

### Apps

- **Admin** : section « IA et paiements » du tableau de bord (77).
- **Vendeuse** : « Relancer mes clientes » (78) depuis « Ma boutique ».
- **Cliente** : texte de la notification de relance.

## Constitution

- **Postgres source de vérité** : en SQL, taux, segments, limite quotidienne, préférences et seuil.
- **Données personnelles** :
  - aucune personne dans le suivi IA ;
  - les événements ne portent que des comptes ;
  - les relances respectent la préférence « promotions ».

## Dérogations

**Gate de la phase 3** : dérogation du porteur produit du 2026-10-10. La relance reste derrière
`vendor_broadcast`, coupé par défaut.
