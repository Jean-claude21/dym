# Plan : Copilote d'intention

**Spec** : [spec.md](spec.md)

**Branche** : `feat/019-intent-copilot`, empilée sur `feat/018-search-voice-image`.

## Technique

### Base

Migration `db/migrations/0021_intent_copilot.sql` :

- `app.copilot_quote(lignes)` : chiffrage au prix du jour, groupé par boutique. Les lignes invalides
  sont écartées et la quantité est bornée.
- `app.copilot_pick(quartier, besoins)` :
  - un produit par besoin, en préférant une boutique déjà retenue ;
  - besoins non trouvés rangés dans `missing`.
- `public.copilot_quote` : rechiffrage par la Data API.
- `app.copilot_context` : flag, modèle et quartier du pays.
- `app.copilot_proposed` : journal IA et événement de comptes.
- `app.record_ai_request` est généralisé, sans événement pour le copilote.
- Amorçage :
  - modèle `intent_copilot` ;
  - événements `copilot_proposed` (serveur) et `copilot_cart_added` (app).

### Function

`POST /v1/copilot/propose` `{text, zone_id}` :

- planification par sortie structurée de l'AI SDK ;
- choix et chiffrage en SQL ;
- 503 si l'IA échoue.

### Dart

- **Modèles** : `CopilotProposal`, `CopilotStore`, `CopilotLine`.
- **Données** : `CopilotRepository`, avec `propose` et `quote`.

### App cliente

- `CopilotService`, en version Neon et en version mémoire.
- Écran 73, ouvert depuis l'accueil si le flag est actif :
  - saisie, voix et photo (spec 018) ;
  - lignes retirables ;
  - « Tout ajouter au panier » par le panier existant ;
  - « Chercher moi-même ».

## Constitution

- **Postgres source de vérité** : prix, total, disponibilité et choix sont calculés en SQL. L'app
  n'additionne rien : chaque retrait appelle un rechiffrage.
- **Générique** : modèle en base, fournisseur derrière une interface.
- **Données personnelles** : le texte de l'intention n'est ni conservé ni envoyé dans les événements.

## Dérogations

**Gate de la phase 3 (H10 non testée)** : dérogation du porteur produit du 2026-10-10. Tout reste
derrière `intent_copilot`, coupé par défaut.
