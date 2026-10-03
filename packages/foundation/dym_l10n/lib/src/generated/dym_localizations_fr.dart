// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'dym_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class DymLocalizationsFr extends DymLocalizations {
  DymLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appNameClient => 'DYM';

  @override
  String get appNameVendor => 'DYM Vendeuse';

  @override
  String get appNameAdmin => 'DYM Admin';

  @override
  String get tagline => 'Le marché près de chez toi, livré chez toi';

  @override
  String get vendorTagline => 'Ta boutique, tes commandes, ta caisse';

  @override
  String get adminTagline => 'Résoudre chaque incident en moins d\'une heure';

  @override
  String get startupPreparing => 'Préparation…';

  @override
  String environmentLabel(String name) {
    return 'Environnement : $name';
  }

  @override
  String get configErrorTitle => 'Configuration manquante';

  @override
  String get configErrorMessage =>
      'Cette version de l\'app n\'est pas configurée. Installe la version officielle.';

  @override
  String get navHome => 'Accueil';

  @override
  String get navOrders => 'Commandes';

  @override
  String get navStores => 'Boutiques';

  @override
  String get navSettings => 'Réglages';

  @override
  String get welcomeSkip => 'Passer';

  @override
  String get welcomeSlide1Title => 'Le marché de ton quartier, livré chez toi';

  @override
  String get welcomeSlide1Body =>
      'Les boutiques de ton quartier, un seul panier, livré en zem.';

  @override
  String get welcomeSlide2Title => 'Plusieurs boutiques, un seul panier';

  @override
  String get welcomeSlide2Body =>
      'Les tomates du marché, le bissap fait maison : tu commandes tout en une fois.';

  @override
  String get welcomeSlide3Title => 'Cash ou Mobile Money';

  @override
  String get welcomeSlide3Body =>
      'Tu paies à la livraison ou par Mobile Money, et tu suis ton zem.';

  @override
  String welcomePage(int current, int total) {
    return 'Écran $current sur $total';
  }

  @override
  String get authContinueGoogle => 'Continuer avec Google';

  @override
  String get authContinueEmail => 'Continuer avec mon email';

  @override
  String get authLegal =>
      'En continuant, tu acceptes les conditions d\'utilisation et la politique de confidentialité.';

  @override
  String get authBack => 'Retour';

  @override
  String get authEmailTitle => 'Ton email';

  @override
  String get authEmailSubtitle =>
      'On t\'envoie un code à 6 chiffres. Pas de mot de passe à retenir.';

  @override
  String get authEmailLabel => 'Adresse email';

  @override
  String get authEmailValid => 'Adresse valide';

  @override
  String get authEmailInvalid => 'Vérifie ton adresse email';

  @override
  String get authEmailPrivacy =>
      'Ton email reste privé : les vendeuses ne le voient pas.';

  @override
  String get authSendCode => 'Recevoir mon code';

  @override
  String get authCodeTitle => 'Entre le code';

  @override
  String authCodeSentTo(String email) {
    return 'Envoyé à $email';
  }

  @override
  String get authChangeEmail => 'Modifier';

  @override
  String get authCodeLabel => 'Code à 6 chiffres';

  @override
  String authResendIn(int seconds) {
    return 'Renvoyer le code dans $seconds s';
  }

  @override
  String get authResend => 'Renvoyer le code';

  @override
  String get authCodeTip =>
      'Astuce : le code arrive en moins d\'une minute. Regarde aussi dans les spams.';

  @override
  String get authCodeWrong =>
      'Ce code ne marche pas. Vérifie-le ou demande-en un nouveau.';

  @override
  String get authProfileTitle => 'Bienvenue sur DYM !';

  @override
  String get authProfileSubtitle => 'Deux questions et c\'est parti.';

  @override
  String get authFirstNameLabel => 'Ton prénom';

  @override
  String get authFirstNameInvalid => 'Entre ton prénom (40 caractères au plus)';

  @override
  String get authPhotoOptional => 'Photo (facultatif)';

  @override
  String get authZoneLabel => 'Ton adresse';

  @override
  String get authZoneHint =>
      'Ton quartier sert à te montrer les boutiques proches et le délai de livraison.';

  @override
  String get authZoneRequired => 'Choisis ton quartier';

  @override
  String get authStart => 'C\'est parti';

  @override
  String get errorOffline =>
      'Pas de connexion. Vérifie ton réseau et réessaie.';

  @override
  String get errorGeneric =>
      'Un problème est survenu. Réessaie dans un instant.';

  @override
  String get errorSessionExpired => 'Ta session a expiré. Reconnecte-toi.';

  @override
  String get retry => 'Réessayer';

  @override
  String get accountTitle => 'Moi';

  @override
  String get accountAddresses => 'Mes adresses';

  @override
  String get accountNotifications => 'Notifications';

  @override
  String accountLanguage(String language) {
    return 'Langue · $language';
  }

  @override
  String get languageName => 'Français';

  @override
  String get accountHelp => 'Aide et contact';

  @override
  String get accountSignOut => 'Se déconnecter';

  @override
  String get accountDelete => 'Supprimer mon compte';

  @override
  String get accountDeleteTitle => 'Supprimer ton compte ?';

  @override
  String get accountDeleteBody =>
      'Ton profil, tes adresses et ton historique seront effacés. Tes commandes en cours doivent d\'abord être livrées ou annulées. Cette action est définitive.';

  @override
  String get accountDeleteConfirm => 'Supprimer définitivement';

  @override
  String get cancel => 'Annuler';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get vendorWelcomeBody =>
      'Ta boutique, tes commandes, ta caisse. Au marché, chez toi ou dans ta boutique.';

  @override
  String get vendorPoint1 => 'Publie un produit en moins d\'une minute';

  @override
  String get vendorPoint2 => 'Reçois des commandes claires, sans DM';

  @override
  String get vendorPoint3 => 'Encaisse en cash ou Mobile Money';

  @override
  String get vendorNextStep =>
      'Ton compte est prêt. Prochaine étape : ta boutique.';

  @override
  String homeHello(String name) {
    return 'Bonjour $name !';
  }

  @override
  String get adminSignInTitle => 'Connexion de l\'équipe';

  @override
  String get adminSignInBody =>
      'Accès réservé aux comptes Google Workspace de DYM.';

  @override
  String get adminContinueGoogle => 'Continuer avec Google Workspace';

  @override
  String get adminSecurityNote =>
      'Double authentification obligatoire · Déconnexion après 30 min d\'inactivité';

  @override
  String get adminAuditNote =>
      'Chaque action est enregistrée dans le journal d\'audit.';

  @override
  String get adminAccessDenied =>
      'Accès réservé à l\'équipe DYM. Ce compte n\'a pas les droits d\'administration.';

  @override
  String get adminGoogleUnavailable =>
      'La connexion Google n\'est pas configurée pour cet environnement.';

  @override
  String get adminSignedOutInactive =>
      'Tu as été déconnecté après 30 minutes d\'inactivité.';

  @override
  String get navStore => 'Boutique';

  @override
  String storeStepLabel(int current, int total) {
    return 'Étape $current sur $total';
  }

  @override
  String get storeContinue => 'Continuer';

  @override
  String get storeSave => 'Enregistrer';

  @override
  String get storeSaveError =>
      'Enregistrement impossible. Vérifie ta connexion et réessaie.';

  @override
  String get storeIncomplete => 'Il manque encore des informations.';

  @override
  String get storeNameTitle => 'Comment s\'appelle ta boutique ?';

  @override
  String get storeNameSubtitle =>
      'C\'est le nom que verront les clientes. Tu pourras le changer.';

  @override
  String get storeNameLabel => 'Nom de la boutique';

  @override
  String get storeNameInvalid => 'De 2 à 60 caractères.';

  @override
  String get storeDescriptionLabel => 'Présente ta boutique (facultatif)';

  @override
  String get storeDescriptionHint => 'Ce que tu vends, ce qui te rend unique';

  @override
  String storeCharCount(int count, int max) {
    return '$count/$max';
  }

  @override
  String get storePreviewTitle => 'Aperçu pour les clientes';

  @override
  String storePreviewPlace(String zone) {
    return '$zone · ouvert';
  }

  @override
  String get storeOriginTitle => 'Où vends-tu ?';

  @override
  String get storeOriginSubtitle =>
      'Chaque boutique a sa place sur DYM. Tu pourras changer plus tard.';

  @override
  String get storeOriginPrivacy =>
      'Ton adresse reste privée : les clientes voient seulement ton quartier.';

  @override
  String get storeAddressTitle => 'Où récupérer tes commandes ?';

  @override
  String get storeAddressSubtitle =>
      'Le livreur passe chercher les commandes ici.';

  @override
  String get storeZoneLabel => 'Ton quartier';

  @override
  String get storeZoneVisible => '(visible par les clientes)';

  @override
  String get storeAddressLabel => 'Adresse de ramassage';

  @override
  String get storeAddressHint => 'Rue, maison, portail…';

  @override
  String get storeLandmarkLabel => 'Repère';

  @override
  String get storeLandmarkHint => 'Ex. : derrière la pharmacie';

  @override
  String get storeAddressPrivacy =>
      'Ton adresse reste privée : les clientes voient seulement ton quartier. Seul le livreur de la commande la reçoit.';

  @override
  String get storeCategoryTitle => 'Que vends-tu surtout ?';

  @override
  String get storeCategorySubtitle => 'Ta boutique apparaîtra dans ce rayon.';

  @override
  String get storeDeliveryTitle => 'Où livres-tu ?';

  @override
  String get storeDeliverySubtitle =>
      'Les quartiers où tu acceptes les commandes. DYM s\'occupe du zem.';

  @override
  String get storeSelectAll => 'Tout sélectionner';

  @override
  String get storePrepTitle => 'Temps de préparation';

  @override
  String storePrepMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String storePrepHours(int hours) {
    return '$hours h';
  }

  @override
  String get storePickupTitle => 'Les clientes peuvent venir chercher';

  @override
  String get storePickupSubtitle =>
      'Retrait sur place, sans frais de livraison';

  @override
  String get storePaymentTitle => 'Comment veux-tu être payée ?';

  @override
  String get storePaymentSubtitle =>
      'Les clientes choisissent parmi ces moyens.';

  @override
  String get storePaymentCashHint => 'Le livreur te remet l\'argent.';

  @override
  String get storePaymentSoon => 'Bientôt';

  @override
  String get storePaymentSoonHint => 'Bientôt disponible.';

  @override
  String get storePaymentMomoNote =>
      'Le paiement Mobile Money arrive dès que DYM l\'active dans ton pays.';

  @override
  String get storeHoursTitle => 'Quand es-tu ouverte ?';

  @override
  String get storeHoursSubtitle =>
      'Les commandes arrivent seulement pendant tes horaires.';

  @override
  String get storeHoursClosed => 'Fermé';

  @override
  String get storeHoursOpens => 'Ouverture';

  @override
  String get storeHoursCloses => 'Fermeture';

  @override
  String get storeHoursSameEveryDay => 'Mêmes horaires tous les jours ouverts';

  @override
  String get storeHoursInvalid => 'L\'ouverture doit précéder la fermeture.';

  @override
  String get weekday1 => 'Lundi';

  @override
  String get weekday2 => 'Mardi';

  @override
  String get weekday3 => 'Mercredi';

  @override
  String get weekday4 => 'Jeudi';

  @override
  String get weekday5 => 'Vendredi';

  @override
  String get weekday6 => 'Samedi';

  @override
  String get weekday7 => 'Dimanche';

  @override
  String get storeOpenAction => 'Ouvrir ma boutique';

  @override
  String get storeOpenedTitle => 'Ta boutique est ouverte !';

  @override
  String storeNamePlace(String name, String zone) {
    return '$name · $zone';
  }

  @override
  String get storeSummaryName => 'Nom et présentation';

  @override
  String storeSummaryOrigin(String origin) {
    return '$origin · adresse privée';
  }

  @override
  String storeSummaryDelivery(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Livraison dans $count quartiers',
      one: 'Livraison dans 1 quartier',
    );
    return '$_temp0';
  }

  @override
  String storeHoursRange(
    String first,
    String last,
    String opens,
    String closes,
  ) {
    String _temp0 = intl.Intl.selectLogic(last, {
      '1': 'lundi',
      '2': 'mardi',
      '3': 'mercredi',
      '4': 'jeudi',
      '5': 'vendredi',
      '6': 'samedi',
      'other': 'dimanche',
    });
    return '$first au $_temp0, $opens – $closes';
  }

  @override
  String storeHoursSingle(String day, String opens, String closes) {
    return '$day, $opens – $closes';
  }

  @override
  String storeHoursDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours par semaine',
      one: '1 jour par semaine',
    );
    return '$_temp0';
  }

  @override
  String get storeAddFirstProduct => 'Ajouter mon premier produit';

  @override
  String get storeSeeMine => 'Voir ma boutique';

  @override
  String get myStoreTitle => 'Ma boutique';

  @override
  String get myStoreOpen => 'Ouverte';

  @override
  String get myStoreOpenHint => 'Les clientes peuvent commander';

  @override
  String get myStoreClosed => 'Fermée';

  @override
  String get myStoreClosedHint => 'Les clientes ne peuvent pas commander';

  @override
  String get myStoreSuspended =>
      'Ta boutique est suspendue par l\'équipe DYM. Contacte-nous pour la rouvrir.';

  @override
  String get myStoreRowOrigin => 'Où vends-tu';

  @override
  String get myStoreAddressPrivate => 'privée';

  @override
  String get myStoreRowDelivery => 'Livraison';

  @override
  String myStoreDeliveryValue(int count, String prep) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count quartiers',
      one: '1 quartier',
    );
    return '$_temp0 · $prep';
  }

  @override
  String get myStoreRowPayment => 'Paiement';

  @override
  String get myStoreRowHours => 'Horaires';

  @override
  String get myStoreRowCategory => 'Rayon';

  @override
  String get navProducts => 'Produits';

  @override
  String get productsTitle => 'Mes produits';

  @override
  String get productsAll => 'Tout';

  @override
  String get productsArchived => 'Archivés';

  @override
  String get productsEmpty => 'Aucun produit pour l\'instant.';

  @override
  String get productsEmptyHint =>
      'Ajoute ton premier produit : une photo suffit pour commencer.';

  @override
  String get productsAdd => 'Ajouter un produit';

  @override
  String get productInStock => 'En stock';

  @override
  String get productOutOfStock => 'Rupture';

  @override
  String get productDraft => 'Brouillon';

  @override
  String productStockCount(int count) {
    return '$count en stock';
  }

  @override
  String productVariantCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count variantes',
      one: '1 variante',
    );
    return '$_temp0';
  }

  @override
  String get productRestore => 'Restaurer';

  @override
  String get productArchive => 'Archiver';

  @override
  String get productDeleteDraft => 'Supprimer le brouillon';

  @override
  String get productEdit => 'Modifier';

  @override
  String productActions(String name) {
    return 'Actions sur $name';
  }

  @override
  String get productNewTitle => 'Nouveau produit';

  @override
  String get productEditTitle => 'Modifier le produit';

  @override
  String get productPhotoSubtitle => 'Prends une photo, DYM remplit la fiche.';

  @override
  String get productTakePhoto => 'Prendre une photo';

  @override
  String get productChoosePhoto => 'Choisir dans la galerie';

  @override
  String get productAddPhoto => 'Photo';

  @override
  String productPhotoCount(int count, int max) {
    return '$count/$max photos';
  }

  @override
  String get productRemovePhoto => 'Retirer la photo';

  @override
  String get productPhotoUploading => 'Envoi de la photo…';

  @override
  String get productPhotoFailed =>
      'La photo n\'a pas pu être envoyée. Réessaie.';

  @override
  String get productSuggesting => 'DYM prépare la fiche…';

  @override
  String get productSuggestedBy => 'Proposé par DYM';

  @override
  String get productSuggestionCheck => 'Vérifie et corrige si besoin.';

  @override
  String get productSuggestionUnavailable => 'Remplis la fiche toi-même.';

  @override
  String get productNameLabel => 'Nom';

  @override
  String get productNameHint => 'Ex. : Jus de bissap 50 cl';

  @override
  String get productNameInvalid => 'De 2 à 80 caractères.';

  @override
  String get productAisleLabel => 'Rayon';

  @override
  String get productDescriptionLabel => 'Description (facultatif)';

  @override
  String get productPriceTitle => 'Prix et stock';

  @override
  String get productPriceLabel => 'Prix';

  @override
  String get productPriceInvalid => 'Saisis un prix supérieur à zéro.';

  @override
  String get productUnitLabel => 'Unité';

  @override
  String get productVariantsTitle => 'Variantes';

  @override
  String get productTrackStock => 'Je compte mon stock';

  @override
  String get productTrackStockHint =>
      'Sinon, le produit reste disponible tant que tu ne le mets pas en rupture.';

  @override
  String get productStockLabel => 'Stock';

  @override
  String get productVariantLabel => 'Variante (ex. : 1 L)';

  @override
  String get productVariantPrice => 'Prix (facultatif)';

  @override
  String get productVariantAdd => 'Ajouter une variante';

  @override
  String get productVariantRemove => 'Retirer la variante';

  @override
  String productVariantNamed(String label) {
    return 'Variante $label';
  }

  @override
  String get productStockDecrease => 'Un de moins';

  @override
  String get productStockIncrease => 'Un de plus';

  @override
  String get productStoreCategoryTitle => 'Catégorie de ma boutique';

  @override
  String get productStoreCategoryNew => 'Nouvelle';

  @override
  String get productPublish => 'Publier le produit';

  @override
  String get productMissingPhoto => 'Ajoute au moins une photo pour publier.';

  @override
  String get productVariantLabelsRequired => 'Donne un nom à chaque variante.';

  @override
  String get categoriesTitle => 'Mes catégories';

  @override
  String get categoriesSubtitle => 'Range tes produits pour les clientes.';

  @override
  String get categoriesNewHint => 'Nouvelle catégorie';

  @override
  String get categoriesAdd => 'Ajouter';

  @override
  String categoriesProductCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produits',
      one: '1 produit',
      zero: 'Aucun produit',
    );
    return '$_temp0';
  }

  @override
  String get categoriesArchived => 'archivée';

  @override
  String get categoriesRestore => 'Réactiver';

  @override
  String get categoriesRename => 'Renommer';

  @override
  String get categoriesArchive => 'Archiver';

  @override
  String get categoriesDuplicate => 'Cette catégorie existe déjà.';

  @override
  String categoriesMove(String name) {
    return 'Déplacer $name';
  }

  @override
  String get categoriesEmpty => 'Aucune catégorie : crée la première.';

  @override
  String get navAisles => 'Rayons';

  @override
  String homeDeliveredIn(int minutes) {
    return 'Livré en $minutes min';
  }

  @override
  String get homeSearchHint => 'Cherche tomates, gari, jus maison…';

  @override
  String get homeOpenStores => 'Boutiques ouvertes près de toi';

  @override
  String get homeOtherStores => 'Les autres boutiques du quartier';

  @override
  String get homeNoOpenStore =>
      'Aucune boutique ouverte pour l\'instant dans ton quartier.';

  @override
  String get homeAisles => 'Rayons';

  @override
  String homeChangeZone(String zone) {
    return 'Changer de quartier : $zone';
  }

  @override
  String storeOpenUntil(String time) {
    return 'Ouvert jusqu\'à $time';
  }

  @override
  String get storeOpenNow => 'Ouvert';

  @override
  String get storeClosedNow => 'Fermé';

  @override
  String distanceMeters(int meters) {
    return '$meters m';
  }

  @override
  String distanceKm(String km) {
    return '$km km';
  }

  @override
  String placeAndMeta(String place, String meta) {
    return '$place · $meta';
  }

  @override
  String get zonePickerTitle => 'Où te livrer ?';

  @override
  String get zoneUseLocation => 'Utiliser ma position';

  @override
  String get zoneLocating => 'Recherche de ta position…';

  @override
  String get zoneLocationUnavailable =>
      'Position indisponible : cherche ton quartier.';

  @override
  String zoneSuggestion(String zone) {
    return 'Tu es à $zone ?';
  }

  @override
  String get zoneConfirm => 'Oui, c\'est ça';

  @override
  String get zoneSearchLabel => 'Cherche ton quartier';

  @override
  String get zoneSearchHint => 'Quartier ou ville';

  @override
  String get zoneNoResult =>
      'Aucun quartier trouvé. Essaie un autre nom ou utilise ta position.';

  @override
  String get zoneOutsideArea =>
      'Ta position est hors des zones desservies : cherche ton quartier.';

  @override
  String get aisleAll => 'Tous';

  @override
  String get aisleEmpty =>
      'Rien dans ce rayon pour ton quartier pour l\'instant.';

  @override
  String get searchHint => 'Cherche un produit ou une boutique';

  @override
  String get searchClear => 'Effacer la recherche';

  @override
  String get searchTabAll => 'Tout';

  @override
  String get searchTabProducts => 'Produits';

  @override
  String get searchTabStores => 'Boutiques';

  @override
  String get searchFilters => 'Filtres';

  @override
  String searchFiltersActive(int count) {
    return 'Filtres, $count actifs';
  }

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count résultats',
      one: '1 résultat',
      zero: 'Aucun résultat',
    );
    return '$_temp0';
  }

  @override
  String get searchEmpty => 'Rien trouvé. Essaie un autre mot.';

  @override
  String get searchPrompt => 'Tape au moins 2 lettres.';

  @override
  String get searchLoadMore => 'Voir plus';

  @override
  String get sortRelevance => 'Pertinence';

  @override
  String get sortPriceAsc => 'Prix croissant';

  @override
  String get sortPriceDesc => 'Prix décroissant';

  @override
  String get filtersTitle => 'Filtres';

  @override
  String get filtersClear => 'Effacer';

  @override
  String get filtersSort => 'Trier par';

  @override
  String get filtersOrigin => 'Origine';

  @override
  String get filtersPrice => 'Prix';

  @override
  String get filtersMin => 'Min';

  @override
  String get filtersMax => 'Max';

  @override
  String get filtersAisle => 'Rayon';

  @override
  String get filtersAvailable => 'Disponible seulement';

  @override
  String get filtersApply => 'Voir les résultats';

  @override
  String get filtersPriceInvalid => 'Le minimum dépasse le maximum.';

  @override
  String productFrom(String price) {
    return 'dès $price';
  }

  @override
  String get productChoose => 'Choisis';

  @override
  String productDeliveryEstimate(int minutes, String zone) {
    return 'Livré en $minutes min environ à $zone';
  }

  @override
  String productDeliveryEstimateShort(int minutes) {
    return 'Livré en $minutes min environ';
  }

  @override
  String productNotServed(String zone) {
    return 'Cette boutique ne livre pas $zone.';
  }

  @override
  String productPhotoPosition(int index, int count) {
    return 'Photo $index sur $count';
  }

  @override
  String get productUnavailableTitle => 'Ce produit n\'est plus proposé.';

  @override
  String storePagePickupNote(String zone) {
    return 'Retrait possible à $zone · adresse partagée avec le livreur uniquement';
  }

  @override
  String get storePageProducts => 'Ses produits';

  @override
  String get storePageEmpty => 'Pas encore de produit publié.';

  @override
  String get storePageUnavailable => 'Cette boutique n\'est plus disponible.';

  @override
  String get shareLabel => 'Partager';

  @override
  String get cartTitle => 'Ton panier';

  @override
  String cartSummary(int stores, int items) {
    String _temp0 = intl.Intl.pluralLogic(
      stores,
      locale: localeName,
      other: '$stores boutiques',
      one: '1 boutique',
    );
    String _temp1 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items articles',
      one: '1 article',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String cartMiniSummary(int stores, int items) {
    String _temp0 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items articles',
      one: '1 article',
    );
    String _temp1 = intl.Intl.pluralLogic(
      stores,
      locale: localeName,
      other: '$stores boutiques',
      one: '1 boutique',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get cartView => 'Voir le panier';

  @override
  String get cartAdd => 'Ajouter au panier';

  @override
  String get cartAdded => 'Ajouté au panier';

  @override
  String get cartFreeLead => 'Plus que';

  @override
  String get cartFreeTrail => 'pour la livraison offerte';

  @override
  String get cartFreeReached => 'Livraison offerte !';

  @override
  String get cartSubstitutionTitle => 'Si un produit manque';

  @override
  String get cartSubstitutionSubtitle =>
      'La boutique propose un équivalent au même prix';

  @override
  String get cartDelivery => 'Livraison';

  @override
  String cartDeliveryMeta(int pickups, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      pickups,
      locale: localeName,
      other: '$pickups ramassages',
      one: '1 ramassage',
      zero: 'Retrait sur place',
    );
    return '$_temp0 · $minutes min';
  }

  @override
  String get cartChange => 'Changer';

  @override
  String get cartPayment => 'Paiement';

  @override
  String get cartSubtotal => 'Sous-total';

  @override
  String get cartTotal => 'Total';

  @override
  String cartOrder(String total) {
    return 'Commander · $total';
  }

  @override
  String get cartEmptyTitle => 'Ton panier est vide';

  @override
  String get cartEmptyMessage =>
      'Ajoute des produits des boutiques ouvertes près de toi.';

  @override
  String get cartBrowse => 'Voir les boutiques';

  @override
  String get cartRemove => 'Retirer';

  @override
  String get cartIssueUnavailable => 'Rupture';

  @override
  String cartIssueStock(int count) {
    return 'Plus que $count en stock';
  }

  @override
  String get cartIssuePriceChanged => 'Prix modifié';

  @override
  String get cartIssueClosed => 'Fermée maintenant';

  @override
  String get cartIssueSuspended => 'Boutique indisponible';

  @override
  String get cartIssueNotDelivered =>
      'Ne livre pas ton adresse : choisis le retrait ou une autre adresse';

  @override
  String get cartIssuePickupUnavailable =>
      'Retrait non proposé par cette boutique';

  @override
  String get cartIssuePaymentNotAccepted =>
      'Paiement non accepté par cette boutique';

  @override
  String get cartBlocked => 'Corrige les points signalés pour commander.';

  @override
  String get cartUnavailable => 'Ce produit n\'est plus disponible.';

  @override
  String get cartOtherCountry =>
      'Ce produit vient d\'un autre pays que ton panier.';

  @override
  String get orderErrorAddressRequired => 'Choisis une adresse de livraison.';

  @override
  String get orderErrorTotalChanged =>
      'Le panier a changé : vérifie le nouveau total.';

  @override
  String get orderErrorPaymentUnavailable =>
      'Ce moyen de paiement n\'est pas encore disponible.';

  @override
  String get orderErrorEmpty => 'Ton panier est vide.';

  @override
  String get deliveryTitle => 'Livraison';

  @override
  String get deliveryWhere => 'Où te livrer ?';

  @override
  String get deliveryAddAddress => 'Ajouter une adresse';

  @override
  String get deliveryModes => 'Mode par boutique';

  @override
  String get deliveryModeDelivery => 'Livraison';

  @override
  String get deliveryModePickup => 'Je récupère';

  @override
  String get deliveryConfirm => 'Valider la livraison';

  @override
  String get deliveryNoAddress => 'Ajoute une adresse pour être livrée.';

  @override
  String get addressesTitle => 'Mes adresses';

  @override
  String get addressDefault => 'Par défaut';

  @override
  String get addressPositionSaved => 'Position enregistrée';

  @override
  String get addressSetDefault => 'Choisir par défaut';

  @override
  String get addressEdit => 'Modifier';

  @override
  String get addressDelete => 'Supprimer';

  @override
  String get addressMenu => 'Options de l\'adresse';

  @override
  String get addressesEmptyTitle => 'Aucune adresse';

  @override
  String get addressesEmptyMessage =>
      'Ajoute ton adresse pour être livrée plus vite.';

  @override
  String get addressKindHome => 'Maison';

  @override
  String get addressKindWork => 'Bureau';

  @override
  String get addressKindOther => 'Autre';

  @override
  String get addressNewTitle => 'Nouvelle adresse';

  @override
  String get addressEditTitle => 'Modifier l\'adresse';

  @override
  String get addressWhere => 'Où ?';

  @override
  String get addressLabel => 'Nom de l\'adresse (facultatif)';

  @override
  String get addressLandmark => 'Repère';

  @override
  String get addressLandmarkHint => 'Ex. portail bleu après la pharmacie';

  @override
  String get addressLandmarkInvalid => 'Décris un repère (3 à 200 caractères)';

  @override
  String get addressPhone => 'Téléphone pour la livraison';

  @override
  String get addressPhoneInvalid => 'Numéro de téléphone invalide';

  @override
  String get addressMakeDefault => 'Adresse par défaut';

  @override
  String get addressSave => 'Enregistrer l\'adresse';

  @override
  String get orderSentTitle => 'Commande envoyée !';

  @override
  String get orderSentSubtitle =>
      'Les vendeuses vont l\'accepter. Tu seras prévenue.';

  @override
  String get orderPending => 'En attente d\'acceptation';

  @override
  String orderItems(int items) {
    String _temp0 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items articles',
      one: '1 article',
    );
    return '$_temp0';
  }

  @override
  String orderDeliveryTo(String place) {
    return 'Livraison : $place';
  }

  @override
  String get orderBackHome => 'Retour à l\'accueil';

  @override
  String get cartAddShort => 'Ajouter';

  @override
  String get paymentTitle => 'Paiement';

  @override
  String get paymentWaitingTitle => 'En attente du paiement';

  @override
  String get paymentWaitingBody =>
      'Valide le paiement sur la page qui vient de s\'ouvrir, puis reviens ici.';

  @override
  String get paymentAmount => 'Montant';

  @override
  String get paymentReference => 'Référence';

  @override
  String get paymentChecking => 'Vérification automatique…';

  @override
  String get paymentOpenPage => 'Ouvrir la page de paiement';

  @override
  String get paymentPayOnDeliveryInstead => 'Payer à la livraison à la place';

  @override
  String get paymentFailedTitle => 'Le paiement n\'a pas abouti';

  @override
  String get paymentFailedBody =>
      'Aucun montant n\'a été débité. Ta commande est gardée : réessaie ou paie à la livraison.';

  @override
  String get paymentRetry => 'Réessayer le paiement';

  @override
  String get paymentPayOnDelivery => 'Payer à la livraison';

  @override
  String get paymentConfirmed => 'Paiement confirmé';

  @override
  String get paymentCashOnDelivery => 'Cash à la livraison';

  @override
  String get paymentCashNotAccepted =>
      'Une boutique n\'accepte pas le paiement à la livraison.';

  @override
  String get paymentOpenFailed => 'Impossible d\'ouvrir la page de paiement.';

  @override
  String get ordersEmptyTitle => 'Aucune commande pour l\'instant';

  @override
  String get ordersEmptyMessage =>
      'Les commandes payées ou en cash apparaissent ici.';

  @override
  String vendorOrderOf(String name) {
    return 'Commande de $name';
  }

  @override
  String vendorOrderReceivedAt(String time) {
    return 'Reçue à $time';
  }

  @override
  String get vendorPaidTitle => 'Paiement confirmé';

  @override
  String get vendorPaidBody => 'Tu peux préparer la commande.';

  @override
  String get vendorCashTitle => 'Cash à la livraison';

  @override
  String vendorCashBody(String amount) {
    return 'Encaisse $amount à la remise de la commande.';
  }

  @override
  String get vendorItems => 'Articles';

  @override
  String get vendorPayment => 'Paiement';

  @override
  String get vendorPaymentMethod => 'Moyen';

  @override
  String get vendorPaymentDate => 'Date';

  @override
  String get vendorDelivery => 'Livraison';

  @override
  String get vendorPickup => 'Retrait sur place';

  @override
  String vendorLandmark(String landmark) {
    return 'Repère : $landmark';
  }

  @override
  String get vendorCall => 'Appeler';

  @override
  String vendorQuantity(int count) {
    return '× $count';
  }

  @override
  String get orderStatusPending => 'En attente';

  @override
  String get orderStatusAccepted => 'Acceptée';

  @override
  String get orderStatusPreparing => 'En préparation';

  @override
  String get orderStatusReady => 'Prête';

  @override
  String get orderStatusOutForDelivery => 'En route';

  @override
  String get orderStatusDelivered => 'Livrée';

  @override
  String get orderStatusCollected => 'Récupérée';

  @override
  String get orderStatusRefused => 'Refusée';

  @override
  String get orderStatusCancelled => 'Annulée';

  @override
  String get ordersMineTitle => 'Mes commandes';

  @override
  String get ordersActive => 'En cours';

  @override
  String get ordersDone => 'Terminées';

  @override
  String get ordersMineEmptyMessage => 'Tes commandes apparaissent ici.';

  @override
  String orderEtaAt(String time) {
    return 'Livrée vers $time';
  }

  @override
  String orderPickupAt(String time) {
    return 'Prête vers $time';
  }

  @override
  String orderOn(String date) {
    return 'Le $date';
  }

  @override
  String get trackTitle => 'Suivi de commande';

  @override
  String get trackConfirmed => 'Confirmée';

  @override
  String get trackPrepared => 'Préparée';

  @override
  String trackArrives(String time) {
    return 'Arrive vers $time';
  }

  @override
  String trackReadyAt(String time) {
    return 'Prête vers $time';
  }

  @override
  String get trackPayOnDelivery => 'À payer à la livraison';

  @override
  String trackCashAmount(String amount) {
    return '$amount en cash';
  }

  @override
  String get trackCancel => 'Annuler la commande';

  @override
  String get trackCancelTitle => 'Annuler la commande ?';

  @override
  String get trackCancelBody =>
      'La boutique sera prévenue. La commande ne pourra pas être reprise.';

  @override
  String get trackCancelKeep => 'Garder la commande';

  @override
  String trackRefused(String reason) {
    return 'Refusée par la boutique : $reason';
  }

  @override
  String get trackCancelledByYou => 'Tu as annulé cette commande.';

  @override
  String get trackRefundDue => 'Un remboursement est en cours.';

  @override
  String get orderStatusChanged =>
      'La commande a changé : elle vient d\'être mise à jour.';

  @override
  String get reasonOutOfStock => 'Produit en rupture';

  @override
  String get reasonTooBusy => 'Boutique trop chargée';

  @override
  String get reasonAreaNotServed => 'Livraison impossible dans ce quartier';

  @override
  String get reasonOther => 'Autre raison';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsReadAll => 'Tout lire';

  @override
  String get notificationsEmptyTitle => 'Aucune notification';

  @override
  String get notificationsEmptyMessage =>
      'Tu seras prévenue à chaque étape de tes commandes.';

  @override
  String notificationsUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count non lues',
      one: '1 non lue',
    );
    return '$_temp0';
  }

  @override
  String get notifNewOrderTitle => 'Nouvelle commande !';

  @override
  String notifNewOrderBody(String name) {
    return '$name a commandé.';
  }

  @override
  String get notifCancelledByClientTitle => 'Commande annulée';

  @override
  String get notifCancelledByClientBody => 'La cliente a annulé sa commande.';

  @override
  String get notifAcceptedTitle => 'Commande acceptée';

  @override
  String notifAcceptedBody(String store) {
    return '$store a accepté ta commande.';
  }

  @override
  String get notifRefusedTitle => 'Commande refusée';

  @override
  String notifRefusedBody(String store) {
    return '$store ne peut pas honorer ta commande.';
  }

  @override
  String notifPreparingBody(String store) {
    return '$store prépare ta commande.';
  }

  @override
  String get notifReadyTitle => 'Commande prête';

  @override
  String notifReadyBody(String store) {
    return 'Ta commande chez $store est prête.';
  }

  @override
  String get notifOnTheWayBody => 'Ta commande arrive bientôt.';

  @override
  String get notifDeliveredBody => 'Bon appétit ! Dis-nous si tout va bien.';

  @override
  String get notifPaidBody => 'Ta commande est payée.';

  @override
  String get notifPaymentFailedTitle => 'Paiement échoué';

  @override
  String get notifPaymentFailedBody =>
      'Ton paiement n\'a pas abouti : réessaie ou paie à la livraison.';

  @override
  String get timeJustNow => 'à l\'instant';

  @override
  String timeMinutesAgo(int count) {
    return 'il y a $count min';
  }

  @override
  String timeHoursAgo(int count) {
    return 'il y a $count h';
  }

  @override
  String get timeYesterday => 'hier';

  @override
  String timeDaysAgo(int count) {
    return 'il y a $count j';
  }

  @override
  String get notifSettingsTitle => 'Réglages des notifications';

  @override
  String get notifSettingsIntro =>
      'Choisis ce que DYM peut t\'envoyer sur ce téléphone.';

  @override
  String get prefOrdersTitle => 'Suivi de mes commandes';

  @override
  String get prefOrdersBody => 'Acceptée, en préparation, en route, livrée';

  @override
  String get prefPaymentsTitle => 'Paiements';

  @override
  String get prefPaymentsBody => 'Paiement confirmé ou échoué';

  @override
  String get prefMessagesTitle => 'Messages des boutiques';

  @override
  String get prefMessagesBody => 'Réponses des vendeuses';

  @override
  String get prefPromotionsTitle => 'Bons plans';

  @override
  String get prefPromotionsBody => 'Promotions de mes boutiques';

  @override
  String get notifSettingsNote =>
      'Les notifications importantes restent visibles dans l\'app.';

  @override
  String get vendorScopeNew => 'Nouvelles';

  @override
  String get vendorScopeActive => 'En cours';

  @override
  String get vendorScopeDone => 'Terminées';

  @override
  String get vendorReplyQuickly => 'Réponds vite : la cliente attend.';

  @override
  String get vendorYouCollect => 'Tu encaisses';

  @override
  String get vendorAccept => 'Accepter';

  @override
  String get vendorRefuse => 'Refuser';

  @override
  String get vendorRefuseTitle => 'Refuser la commande ?';

  @override
  String get vendorRefuseBody =>
      'La cliente sera prévenue. Choisis une raison.';

  @override
  String get vendorRefuseNote => 'Précise (facultatif)';

  @override
  String get vendorRefuseConfirm => 'Refuser la commande';

  @override
  String get vendorStartPreparing => 'Commencer la préparation';

  @override
  String get vendorMarkReady => 'Marquer prête';

  @override
  String get vendorOutForDelivery => 'Partir livrer';

  @override
  String get vendorMarkDelivered => 'Marquer livrée';

  @override
  String get vendorMarkCollected => 'Marquer récupérée';

  @override
  String vendorConfirmCash(String amount) {
    return 'J\'ai encaissé $amount';
  }

  @override
  String get vendorCashCollected => 'Encaissement confirmé';

  @override
  String get vendorNewOrderAlert => 'Nouvelle commande reçue';

  @override
  String get vendorRefundDue => 'Remboursement à faire par l\'équipe DYM.';

  @override
  String vendorOrderRefusedReason(String reason) {
    return 'Refusée : $reason';
  }

  @override
  String get disputeReport => 'Signaler un problème';

  @override
  String get disputeWhatHappened => 'Que s\'est-il passé ?';

  @override
  String get disputeTellUs => 'Raconte-nous';

  @override
  String get disputeDescriptionInvalid =>
      'Décris le problème (3 à 500 caractères)';

  @override
  String get disputeWhoAnswers =>
      'La boutique et l\'équipe DYM vont te répondre.';

  @override
  String get disputeSend => 'Envoyer le signalement';

  @override
  String get disputeReasonMissingItem => 'Il manque un article';

  @override
  String get disputeReasonWrongItem => 'Mauvais article';

  @override
  String get disputeReasonDamaged => 'Article abîmé';

  @override
  String get disputeReasonQuality => 'Qualité décevante';

  @override
  String get disputeReasonNotDelivered => 'Commande jamais reçue';

  @override
  String get disputeReasonOther => 'Autre';

  @override
  String get disputeMine => 'Mon signalement';

  @override
  String get disputeOpenStatus => 'En cours de traitement';

  @override
  String get disputeResolvedStatus => 'Traité';

  @override
  String get disputeYou => 'Toi';

  @override
  String get disputeTeam => 'Équipe DYM';

  @override
  String get disputeCustomer => 'Cliente';

  @override
  String get disputeWriteMessage => 'Écris un message…';

  @override
  String get disputeSendMessage => 'Envoyer';

  @override
  String disputeRefunded(String amount) {
    return 'Remboursement de $amount décidé.';
  }

  @override
  String get disputeNoAction => 'Signalement clos sans remboursement.';

  @override
  String get disputeAlreadyOpen =>
      'Un signalement est déjà en cours pour cette commande.';

  @override
  String get disputeNotAllowed => 'Cette commande ne peut plus être signalée.';

  @override
  String disputeVendorBanner(String reason) {
    return 'Problème signalé : $reason';
  }

  @override
  String get disputeReply => 'Répondre';

  @override
  String get disputeReplyHint => 'Ta réponse à la cliente';

  @override
  String get disputeSeeThread => 'Voir le signalement';

  @override
  String disputeMessageLine(String author, String body) {
    return '$author : $body';
  }

  @override
  String get notifDisputeRepliedTitle => 'Réponse à ton signalement';

  @override
  String notifDisputeRepliedBody(String author) {
    return '$author t\'a répondu.';
  }

  @override
  String get notifDisputeResolvedTitle => 'Signalement traité';

  @override
  String get notifDisputeResolvedBody =>
      'L\'équipe DYM a traité ton signalement.';
}
