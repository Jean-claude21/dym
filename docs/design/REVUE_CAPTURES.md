# Relecture des captures : la grille

Chaque page modifiée est capturée (tests `golden` de `test/capture/`) puis relue avec cette grille,
**avant** de la montrer. Un défaut trouvé se corrige tout de suite, dans le composant partagé quand il
vient de lui. La relecture se fait sur les sept tailles de référence pour la mise en page, et au moins
en téléphone portrait (412 × 915) avec de vraies photos pour le rendu.

## 1. Espacement (règle « Uber Eats »)

| Entre | Écart |
|---|---|
| Deux boutons empilés | 12 px |
| Deux boutons côte à côte | 8 px |
| Deux champs de saisie ; dernier champ et son bouton | 16 px |
| Titre de section et son contenu | 8 px |
| Deux sections | 24 px |
| Contenu et barre d'action du bas | 16 px au-dessus, marge de 16 px autour |
| Bords de l'écran (gouttière) | 16 px minimum |

Aucun élément interactif ne touche un autre. Aucun texte ne colle à un bord de carte (12 px de marge
intérieure minimum).

## 2. Cartes et listes identiques

- Dans une même rangée ou grille, toutes les cartes ont **exactement** la même taille : photo carrée de
  même taille, même hauteur de texte réservée, prix et « + » alignés en bas.
- Une liste aligne ses vignettes, ses textes et ses montants sur les mêmes colonnes.

## 3. Débordement du texte

| Texte | Règle |
|---|---|
| Nom de produit, de boutique dans une carte | 2 lignes maximum, place de 2 lignes toujours réservée, puis « … » |
| Unité, boutique, méta | 1 ligne, puis « … » |
| Prix, montants | jamais coupés : la ligne se réorganise (passage à la ligne de l'étiquette) |
| Titres de page | passent à la ligne, jamais coupés |
| Boutons | libellé court ; s'il ne tient pas, les boutons s'empilent au lieu de se couper |

Le texte complet reste disponible (fiche, lecteur d'écran). Aucun débordement rayé jaune et noir, à
130 % de texte compris.

## 4. Couleurs

- Vert : actions et états positifs.
- Jaune : cash, notes et **moments forts** (promotion, fin de marché, « Nouveau », célébration, badge du
  panier). Jamais sur un simple « Continuer ».
- Rouge : erreur, retard, rupture, montant dû.
- Pêche : alerte à surveiller. Menthe : information, sélection.

## 5. Hiérarchie et propreté

- Un seul bouton principal visible par écran.
- Titres à gauche, sauf écrans de célébration.
- Pas plus de trois cartes blanches à la suite sans respiration ; regrouper les raccourcis.
- Photos : jamais de cadre vide ou d'erreur ; repli menthe avec icône.
- États vides avec une icône propre au sujet et une action.
- Aucune donnée incohérente visible (doublon, photo qui ne correspond pas) : la signaler.

## 6. Avant de dire « fait »

Toutes les pages touchées sont recapturées, relues avec cette grille, et la liste des pages non
capturées est donnée explicitement.
