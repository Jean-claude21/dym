# 0021 — Secrets centralisés dans Doppler

**Statut** : Acceptée (2026-11-14)

## Contexte

Les secrets de DYM (variables des Functions, clés Sentry des apps, fichiers Firebase, jetons
d'outillage) vivaient dans des fichiers hors dépôt sur un seul PC, et les clés de signature Android
n'existaient pas encore. Le porteur veut tout centraliser et sauvegarder (2026-11-14).

## Décision

- Doppler (espace du porteur) est la référence des secrets, en trois projets :
  - `dym-functions` (`stg`, `prd`) : variables des Neon Functions ;
  - `dym-apps` (`stg`, `prd`) : DSN Sentry des apps, `google-services.json`, clés de signature
    Android (« upload key », PKCS12, RSA 4096, 10 000 jours) et leurs mots de passe, en base64 ;
  - `dym-outils` : jetons Neon, Sentry, LiveKit, Moneroo, BrowserStack, Coolify, Agent37, OAuth.
- Les clés personnelles du porteur (jetons d'admin des services : OpenAI, Neon, Sentry,
  Cloudflare, Resend…) vivent une seule fois dans le projet `cles-perso` (config `prd`), partagé
  par tous ses projets et tous ses PC. Les projets DYM y pointent par référence
  (`${cles-perso.prd.NOM}`) au lieu de copier la valeur : changer une clé se fait à un seul endroit.
  Seul `DOPPLER_TOKEN` reste hors de Doppler (il l'ouvre).
- `scripts/secrets.mjs` régénère les fichiers locaux depuis Doppler (jeton dans `DOPPLER_TOKEN`) ;
  aucune valeur n'est affichée ni écrite dans le dépôt. `perso prd <fichier>` réécrit le fichier
  des clés personnelles (`.secrets/.admin.env`) ; sur un PC sans le dépôt :
  `doppler login` puis `doppler secrets download --project cles-perso --config prd --no-file --format env`.
- Play Store : Google garde la clé de signature de l'app (Play App Signing) ; la clé d'envoi est
  dans Doppler, avec une copie chiffrée hors ligne chez le porteur.

## Conséquences

- Un nouveau poste ou une CI récupère tout avec un jeton Doppler.
- Un nouveau projet du porteur crée son propre projet Doppler et référence `cles-perso` pour
  les clés communes.
- Changer un secret se fait dans Doppler, puis on régénère les fichiers et on redéploie.
