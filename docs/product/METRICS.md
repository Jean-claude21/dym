# DYM — Métriques et plan de mesure

## Métrique principale (North Star)

> **Commandes livrées et payées par semaine.**

Elle n'augmente que si les trois preuves V1 avancent ensemble : offre (Fatou), demande (Awa),
fiabilité (ops).

## KPIs de vérité

| KPI | Définition | Seuil | Hypothèse |
|---|---|---|---|
| Conversion | Commandes payées / sessions avec panier non vide | > 25 % | H3 |
| Délai de livraison | Médiane commande créée → livrée | < 4 h | H5 |
| Taux de livraison | Commandes livrées / commandes acceptées | > 90 % | H5 |
| Réachat 30 j | Clientes avec ≥ 2 commandes en 30 jours | > 30 % | H3 |
| Activation vendeuse | Inscription → première commande reçue | < 24 h | H1 |
| Réactivité vendeuse | Médiane commande créée → acceptée | < 15 min | H9 |
| Multi-boutiques | Commandes avec ≥ 2 boutiques | ≥ 15 % | H2 |
| Résolution incident | Médiane ouverture → résolution | < 1 h | Preuve 3 |

## Plan d'instrumentation

- Les événements sont écrits dans la table Postgres `events` (pas d'outil tiers en V1) :
  `id, occurred_at, actor_id, actor_role, app, country_code, name, entity_type, entity_id, props jsonb`.
- Nommage : `objet_verbe_passé` en snake_case (ex. `order_created`, `product_published`).
- Les événements métier critiques sont émis **côté serveur** (SQL/Functions), jamais seulement
  depuis l'app, pour qu'ils ne puissent pas manquer.
- Aucune donnée personnelle dans `props` (pas de téléphone, d'email ni d'adresse).
- Tout événement lié à une boutique porte `store_origin` (`marche`, `maison`, `magasin`) pour suivre
  H11, et tout événement de commande porte `stores_count` pour suivre H2.

### Événements minimum de la phase 1

| Événement | Émis par | Sert à |
|---|---|---|
| `user_signed_up`, `user_signed_in` | Serveur | Activation |
| `store_created`, `store_opened`, `store_closed` | Serveur | Activation vendeuse |
| `product_published`, `product_stock_changed` | Serveur | H1 |
| `ai_product_suggestion_shown`, `ai_product_suggestion_accepted` | App + serveur | H8 |
| `search_performed`, `product_viewed`, `cart_item_added` | App | Conversion |
| `voice_search_used`, `photo_search_used` (résultat, latence ; jamais le contenu) | Serveur | H10 |
| `copilot_proposed` (articles, boutiques, manquants, latence) | Serveur | H10 |
| `copilot_cart_added` (articles ajoutés, refusés) | App | H10 |
| `content_published` (type, produits tagués), `content_product_clicked`, `content_reported` (cible, motif) | Serveur | H10 |
| `vendor_broadcast_sent` (segment, destinataires, produit joint) | Serveur | H12 |
| `checkout_started`, `order_created` | App / serveur | Conversion, H2 |
| `payment_initiated`, `payment_succeeded`, `payment_failed` | Serveur | Paiements |
| `order_accepted`, `order_rejected`, `order_status_changed`, `order_delivered`, `order_cancelled` | Serveur | H5, H9 |
| `dispute_opened`, `dispute_resolved` | Serveur | Preuve 3 |
| `admin_action_performed` | Serveur | Audit |
| `wallet_topped_up` (montant, fournisseur), `wallet_payment_succeeded` (montant), `pocket_created` (objectif, arrondi : oui/non) | Serveur | Wallet (spec 025) |
| `shopping_list_saved` (articles, récurrence), `shopping_list_proposed` (articles, boutiques, manquants), `shopping_reminder_sent` (période) | Serveur | Assistant de courses (spec 029) |
| `shopping_list_cart_added` (articles ajoutés, refusés) | App | Assistant de courses (spec 029) |
| `favorite_added` (type), `basket_saved` (lignes), `basket_reordered` (ajoutés, non ajoutés) | Serveur | Carnet (spec 030) |
| `space_created` (budget : oui/non), `space_joined`, `space_validated` (articles, montant) | Serveur | Espaces (spec 031) |
| `space_contributed` (montant), `space_funded` (montant) | Serveur | Argent des espaces (spec 032) |
| `order_scheduled` (jours d'avance, précommande), `product_arrival_set` (jours d'avance) | Serveur | Précommande et créneaux (spec 033) |
| `substitution_proposed`, `substitution_answered` (accepté), `freshness_claimed` (montant) | Serveur | Remplacement et fraîcheur (spec 034) |
| `voice_message_sent` (durée), `call_started` (type), `call_ended` (issue, durée) | Serveur | Vocaux et appels (spec 035) |
| `creator_joined`, `content_published` (+ catégorie, provenance, créatrice) | Serveur | Créateurs (spec 036) |
| `follow_added` (cible), `comment_added` | Serveur | Fil classé (spec 037) |
| `recipe_basket_built` (articles, manquants) | Serveur | Tout pour la faire (spec 038) |
| `commission_earned` (montant, taux, origine), `commission_paid` (montant, payeur) | Serveur | Affiliation (spec 039) |
| `tiktok_imported`, `share_link_created`, `share_link_opened` | Serveur | Pont TikTok (spec 040) |
| `courier_joined` (moyen, zones), `courier_online`, `courier_offline`, `mission_accepted` (minutes), `mission_released` | Serveur | App livreur (spec 041) |
| `run_accepted` (boutiques), `handover_code_failed` (essais) | Serveur | Tournées et remise (spec 042) |
| `courier_earned` (frais, cash), `courier_cash_remitted` (montant), `wallet_withdrawn` (montant, fournisseur) | Serveur | Cash et gains du livreur (spec 043) |
| `till_sale_recorded` (montant, moyen, produit reconnu), `store_paid_out` (montant, fournisseur) | Serveur | Caisse de la vendeuse (spec 045) |
| `qr_paid` (montant) | Serveur | Paiement par QR (spec 046) |
| `credit_given`, `credit_repaid` (montant), `credit_reminded` (dû) | Serveur | Ardoise (spec 047) |
| `end_of_market_started` (pourcentage, durée, produits) | Serveur | Partage et fin de marché (spec 048) |
| `wholesale_offer_opened` (minimum, durée), `wholesale_committed` (quantité) | Serveur | Achat de gros (spec 049) |
| `haggle_proposed` (issue, remise demandée en points de base), `haggle_accepted` (offre ou contre-prix, remise), `haggle_limit_set` (pourcentage, boutique ou produit) | Serveur | Marchandage (spec 050) |
| `group_offer_opened` (minimum, durée, livraison partagée), `group_joined` (quantité ; 0 : retrait), `group_unlocked` (membres, quantité totale) | Serveur | Achat groupé entre voisins (spec 051) |
| `membership_started` (code de la formule, prolongation), `member_benefit_paid` (montant) | Serveur | DYM+, Pro, visibilité (spec 052) |
| `fraud_signals_detected` (nombre), `report_triaged` (avis), `support_draft_requested` | Serveur | Antifraude, modération et support assistés (spec 054) |
