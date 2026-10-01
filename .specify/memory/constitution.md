# DYM Constitution

## Core Principles

### I. Contrat V1 et phases à gates

- Tout travail DOIT correspondre à une spec listée dans `docs/product/ROADMAP.md` et citer ses
  identifiants de features (C-\*, V-\*, L-\*, A-\*).
- Une phase ne s'ouvre que lorsque le gate de la précédente est atteint et consigné.
- Jusqu'à la fin du pilote, seules les actions du contrat V1 (`docs/product/VISION.md` §3) sont
  construites. Une feature du backlog n'en sort que si une personne réelle est bloquée par son absence.
- Pas de refactoring de code fonctionnel sans spec qui le justifie.

Justification : les versions précédentes ont échoué par excès de périmètre, pas par manque de code.

### II. Valider avant de construire

- Toute spec qui crée ou modifie un écran DOIT référencer une maquette validée sur le terrain
  (`docs/design/MOCKUPS.md`) ; ses critères d'acceptation reprennent la tâche et le critère de test.
- Toute hypothèse produit est inscrite dans `docs/product/HYPOTHESES.md` avec son seuil avant le
  test, et les seuils ne sont pas modifiés après lecture des résultats.

Justification : une maquette corrigée coûte des minutes ; un écran reconstruit coûte des heures.

### III. Postgres est la source de vérité

- Les règles métier (calcul des montants, transitions de statut, permissions) DOIVENT vivre en SQL :
  contraintes, fonctions transactionnelles, RLS.
- Les apps NE DOIVENT PAS calculer un prix ni décider d'une transition ; tout montant envoyé par
  une app est ignoré et recalculé côté serveur.
- Les Neon Functions ne portent que les effets externes (paiement, push, IA, stockage, crons) et
  NE DOIVENT PAS dupliquer une règle déjà en SQL.
- Toute écriture qui déclenche un effet passe par une Function ; le CRUD simple propriétaire passe
  par la Data API.

Justification : une seule vérité, partagée par toutes les apps, impossible à contourner depuis un client.

### IV. Générique par configuration

- Pays, devises, villes et zones, catégories, moyens de paiement, commissions, frais par défaut,
  feature flags et modèles d'IA DOIVENT être des données de référence, jamais des constantes de code.
- Tout montant est stocké en `amount_minor bigint` + `currency_code` (ISO 4217) ; aucun flottant.
  Les décimales viennent de la table des devises. Un panier ne mélange ni pays ni devises.
- Les fournisseurs externes (paiement, IA, messages OTP, push) sont derrière une interface ; en
  ajouter un ne modifie aucune app.
- Aucun texte visible n'est écrit en dur : tout passe par les fichiers de localisation.

Justification : ouvrir un nouveau pays doit être une opération de configuration.

### V. Sécurité par défaut (NON NÉGOCIABLE)

- Aucune table n'est exposée par la Data API sans RLS activé et politiques testées par pgTAP
  (lecture et écriture par un autre utilisateur refusées).
- Les colonnes sensibles (statut de boutique, rôles, montants, statut de paiement) ne sont
  modifiables que par des fonctions `SECURITY DEFINER` ou des Functions.
- Aucun secret dans une app ni dans le dépôt : secrets uniquement dans les variables des Functions
  et les coffres de CI.
- Tout webhook est vérifié par signature, traité de façon idempotente et journalisé brut.
- Toute action admin écrit dans `audit_log` (qui, quoi, quand, avant, après).

### VI. Architecture Flutter en couches

- Stacked MVVM : les vues ne contiennent aucune logique ; les viewmodels orchestrent via des
  repositories qui retournent `Result<T>`.
- Les dépendances descendent uniquement : `apps → features → ui · data → domain → infra → foundation`.
- Seuls les apps et les packages de feature dépendent de Stacked ; `foundation` et `domain` sont
  en Dart pur.
- Un package n'est créé que s'il est générique, partagé par au moins deux apps ou s'il trace une
  frontière nette (`docs/architecture/PACKAGES.md`). Sinon, le code vit dans l'app, par feature.

### VII. Qualité vérifiable

- Une spec est terminée seulement si : pgTAP passe sur une branche Neon dédiée ; `melos run analyze`
  et `melos run test` passent ; au moins un test d'intégration couvre le parcours nominal ; une démo
  sur un Android d'entrée de gamme a eu lieu.
- Les tests d'une règle métier sont écrits avant ou avec la règle, jamais après la livraison.
- Aucune donnée fictive dans un flux de production ; aucun repli silencieux vers une valeur inventée.
- Une nouvelle tentative réseau n'a lieu que sur erreur réseau ou 5xx, jamais sur 4xx.

### VIII. Conçu pour le terrain

- Cible de référence : Android 11, 2 Go de RAM, réseau 3G instable, plein soleil.
- Chaque écran DOIT gérer les états vide, chargement, erreur et hors ligne.
- Contraste AA minimum, cibles tactiles ≥ 48 dp, icône + libellé sur chaque action principale.
- Toute création (commande, paiement) porte une clé d'idempotence.
- Les animations sont légères, interruptibles et désactivables.

### IX. Mesurer et tracer

- Les événements de `docs/product/METRICS.md` DOIVENT être émis par toute spec qui touche le
  parcours concerné ; les événements métier critiques sont émis côté serveur.
- Aucune donnée personnelle dans les propriétés d'événement.
- Les erreurs des apps et des Functions sont remontées à un outil de suivi d'erreurs.

## Stack et contraintes techniques

| Domaine | Choix |
|---|---|
| SDK | Flutter **3.47.5** (Dart 3.13) via **FVM**, épinglé dans `.fvmrc` ; aucune commande `flutter` hors `fvm` |
| Monorepo | Pub workspaces + **Melos** (configuration dans le `pubspec.yaml` racine) |
| Architecture app | Stacked, freezed, json_serializable |
| Backend | Neon : Postgres, Auth (Better Auth managé), Data API, Object Storage, Functions (Node 24, TypeScript) |
| Paiement | Interface `PaymentProvider` : `cash`, `moneroo`, `chariow` (offres numériques DYM) |
| IA | AI SDK (`ai` + `@ai-sdk/openai`) dans les Functions ; modèles configurés en base |
| Push | FCM |
| Hébergement annexe | Coolify (admin web, site léger) |
| Région | Neon Francfort |

Changer un élément de ce tableau exige une décision dans `docs/architecture/decisions/`.

## Flux de développement

- Spec Kit : `/speckit-specify` → `/speckit-clarify` → `/speckit-plan` → `/speckit-tasks` →
  `/speckit-analyze` → `/speckit-implement`. Pas de code produit hors spec.
- Modèle de branches :
  - `main` : production. Ne reçoit que des fusions depuis `dev` (release) ou `hotfix/<slug>`.
  - `dev` : intégration. Cible de toutes les pull requests de travail.
  - `feat/NNN-<slug>` : une branche par spec, créée depuis `dev` par l'extension git de Spec Kit
    (préfixe `feat`). Le numéro en tête du dernier segment est exigé par Spec Kit.
  - `feat/<slug>` : travail hors spec (design, documentation), créé depuis `dev`.
  - `hotfix/<slug>` : correctif urgent créé depuis `main`, fusionné dans `main` puis dans `dev`.
- Aucun commit direct sur `main` ni sur `dev` : tout passe par une pull request.
- Commits conventionnels (`feat:`, `fix:`, `docs:`, `chore:`, `test:`, `refactor:`).
- Relecture humaine obligatoire avant fusion pour : migrations, RLS, authentification, argent,
  transitions de statut, webhooks.
- La CI exécute l'analyse, les tests Dart, pgTAP et la vérification des migrations sur une branche
  Neon éphémère.

## Governance

- Cette constitution prévaut sur toute autre pratique ou document du dépôt.
- Amendement : proposition écrite, décision consignée dans `docs/architecture/decisions/` si elle
  touche l'architecture, mise à jour de ce fichier et de sa version.
- Versionnement sémantique : MAJEUR pour une suppression ou une redéfinition de principe ;
  MINEUR pour un principe ou une section ajoutés ; CORRECTIF pour une clarification.
- Chaque plan (`/speckit-plan`) vérifie sa conformité dans sa section « Constitution Check » ;
  toute dérogation est justifiée dans la section « Complexity Tracking ».
- Guide opérationnel pour les agents : `AGENTS.md`.

**Version**: 1.1.0 | **Ratified**: 2026-10-01 | **Last Amended**: 2026-10-01
