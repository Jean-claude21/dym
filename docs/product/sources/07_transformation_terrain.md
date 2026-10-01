# DYM — Transformation Terrain Réelle

> **Question préliminaire à toute lecture de ce document :**
> *"As-tu rencontré en personne quelqu'un qui a le problème décrit ici ?"*
>
> Si oui — ce document ancre et formalise ce que tu as observé.
> Si non — les personas ci-dessous sont des hypothèses de travail, pas des preuves. La première action terrain est de les vérifier ou corriger avec des personnes réelles.

---

## Ce que le document fait

Ce document décrit la **transformation mesurable** que DYM doit produire dans la vie de vraies personnes.

Pas les fonctionnalités. Pas l'architecture. Pas le pitch.

**L'avant exact. L'après exact. Et la fréquence à laquelle ça se passe.**

La règle : si la transformation ne se produit pas au moins une fois par semaine dans la vie de la personne concernée, elle n'est pas assez réelle pour être une priorité V1.

---

## Fatou — La Vendeuse

> **Note de terrain :** Ce profil est une hypothèse construite à partir d'observations du commerce informel urbain en Afrique de l'Ouest. Il doit être validé avec au moins 3 vendeuses réelles avant la fin du pilote. S'il est inexact, corriger ce document.

**Qui :** Fatou, vendeuse de tissu depuis 8 ans, Lomé. Tenu de commerce informel — pas d'RCCM, pas de terminal de paiement, pas de site web. Son téléphone est son bureau.

---

### AVANT — Ce qui se passe en ce moment

**Commandes reçues par DM WhatsApp** (fréquence : 5 à 30 fois par jour).
- Elle reçoit : "Bonjour chérie tu as le tissu wax bleu ?"
- Elle répond, cherche dans son stock, négocie, confirme.
- Elle envoie son numéro MoMo.
- Le client envoie une capture d'écran. Elle ne sait pas si c'est vrai.
- Elle livre ou fait livrer. Parfois la capture était fausse.

**Pertes typiques :**
- 2 à 5 commandes perdues par semaine parce qu'une conversation s'est "noyée" dans les DMs.
- 1 à 3 incidents de fausse capture par mois.
- 0 historique de ventes. Elle ne sait pas ce qu'elle a vendu la semaine dernière.
- 0 mémoire client. Si la même cliente revient 6 mois plus tard, elle repart de zéro.

**Ce qu'elle dit (ou dirait si tu lui posais la question) :**
> "Je perds des clientes parce que je réponds pas assez vite. Et parfois j'envoie la marchandise et le paiement arrive pas."

---

### APRÈS — Ce que DYM produit

**Chaque commande arrive structurée** — produit, quantité, adresse, mode de paiement explicite (cash à la livraison ou MoMo), et statut d'encaissement clair. Pour MoMo : confirmation webhook automatique. Pour cash : confirmation à la livraison.

**Elle met à jour le statut en 2 taps** — "en préparation", "livré". La cliente voit ça en temps réel.

**Elle ne perd plus de commandes** parce que tout est dans l'app, pas dans ses DMs.

---

### Mesure de la transformation

| Avant | Après | Mesure |
|---|---|---|
| 2 à 5 commandes perdues / semaine | 0 commande perdue (pas de DM) | Nombre de commandes sans suivi |
| 1 à 3 fausses captures / mois | 0 fraude (paiement vérifié auto) | Incidents de fraude MoMo |
| Encaissements cash notés de façon informelle | Encaissements cash tracés par commande | Taux de commandes cash avec statut d'encaissement |
| 0 historique | Historique complet en app | Disponibilité de l'historique |
| 30 min de DMs / commande | 3 min de traitement en app | Temps de traitement |

**Fréquence :** à chaque commande. Minimum 1 fois par jour pour une vendeuse active.

---

## Awa — La Cliente

> **Note de terrain :** Même prudence. Valider avec 3 vraies clientes avant la fin du pilote.

**Qui :** Awa, 28 ans, salariée à Lomé. Elle achète régulièrement des tissus, des petits plats cuisinés, et de l'artisanat en tant que cadeaux. Elle découvre des vendeurs sur TikTok, Instagram, et les stories WhatsApp. Elle passe ses commandes par DM.

---

### AVANT — Ce qui se passe en ce moment

**Processus d'une commande (fréquence : 2 à 4 fois par mois)** :
- Elle voit un produit sur TikTok ou Instagram.
- Elle cherche le contact de la vendeuse dans les commentaires.
- Elle envoie un DM : "Combien pour le wax rouge ? Tu livres ?"
- Elle attend. Parfois quelques heures, parfois 2 jours.
- Elle envoie son argent MoMo sur un numéro reçu par DM.
- Elle paie parfois en cash à la livraison, mais sans preuve structurée de ce qui a été convenu.
- Elle attend la livraison. Aucun suivi.
- Si quelque chose va mal (pas livré, mauvaise taille) : elle envoie un DM. Parfois ça marche, parfois elle abandonne.

**Ce qu'elle dit :**
> "C'est compliqué de commander. Des fois j'abandonne si la vendeuse répond pas vite. Et je sais jamais si mon argent est safe."

---

### APRÈS — Ce que DYM produit

**Elle commande directement depuis l'app** sans DM préliminaire. Le prix, la disponibilité, la livraison — tout est dans la fiche produit.

**Elle choisit son mode de paiement** selon son habitude : cash à la livraison (le plus fréquent) ou MoMo depuis l'app.

**Si elle choisit MoMo** — confirmation instantanée, plus d'inquiétude sur les arnaques.

**Si elle choisit cash** — le mode est clair dès la commande, et l'encaissement est confirmé à la livraison.

**Elle sait exactement où est sa commande** sans envoyer un DM à la vendeuse.

**Elle peut commander plusieurs boutiques** (tissu ici, plat là) en un seul panier.

---

### Mesure de la transformation

| Avant | Après | Mesure |
|---|---|---|
| 1 à 3 jours entre décision et paiement | Moins de 10 minutes | Délai décision → paiement confirmé |
| Aucun suivi possible | Statuts notifiés en temps réel | Nombre de DMs envoyés pour demander où est la commande |
| Commandes abandonnées par friction | Taux de complétion | Paniers commencés vs payés |
| Confiance fragile dans le paiement MoMo | Confiance totale (webhook automatique) | Incidents de fraude déclarés |
| Flou sur les commandes cash | Commandes cash explicites et tracées | Taux de litiges sur paiement cash |

**Fréquence :** 2 à 4 fois par mois. Pour être une vraie transformation, Awa doit refaire le chemin par DYM — pas revenir aux DMs pour la prochaine commande.

---

## L'équipe DYM — L'opérateur

**Qui :** La personne (ou les 2 personnes) qui gèrent les incidents terrain pendant le pilote.

### AVANT — Sans DYM

Quand un incident survient (commande bloquée, paiement non confirmé, vendeur qui n'a pas vu la commande) :
- Il faut appeler le vendeur, appeler le client.
- Si la DB est incohérente : appeler un développeur.
- Résolution : entre 2h et 2 jours.
- Aucun historique des incidents.

### APRÈS — Avec DYM V1

Un incident se gère depuis Supabase Studio ou un script fourni :
- Voir la commande, voir son statut, comprendre le blocage.
- Corriger le statut manuellement si nécessaire.
- Déclencher un remboursement si le paiement est confirmé mais la livraison échoue.
- Temps cible : résolution en moins d'1 heure, sans appel développeur.

**Fréquence :** 1 à 5 incidents par semaine pendant le pilote. Si c'est plus — le produit a un problème de fiabilité à corriger en priorité.

---

## La question à poser avant de démarrer le pilote

Ces transformations sont les hypothèses actuelles. Avant de lancer les 30 premiers vendeurs :

1. **Rencontrer 3 vendeuses** dans la ville cible. Leur demander de décrire leur semaine de travail. Écouter, noter exactement. Corriger le profil Fatou si nécessaire.

2. **Rencontrer 3 clientes**. Leur demander la dernière fois qu'elles ont commandé à une boutique en ligne ou via DM. Écouter le friction. Corriger le profil Awa si nécessaire.

3. **La règle de validation** : si les profils ci-dessus sont à plus de 30% faux après les entretiens — arrêter le développement et corriger d'abord les profils. Le produit doit servir les personnes réelles, pas les hypothèses.

---

*Transformation Terrain Réelle — DYM — Mai 2026*
