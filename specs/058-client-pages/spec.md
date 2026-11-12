# Feature Specification: Pages de la cliente restructurées

**Feature Branch**: `feat/058-client-pages`

**Created**: 2026-11-11

**Status**: Draft

**Input**: Spec `client-pages` de la roadmap (Phase 14). Directions validées par le porteur le
2026-11-11 : planches [08 produit](../../docs/design/screens/epure/08-cliente-page-produit.webp) et
[09 boutique](../../docs/design/screens/epure/09-cliente-page-boutique.webp) ; pour les pages sans
planche, disposition conçue dans l'esprit des planches et vérifiée sur capture (option A). Planche
[03](../../docs/design/screens/epure/03-cliente-moi-wallet-espaces.webp) pour le wallet et l'espace.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fiche produit (Priority: P1)

1. **Given** une fiche, **Then** photo pleine largeur sur menthe ; boutique en une ligne cliquable ;
   nom, prix en vert et unité ; formats en tuiles égales ; livraison, fraîcheur, arrivage et stock en
   lignes à filets ; description ; vidéos, question, signalement ; « De la même boutique » (4 produits) ;
   barre du bas « Ajouter · prix » (prix unitaire de la base, affiché seulement pour 1).

### User Story 2 - Page boutique (Priority: P1)

1. **Given** une boutique, **Then** couverture (la vendeuse et son étal), photo ronde qui déborde ; nom,
   origine, quartier et horaires, note ; délai, livraison et retrait en trois colonnes ; mention de
   retrait sans adresse publique (fait maison) ; message et avis ; puces de catégories ; produits en
   liste (photo, nom, unité, prix, « + » ou quantité, « Rupture ») ; mini-panier.

### User Story 3 - Toutes les autres pages (Priority: P1)

1. **Given** wallet, espace, notifications, suivi, recherche, livraison, favoris, copilote, messages,
   aide, DYM+, achats groupés, adresse, avis, paiement, **Then** titre à gauche, listes à filets plutôt
   que cartes empilées, vignettes menthe, jaune réservé au cash, aux notes et aux mentions de
   simulation, états vides avec une icône propre au sujet.

### Edge Cases

- Pas de photo : vignette menthe avec feuille ; couverture absente : fond menthe.
- Plusieurs formats : « dès X » une seule fois dans les listes.
- Texte à 130 %, petit écran : aucun débordement (tests aux sept tailles).

## Requirements *(mandatory)*

- **FR-001**: Aucun prix calculé dans l'app (prix × quantité jamais affiché).
- **FR-002**: Aucune nouvelle règle métier ; aucune migration.
- **FR-003**: Aucun texte en dur.

## Success Criteria *(mandatory)*

- **SC-001**: 31 captures de la cliente regardées, avec photos de contrôle.
- **SC-002**: Analyse et tests verts.
