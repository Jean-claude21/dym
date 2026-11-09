# 0014 — Admins par défaut, connexion admin par code email, pays ouverts

**Statut :** acceptée (porteur produit, 2026-11-05). Remplace la partie admin de la décision 0007.

## Contexte

La décision 0007 réservait l'admin aux comptes Google Workspace, avec un premier admin accordé à la
main (`dym-db grant-admin`). Le porteur produit veut que l'équipe crée elle-même son compte, et que
les apps fonctionnent partout, sans pays figé.

## Décision

1. **Admins par défaut.** La variable `ADMIN_EMAILS` (emails séparés par des virgules) est
   synchronisée en base par `ADMIN_EMAILS=… node db/scripts/dym-db.mjs admins --url …`
   (table `admin_invites`, source `env`). Un compte dont l'email **vérifié** y figure reçoit le rôle
   admin à sa connexion à DYM Admin (`record_sign_in('admin')` → `app.claim_admin_invite`), audité.
2. **Invitations.** Un admin invite d'autres emails depuis Réglages → Admins
   (`admin_invite_admin`) et retire un accès (`admin_remove_admin`). Interdit : retirer un admin
   par défaut (à retirer de `ADMIN_EMAILS`), se retirer soi-même, retirer le dernier admin.
3. **Connexion admin par code email** (Google reste possible quand il est configuré).
4. **Pays ouverts.** Togo, Ghana et France sont actifs (migration 0026). À l'inscription, la
   position détecte le quartier le plus proche parmi tous les pays actifs (`nearest_zone`) et fixe
   le pays ; sans position, la personne choisit.

## Conséquences

- Risque : sans Google Workspace, plus de double authentification imposée. Le code email reste un
  facteur unique ; déconnexion après inactivité et audit inchangés. À revoir avant la production
  (MFA Neon).
- Données de démonstration : `db/scripts/seed-demo.mjs` (staging ou branche de test seulement).
