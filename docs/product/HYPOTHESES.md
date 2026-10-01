# DYM — Registre des hypothèses

> Ce qu'on croit vrai sans l'avoir prouvé. Chaque hypothèse a un test, un seuil et une décision.
> On teste d'abord les plus risquées, et le moins cher possible (maquette, terrain) avant le code.
> Statuts : `À tester` · `En test` · `Validée` · `Invalidée` · `Ajustée`.

| ID | Hypothèse | Risque | Test le moins cher | Seuil de validation | Si invalidée | Statut |
|---|---|---|---|---|---|---|
| H1 | Fatou publie et maintient son catalogue seule. | Critique | Maquette parcours 10 (photo → fiche) chronométrée avec 5 vendeuses, puis observation pilote J+7. | 4/5 publient un produit en < 60 s sans aide ; 70 % des vendeuses pilotes mettent à jour un stock en 7 jours. | Onboarding assisté + catalogue saisi par l'équipe ; reconsidérer la saisie vocale. | À tester |
| H2 | Awa veut combiner plusieurs boutiques dans un panier (différenciateur vs Kidia). | Critique | Maquette parcours 4 avec 5 clientes : on observe si elles le font spontanément. Pilote : part des commandes multi-boutiques. | 3/5 combinent spontanément ; ≥ 15 % des commandes pilotes multi-boutiques. | Simplifier en mono-boutique ; repositionner le différenciateur. | À tester |
| H3 | Awa ose commander chez une vendeuse inconnue. | Critique | Maquette fiche boutique (badges de fiabilité, avis) : « commanderais-tu ici ? » | 4/5 disent oui avec cash ; taux panier → commande ≥ 25 % au pilote. | Renforcer la preuve sociale (avis, badge « vendeuse vérifiée DYM »). | À tester |
| H4 | Le cash à la livraison reste majoritaire et ne génère pas trop d'annulations. | Élevé | Pilote : mesurer le mode de paiement et le taux de refus à la porte. | Refus à la porte < 10 %. | Acompte MoMo obligatoire au-delà d'un montant (configurable par pays). | À tester |
| H5 | Les vendeuses livrent elles-mêmes en < 4 h. | Élevé | Pilote : horodatage commande → livrée. | Médiane < 4 h ; ≥ 90 % des commandes livrées. | Partenariat coursiers ; avancer l'app livreur. | À tester |
| H6 | L'économie unitaire tient (commission − frais de paiement − support). | Élevé | Modèle tableur avec les frais réels Moneroo du pays pilote. | Marge contributive positive par commande à 15 % de commission maximum. | Ajuster la commission, le panier minimum ou l'offre vendeuse payante. | À tester |
| H7 | La connexion Google + OTP email suffit pour l'inscription. | Moyen | Maquette parcours 1 avec 5 vendeuses et 5 clientes. | 9/10 se connectent sans aide. | Accélérer l'OTP téléphone/WhatsApp. | À tester |
| H8 | L'IA « photo → fiche produit » fait gagner du temps sans erreurs gênantes. | Moyen | Test sur 50 photos réelles de vendeuses. | ≥ 80 % de suggestions acceptées avec au plus une correction. | Garder la saisie manuelle, IA en option. | À tester |
| H9 | Les notifications push suffisent pour que Fatou ne rate pas de commande. | Moyen | Pilote : délai commande → acceptation. | Médiane < 15 min. | Rappel SMS/WhatsApp après 10 min sans action. | À tester |
| H10 | L'IA d'intention et la vidéo shoppable donnent envie (phase 2). | Moyen | Maquettes « vision » 18 et 19 en test d'envie. | 3/5 disent qu'elles l'utiliseraient cette semaine. | Rester sur la recherche classique ; reporter. | À tester |

## Règles

- Une hypothèse `Invalidée` déclenche une décision écrite dans `docs/architecture/decisions/` ou
  une mise à jour de `ROADMAP.md`, jamais un contournement silencieux.
- Les seuils viennent des KPIs de `METRICS.md` ; on ne les modifie pas après avoir vu les résultats.
