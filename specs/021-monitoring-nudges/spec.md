# Feature Specification: Suivi de l'IA et relances

**Feature Branch**: `feat/021-monitoring-nudges`

**Created**: 2026-10-11

**Status**: Draft

**Input**: Spec `monitoring-nudges` de la roadmap (Phase 4 ; A-DASH-06, A-AI-01..03, V-MSG-05,
V-PROD-10). Elle est construite avant le gate de la phase 3 par décision du porteur produit du
2026-10-10. La relance reste derrière le flag `vendor_broadcast`, coupé par défaut.

## Contexte

L'équipe doit savoir si l'IA aide vraiment : combien de requêtes sont comprises, en combien de
temps, et combien finissent dans la recherche classique. Elle doit aussi savoir quand les paiements
décrochent. Fatou veut prévenir ses clientes fidèles quand le gombo arrive, et être prévenue avant
la rupture.

**Maquettes** à valider : 77 (IA et paiements), 78 (relancer mes clientes).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - IA et paiements (Priority: P1)

Le tableau de bord de l'admin gagne une section « IA et paiements » (77). Elle montre :

- les requêtes comprises sur 24 h ;
- la latence moyenne ;
- les passages à la recherche classique (copilote sans proposition) ;
- les paiements réussis sur la dernière heure, avec une alerte sous 90 % ;
- la compréhension sur 7 jours ;
- les dernières requêtes non comprises, sans personne.

### User Story 2 - Relancer mes clientes (Priority: P2)

Depuis « Ma boutique », Fatou choisit un segment et voit le nombre de clientes pour chacun :

- régulières : 2 commandes ou plus ;
- du mois ;
- toutes.

Elle écrit un message (300 caractères au plus), peut joindre un produit, puis envoie. Une relance
par jour au plus. Les clientes qui ont coupé les promotions ne la reçoivent pas.

### User Story 3 - Stock bas (Priority: P2)

Fatou active « Me prévenir sous N unités ». Quand une variante passe sous ce seuil, elle reçoit
une notification, une seule fois par passage.

### Edge Cases

- Aucune cliente dans le segment : l'envoi est désactivé.
- Flag coupé : l'entrée « Relancer mes clientes » n'apparaît pas et l'envoi est refusé
  (`feature_disabled`).
- Aucune requête IA sur la période : les taux s'affichent « — ».

## Requirements *(mandatory)*

- **FR-001**: `admin_ai_health` est calculé en SQL depuis `ai_requests` et `payments`, et réservé à
  l'équipe. Le texte d'une requête n'est gardé que si rien n'a été proposé, et il est affiché sans
  personne.
- **FR-002**: Relance :
  - envoyée par une Function, avec la notification `store_broadcast` (catégorie promotions) ;
  - une par jour et par boutique ;
  - produit joint appartenant à la boutique et publié ;
  - événement `vendor_broadcast_sent`.
- **FR-003**: Stock bas : seuil par boutique (1 à 999), déclencheur SQL au passage sous le seuil,
  notification `low_stock` dans l'app vendeuse.
- **FR-004**: Écrans 77 et 78 :
  - états vide, chargement, erreur et hors ligne ;
  - sept tailles, texte à 130 %.

## Success Criteria *(mandatory)*

- **SC-001**: L'équipe voit une chute des paiements dans l'heure (alerte sous 90 %).
- **SC-002**: Aucune cliente ayant coupé les promotions n'est relancée (pgTAP).

## Assumptions

- L'alerte de paiement s'affiche dans l'admin. L'envoi automatique (e-mail, push à l'équipe)
  attend l'outil de suivi d'erreurs.
- Le seuil de stock bas est fixé par boutique et non par produit, comme sur la maquette 78. Un
  seuil par produit reste au backlog.
