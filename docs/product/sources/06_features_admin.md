# DYM — Features Admin Web

> **Version :** 1.0 — Mai 2026  
> **Surface :** Web Dashboard Desktop (navigateur, interne équipe DYM)  
> **Tech cible :** Flutter Web ou Next.js/React (décision à prendre en Phase 2)  
> **Utilisateurs :** Équipe DYM (ops, support, management) — 2 à 10 personnes

---

## Principes de l'Admin Web

1. **Operational, pas décoratif.** Chaque page doit permettre d'agir, pas juste de voir.
2. **Pas de dev requis pour gérer un incident.** L'équipe ops doit pouvoir résoudre 90% des problèmes sans intervention technique.
3. **Temps réel sur ce qui compte.** Commandes actives, paiements en attente, incidents ouverts.
4. **Impersonation sécurisée.** Admin peut voir ce que voit un vendeur ou un client pour le support.
5. **Audit trail.** Chaque action admin est loggée (qui, quoi, quand).

---

## Légende priorité

| Label | Signification |
|---|---|
| 🔴 P0 | Nécessaire dès Phase 2 (première cohorte vendeurs) |
| 🟠 P1 | Nécessaire avant scale (pilote → 300 users) |
| 🟡 P2 | Croissance et optimisation |
| ⚫ OUT | Non prévu |

---

## Module 1 — Authentification Admin

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| A-AUTH-01 | Connexion sécurisée (email + mot de passe fort) | 🔴 P0 | |
| A-AUTH-02 | 2FA obligatoire (TOTP/SMS) | 🔴 P0 | Sécurité critique |
| A-AUTH-03 | Gestion des rôles admin (superadmin, ops, support, readonly) | 🟠 P1 | |
| A-AUTH-04 | Log des connexions admin | 🔴 P0 | |
| A-AUTH-05 | Déconnexion automatique (inactivité 30 min) | 🔴 P0 | |

---

## Module 2 — Dashboard Plateforme (Vue d'Ensemble)

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| A-DASH-01 | Commandes actives en cours (temps réel) | 🔴 P0 | |
| A-DASH-02 | CA total du jour / semaine / mois | 🔴 P0 | |
| A-DASH-03 | Nombre d'utilisateurs actifs (clients, vendeurs, livreurs) | 🔴 P0 | |
| A-DASH-04 | Incidents ouverts | 🔴 P0 | |
| A-DASH-05 | Litiges en attente de traitement | 🔴 P0 | |
| A-DASH-06 | Taux de succès paiements (dernier 1h / 24h) | 🔴 P0 | Alerting si <90% |
| A-DASH-07 | Taux de livraisons réussies | 🟠 P1 | |
| A-DASH-08 | Nouvelles inscriptions (vendeurs en attente de validation) | 🔴 P0 | |
| A-DASH-09 | Graphiques temps réel (commandes/heure, revenus) | 🟠 P1 | |
| A-DASH-10 | Alertes automatiques (anomalies seuil dépassé) | 🟠 P1 | |

---

## Module 3 — Gestion des Vendeurs

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| A-VEN-01 | Liste de tous les vendeurs (filtre: actif, en attente, suspendu) | 🔴 P0 | |
| A-VEN-02 | Profil vendeur complet (boutique, produits, commandes, avis, revenus) | 🔴 P0 | |
| A-VEN-03 | Activer un compte vendeur | 🔴 P0 | |
| A-VEN-04 | Suspendre un compte vendeur (avec raison) | 🔴 P0 | |
| A-VEN-05 | Réactiver un compte suspendu | 🔴 P0 | |
| A-VEN-06 | Supprimer un compte vendeur | 🔴 P0 | |
| A-VEN-07 | Mode impersonation vendeur (voir son app) | 🔴 P0 | Audit trail obligatoire |
| A-VEN-08 | Modifier manuellement les données d'une boutique | 🔴 P0 | Ex: corriger une adresse |
| A-VEN-09 | Historique des actions admin sur ce vendeur | 🔴 P0 | |
| A-VEN-10 | Envoyer une notification ciblée à un vendeur | 🟠 P1 | |
| A-VEN-11 | Valider les documents d'identité vendeur | 🟠 P1 | |
| A-VEN-12 | Exporter la liste des vendeurs (CSV) | 🟡 P2 | |

---

## Module 4 — Gestion des Clients

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| A-CLI-01 | Liste de tous les clients | 🟠 P1 | |
| A-CLI-02 | Profil client (commandes, adresses, avis, litiges) | 🔴 P0 | Pour support |
| A-CLI-03 | Mode impersonation client (voir son app) | 🟠 P1 | |
| A-CLI-04 | Suspendre un compte client abusif | 🟠 P1 | |
| A-CLI-05 | Historique des actions admin sur ce client | 🟠 P1 | |
| A-CLI-06 | Envoyer notification ciblée à un client | 🟠 P1 | |

---

## Module 5 — Gestion des Livreurs

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| A-LIV-01 | Liste livreurs (actif, en mission, indisponible, suspendu) | 🟠 P1 | Actif en V2 avec app livreur |
| A-LIV-02 | Profil livreur (missions, gains, note, documents) | 🟠 P1 | |
| A-LIV-03 | Valider inscription livreur (documents OK) | 🔴 P0 | Phase 1 manuelle |
| A-LIV-04 | Assigner une livraison manuellement | 🔴 P0 | Phase 1 sans app livreur |
| A-LIV-05 | Suspendre un livreur | 🟠 P1 | |
| A-LIV-06 | Voir la position temps réel des livreurs actifs (carte) | 🟡 P2 | |
| A-LIV-07 | Exporter historique gains livreur | 🟡 P2 | |

---

## Module 6 — Gestion des Commandes

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| A-ORD-01 | Liste toutes les commandes (filtre statut, date, vendeur, client) | 🔴 P0 | |
| A-ORD-02 | Détail complet d'une commande | 🔴 P0 | |
| A-ORD-03 | Forcer un changement de statut | 🔴 P0 | Cas de blocage |
| A-ORD-04 | Annuler une commande (avec raison + remboursement) | 🔴 P0 | |
| A-ORD-05 | Replay de l'historique d'une commande (timeline complète) | 🔴 P0 | Pour comprendre un incident |
| A-ORD-06 | Recherche commande par ID, client, vendeur | 🔴 P0 | |
| A-ORD-07 | Export commandes (CSV, PDF) | 🟠 P1 | |
| A-ORD-08 | Assigner manuellement une livraison externe | 🔴 P0 | Phase 1 |

---

## Module 7 — Gestion des Litiges

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| A-LIT-01 | Liste des litiges ouverts | 🔴 P0 | |
| A-LIT-02 | Détail litige (conversation, commande, preuves, timeline) | 🔴 P0 | |
| A-LIT-03 | Décision admin (fermer, rembourser partiel, rembourser total) | 🔴 P0 | |
| A-LIT-04 | Exécuter un remboursement | 🔴 P0 | Via API paiement |
| A-LIT-05 | Avertir un vendeur (escalade réputation) | 🔴 P0 | |
| A-LIT-06 | Clore un litige avec note interne | 🔴 P0 | |
| A-LIT-07 | SLA tracking (litiges non traités > 48h) | 🟠 P1 | |
| A-LIT-08 | Historique des litiges d'un vendeur | 🟠 P1 | |

---

## Module 8 — Finances & Commissions

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| A-FIN-01 | Vue des revenus plateforme (commissions prélevées) | 🔴 P0 | |
| A-FIN-02 | Détail par vendeur (CA vendeur, commission DYM, net vendeur) | 🔴 P0 | |
| A-FIN-03 | Paiements en attente de traitement | 🔴 P0 | |
| A-FIN-04 | Remboursements effectués | 🔴 P0 | |
| A-FIN-05 | Déclencher un paiement vendeur (virement wallet → MoMo) | 🟠 P1 | |
| A-FIN-06 | Export comptable (CSV, intégration Excel) | 🟠 P1 | |
| A-FIN-07 | Réconciliation paiements MoMo | 🟠 P1 | |
| A-FIN-08 | Dashboard financier global (P&L simplifié) | 🟡 P2 | |

---

## Module 9 — Monitoring IA

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| A-AI-01 | Taux de compréhension des requêtes IA (succès vs échec) | 🔴 P0 | |
| A-AI-02 | Latence moyenne des requêtes IA | 🔴 P0 | |
| A-AI-03 | Requêtes avec handoff humain (IA a dit "je ne sais pas") | 🔴 P0 | |
| A-AI-04 | Top requêtes non comprises (amélioration IA) | 🟠 P1 | |
| A-AI-05 | Conversations IA les plus longues / abandonnées | 🟠 P1 | |
| A-AI-06 | Test IA en sandbox (tester l'intent engine directement) | 🟠 P1 | |
| A-AI-07 | Configuration prompts IA (sans redéploiement) | 🟡 P2 | |

---

## Module 10 — Modération de Contenu

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| A-MOD-01 | File de modération (produits signalés, avis signalés, contenus signalés) | 🔴 P0 | |
| A-MOD-02 | Approuver / rejeter un contenu signalé | 🔴 P0 | |
| A-MOD-03 | Supprimer un produit en violation | 🔴 P0 | |
| A-MOD-04 | Supprimer un avis abusif | 🔴 P0 | |
| A-MOD-05 | Supprimer une vidéo / story en violation | 🔴 P0 | |
| A-MOD-06 | Modération automatique IA (pré-filtre) | 🟡 P2 | |
| A-MOD-07 | Règles de modération configurables | 🟡 P2 | |

---

## Module 11 — Configuration Plateforme

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| A-CFG-01 | Gestion des pays actifs | 🔴 P0 | |
| A-CFG-02 | Gestion des devises par pays | 🔴 P0 | |
| A-CFG-03 | Gestion des opérateurs MoMo actifs par pays | 🔴 P0 | |
| A-CFG-04 | Configuration taux de commission (%) | 🔴 P0 | |
| A-CFG-05 | Configuration des frais de livraison par défaut | 🔴 P0 | |
| A-CFG-06 | Gestion des catégories générales (marketplace) | 🔴 P0 | |
| A-CFG-07 | Feature flags (activer/désactiver une feature sans déploiement) | 🟠 P1 | Critique pour contrôle prod |
| A-CFG-08 | Messages système (maintenance, alertes globales) | 🟠 P1 | |
| A-CFG-09 | Configuration notifications push globales | 🟠 P1 | |
| A-CFG-10 | Gestion des promotions globales (DYM Days) | 🟡 P2 | |

---

## Module 12 — Support Client / Vendeur

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| A-SUP-01 | Liste des tickets de support ouverts | 🔴 P0 | |
| A-SUP-02 | Répondre à un ticket depuis l'admin | 🔴 P0 | |
| A-SUP-03 | Fermer un ticket | 🔴 P0 | |
| A-SUP-04 | Voir la conversation in-app du client avec l'IA | 🔴 P0 | |
| A-SUP-05 | Envoyer un message direct (push / in-app) à un user | 🟠 P1 | |
| A-SUP-06 | FAQ admin (réponses types) | 🟠 P1 | |
| A-SUP-07 | Intégration ticketing externe (Freshdesk, Zendesk) | 🟡 P2 | |

---

## Module 13 — Analytics & Reporting

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| A-ANA-01 | Évolution commandes/revenus (graphiques 30/90 jours) | 🟠 P1 | |
| A-ANA-02 | Top vendeurs (CA, commandes, note) | 🟠 P1 | |
| A-ANA-03 | Top catégories et produits | 🟠 P1 | |
| A-ANA-04 | Rétention clients (cohortes, réachat) | 🟡 P2 | |
| A-ANA-05 | Funnel conversion (session → panier → paiement) | 🟡 P2 | |
| A-ANA-06 | Géographique (zones les plus actives sur carte) | 🟡 P2 | |
| A-ANA-07 | Rapport hebdomadaire automatique par email | 🟡 P2 | |

---

## Module 14 — Logs & Audit

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| A-LOG-01 | Log de toutes les actions admin (qui, quoi, quand) | 🔴 P0 | |
| A-LOG-02 | Recherche dans les logs | 🔴 P0 | |
| A-LOG-03 | Logs des appels API MoMo (succès, échecs, réponses) | 🔴 P0 | |
| A-LOG-04 | Logs des erreurs plateforme | 🟠 P1 | |
| A-LOG-05 | Export des logs | 🟡 P2 | |

---

## Résumé des priorités

| Priorité | Nb features |
|---|---|
| 🔴 P0 | ~52 features |
| 🟠 P1 | ~32 features |
| 🟡 P2 | ~17 features |
| ⚫ OUT | 0 |

---

## Choix technique (décision à valider)

### Option A — Flutter Web
- Avantage : même codebase, composants partagés.
- Inconvénient : web admin avec Flutter est verbeux, moins d'outillage admin prêt.
- Recommandation : Seulement si l'équipe est 100% Flutter.

### Option B — Next.js + shadcn/ui (React)
- Avantage : Rapidité de développement admin, bibliothèques admin riches.
- Inconvénient : Stack séparée, JS/TS vs Dart.
- Recommandation : **Préféré** pour l'admin web — indépendance du cycle de release mobile.

### Option C — Supabase Studio + customisations légères
- Avantage : Quasi gratuit en termes de dev pour Phase 1.
- Inconvénient : Pas personnalisable, expérience non-dev dégradée.
- Recommandation : **Acceptable pour Phase 1** (interne, petit volume). À remplacer en Phase 2.

---

## Sécurité Admin Web (non négociable)

- HTTPS obligatoire.
- 2FA obligatoire pour tous les comptes admin.
- Sessions expirées après 30 minutes d'inactivité.
- Chaque action admin loggée avec IP, timestamp, userId, détail.
- Aucune donnée sensible visible en clair sans besoin explicite (ex: numéros de carte masqués).
- Accès par rôle (pas de "super admin" généralisé pour tout le monde).

---

*Document Features Admin Web DYM — Mai 2026*
