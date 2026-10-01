# DYM — Personas & Use Cases

> **Version :** 1.0 — Mai 2026  
> **Objectif :** Définir précisément les utilisateurs réels et les scénarios d'usage qui guident chaque décision produit.

---

## 1. Personas

### Persona 1 — Awa, la cliente (25 ans, Cotonou)

**Situation**
- Salariée, 25 ans, Cotonou.
- Smartphone Android milieu de gamme.
- Sur TikTok et Instagram chaque jour.
- Paie avec MTN MoMo.
- Achète souvent auprès de vendeuses connues via DM.

**Frustrations actuelles**
- Elle voit un produit sur TikTok → doit envoyer un DM → attendre → négocier → payer manuellement → ne sait pas quand ça arrive.
- Elle veut parfois commander chez 2-3 vendeurs différents mais c'est 3 fois le même chaos.
- Elle ne sait pas si le vendeur est fiable avant d'avoir payé.

**Ce qu'elle veut**
- Voir les produits clairement avec les prix.
- Commander sans friction.
- Payer avec MTN MoMo en 2 taps.
- Savoir où est sa commande.
- Revenir facilement chez un vendeur qu'elle a aimé.

**Ce qu'elle ne veut pas**
- S'inscrire avec 5 étapes avant de voir quoi que ce soit.
- Un formulaire complexe pour commander.
- Envoyer une capture MoMo et attendre une validation manuelle.

---

### Persona 2 — Fatou, la vendeuse (34 ans, Lomé)

**Situation**
- Vend du tissu wax depuis son domicile et via un étalage au marché.
- Smartphone Android entrée de gamme (2 Go RAM, Android 11).
- Utilise WhatsApp Business depuis 2 ans pour ses commandes.
- A un profil Instagram avec 800 followers, poste irrégulièrement.
- Encaisse via T-Money et paiement en main propre.

**Frustrations actuelles**
- Gère 20-30 DMs par jour manuellement.
- Ne sait jamais précisément combien elle a vendu cette semaine.
- Des clients envoient de fausses captures MoMo.
- Elle perd des commandes dans le désordre des conversations.
- Elle ne peut pas relancer ses clientes fidèles facilement.

**Ce qu'elle veut**
- Recevoir des commandes déjà structurées (qui, quoi, combien, où livrer).
- Valider un paiement sans risque de fraude.
- Savoir ses ventes du jour en un coup d'œil.
- Relancer ses clientes régulières facilement.
- Mettre un produit en rupture en 1 geste.

**Ce qu'elle ne veut pas**
- Un dashboard complexe avec des graphiques qu'elle ne comprend pas.
- Saisir des informations dans plusieurs formulaires.
- Apprendre une nouvelle façon de travailler radicalement différente de WhatsApp.

---

### Persona 3 — Kofi, le livreur (22 ans, Lomé)

**Situation**
- Jeune, moto personnelle, cherche des revenus flexibles.
- Fait déjà des livraisons ponctuelles pour des connaissances.
- Smartphone correct, bonne maîtrise des apps.

**Frustrations actuelles**
- Pas de flux régulier de missions.
- Pas de traçabilité de ses gains.
- Litiges avec clients ou vendeurs sans arbitrage.

**Ce qu'il veut**
- Voir les missions disponibles près de lui.
- Accepter, naviguer, livrer, prouver, encaisser.
- Voir ses gains en temps réel.
- Un support si problème terrain.

---

### Persona 4 — L'équipe DYM (Admin Web)

**Situation**
- Petite équipe (2-5 personnes) qui supervise la plateforme.
- Besoin de visibilité temps réel sur la santé de la plateforme.
- Gestion des incidents, support vendeurs et clients, modération.

**Ce qu'elle veut**
- Vue d'ensemble plateforme en temps réel.
- Outils de support sans avoir à coder.
- Capacité d'intervention rapide sur un litige ou un incident.
- Données pour piloter la croissance.

---

## 2. Use Cases Client (Awa)

### UC-C01 — Découverte et exploration

**Déclencheur :** Awa ouvre DYM, elle ne cherche rien de précis.

**Flux :**
1. Elle voit le home avec des boutiques près d'elle et des produits tendances.
2. Elle scroll le feed de vidéos/stories shoppables.
3. Elle tape sur un produit qui l'intéresse.
4. Elle voit la fiche produit avec photos, prix, stock, délai de livraison.
5. Elle ajoute au panier ou continue à explorer.

**Résultat attendu :** Elle découvre au moins un produit pertinent en moins de 2 minutes.

---

### UC-C02 — Commande par intention (texte/image/vocal)

**Déclencheur :** Awa a une idée précise mais ne sait pas où chercher.

**Flux :**
1. Elle tape ou dicte "je cherche du tissu wax bleu pas cher à Lomé".
2. OU elle envoie une photo d'un tissu qu'elle a vu sur TikTok.
3. L'IA comprend l'intention et propose 3-5 produits correspondants depuis plusieurs boutiques.
4. Elle choisit, ajoute au panier.
5. L'IA demande: "Tu veux autre chose?" — elle peut combiner plusieurs boutiques.
6. Elle confirme son panier multi-boutiques.

**Résultat attendu :** Panier construit en moins de 45 secondes.

---

### UC-C03 — Panier et checkout

**Déclencheur :** Awa a ses produits dans le panier.

**Flux :**
1. Elle voit le récapitulatif (produits, sous-commandes par vendeur, frais de livraison).
2. Elle choisit son adresse de livraison (ou en saisit une nouvelle).
3. Elle choisit le mode de livraison (livraison ou retrait).
4. Elle confirme et passe au paiement.

**Résultat attendu :** Moins de 3 étapes du panier au paiement.

---

### UC-C04 — Paiement Mobile Money

**Déclencheur :** Awa est prête à payer.

**Flux :**
1. Elle choisit son opérateur (MTN / Orange / T-Money / Wave).
2. Elle reçoit un lien de paiement direct ou un numéro + montant.
3. Elle paie depuis son app MoMo.
4. DYM reçoit la confirmation automatique.
5. Elle reçoit une notification "Commande confirmée".

**Résultat attendu :** Paiement validé sans capture manuelle, sans attente humaine.

---

### UC-C05 — Suivi de commande

**Déclencheur :** Awa a payé et veut savoir où en est sa commande.

**Flux :**
1. Elle ouvre "Mes commandes".
2. Elle voit le statut par sous-commande (confirmée, en préparation, prête, en livraison, livrée).
3. Elle reçoit une notification à chaque changement de statut.
4. Quand le livreur part, elle voit l'ETA.

**Résultat attendu :** Elle n'a pas besoin d'envoyer un message pour savoir où est sa commande.

---

### UC-C06 — Réachat rapide

**Déclencheur :** Awa veut recommander ce qu'elle a déjà acheté.

**Flux :**
1. Elle ouvre "Mes commandes" → historique.
2. Elle tape "Commander à nouveau".
3. Le panier est reconstitué automatiquement.
4. Elle confirme ou ajuste.

---

### UC-C07 — Litige et réclamation

**Déclencheur :** Awa a reçu un produit défectueux ou ne l'a pas reçu.

**Flux :**
1. Elle ouvre la commande concernée.
2. Elle tape "Signaler un problème".
3. Elle choisit le type (non reçu, défectueux, incorrect).
4. Elle envoie une photo si applicable.
5. DYM notifie le vendeur et ouvre un litige.
6. Délai de résolution défini (ex: 48h).
7. Si non résolu → escalade admin.

---

## 3. Use Cases Vendeur (Fatou)

### UC-V01 — Onboarding boutique

**Déclencheur :** Fatou s'inscrit sur DYM.

**Flux :**
1. Téléphone + OTP.
2. Nom de la boutique + catégorie principale.
3. Zone de service (quartier ou ville).
4. Mode de paiement accepté (T-Money, Orange Money...).
5. Mode de livraison proposé (livraison personnelle, retrait, livreur DYM).
6. Photo de profil boutique.
7. Premier produit ajouté (guidé).

**Résultat attendu :** Boutique opérationnelle en moins de 10 minutes.

---

### UC-V02 — Ajout produit rapide

**Déclencheur :** Fatou reçoit un nouveau stock et veut le publier vite.

**Flux :**
1. Photo du produit (depuis galerie ou appareil).
2. Nom suggéré par l'IA (elle valide ou corrige).
3. Prix.
4. Quantité en stock.
5. Catégorie (pré-remplie si déjà utilisée).
6. Publier.

**Résultat attendu :** Produit en ligne en moins de 60 secondes.

---

### UC-V03 — Réception et traitement d'une commande

**Déclencheur :** Une commande arrive.

**Flux :**
1. Notification push + son.
2. Elle voit: client, produits, adresse, montant, mode de paiement.
3. Elle accepte ou refuse (avec raison).
4. Si acceptée: elle prépare, met à jour le statut "En préparation".
5. Commande prête: "Prête pour livraison/retrait".
6. Livreur assigné ou elle livre elle-même.
7. Livraison confirmée: statut "Livrée".

---

### UC-V04 — Validation paiement

**Déclencheur :** Un paiement MoMo doit être confirmé.

**Flux (paiement automatique via API MoMo) :**
1. DYM reçoit la confirmation automatique.
2. Fatou voit "Paiement confirmé" sans rien faire.

**Flux (fallback capture photo) :**
1. Le client envoie une capture MoMo dans l'app.
2. DYM (vision IA) vérifie le montant, la date, le format.
3. Si valide: confirmation automatique.
4. Si suspect: alerte à Fatou "⚠️ Capture suspecte. Vérifiez votre compte avant de livrer."

---

### UC-V05 — Résumé du jour

**Déclencheur :** Fatou veut voir ses chiffres du jour.

**Flux :**
1. Elle ouvre l'app → home vendor.
2. Elle voit: commandes du jour, CA du jour, paiements en attente, produits en rupture.
3. Notification proactive le soir: "Aujourd'hui: 4 commandes, 42 000F, 2 paiements en attente."

---

### UC-V06 — Relance client ciblée

**Déclencheur :** Fatou veut relancer ses clientes qui ont acheté du tissu le mois dernier.

**Flux :**
1. Elle va dans "Mes clientes".
2. Elle filtre: "ont acheté tissu, ce mois-ci".
3. Elle rédige un message type ou choisit un template.
4. Elle envoie le broadcast in-app.

---

### UC-V07 — Gestion rupture

**Déclencheur :** Fatou n'a plus de stock sur un produit.

**Flux :**
1. Elle va sur le produit OU elle voit l'alerte stock bas.
2. Un geste: "Mettre en rupture".
3. Le produit devient indisponible immédiatement.
4. Les clients qui l'avaient en favoris sont notifiés quand il revient.

---

## 4. Use Cases Livreur (Kofi)

### UC-L01 — Accepter une mission

**Flux :**
1. Kofi voit une mission disponible (pickup address, drop address, montant, distance).
2. Il accepte.
3. Il reçoit les détails complets (contact vendeur, contact client, adresses exactes).

### UC-L02 — Exécuter une livraison

**Flux :**
1. Navigation vers pickup.
2. Confirmation récupération (code ou photo du colis).
3. Navigation vers le client.
4. Livraison: preuve (code client ou photo de remise).
5. Mission complétée, gain enregistré.

### UC-L03 — Incident terrain

**Flux :**
1. Problème: client absent, adresse incorrecte, accident.
2. Kofi tape "Signaler un incident".
3. DYM notifie le client et le vendeur.
4. Résolution guidée (rappeler client, replanifier, annuler).

---

## 5. Use Cases Admin Web

### UC-A01 — Supervision plateforme

**Flux :**
1. Dashboard temps réel: commandes actives, paiements en cours, litiges ouverts.
2. Alertes automatiques si anomalie (taux échec paiement > seuil, latence élevée).

### UC-A02 — Gestion litige

**Flux :**
1. Litige ouvert par client ou vendeur.
2. Admin voit: conversation, preuve paiement, historique commande, statuts.
3. Admin décide: remboursement partiel/total, avertissement vendeur, clôture.
4. Action exécutée depuis l'interface sans dev.

### UC-A03 — Support vendeur

**Flux :**
1. Admin se connecte en mode "vue vendeur" (impersonation).
2. Voit exactement ce que voit Fatou.
3. Peut corriger des données sans demander 15 captures d'écran.

---

*Document Personas & Use Cases DYM — Mai 2026*
