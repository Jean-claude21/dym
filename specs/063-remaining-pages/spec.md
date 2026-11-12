# Feature Specification: Pages restantes revisitées

**Feature Branch**: `feat/063-remaining-pages`

**Created**: 2026-11-11

**Status**: Draft

**Input**: Demande du porteur (2026-11-11) : refaire les quatre pages jugées à refaire (caisse, ardoise,
éditeur de produit, fiche commande de l'admin) puis revisiter toutes les autres pages, capture à
l'appui, dans l'esprit des planches (option A).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Les quatre pages à refaire (Priority: P1)

1. **Caisse** : total du jour en grand ; en app et hors app côte à côte ; « Vente cash » et
   « Encaisser » en tête ; ventes en lignes à filets ; solde et versement.
2. **Ardoise** : total dû en grand ; « Nouvelle cliente » en tête ; clientes en lignes (initiale, plafond,
   montant dû).
3. **Éditeur de produit** : titre à gauche, sections à plat, photo sur menthe et repli si elle ne charge
   pas.
4. **Fiche commande (admin)** : statut en pastille, cliente · boutique · montant en ligne, chronologie
   à gauche et actions à droite.

### User Story 2 - Toutes les autres pages revisitées (Priority: P1)

1. Vendeuse : relance (barre claire), boutique ouverte (fond clair, photo), catégories (titre à gauche),
   sections de formulaire à plat, note « adresse privée » sans pêche.
2. Admin : plus de jaune hors cash et notes ; listes à filets ; panneau « choisis un élément » encadré.
3. Cliente : studio créatrice (espacement), liste de courses (croix discrète).

### Edge Cases

- Photo de produit illisible : fond menthe et icône, jamais l'écran d'erreur.

## Requirements *(mandatory)*

- **FR-001**: Aucune règle métier ni migration.
- **FR-002**: Aucun texte en dur ; jaune réservé au cash, aux notes et aux mentions de simulation.

## Success Criteria *(mandatory)*

- **SC-001**: Captures regardées pour chaque page revisitée (vendeuse 20, admin 12, cliente 5, livreur 1).
- **SC-002**: Analyse et tests verts.
