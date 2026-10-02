# DYM — Architecture

> Décisions détaillées : `decisions/`. Carte des packages : `PACKAGES.md`.
> Les points marqués **[à valider]** sont vérifiés par la spec `foundation` avant tout code produit.

## 1. Vue d'ensemble

```
 dym_client · dym_vendor · dym_admin (web) · dym_delivery (phase 5)
        │  Flutter + Stacked, packages partagés (neon_kit, dym_data, dym_ui…)
        │  HTTPS uniquement, JWT Neon Auth (15 min, rafraîchi)
        ▼
 ┌──────────────────────────── Neon (région Francfort) ───────────────────────────┐
 │ Auth (Better Auth managé)  ── émet le JWT                                      │
 │ Data API (PostgREST)       ── lectures + CRUD simple, RLS via auth.user_id()  │
 │ Functions (Node 24, TS)    ── écritures à effets externes, webhooks, crons    │
 │ Object Storage (S3)        ── photos produits (public_read), preuves (private)│
 │ Postgres                   ── vérité : schéma, RLS, machines à états, montants│
 └─────────────────────────────────────────────────────────────────────────────────┘
        │                                   │
   Moneroo (MoMo), cash               OpenAI (via AI SDK), FCM (push)

 Coolify : admin Flutter Web, site léger (CGU, deep links, retour paiement), GlitchTip (optionnel)
```

Aucun serveur applicatif à maintenir : Neon fournit l'auth, l'API de données, le stockage et le calcul.

## 2. Où vit chaque règle

| Couche | Responsabilité | Interdit |
|---|---|---|
| **Postgres** | Schéma, contraintes, RLS, référentiel générique, calcul des montants, machines à états (commande, paiement, litige), événements métier, audit | Appeler un service externe |
| **Functions** | Effets externes : fournisseurs de paiement et webhooks, push FCM, URLs présignées, appels IA, crons, envoi des OTP | Dupliquer une règle métier déjà en SQL |
| **Apps Flutter** | Présentation, navigation, état d'écran, cache | Calculer un prix, décider d'une transition de statut, détenir un secret |

**Règle d'écriture :**
- Lecture et CRUD simple propriétaire (profil, adresse, produit de sa boutique) → **Data API** + RLS.
- Écriture qui déclenche un effet (créer une commande, changer un statut, payer, rembourser) →
  **Function**, qui appelle une fonction SQL transactionnelle puis émet les effets.
- Filet de sécurité : la table `outbox` est vidée par un cron (relance des push et webhooks échoués).

## 3. Générique par construction

### Référentiel (données, pas code)

`countries` (code ISO, devise, indicatif, locale, fuseau, actif) · `currencies` (code ISO 4217,
décimales, symbole) · `cities`, `zones` · `categories` · `payment_methods` par pays et fournisseur
· `commission_rules` · `delivery_fee_defaults` · `feature_flags` · `ai_models` (usage vers
fournisseur et modèle) · `store_origins` (`marche`, `maison`, `magasin`, extensible par pays) · `units` (le tas,
la botte, la boîte, le litre, le kilo…, par pays, avec poids ou volume indicatif).

Implémenté par la spec 004 (`db/migrations/0002` à `0004`) :
- **Libellés** en `jsonb` avec le français obligatoire.
- **Montants** en unités mineures et **commission** en points de base.
- **Lecture** des seuls éléments actifs, dont tous les parents sont actifs, par les apps.
- **Aucune écriture** par les apps.
- **Événements** par `track_event`, avec une liste blanche, l'auteur imposé et une garde contre les données personnelles.
- **Audit** en ajout seul.

### Boutiques (décision [0010](decisions/0010-market-groceries-boutiques.md))

- Toute vendeuse a une boutique, avec une `origin` issue de `store_origins` et une `zone_id` publique.
- L'adresse de ramassage est stockée à part (`store_pickup_addresses`), lisible uniquement par la
  vendeuse, l'admin et le livreur affecté à une commande en cours (RLS + pgTAP). Pour l'origine
  `maison`, l'app cliente n'affiche que la zone.
- Une commande multi-boutiques produit un ramassage par boutique ; les frais de livraison sont
  calculés côté serveur selon les ramassages.

### Argent

- Toujours `amount_minor bigint` + `currency_code char(3)`. Jamais de flottant.
- Les décimales viennent de `currencies` (XOF = 0, GHS = 2…).
- Une boutique hérite de la devise de son pays. Un panier ne mélange ni pays ni devises.
- Tous les montants (sous-totaux, frais, commission, total) sont **recalculés côté serveur** ;
  le prix envoyé par l'app est ignoré.
- Côté Dart : type `Money` dans `dym_core`, formaté selon la locale du pays.

### Fournisseurs interchangeables

| Domaine | Interface | Implémentations prévues |
|---|---|---|
| Paiement | `PaymentProvider` : `initiate`, `verifyWebhook`, `normalizeEvent`, `refund`, `payout` | `cash` → `moneroo` → autres agrégateurs ; `chariow` pour les offres numériques DYM |
| IA | AI SDK (`ai`), modèle choisi par usage dans `ai_models` | OpenAI au départ |
| Messages OTP | Webhook `send.otp` de Neon Auth | Email (SMTP) au départ ; SMS/WhatsApp ensuite **[à valider]** |
| Push | `NotificationSender` | FCM |

## 4. Sécurité

- RLS activé sur **toutes** les tables exposées ; une table sans politique n'est pas exposée.
- pgTAP vérifie, pour chaque table, qu'un utilisateur ne lit ni ne modifie les données d'un autre.
- Les colonnes sensibles (`status` d'une boutique, rôles, montants) ne sont modifiables que par
  des fonctions `SECURITY DEFINER` ou par des Functions, jamais par un `UPDATE` direct de l'app.
- Secrets (Moneroo, OpenAI, FCM, SMTP) uniquement dans les variables des Functions.
- Webhooks : vérification de signature, idempotence par identifiant d'événement, payload brut
  journalisé.
- Admin : comptes Google Workspace avec 2FA imposée tant que la MFA Neon n'est pas disponible ;
  chaque action admin écrit dans `audit_log`.

## 5. Résilience terrain

- Clé d'idempotence sur toute création (commande, paiement) : un réseau qui renvoie la requête
  ne crée pas de doublon.
- Nouvelle tentative uniquement sur erreur réseau ou 5xx, jamais sur 4xx (ex. OTP invalide).
- Rafraîchissement du JWT avant expiration, et une seule nouvelle tentative après un 401.
- Images compressées sur l'appareil avant upload ; miniatures générées par une Function
  déclenchée à la création de l'objet.
- Le centre de notifications in-app est la source de vérité ; le push n'est qu'un signal.

## 6. Environnements

| Environnement | Neon | Usage |
|---|---|---|
| `production` | Branche `main` | Pilote réel |
| `staging` | Branche `staging` | Démos, tests terrain |
| `preview` | Une branche par PR (base + stockage + Functions) | Tests pgTAP et d'intégration en CI, agents en parallèle |

Les apps choisissent l'environnement à la compilation (`--dart-define=ENV=…`) ; aucune URL en dur.

## 7. Points à valider (spec `foundation`)

1. Flux Better Auth en REST depuis Dart : OTP email, Google `idToken`, obtention et rafraîchissement du JWT.
2. Package Dart `postgrest` contre la Data API : en-tête `Authorization`, RLS, appels RPC.
3. Upload Flutter via URL présignée vers Object Storage ; lecture publique d'un bucket `public_read`.
4. Déploiement d'une Function (`neon.ts`), secret, appel HTTP depuis l'app, envoi d'un push FCM.
5. Génération Stacked + freezed + json_serializable sur la version Flutter retenue.
6. Inscription par téléphone via le webhook `send.otp` (pour la spec `phone-otp`).

Chaque point donne un go ou un no-go écrit dans `decisions/`, avec un plan B.
