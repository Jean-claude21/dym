# Feature Specification: Parcours d'achat de haut niveau

**Feature Branch**: `feat/074-parcours-client`

**Created**: 2026-11-13

**Status**: Draft

**Input**: Point 2 de la liste validée par le porteur (2026-11-13) : accueil → fiche → panier →
paiement → suivi « en direct ». Features C-05 (fiche), C-08 (panier), C-11 (suivi).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Savoir où en est ma commande d'un coup d'œil (Priority: P1)

En tête du suivi : la phase en clair (« En attente de la boutique », « En préparation », « Prête »,
« En route », « Livrée »), une phrase qui dit quoi attendre, l'heure prévue avec « dans 20 min »,
une barre d'avancement. Les étapes commencent à « Envoyée » et disent « En préparation » tant
qu'elle dure.

### User Story 2 - Agir sans chercher (Priority: P1)

Livreur assigné : nom, numéro et bouton « Appeler ». « Écrire à la boutique » ouvre la conversation.
« Signaler un problème » reste disponible.

### User Story 3 - Comprendre ce que je paie (Priority: P1)

Récapitulatif : articles avec quantité, sous-total, livraison (ou « Retrait en boutique · Gratuit »),
total, mode de paiement ; cash à la livraison mis en avant.

### User Story 4 - Fiche produit honnête (Priority: P2)

Un format épuisé affiche « Rupture » en clair au lieu d'être seulement barré.

## Requirements *(mandatory)*

- **FR-001**: phase, minutes restantes et avancement calculés par le viewmodel (statut lu en base).
- **FR-002**: appel par le composeur du téléphone (`tel:`), aucune donnée envoyée.
- **FR-003**: textes dans `dym_l10n`.

## Success Criteria *(mandatory)*

- **SC-001**: test du suivi (phase, minutes, avancement) ; écrans aux 7 tailles ; captures « en
  préparation » et « en route » relues.
