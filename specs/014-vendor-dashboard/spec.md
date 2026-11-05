# Feature Specification: Tableau de bord vendeuse

**Branch**: `feat/014-vendor-dashboard` · **Date**: 2026-10-03 · **Status**: Draft
**Input**: terminer le noyau commerce avant le pilote ; roadmap `vendor-dashboard`.
**IDs**: V-DASH-01..05/08, V-ANA-01/02. V-DASH-04 est complété par `messaging`.

## Clarifications
- Le CA représente les articles livrés et encaissés, hors livraison, avant commission,
  diminués de la part articles des remboursements réussis. Annulations, refus et cash non encaissé
  ne sont pas des ventes. Aucun total ne traverse les devises.
- Jour, semaine (lundi) et mois utilisent le fuseau du pays de la boutique.
- Un récap par boutique et date après 19 h locales. Pas de graphique, export ni classement.

## User Scenarios & Testing
### US1 — Voir mes chiffres (P1)
Fatou lit les ventes et commandes du jour en moins de 5 s, puis choisit semaine ou mois.
Acceptance : cash livré sans encaissement exclu ; après encaissement inclus ; autre boutique exclue ;
sans activité zéro. Libellé du CA et période explicites.
### US2 — Agir sur les urgences (P1)
Commandes en attente et actives, paiements attendus, variantes en rupture, notifications critiques
non lues prioritaires ; navigation vers commandes et produits.
Acceptance : traiter une commande depuis l'accueil ; produit archivé exclu des ruptures ;
stock non suivi n'est pas une rupture.
### US3 — Récap du soir (P1)
Notification interne après 19 h ; push selon préférences et téléphones enregistrés.
Acceptance : aucun récap avant 19 h ; deux exécutions ne dupliquent pas ; fuseau du pays respecté.
### Edge cases
Échec initial : erreur/réessai ; rafraîchissement hors ligne : conserver les chiffres avec indication.
Aucune valeur inventée. Deux requêtes de périodes différentes : dernière sélection prioritaire.
Boutique suspendue : lecture propriétaire autorisée.

## Requirements
- FR-001 : CA, commandes et paiements attendus par période, calcul serveur seulement.
- FR-002 : isolation propriétaire ; anonymes et comptes sans boutique refusés.
- FR-003 : navigation explicite depuis commandes, ruptures et notifications.
- FR-004 : vide, chargement, erreur, hors ligne, français et anglais.
- FR-005 : récap idempotent ; aucun pays ni texte dans le code.
- FR-006 : sept tailles de référence, texte 130 %, cibles 48 dp.
## Key Entities
Résumé de période, notification de récap, boutique, commande encaissée, variante en rupture.
## Success Criteria
SC-001 : 4/5 vendeuses lisent les ventes sans aide en moins de 5 s.
SC-002 : zéro fuite entre vendeuses et zéro doublon de récap quotidien.
SC-003 : chiffres identiques aux commandes encaissées de la période.
## Dependencies and assumptions
Specs 006–013 ; Firebase pour le push réel. Maquette 59 :
`docs/design/screens/59-vendeuse-tableau-de-bord.webp`, parcours 11 ; validation humaine avant fusion
selon la dérogation ROADMAP phase 0. Gate pilote à prouver sur le terrain.
