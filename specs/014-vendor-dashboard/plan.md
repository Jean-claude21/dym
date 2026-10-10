# Implementation Plan: Tableau de bord vendeuse

Migration additive 0016, RPC `my_vendor_dashboard(period)`, calcul SQL en unités mineures et bornes
dans le fuseau `countries.timezone`. Modèle Dart immuable, repository Result, service injectable,
viewmodel Stacked dans l'app ; réutiliser dym_ui, dym_l10n et la navigation existante.
Cron externe : route avec secret serveur ; SQL décide heure et unicité (store, local_date).

## Constitution Check
I : roadmap phase 2 et IDs cités. III–VI : calcul SQL, RLS et droits explicites, pas de package
nouveau, générés par outils. VII–IX : pgTAP, tests Dart/UI et staging ; événements serveur.
Démo Android et validation des maquettes restent humaines.
## Complexity Tracking
II : maquette 59 dans la direction validée, validation avant fusion (dérogation ROADMAP phase 0).
Branche créée depuis dev puis avancée sur 013 pour ses dépendances ; aucune fusion sensible dans dev.
## Validation
pgTAP : refus anonyme/cliente/autre propriétaire, cash, paiement en ligne, remboursements, bornes
et fuseaux, récap avant/après 19 h/replay. Viewmodel : réseau et requêtes concurrentes.
UI : sept tailles/fr/en/130 %. Parcours live avec comptes nettoyés.
