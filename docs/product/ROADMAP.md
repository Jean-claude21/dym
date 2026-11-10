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
| 13 · Différence | Marchandage, achat groupé, DYM+, centre d'opérations | Démonstration complète validée | ~22 h | 🔵 En cours (spec 050) |

**Légende :** ✅ faite · 🔵 en cours · 🟡 code fait, gate terrain ou relecture à faire · ⬜ à faire · ⏸️ reportée · ➖ remplacée.
Mis à jour à chaque spec (dernière mise à jour : 2026-11-10).

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
| `haggling` | Marchandage dans la limite de la vendeuse | 🟡 Spec 050 : code fait, en attente de relecture humaine (limite de la boutique et par produit, réponse immédiate : conclu au-dessus du plancher, sinon contre-prix ; prix conclu au panier 2 heures pour la quantité marchandée, consommé par la commande ; limite jamais montrée, 3 essais par jour) |
| `group-buying` | Achat groupé entre voisins, départ groupé | ⬜ À faire |
| `memberships` | DYM+, vendeuse Pro, visibilité sponsorisée | ⬜ À faire |
| `ops-center` | Centre d'opérations en direct, rôles par pays, antifraude et modération par IA, agent support | ⬜ À faire |

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
