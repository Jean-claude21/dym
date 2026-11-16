# DYM — Roadmap

> Toutes les phases sont planifiées dès le départ ; chacune ne s'ouvre que si la précédente a
> passé son **gate**. Les durées sont des **heures de production** (agent IA + relecture humaine),
> hors délais externes (KYC, stores, terrain) qui sont lancés en parallèle dès l'heure 0.
> Chaque ligne « Spec » devient une spec Spec Kit (`/speckit-specify`). Les numéros sont
> attribués par Spec Kit à la création ; l'ordre ci-dessous est l'ordre de création prévu.

## Vue d'ensemble

| Phase | Objectif | Gate de sortie | Heures | État |
|---|---|---|---|---|
| 0 · Cadrage et validation | Valider les interfaces et les hypothèses avant de coder | 4/5 testeurs réussissent chaque parcours clé sans aide | ~10 h + sessions terrain | ✅ Faite (gate du 2026-10-02) |
| 1 · Socle | Monorepo, design system adaptatif, référentiel générique, authentification | Une cliente et une vendeuse se connectent sur un vrai téléphone, données en base avec RLS testé | ~11 h | 🟡 Code fait (specs 001-005) ; démo téléphone à faire |
| 2 · Noyau commerce | Boucle complète publier → commander → payer → livrer → résoudre | Une vendeuse externe traite une commande réelle de bout en bout | ~49 h | 🟡 Code fait (specs 006-015) ; commande réelle externe à faire |
| 3 · Pilote | Vendeuses et clientes réelles | KPIs de `METRICS.md` atteints ou écarts expliqués | ~10 h + terrain | 🟡 Code fait (specs 016, 017, 022) ; terrain à faire |
| 4 · Différenciation | IA d'intention, recherche image/voix, contenu shoppable | Ouverte si H10 validée ; > 70 % d'intentions comprises | ~24 h | 🟡 Code fait (specs 018-021) ; H10 à tester |
| 5 · Scale | Remplacée par les phases 6 à 13 (décision 0015), sauf `phone-otp`, `new-country`, `admin-v2` | Sur déclencheur | — | ➖ Remplacée |
| 6 · Assainissement | Corrections relevées, CI au vert | CI verte sur `dev`, parcours rejoués en web | ~5 h | ✅ Faite (spec 023) |
| 7 · Argent | Compte unique, grand livre, wallet et poches | Recharger, payer, chaque franc tracé | ~18 h | ✅ Faite (specs 024, 025) ; gate : démonstration web à faire |
| 8 · Expérience et IA | Finition, accueil, recherche et assistant | Commande en un écran ; « riz pour 4 » compris | ~22 h | ✅ Faite (specs 026-029) ; gate : démonstration web à faire |
| 9 · Vie réelle | Carnet, espaces, précommande, créneaux, chat, appel | Un espace remplit, valide et paie | ~24 h | ✅ Faite (specs 030-035) ; gate : démonstration web à faire |
| 10 · Contenus | Créateurs, fil, recettes, ustensiles, affiliation | Commission versée après un achat livré | ~26 h | ✅ Faite (specs 036-040) ; gate : démonstration web à faire |
| 11 · Livreur | App, tournées, cash, suivi en direct | Commande livrée de bout en bout par l'app livreur | ~26 h | ✅ Faite (specs 041-043 fusionnées, migrations sur staging ; suivi en direct reporté) ; gate : démonstration web à faire |
| 12 · Vendeuse | Caisse, QR, ardoise, Studio IA, gros | Vente hors app et QR enregistrés au grand livre | ~22 h | ✅ Faite (specs 045-049 fusionnées, migrations sur staging) ; gate : démonstration web à faire |
| 13 · Différence | Marchandage, achat groupé, DYM+, centre d'opérations | Démonstration complète validée | ~22 h | ✅ Faite (specs 050-054 fusionnées, migrations sur staging) ; gate : démonstration web complète du 2026-11-11, ouverture de la phase 14 accordée par le porteur produit le 2026-11-11 |
| 14 · Épuré | Design system épuré, navigation des quatre apps, flux vidéo, fluidité terrain | Les huit parcours de `PARCOURS.md` rejoués sur un Android d'entrée de gamme en plein soleil, aux budgets de fluidité, validés par le porteur produit | ~46 h | 🔵 En cours (design et parcours validés, accord du 2026-11-11) |
| 15 · Mondial et commerce | Tout par position, carte, livraison suivie, notifications, vendeuse, chat de commerce, wallet entre personnes, Cuisine sociale | Une commande passée et suivie sur la carte depuis Rouen et depuis Lomé, de la boutique à la porte, validée par le porteur produit | ~25 j | 🔵 En cours (plan validé le 2026-11-16) |

**Légende :** ✅ faite · 🔵 en cours · 🟡 code fait, gate terrain ou relecture à faire · ⬜ à faire · ⏸️ reportée · ➖ remplacée.
Mis à jour à chaque spec (dernière mise à jour : 2026-11-16).

Les gates des phases 6 à 13 se valident par une démonstration web au porteur produit, en simulation
pour tout service indisponible. Les durées sont des estimations.

## Délais externes à lancer à l'heure 0

| Démarche | Pourquoi | Bloque |
|---|---|---|
| Compte Moneroo + KYC | Paiement MoMo | Spec paiements (mode réel) |
| Comptes Google Play et Apple Developer | Publication | Pilote |
| Projet Firebase (FCM) | Notifications push | Spec cycle de commande |
| Domaine + SMTP de production | OTP email délivrés | Pilote |
| Projet Neon (région Francfort) | Toute la plateforme | Phase 1 |
| CGU, confidentialité, politique de remboursement | Stores + confiance | Pilote |
| Recrutement de 10 vendeuses et 10 clientes testeuses | Tests de maquettes puis pilote | Phase 0 |

## Phase 0 — Cadrage et validation (sans code de production)

| Livrable | Contenu | Heures |
|---|---|---|
| Direction de design | **Fait (2026-10-01)** : « Le marché de Lomé, livré chez toi », 8 écrans validés, tokens (`docs/design/DESIGN_DIRECTION.md`) | 2 h |
| Maquettes clés | 19 parcours cliquables (`docs/design/MOCKUPS.md`), états vide/chargement/erreur/hors ligne, 2 pays | 6-8 h |
| Tests terrain | 5 vendeuses + 5 clientes, tâches chronométrées, verbatims | ~5 h de sessions |
| Itération et gel | Corrections, puis gel de l'UI : les maquettes deviennent des critères d'acceptation | 2 h |

**Gate de la Phase 0 :** tests terrain confirmés par le porteur produit le 2026-10-02. Les écrans
non encore maquettés sont produits spec par spec dans la direction validée, puis validés par le
porteur produit avant fusion (une dérogation à la constitution II est consignée dans chaque plan).

## Phase 1 — Socle

| Spec | Contenu | IDs couverts | Heures |
|---|---|---|---|
| `foundation` | **Spec 003.** Validations techniques (Better Auth REST depuis Dart, Data API via `postgrest` + RLS + RPC, upload présigné, déploiement de Function + push, génération Stacked/freezed sur la version Flutter retenue) ; monorepo FVM + Melos ; squelettes des apps et packages ; lints ; CI | T-001, T-007 | 4 h |
| `responsive-layout` | **Volet interface du socle** (spec 002) : classes de fenêtre, tokens de mise en page, navigation adaptative (barre basse / rail), contenu borné, grilles adaptatives ; écrans validés vérifiés du téléphone au bureau | — | 2 h |
| `reference-data` | Pays, devises, villes/zones, catégories, moyens de paiement par pays, règles de commission, frais de livraison par défaut, feature flags, `events`, `audit_log` ; RLS + pgTAP | A-CFG-01..06 | 2 h |
| `auth` | Google + OTP email, profils, rôles (cliente, vendeuse, admin, livreur), suppression de compte, partagé via `dym_auth` | C-AUTH-01..04, V-AUTH-01/02, C-PROF-09 | 3 h |

## Phase 2 — Noyau commerce

| Spec | Contenu | IDs couverts | Heures |
|---|---|---|---|
| `store-onboarding` | Onboarding 7 étapes avec reprise, **« Où vends-tu ? » (origine : au marché, fait maison, boutique)**, adresse de ramassage privée pour le fait maison, réglages boutique, ouverture/fermeture, horaires, zones et frais de livraison, délai de préparation | V-AUTH-03/04, V-SET-01..06, V-DEL-01..04 | 5 h |
| `catalog` | Catégories boutique, produits, multi-photos, variantes, stock par variante, rupture en un geste, archivage, prix par variante, **photo → nom/catégorie/description proposés par l'IA** | V-CAT-01..03, V-PROD-01..09, V-PRIX-01/02 | 6 h |
| `discovery` | Détection de zone, « Boutiques ouvertes près de toi » avec badges d'origine, rayons (dont « Fait maison »), unités du marché, recherche plein texte, filtres (dont par origine), tri, page boutique, fiche produit | C-AUTH-05, C-HOME-01/02, C-SEARCH-01..03, C-CAT-01..07 | 5 h |
| `cart-checkout` | Panier multi-boutiques persistant côté serveur, sous-paniers, frais selon le nombre de ramassages, alertes rupture, adresses (saisie, GPS, sauvegarde), mode de livraison par boutique, récapitulatif, confirmation en un tap ; idempotence | C-CART-01..09, C-CHECK-01..05, C-ADDR-01..03, C-PROF-02 | 5 h |
| `payments` | Interface `PaymentProvider` générique ; fournisseurs `cash` puis `moneroo` ; webhooks signés et journalisés ; confirmation automatique ; badge « paiement confirmé » ; file de vérification manuelle (remplace la capture photo vérifiée par IA) | C-PAY-01/02/06, V-PAY-01/02/04/05, A-LOG-03 | 6 h |
| `order-lifecycle` | Machine à états serveur ; accepter/refuser, préparation, prête, livrée ; push + son ; centre de notifications ; suivi client avec ETA ; annulation avant préparation | V-ORD-01..09, C-ORD-01..04/07, C-NOTIF-01..05/09, C-PROF-03/06 | 6 h |
| `disputes` | Signaler un problème, ouverture de litige, notification de réponse | C-ORD-08, C-NOTIF-06, A-LIT-01..06 | 3 h |
| `admin-ops` | Admin Flutter Web : connexion (Google Workspace avec 2FA imposée), commandes (recherche, détail, chronologie, forcer un statut, annuler et rembourser, assigner une livraison externe), vendeuses (liste, profil, activer, suspendre), configuration, journal d'audit | A-AUTH-01/02/04/05, A-ORD-01..06/08, A-VEN-01..05/08/09, A-LIV-04, A-LOG-01/02, A-FIN-03/04 | 6 h |
| `vendor-dashboard` | Résumé du jour, commandes en attente, ruptures, notifications critiques, récap de 19 h (cron) | V-DASH-01..05/08, V-ANA-01/02 | 3 h |
| `messaging` | Chat cliente ↔ vendeuse (texte, image, partage produit), non-lus, push (SSE via Function) | C-CHAT-01/02/04, V-MSG-01..04, V-DASH-04 | 4 h |

Les profils, la FAQ et le support (C-PROF-01/08, V-PROF-01..04) sont livrés avec `auth` et `admin-ops`.

## Phase 3 — Pilote

| Spec | Contenu | IDs couverts | Heures |
|---|---|---|---|
| `pilot-hardening` | Avis après livraison, réponse vendeuse, note boutique, réachat en un tap, support (tickets) depuis les apps | C-REV-01/03/04, V-REV-01/02/04, C-ORD-09, A-SUP-01..03 (côté apps) | 5 h |
| `admin-pilot` | Tableau de bord de l'équipe, analytics minimales, feature flags pilotés depuis l'admin, SLA incidents, tickets, profil d'une cliente, revenus de la plateforme, suppression et vue d'une vendeuse | A-DASH-01..08, A-ANA-01..03, A-CFG-07, A-SUP-01..03, A-LIT-07, A-CLI-02, A-VEN-06/07, A-FIN-01/02 | 5 h |
| `pilot-readiness` | Prêt pour le pilote : profil modifiable (prénom, langue de l'app enregistrée et appliquée), entrées « bientôt » retirées, suivi des erreurs des apps et des Functions (constitution IX), câblage de démarrage vérifié, builds de release (permissions Android/iOS, signature hors dépôt) | C-PROF-01/07, V-PROF-01 | 3 h |

**Dérogation du 2026-10-10 (porteur produit) :** les phases 3 et 4 sont construites avant le
gate de la phase 2 (commande réelle d'une vendeuse externe) et avant le test de H10. Les gates
restent à prouver sur le terrain avant le pilote ; le code de la phase 4 reste désactivable par
feature flag tant que H10 n'est pas validée. Ajouts au pilote (besoin du support et des finances
pendant le pilote) : A-CLI-02, A-VEN-06/07, A-FIN-01/02, A-LIT-07. V-PAY-03 sort du périmètre
avec C-PAY-03, dont elle dépend.

Pilote : montée progressive du nombre de vendeuses après chaque semaine sans incident non résolu
en plus d'une heure.

## Phase 4 — Différenciation (ouverte si H10 validée)

| Spec | Contenu | IDs couverts | Heures |
|---|---|---|---|
| `search-voice-image` | Transcription vocale, recherche par image (description + embeddings + pgvector), historique, suggestions | C-SEARCH-04/05/07/08 | 6 h |
| `intent-copilot` | Intention (texte/photo/voix) → panier multi-boutiques proposé, avec retour à la recherche classique en cas d'échec et « je n'ai rien trouvé » explicite | C-SEARCH-06 | 6 h |
| `shoppable-content` | Stories 24 h et vidéos avec produits tagués, statistiques, modération | C-HOME-06/07, C-CAT-12, V-CONT-01..08, A-MOD-01..05 | 8 h |
| `monitoring-nudges` | Monitoring paiements/IA, relances proactives vendeuse | A-DASH-06, A-AI-01..03, V-MSG-05, V-PROD-10 | 4 h |

## Phase 6 — Assainissement

| Spec | Contenu | État |
|---|---|---|
| `foundation-fixes` | pgTAP aligné sur les pays ouverts (0026), mot de passe réservé aux environnements de test, moyens simulés absents de la production finale, régularisation du lot 023, texte admin sur la double authentification, boutique fermée visible dès la fiche, état réel affiché à la vendeuse, quartier d'inscription repris en adresse, confirmation d'ajout au panier, achat dans sa propre boutique interdit, dépendances vulnérables | ✅ Spec 023 · PR #28 |

## Phase 7 — Argent

| Spec | Contenu | État |
|---|---|---|
| `unified-account` | Un compte, plusieurs rôles (client, vendeur, livreur, créateur), bascule de rôle | ✅ Déjà en place (un compte, plusieurs rôles) ; rôle créateur avec la phase 10 |
| `ledger` | Grand livre à double écriture en SQL, rapprochements, audit | ✅ Spec 024 · PR #29 |
| `wallet-pockets` | Wallet, poches libres et règles, recharge simulée, paiement d'une commande, cashback, paniers à offrir | ✅ Spec 025 · PR #30, #31 (paniers à offrir → `spaces`) |

## Phase 8 — Expérience et IA

| Spec | Contenu | État |
|---|---|---|
| `premium-foundation` | Squelettes, cache d'images, animations, onglet Panier, commande en un écran | ✅ Spec 026 · PR #33 |
| `home-redesign` | Accueil « Qu'est-ce qu'on mange ? », fil personnel | ✅ Spec 027 · PR #35 |
| `ai-search-ranking` | Compréhension, savoir (quantités, noms locaux), règles de classement réglables, explication | ✅ Spec 028 · PR #36 |
| `shopping-agent` | Agent de courses, composition de panier, validation, récurrence | ✅ Spec 029 · PR #37 (listes libres, liste habituelle, liste décrite à l'IA, panier composé en base, rappels à 8 h) |

## Phase 9 — Vie réelle

| Spec | Contenu | État |
|---|---|---|
| `address-book-favorites` | Carnet, favoris, paniers enregistrés | ✅ Spec 030 · PR #38 (cœurs boutique et produit, « Mes favoris », paniers enregistrés remis au panier au prix du jour ; adresses : spec 009) |
| `spaces` | Espaces illimités, rôles, budget, validation, commande pour un proche | ✅ Spec 031 · PR #39 (code d'invitation, « remplit » ou « valide et paie », panier commun, budget du mois, validation vers le panier ; proche : adresse du carnet) |
| `spaces-money` | Poche commune, contributions des membres, paiement depuis l'espace, budget par personne | ✅ Spec 032 · PR #40 (poche au grand livre, versements depuis le wallet, part de chacun ce mois, validation financée par la poche) |
| `preorder-slots` | Précommande à prix bloqué, créneaux, courses récurrentes | ✅ Spec 033 · PR #41 (créneaux par pays, arrivages à prix bloqué, commande programmée validée en base ; récurrence : spec 029) |
| `substitution-freshness` | Remplacement validé par photo, garantie fraîcheur | ✅ Spec 034 · PR #42 (remplacement même prix validé par la cliente, refus et fraîcheur rendus sur le wallet au grand livre, délai et limite par pays) |
| `chat-calls` | Vocaux, médias, livreur dans la conversation, appel audio et vidéo | ✅ Spec 035 · PR #43 (vocaux privés, appels audio et vidéo tenus en base, média simulé et signalé jusqu'au vrai fournisseur ; livreur : phase 11) |

## Phase 10 — Contenus

| Spec | Contenu | État |
|---|---|---|
| `creators-content` | Profil créateur, posts de tous, formats, catégorie choisie ou classée, modération | ✅ Spec 036 · PR #44 (studio créatrice, posts photo et vidéo, catégorie choisie, proposée par l'IA ou « Autre », produits de toutes boutiques, modération existante) |
| `feed-ranking` | Lecture haut de gamme, vues flexibles, algorithme de valorisation, abonnements, commentaires | ✅ Spec 037 · PR #45 (score SQL à poids par pays, onglets et catégories, grille ou plein écran, abonnements créatrices et boutiques, commentaires modérés ; écran admin des poids : phase 13) |
| `recipe-to-cart` | « Tout pour la faire », rayon ustensiles, ingrédients génériques reliés aux vendeuses | ✅ Spec 038 · PR #46 (ingrédients à la main ou par l'IA, panier composé en base chez la meilleure vendeuse du quartier, rayon ustensiles, rayons hors grocery retirés) |
| `affiliation` | Taux, attribution, commission en attente puis versée, annulation, antifraude, tableau de bord | ✅ Spec 039 · PR #47 (taux par produit, boutique ou minimum du pays ; dernier contenu par article ; versée au wallet après le délai de réclamation, annulée si refusée ou remboursée ; ni soi-même, ni même appareil, ni même foyer ; gains du studio, « Contenu rémunéré ») |
| `tiktok-bridge` | Import par le créateur, partage vers TikTok avec lien de panier | ✅ Spec 040 · PR #48 (compte déclaré, vidéo importée par oEmbed avec couverture et « Voir sur TikTok », lien court copié qui ouvre « Tout pour la faire » ; connexion et dépôt TikTok : à l'ouverture de l'accès développeur) |

## Phase 11 — Livreur

| Spec | Contenu | État |
|---|---|---|
| `delivery-app` | App livreur, inscription, missions, acceptation | ✅ Spec 041 · PR #49 (app `dym_delivery`, même compte DYM, moyen et zones, en ligne, missions de ses zones, acceptation unique et limitée par pays, récupérée puis livrée par le livreur, coordonnées après acceptation) |
| `delivery-routing` | Tournées multi-boutiques, code de remise, consignes de conservation | ✅ Spec 042 · PR #50 (un achat multi-boutiques = une tournée, code à 4 chiffres de la cliente exigé à la remise, 5 essais, consignes par rayon ou par produit affichées au livreur) |
| `delivery-cash` | Circuit du cash, gains en direct, retrait, point de recharge | ✅ Spec 043 · PR #51 (frais au wallet, cash dû à la boutique puis confirmé, code de recharge, retrait simulé ; écran de l'équipe : `ops-center`) |
| `live-tracking` | Suivi en direct (GPS simulé), heure d'arrivée, score, bonus, zones | ⏸️ Reportée (décision du porteur produit, 2026-11-10) : les étapes à cocher (acceptée, récupérée, remise par code) suffisent ; brouillon sur la branche `feat/044-live-tracking` (PR #52 fermée) |

## Phase 12 — Vendeuse

| Spec | Contenu | État |
|---|---|---|
| `vendor-till` | Caisse en app et hors app, à la voix, « Ma caisse », frise de commande, tableau de bord utile | ✅ Spec 045 · PR #53 (ventes hors app tapées ou dictées, montant lu en base, stock décompté, « Ma caisse » du jour par moyen, solde et versement simulé, frise de la commande, accès depuis le tableau de bord) |
| `qr-payments` | Paiement et encaissement par QR | ✅ Spec 046 · PR #54 (demande de la vendeuse en QR et code à 6 chiffres, 10 minutes ; la cliente scanne ou tape le code et paie depuis son wallet ; vente dans « Ma caisse » ; commission par pays, 0 par défaut) |
| `vendor-credit` | Ardoise, relances | ✅ Spec 047 · PR #55 (clientes, crédits et remboursements datés, plafond, solde en base, relance WhatsApp une fois par jour, archivage une fois soldée) |
| `vendor-studio` | Studio IA, boutique partageable sur WhatsApp, arrivages, fin de marché | ✅ Spec 048 · PR #56 (lien public de la boutique partagé sur WhatsApp et page légère qui l'ouvre, prix de fin de marché en pourcentage pour quelques heures appliqués partout par la fonction de prix ; studio IA et arrivages : specs 007, 019, 033) |
| `wholesale` | Achat de gros groupé | ✅ Spec 049 · PR #57 (offre d'une grossiste avec minimum et date limite, réservations des vendeuses du pays, jauge, confirmation au minimum, acheteuses prévenues ; règlement hors DYM) |

## Phase 13 — Différence

| Spec | Contenu | État |
|---|---|---|
| `haggling` | Marchandage dans la limite de la vendeuse | ✅ Spec 050 · PR #58 (limite de la boutique et par produit, réponse immédiate : conclu au-dessus du plancher, sinon contre-prix ; prix conclu au panier 2 heures pour la quantité marchandée, consommé par la commande ; limite jamais montrée, 3 essais par jour) |
| `group-buying` | Achat groupé entre voisins, départ groupé | ✅ Spec 051 · PR #59 (offre groupée de la vendeuse aux quartiers qu'elle livre, jauge anonyme, déblocage au minimum, prix de groupe pour sa part et frais de livraison partagés au panier, avantage consommé par la commande) |
| `memberships` | DYM+, vendeuse Pro, visibilité sponsorisée | ✅ Spec 052 · PR #60 (formules par pays payées depuis le wallet et prolongeables ; DYM+ : frais de livraison rendus et cashback en plus à la livraison ; Pro : commission réduite ; « À la une » signalée sponsorisée ; prix de départ validés le 2026-11-11, modifiables depuis le centre d'opérations) |
| `ops-center` | Centre d'opérations en direct, rôles par pays, antifraude et modération par IA, agent support | ✅ Spec 053 · PR #61 (vue en direct d'un pays, retards selon des seuils par pays, cash des livreurs reçu, réglages audités : seuils, poids du fil, formules ; admins limités à des pays, limite appliquée au centre d'opérations seulement) · ✅ Spec 054 · PR #62 (signaux de fraude par règles SQL à seuils en base, décision de l'équipe auditée ; avis de l'IA sur les signalements ; brouillon de l'agent support relu par l'équipe) |

## Phase 14 — Épuré

Refonte visuelle et de navigation des quatre apps, sans nouvelle règle métier sauf mention.
Références : [`docs/design/PARCOURS.md`](../design/PARCOURS.md) (sitemaps, parcours, règles
d'implémentation) et les planches validées de [`docs/design/screens/epure/`](../design/screens/epure/).
Une spec à la fois, dans cet ordre : chaque spec suivante s'appuie sur les composants de la première.
Le nouveau design s'applique strictement à **chaque page** de chaque app (bienvenue, connexion,
inscription, onboarding compris) : une page n'est terminée que propre et conforme aux planches.

| Spec | Contenu | Heures | État |
|---|---|---|---|
| `design-system-epure` | Décision de design (remplace 0009 et 0011), tokens : vert `#145C43`, Inter, rayons 10–12 px, filets plutôt que cartes ; composants `dym_ui` (boutons, puces, champs à libellé visible, cartes, barre et rail de navigation, mini-panier, états vide, chargement, erreur, hors ligne) ; boutons accessibles avec leur action ; pages partagées de bienvenue, connexion, code et profil (`dym_auth`) avec photographies dédiées ; galerie et captures aux sept tailles | 12 h | ✅ Spec 055 (thème, composants, pages d'entrée avec photos, décision 0016) |
| `client-navigation` | Cliente : Accueil · Marché · Cuisine · Panier · Moi ; bandeau « commande en cours », « Racheter », micro dans la recherche ; commandes, wallet, espaces et compte regroupés dans Moi ; confirmation qui rappelle le créneau | 9 h | ✅ Spec 056 (cinq onglets, Accueil, Marché, Moi, panier selon la planche, créneau rappelé, filets sur toutes les cartes) |
| `cuisine-video-feed` | Flux vidéo plein écran à faire défiler ; produits de la vidéo, « Tout pour la recette » et quantités pour N personnes sans quitter la vidéo ; barre sombre en lecture ; une seule vidéo préchargée, qualité selon le réseau | 7 h | ✅ Spec 057 (feuilles produits et recette sur la vidéo, portions calculées en base, barre sombre ; préchargement reporté à `field-performance`) |
| `client-pages` | Pages de la cliente restructurées dans l'esprit des planches (produit, boutique, rayon, recherche, livraison, suivi, commandes, notifications, wallet, espaces, favoris, achats groupés, DYM+, messages, aide) : vraie photo, information clé en haut, listes à filets, action principale visible ; directions produit et boutique validées le 2026-11-11 | 8 h | ✅ Spec 058 (produit, boutique, wallet, espace, notifications, suivi, recherche, favoris, copilote, messages, aide ; 31 captures) |
| `vendor-navigation` | Vendeuse : Aujourd'hui (« Encaisser » en tête) · Commandes · Catalogue · Messages · Boutique ; rupture en un geste ; photo produit recadrée sur fond menthe (détourage automatique si le studio IA le permet) ; compte rangé dans Boutique | 8 h | ✅ Spec 059 (cinq onglets, Encaisser en tête avec clavier géant, catalogue à filets, compte dans Boutique) |
| `courier-refresh` | Livreur : Missions (tournée, remise par code au clavier géant) · Historique · Gains · Moi | 4 h | ✅ Spec 060 (missions avec course en cours, remise au clavier géant `DymKeypad`, historique, gains à filets) |
| `ops-console` | Opérations : sept domaines (En direct, Commandes, Support, Comptes, Finances, Configuration, Journal) à la place des onze onglets | 4 h | ✅ Spec 061 (sept domaines avec sous-sections en puces, En direct selon la planche 06) |
| `field-performance` | Premier écran depuis le cache, gestes optimistes et file hors ligne, images WebP à budget, mesures sur Android d'entrée de gamme ; les huit parcours de `PARCOURS.md` en tests d'intégration | 4 h | 🟡 Spec 062, partielle : images à budget (test), décodage à la taille affichée, rupture optimiste ; restent le cache persistant (décision de stockage), la file hors ligne, la vidéo selon le réseau, les mesures Android et les huit parcours en intégration |
| `remaining-pages` | Pages restantes refaites ou revisitées (caisse, ardoise, éditeur, fiche commande admin, puis toutes les autres) | 3 h | ✅ Spec 063 |
| `coverage-radius` | Rayon de service par ville (Configuration) ; position hors zone signalée sans imposer de quartier (commander pour un proche reste possible) ; positions hors zone comptées par pays dans le tableau de bord | 2 h | ✅ Spec 065 |
| `courier-dispatch` | Relance des livreurs (mêmes quartiers, puis toute la ville), alerte « commande prête » au livreur assigné, refus automatique d'une commande sans réponse (remboursement dû si payée) ; délais réglés par pays ; carte « Livraisons » du tableau de bord | 3 h | ✅ Spec 066 |
| `realtime-gateway` | Passerelle temps réel : événements adressés à une personne (messages, statuts, notifications) écrits en base dans la même transaction, poussés par WebSocket depuis les Functions ; reprise après coupure, connexion seulement quand un écran écoute et au premier plan ; livreur, vendeuse, cliente et chat branchés, relecture régulière gardée en filet | 4 h | ✅ Spec 067 |
| `screen-quality` | Rôles de la livraison (livreur visible pour la vendeuse et la cliente, plus de « Partir livrer » quand un livreur DYM est assigné, cash encaissé par le livreur), action qui suit le contenu quand le clavier est ouvert, « Commande envoyée » suivie en direct, langue du profil = celle du pays, champs annoncés au lecteur d'écran (test) | 3 h | ✅ Spec 068 |
| `push-notifications` | Notifications du téléphone (FCM) dans les apps cliente, vendeuse et livreur : autorisation, jeton enregistré et renouvelé, affichage app ouverte, toucher qui ouvre la commande ou les courses ; clé d'envoi sur staging ; essai réel : « Nouveau message » reçu par la vendeuse, app en arrière-plan | 2 h | ✅ Spec 069 |
| `chat-ergonomie` | Messagerie claire et fiable : jours, heures, « vu », envois immédiats renvoyés seuls au retour du réseau, réponses rapides, « Joindre » (produits, photo), panier proposé par la vendeuse, commande en cours en tête du fil, boutique depuis l'en-tête, notification qui ouvre la conversation | 3 h | ✅ Spec 070 |
| `supermarches` | Origine « Supermarché » (supermarchés et supérettes) : choisie à l'ouverture de la boutique, badge, filtre de recherche, photo dédiée | 0,5 h | ✅ Spec 071 |
| `notifications-utiles` | Notifications plus utiles : montant et articles dans les textes, quatre canaux Android (commandes, messages, courses, infos), notifications d'une même commande ou conversation remplacées, « Nuit calme » (22 h – 7 h) | 2 h | ✅ Spec 072 |
| `admin-pilotage` | Tableau de bord admin refait : à traiter, six chiffres comparés à la période précédente avec mini-courbes, évolution avec axes et survol, parcours d'achat, issues des commandes, livraisons, types de boutiques, échanges, classements ; grand écran, tablette, téléphone | 4 h | ✅ Spec 073 |
| `parcours-client` | Parcours d'achat : suivi « en direct » (phase en clair, minutes restantes, avancement, appeler le livreur, écrire à la boutique, récapitulatif complet), format épuisé dit en clair | 2 h | ✅ Spec 074 |
| `nouvelle-commande` | Nouvelle commande chez la vendeuse : alerte plein écran sur tous les onglets (son répété, montant, « Voir la commande »), compte à rebours avant refus automatique sur la carte et le détail | 2 h | ✅ Spec 075 |
| `journee-vendeuse` | Accueil de la vendeuse : commandes en attente en tête avec heure limite, ventes comparées à la veille au même moment ; catalogue : « En stock / Rupture » qui suit l'interrupteur | 1 h | ✅ Spec 076 |
| `statuts` | Statuts : « Publier un statut » depuis l'accueil de la vendeuse, vocabulaire « statut » partout, partage WhatsApp (repli : copie) depuis le fil, la créatrice et le lecteur de statuts | 1 h | ✅ Spec 077 |
| `livreur-terrain` | Livreur : « Appeler » et « Itinéraire » (app de cartes du téléphone) pour la boutique et la cliente de la course en cours | 0,5 h | ✅ Spec 078 |
| `recherche-tolerante` | Recherche tolérante aux fautes (« tomattes » trouve les tomates), résultat signalé « Résultats proches de … » | 1 h | ✅ Spec 079 |
| `notifications-suite` | Notifications : photo du produit principal dans le push d'une commande, rappel « Ton panier t'attend » (une fois par jour, 9 h – 20 h) qui ouvre le panier ; boutons d'action reportés | 1,5 h | ✅ Spec 080 |
| `import-catalogue` | Import du catalogue (supermarchés) : coller des lignes depuis un tableur, vérification ligne par ligne, création en brouillon ; personnel multiple et succursales à cadrer | 2 h | ✅ Spec 081 |
| `marque` | Marque : logo (sac DoYourMarket aux couleurs « Épuré »), icônes des trois apps (fond propre à chacune, icône adaptative), splash animé « Réalisé par Kete » identique à `splash-anime.gif` (4 s), photos d'accueil gardées sans monument | 3 h | ✅ Spec 082 |
| `suivi-erreurs` | Suivi des erreurs : cinq projets Sentry (quatre apps, Functions), DSN hors dépôt, `ERROR_REPORTING_DSN` enfin transmis au déploiement des Functions | 0,5 h | ✅ Spec 083 |
| `appels-livekit` | Appels réels dans le chat (LiveKit) : fournisseur choisi par la base (flag `calls_livekit`), jeton émis par la Function aux deux personnes de l'appel, micro, haut-parleur, vidéo plein écran ; numéro jamais dévoilé | 3 h | ✅ Spec 084 |
| `roles-admin` | Rôles des admins (super-admin, opérations, support, finance, contenu, analyste) : permission exigée par la base pour chaque fonction admin, menu et réglages filtrés, rôle choisi à l'invitation et modifiable, changements journalisés | 3 h | ✅ Spec 085 |
| `analytics-mcp` | Analytics dans la base (vues sans donnée personnelle, lecteur en lecture seule pour Looker Studio ou Metabase) et serveur MCP de l'admin : clés personnelles, fonctions admin avec les droits de l'admin, requêtes d'analyse, écritures journalisées | 4 h | ✅ Spec 086 |
| `personnel-boutique` | Personnel des boutiques (gérante, préparatrice, caissière) invité par email, accès vérifiés par la base, argent et réglages à la propriétaire ; succursales : une boutique par lieu, changement de boutique | 4 h | ✅ Spec 087 |
| `moneroo` | Mobile Money par Moneroo (bac à sable ou réel selon la clé) : page Moneroo, webhook signé relu chez Moneroo, bascule simulation ↔ Moneroo par l'admin, journalisée | 3 h | ✅ Spec 088 |
| `appels-audio` | Appels audio seulement (vidéo fermée par le flag `calls_video`), validés entre deux téléphones : sonnerie, décroché, voix dans les deux sens, raccrocher | 1 h | ✅ Spec 089 |
| `essais-testeurs` | Côte d'Ivoire ouverte par configuration, admin en ligne (Firebase Hosting) avec le logo, comptes des testeuses, APK Android signés, retours des premiers essais | 5 h | ✅ Spec 090 |
| `admin-refonte` | Admin refondue en console : menu groupé avec compteurs, tableau de bord en six cartes, boutiques en tableau avec fiche latérale, connexion dans le même style, déployée | 6 h | ✅ Spec 091 |
| `suivi-erreurs` | Erreurs du serveur attrapées par les apps (5xx, réponse illisible, erreur inconnue) signalées à Sentry par lieu, sans donnée personnelle ; branchement vérifié dans les quatre projets | 1 h | ✅ Spec 092 |
| `last-pages` | Grille de relecture des captures (`REVUE_CAPTURES.md`), espacements, jaune des moments forts, cartes produit identiques, rayon et accueil resserrés ; toutes les captures relues et corrigées | 4 h | ✅ Spec 064 |

Gate : les huit parcours rejoués sur un Android d'entrée de gamme en plein soleil, 60 images/s au
défilement, ouverture en moins de 3 s, validés par le porteur produit. La phase s'ouvre quand le
gate de la phase 13 est consigné.

## Phase 15 — Mondial et commerce

Retours des premiers essais (2026-11-16) et décisions du porteur produit : DYM devient une application
mondiale (France ouverte : Rouen, Troyes, Paris, Toulouse), la position remplace le quartier comme
base de tout, et les grands modules (livraison, chat, wallet, Cuisine, vendeuse) sont poussés au
niveau des grandes applications. On garde le design « Épuré » des apps. Les services indisponibles
restent simulés et signalés (décision 0015). Une spec à la fois, dans cet ordre.

| Spec | Contenu | Heures | État |
|---|---|---|---|
| `identite-visiteurs` | Couleurs par app (client fond clair, vendeuse fond vert, livreur plantain, admin vert profond) sur icônes et splash ; mode visiteur (découvrir sans compte, connexion demandée pour commander, écrire, payer) ; message « page non chargée » distinct de « enregistrement impossible » | 6 h | 🔵 Spec 093 |
| `position-partout` | Tout par position (PostGIS) : boutique placée sur la carte avec rayon ou zone de livraison dessinée, cliente servie selon sa position, tri par distance, frais par tranches de distance (par pays, en SQL), livreurs par distance ; quartiers et villes deviennent des repères facultatifs (nom lisible, repli sans GPS, statistiques) ; données existantes reprises | 18 h | ⬜ Spec 094 |
| `carte` | Carte DYM (MapLibre, fonds OpenFreeMap, style aux couleurs DYM, fournisseur derrière une interface) : boutiques autour de soi en liste ou carte (épingles par type, regroupement, fiche), filtres pays, ville, ouvert, catégorie ; « Placer ma porte » ; zone de livraison de la boutique sur la carte | 14 h | ⬜ Spec 095 |
| `livraison-suivie` | Suivi en direct (position du livreur pendant la course, heure d'arrivée), code de récupération (QR montré par le livreur, scanné par la vendeuse) et code de livraison ; partage du suivi par lien temporaire (proche du livreur, personne qui réceptionne) ; outils du livreur (gains, client injoignable, SOS) ; livreurs propres à la boutique ; validation des comptes vendeuse et livreur | 22 h | ⬜ Spec 096 |
| `notifications-appels` | Un son par événement, boutons d'action dans les notifications (accepter, répondre, appeler, voir), boîte de notifications de la vendeuse et du livreur, appel qui sonne en plein écran même téléphone verrouillé, appel manqué | 14 h | ⬜ Spec 097 |
| `vendeuse-plus` | Accueil de la vendeuse poussé : alerte de commande, statistiques simples, résumé du jour, alertes de stock, meilleurs produits et clientes fidèles | 12 h | ⬜ Spec 098 |
| `chat-commerce` | Chat de commerce : vidéo enregistrée ou partagée, vocal soigné avec transcription, position (ponctuelle ou en direct), fiches produit avec ajout au panier, devis accepté en un geste, demande de paiement, coupons, appels vidéo | 22 h | ⬜ Spec 099 |
| `wallet-personnes` | Avoir DYM entre personnes (simulé) : QR personnel, envoyer, demander (« paie ma commande »), recharger pour un proche, argent de poche et suivi parental avec plafonds ; jamais de retrait | 14 h | ⬜ Spec 100 |
| `cuisine-sociale` | Cuisine sociale : profils de créatrices et boutiques, s'abonner, fils Pour toi / Abonnements / Près de moi, commentaires, « Mes recettes », « J'ai fait la recette » ; vidéo adaptative (HLS) dès que le compte vidéo est fourni | 18 h | ⬜ Spec 101 |
| `connexion-google` | Pont de connexion (Function) : jeton Google vérifié puis session ouverte ; prêt pour WhatsApp dès que le compte Meta est fourni | 6 h | ⬜ Spec 102 |

Gate : une commande passée et suivie sur la carte depuis Rouen et depuis Lomé, de la boutique à la
porte, avec codes, notifications et chat, rejouée en entier et validée par le porteur produit.

## Phase 5 — Scale (anciennes specs sur déclencheur, remplacées sauf mention)

Seules `phone-otp`, `new-country` et `admin-v2` restent valables ; les autres lignes sont reprises
dans les phases 6 à 13.

| Spec | Déclencheur | IDs couverts | Heures |
|---|---|---|---|
| `phone-otp` | H7 invalidée ou demande terrain | Téléphone/WhatsApp OTP | 3 h |
| `promotions` | Pilote validé | V-PROMO-01..06, V-PRIX-03, C-CART-10 | 4 h |
| `vendor-offers` | Modèle de monétisation validé | Offres DYM payantes aux vendeuses via **Chariow** (produits numériques) | 2 h |
| `wallet` | Conformité réglementaire obtenue | C-WAL-01..04, V-WAL-01..04, A-FIN-05..07 | 8 h |
| `delivery-app` | > 50 commandes/jour pendant 14 jours | L-\* P0, A-LIV-01..05 | 15 h |
| `live-tracking` | `delivery-app` active | C-ORD-05/06, L-DEL-08/09 | 6 h |
| `admin-v2` | Pilote validé | A-ANA-04..07, A-CFG-08..10, A-FIN-08, A-SUP-04..07 | 8 h |
| `new-country` | Demande d'ouverture | Activation par configuration (A-CFG-01..03) | 1-2 h |

## Hors périmètre définitif

C-PAY-03 (capture MoMo vérifiée par IA, remplacée par la file de vérification manuelle), V-PAY-03 (alerte de capture suspecte, qui en dépend).

## Définition de terminé (pour chaque spec)

1. Les critères d'acceptation reprennent les maquettes validées.
2. pgTAP passe (RLS + règles métier) sur une branche Neon dédiée.
3. `melos run analyze` et `melos run test` passent ; au moins un test d'intégration du parcours nominal.
4. Les événements de `METRICS.md` concernés sont émis.
5. Écrans sans débordement aux tailles de référence de `dym_ui` (téléphone portrait et paysage,
   tablette, bureau), le téléphone portrait restant la référence de design.
6. Démo sur un vrai téléphone Android d'entrée de gamme.
