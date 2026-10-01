# DYM — Features App Delivery

> **Version :** 1.0 — Mai 2026  
> **Surface :** App mobile Flutter (dym_delivery)  
> **Lecteur cible :** PM, Développeur, QA

---

## Décision stratégique V1

> ⚠️ **L'app de livraison n'est PAS déployée en V1.**
>
> La livraison V1 est gérée de deux façons :
> 1. **Livraison propre du vendeur** : le vendeur livre lui-même et met à jour le statut manuellement.
> 2. **Partenaires externes** : DYM utilise des coursiers locaux ou GOZEM Express comme fallback.
>
> **L'app dym_delivery est implémentée en V2**, une fois que le volume de commandes justifie un réseau de livreurs propre.  
> Les features ci-dessous définissent ce que l'app fera quand elle sera déployée.

---

## Légende priorité

| Label | Signification |
|---|---|
| 🔴 P0 | Core — sans ça, le livreur ne peut pas opérer |
| 🟠 P1 | Important — valeur terrain forte |
| 🟡 P2 | Nice-to-have |
| ⚫ OUT | Hors scope définitif |

---

## Module 1 — Authentification & Onboarding Livreur

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| L-AUTH-01 | Inscription par téléphone + OTP | 🔴 P0 | |
| L-AUTH-02 | Connexion par téléphone + OTP | 🔴 P0 | |
| L-AUTH-03 | Déclaration véhicule (moto, vélo, voiture, tricycle) | 🔴 P0 | |
| L-AUTH-04 | Upload documents (CNI, photo véhicule) | 🔴 P0 | |
| L-AUTH-05 | Validation compte par admin DYM | 🔴 P0 | Approbation manuelle avant activation |
| L-AUTH-06 | Statut "En attente de validation" avec feedback | 🔴 P0 | |

---

## Module 2 — Disponibilité et Flux Missions

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| L-AVAIL-01 | Bouton disponible / indisponible | 🔴 P0 | Simple bascule |
| L-AVAIL-02 | Notification mission disponible (push) | 🔴 P0 | |
| L-AVAIL-03 | Liste des missions disponibles dans sa zone | 🔴 P0 | |
| L-AVAIL-04 | Détail mission avant acceptation (pickup, drop, distance, gain estimé) | 🔴 P0 | |
| L-AVAIL-05 | Accepter / refuser une mission | 🔴 P0 | |
| L-AVAIL-06 | Délai d'acceptation (30s timeout → mission réattribuée) | 🔴 P0 | |
| L-AVAIL-07 | Voir la mission acceptée (récapitulatif) | 🔴 P0 | |
| L-AVAIL-08 | Heatmap zones actives | 🟡 P2 | |

---

## Module 3 — Exécution Livraison

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| L-DEL-01 | Navigation vers pickup (vendor) | 🔴 P0 | Via Google Maps / OpenStreetMap |
| L-DEL-02 | Confirmation récupération colis | 🔴 P0 | Code ou photo colis |
| L-DEL-03 | Navigation vers drop (client) | 🔴 P0 | |
| L-DEL-04 | Confirmation livraison au client | 🔴 P0 | Code client ou photo remise |
| L-DEL-05 | Mission complétée avec gain enregistré | 🔴 P0 | |
| L-DEL-06 | Appel ou message au client depuis l'app | 🔴 P0 | Numéro masqué |
| L-DEL-07 | Appel ou message au vendeur depuis l'app | 🔴 P0 | Numéro masqué |
| L-DEL-08 | Partage position en temps réel avec client | 🟠 P1 | Tracking côté client |
| L-DEL-09 | ETA dynamique recalculé | 🟠 P1 | |

---

## Module 4 — Gestion des Incidents

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| L-INC-01 | Signaler un incident (client absent, adresse incorrecte, accident) | 🔴 P0 | |
| L-INC-02 | Photos d'incident (preuve) | 🔴 P0 | |
| L-INC-03 | Contact support DYM depuis l'app | 🔴 P0 | |
| L-INC-04 | Replanifier une livraison (si client absent) | 🟠 P1 | |
| L-INC-05 | Retourner un colis non livré au vendeur | 🟠 P1 | |

---

## Module 5 — Historique et Gains

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| L-EARN-01 | Gains du jour | 🔴 P0 | |
| L-EARN-02 | Gains de la semaine | 🔴 P0 | |
| L-EARN-03 | Historique des missions (livrées, annulées, incidents) | 🔴 P0 | |
| L-EARN-04 | Solde wallet livreur | 🟠 P1 | |
| L-EARN-05 | Retrait gains vers MoMo | 🟠 P1 | |
| L-EARN-06 | Bonus de performance (X missions → bonus) | 🟡 P2 | |
| L-EARN-07 | Simulation gains | 🟡 P2 | "Si tu fais X missions demain..." |

---

## Module 6 — Notation et Réputation

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| L-RAT-01 | Note moyenne visible dans le profil | 🔴 P0 | |
| L-RAT-02 | Reçu une note + commentaire après livraison | 🔴 P0 | Du client |
| L-RAT-03 | Voir son historique de notes | 🟠 P1 | |
| L-RAT-04 | Seuil minimal de note pour rester actif | 🔴 P0 | < 3.0 → suspension automatique |

---

## Module 7 — Statistiques

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| L-STATS-01 | Missions du jour / semaine / mois | 🔴 P0 | |
| L-STATS-02 | Taux d'acceptation (missions proposées vs acceptées) | 🟠 P1 | |
| L-STATS-03 | Distance totale parcourue | 🟡 P2 | |
| L-STATS-04 | Temps actif cumulé | 🟡 P2 | |
| L-STATS-05 | Optimisation route multi-missions | 🟡 P2 | Batching de livraisons |

---

## Module 8 — Profil Livreur

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| L-PROF-01 | Voir et modifier son profil (photo, téléphone) | 🔴 P0 | |
| L-PROF-02 | Gérer ses documents (renouvellement CNI) | 🟠 P1 | |
| L-PROF-03 | Modifier le type de véhicule | 🟠 P1 | |
| L-PROF-04 | Support / FAQ livreur | 🔴 P0 | |
| L-PROF-05 | Déconnexion | 🔴 P0 | |
| L-PROF-06 | Paramètres notifications | 🔴 P0 | |

---

## Module 9 — Notifications

| ID | Feature | Priorité | Notes |
|---|---|---|---|
| L-NOTIF-01 | Nouvelle mission disponible | 🔴 P0 | Son + vibration fort |
| L-NOTIF-02 | Mission expirée (tu n'as pas répondu à temps) | 🔴 P0 | |
| L-NOTIF-03 | Message du client ou du vendeur | 🔴 P0 | |
| L-NOTIF-04 | Confirmation gain enregistré | 🔴 P0 | |
| L-NOTIF-05 | Avertissement note basse | 🔴 P0 | |
| L-NOTIF-06 | Bonus débloqué | 🟠 P1 | |

---

## Résumé des priorités

| Priorité | Nb features |
|---|---|
| 🔴 P0 | ~30 features |
| 🟠 P1 | ~13 features |
| 🟡 P2 | ~9 features |
| ⚫ OUT | 0 |

---

## Routes Flutter associées (dym_delivery)

Routes P0 (activées en V2) :
- `startupView`, `welcomeView`, `loginView`, `registerView`
- `authFlowWrapper`, `deliveryOnboardingView`
- `vehicleView`, `documentsView`, `approvalPendingView`
- `shellView`, `homeView`
- `courseListView`, `courseDetailView`
- `deliveriesListView`, `deliveryDetailView`
- `activeDeliveryView`, `deliveryNavigationView`
- `deliveryTrackingView`
- `earningsView`
- `profileView`, `editProfileView`
- `notificationsView`
- `helpView`
- `ratingsView`

Routes P1 :
- `deliveryHistoryView`
- `statsView`
- `walletView`, `paymentHistoryView`
- `chatListView`, `chatDetailView`
- `profileVehicleView`, `profileDocumentsView`
- `reportIssueView`
- `settingsView`

---

## Plan de déploiement progressif

### Phase Pré-V2 (V1 — sans app livreur)

```
Vendeur livre lui-même
    → Statut mis à jour manuellement dans app vendor
    
OU

DYM utilise livreurs partenaires externes
    → Commandes assignées manuellement via admin web
    → Client notifié par SMS/push quand livreur parti
```

### Phase V2 (avec app livreur)

```
Livreur DYM s'inscrit et est validé
    → Pool de livreurs actifs disponibles
    → Missions auto-assignées par proximité
    → Tracking temps réel activé
    → Gains tracés automatiquement
```

### KPIs de déclenchement V2
- > 50 commandes/jour nécessitant une livraison.
- Au moins 1 zone avec > 10 vendeurs actifs.
- Taux de livraison réussie vendeur propre < 85%.

---

*Document Features App Delivery DYM — Mai 2026*
