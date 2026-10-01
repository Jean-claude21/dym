# DYM — Direction de design

> Statut : **proposition, à choisir.** Trois concepts distincts, une recommandation.
> Le concept retenu sera maquetté (`MOCKUPS.md`) puis testé sur le terrain avant tout code d'UI.

## Le constat

L'ancien design system DYM était un Material générique (orange `#FF9800`, vert, gris), sans rien qui
le distingue d'une app de livraison quelconque. Or DYM a un avantage que personne ne peut copier :
**le marché ouest-africain lui-même**, avec ses étals, ses pagnes, ses cauris, ses zems et sa
façon de vendre à la voix. Le design doit rendre DYM **reconnaissable en une seconde, joyeux, et
plus simple que WhatsApp**.

## Contraintes qui ne bougent pas

- Android d'entrée de gamme (2 Go RAM) : 60 images/s, animations légères, repli statique.
- Plein soleil : contraste AA minimum partout, **mode soleil** à contraste renforcé.
- Littératie variable : icône + mot sur chaque action, gros chiffres, cibles tactiles ≥ 48 dp.
- Réseau instable : chaque écran a ses états vide, chargement, erreur et hors ligne, dessinés.
- Générique : la devise, la langue et les moyens de paiement changent avec le pays sans casser la mise en page.

---

## Concept A — « Le Marché Vivant »

**Métaphore :** l'app est un marché qu'on parcourt.

- **Accueil = une allée de marché** de ta zone : chaque boutique est un **étal** avec son auvent.
  Auvent levé = boutique ouverte ; volet baissé = fermée. On « flâne » au lieu de scroller une liste.
- **Le panier tressé** : chaque article ajouté tombe dans un panier en osier ; on voit les petits
  auvents des boutiques mélangées dedans. Le multi-boutiques devient visible et désirable (H2).
- **Le suivi = la course du zem** : un moto-taxi avance sur un chemin, du stand de Fatou jusqu'à
  la porte d'Awa, à chaque changement de statut.
- **Le cauri comme symbole de valeur** (l'ancienne monnaie de la région) : récompenses, badges de
  fiabilité, célébrations.
- **Moments signature** : la **première vente** de Fatou fait pleuvoir des cauris, avec un son de
  caisse, et produit une carte partageable « Ma première vente sur DYM » ; la **caisse du soir**
  (récap de 19 h) compte les cauris de la journée.

**Pour :** très mémorable ; rend le multi-boutiques concret ; parle aux deux personas.
**Risques :** illustration lourde (coût de production, performances) ; ne doit jamais ralentir
la recherche d'un produit précis.

## Concept B — « Le Pagne »

**Métaphore :** DYM est un tissu ; chaque boutique a son motif.

- **Identité générative** : à l'onboarding, Fatou choisit son motif parmi trois motifs générés à
  partir du nom et de la catégorie de sa boutique (géométries inspirées du kente éwé, du wax, de
  l'adire). Elle obtient **une identité de marque en dix secondes**, sans logo ni photo. Fini les
  avatars vides.
- **Cartes « coupons de tissu »** : chaque produit est présenté sur la bande de motif de sa boutique ;
  dans le panier, les bandes s'empilent comme des pagnes pliés.
- **Étiquettes cousues** : prix, statuts et badges ont la forme d'étiquettes de tissu.
- **Affiches pour le statut WhatsApp** : un tap génère une affiche produit dans le cadre du motif
  de la boutique, avec un lien profond. Le canal où vend déjà Fatou devient **la machine
  d'acquisition de DYM**.
- **Transitions** : le tissu se déplie à l'ouverture d'une fiche.

**Pour :** distinctif, très partageable, système graphique cohérent et extensible.
**Risques :** surcharge visuelle si les motifs débordent des zones d'identité ; respect de
l'origine et du sens des motifs (à valider avec des créateurs locaux).

## Concept C — « La Voix du Marché »

**Métaphore :** on vend et on achète en parlant, comme au marché et sur WhatsApp.

- **Tantie DYM** : un personnage animé, à la fois guide et voix de l'app, qui accompagne les
  premiers pas, en français puis en langues locales (éwé, mina, fon).
- **Publier en parlant** : photo + note vocale « trois pagnes wax, cinq mille francs » → la fiche
  se remplit toute seule.
- **Notifications vocales** façon note WhatsApp, pour les vendeuses qui lisent peu.
- **Chercher en parlant** : bouton micro géant sur l'accueil.

**Pour :** le plus inclusif ; très différenciant ; s'appuie sur un usage réel (les notes vocales).
**Risques :** dépend de l'IA (phase 4) ; un personnage peut paraître enfantin ; coût de production
de la voix en langues locales.

---

## Recommandation : A × B, avec la voix en réserve

- **Structure et moments forts de A** : allée d'étals, panier tressé, course du zem, cauris.
- **Moteur d'identité de B** : le motif génératif est le « logo » de chaque boutique, et il habille
  ses étals, ses cartes produits et ses affiches WhatsApp.
- **C en phase 4** : la publication vocale et la recherche vocale arrivent avec la spec
  `search-voice-image`, si H8 et H10 sont validées. Tantie DYM reste une option testée en maquette.

Pourquoi : A rend DYM mémorable et rend visible le multi-boutiques (H2) ; B résout un vrai problème
(les boutiques informelles n'ont pas d'identité visuelle) et ouvre une boucle d'acquisition gratuite
via les statuts WhatsApp ; aucun des deux ne dépend de l'IA pour fonctionner.

## Langage visuel proposé (pour A × B)

| Élément | Proposition |
|---|---|
| Couleurs | Indigo adire (marque), ocre et terracotta (chaleur), vert kente (succès), sur un fond crème (lisible au soleil). Couleurs sémantiques distinctes des motifs. |
| Typographie | Une display condensée et expressive pour les titres et les prix ; une sans-serif humaniste très lisible pour le texte. Chiffres tabulaires pour les montants. |
| Formes | Coins généreux, bords « cousus » (pointillés) pour les étiquettes, auvents festonnés. |
| Motion | Rive pour les moments signature (cauris, zem, panier) ; `flutter_animate` pour les micro-interactions ; tout est désactivable (mode économie). |
| Son | Trois sons maximum : nouvelle commande (fort, distinctif), vente encaissée, erreur. Coupables. |
| Illustration | Scènes de marché pour les états vides et hors ligne (« le marché est fermé, on revient vite »). |

## Garde-fous

- Les motifs ne servent qu'aux **zones d'identité** (auvent, bande de carte, affiche) ; jamais derrière du texte.
- Tout moment « fun » doit être **plus rapide** que sa version neutre, ou désactivable.
- Les motifs et symboles sont choisis avec leur sens et validés par des créatrices et créateurs
  locaux ; pas de pastiche.
- Chaque concept est testé en maquette avec 5 vendeuses et 5 clientes avant d'être figé.
