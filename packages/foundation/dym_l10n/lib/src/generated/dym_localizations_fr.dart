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
      'Les boutiques de ton quartier, un seul panier, livré chez toi.';

  @override
  String get welcomeSlide2Title => 'Plusieurs boutiques, un seul panier';

  @override
  String get welcomeSlide2Body =>
      'Les tomates du marché, le poisson fumé, les épices : tu commandes tout en une fois.';

  @override
  String get welcomeSlide3Title => 'Cash ou Mobile Money';

  @override
  String get welcomeSlide3Body =>
      'Tu paies à la livraison ou par Mobile Money, et tu suis ton livreur.';

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
      'Ton email reste privé : il n\'est montré à personne.';

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
      'Ton quartier sert à te proposer ce qui est près de toi.';

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
      'Accès réservé à l\'équipe DYM : reçois un code sur ton email d\'admin.';

  @override
  String get adminContinueGoogle => 'Continuer avec Google';

  @override
  String get adminSecurityNote =>
      'Accès réservé à l\'équipe · Déconnexion après 30 min d\'inactivité';

  @override
  String get adminAuditNote =>
      'Chaque action est enregistrée dans le journal d\'audit.';

  @override
  String get adminAccessDenied =>
      'Accès réservé à l\'équipe DYM. Ce compte n\'a pas les droits d\'administration.';

  @override
  String get authGoogleNoAccount =>
      'Aucun compte Google sur ce téléphone. Ajoute-en un dans les réglages, ou continue avec ton email.';

  @override
  String get adminGoogleUnavailable =>
      'La connexion Google n\'est pas configurée pour cet environnement.';

  @override
  String get adminSignedOutInactive =>
      'Tu as été déconnecté après 30 minutes d\'inactivité.';

  @override
  String get navStore => 'Boutique';

  @override
  String get navToday => 'Aujourd\'hui';

  @override
  String get navCatalog => 'Catalogue';

  @override
  String vendorGreeting(String name) {
    return 'Bonjour $name';
  }

  @override
  String get vendorCharge => 'Encaisser';

  @override
  String get vendorCashSale => 'Vente cash';

  @override
  String get storeMyAccount => 'Mon compte';

  @override
  String get storeGroupMoney => 'Argent';

  @override
  String get storeGroupSell => 'Vendre plus';

  @override
  String get storeGroupSettings => 'Réglages';

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
  String get storeDeliveryZonesTitle => 'Quartiers desservis';

  @override
  String get storeDeliverySubtitle =>
      'Les quartiers où tu acceptes les commandes. DYM s\'occupe du livreur.';

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
  String get myStoreClosedByHours => 'Fermée pour l\'instant';

  @override
  String get myStoreClosedByHoursHint =>
      'Hors de tes horaires : les clientes peuvent commander pour un créneau où tu es ouverte';

  @override
  String get productStoreClosed =>
      'Cette boutique est fermée pour le moment. Tu peux commander pour un créneau où elle est ouverte.';

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
  String get navMarket => 'Marché';

  @override
  String get navCuisine => 'Cuisine';

  @override
  String get navCart => 'Panier';

  @override
  String get homeDeliverTo => 'Livraison à';

  @override
  String get homeActiveOrder => 'Commande en cours';

  @override
  String homeDeliveredIn(int minutes) {
    return 'Livré en $minutes min';
  }

  @override
  String get homeSearchHint => 'Cherche tomates, gari, jus maison…';

  @override
  String get homeOpenStores => 'Boutiques près de toi';

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
      'DYM n\'est pas encore chez toi. Tu peux choisir un quartier desservi, par exemple pour commander pour un proche.';

  @override
  String get aisleAll => 'Tous';

  @override
  String get aisleWhere => 'Où acheter';

  @override
  String get aisleAnywhere => 'Partout';

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
  String productAddPrice(String price) {
    return 'Ajouter · $price';
  }

  @override
  String get productFormat => 'Format';

  @override
  String get productSameStore => 'De la même boutique';

  @override
  String storeFactMinutes(int count) {
    return '$count min';
  }

  @override
  String get storeFactDelivery => 'Livraison';

  @override
  String get storeFactPickup => 'Retrait possible';

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
      other: '$pickups boutiques',
      one: '1 boutique',
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
  String get orderErrorOwnStore =>
      'Tu ne peux pas commander dans ta propre boutique.';

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
  String vendorCashBodyCourier(String amount, String due) {
    return 'Le livreur DYM encaisse $amount et te remet $due, le prix des articles.';
  }

  @override
  String vendorCourierDym(String name) {
    return 'Livreur DYM : $name';
  }

  @override
  String vendorCourierExternal(String name) {
    return 'Livreur : $name';
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
    return 'Prévue vers $time';
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
  String get reasonNoResponse => 'La boutique n\'a pas répondu à temps';

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

  @override
  String get adminActive => 'Active';

  @override
  String get adminAddCategory => 'Ajouter une catégorie';

  @override
  String get adminAddCity => 'Ajouter une ville';

  @override
  String get adminAddPaymentMethod => 'Ajouter un moyen de paiement';

  @override
  String get adminAddZone => 'Ajouter un quartier';

  @override
  String get adminAfter => 'Après';

  @override
  String get adminAll => 'Toutes';

  @override
  String get adminAuditAction => 'Action';

  @override
  String get adminAuditEntity => 'Entité';

  @override
  String get adminAuditSearch => 'Rechercher (action, entité, raison)';

  @override
  String get adminAuditSubtitle =>
      'Toutes les actions de l\'équipe, en ajout seul.';

  @override
  String get adminAuditTitle => 'Journal d\'audit';

  @override
  String adminAuthorClient(String name) {
    return '$name (cliente)';
  }

  @override
  String adminAuthorVendor(String name) {
    return '$name (vendeuse)';
  }

  @override
  String adminBaseFee(String symbol) {
    return 'Frais de base $symbol';
  }

  @override
  String get adminBefore => 'Avant';

  @override
  String get adminBeforeAfter => 'Avant / après';

  @override
  String get adminCancellation => 'Annulation';

  @override
  String get adminCash => 'Cash';

  @override
  String get adminCityName => 'Nom de la ville';

  @override
  String get adminClose => 'Fermer';

  @override
  String get adminCloseNoAction => 'Clore sans suite';

  @override
  String get adminCountryChecklist =>
      'Avant d\'activer un pays : au moins une ville avec des quartiers, un moyen de paiement et des frais de livraison.';

  @override
  String get adminDecision => 'Décision';

  @override
  String get adminDeliveryMinutes => 'Délai de livraison (minutes)';

  @override
  String adminDeliveryMinutesValue(int n) {
    return 'Livraison en $n min environ';
  }

  @override
  String get adminCoverageTitle => 'Hors zone desservie';

  @override
  String get opsAutoDispatch => 'Livraison automatique';

  @override
  String get opsAutoRefuse => 'Refus automatique sans réponse (minutes)';

  @override
  String get opsRelaunch => 'Relance des livreurs (minutes)';

  @override
  String get opsRelaunchMax => 'Nombre de relances (0 : aucune)';

  @override
  String get adminDispatchTitle => 'Livraisons';

  @override
  String get adminCouriersOnline => 'Livreurs en ligne';

  @override
  String adminCouriersOnlineValue(int online, int active) {
    return '$online sur $active';
  }

  @override
  String get adminMissionsWaiting => 'Sans livreur';

  @override
  String get adminMedianAccept => 'Prise médiane';

  @override
  String adminMinutesValue(int minutes) {
    return '$minutes min';
  }

  @override
  String get adminRelaunches => 'Relances';

  @override
  String adminRelaunchesValue(int count, int widened) {
    return '$count dont $widened à toute la ville';
  }

  @override
  String get adminAutoRefused => 'Refus auto';

  @override
  String get adminReadyAlerts => 'Alertes « prête »';

  @override
  String get adminCoverageHelp =>
      'Positions d\'utilisatrices trop loin de tout quartier desservi, par pays le plus proche.';

  @override
  String get adminCoverageTotal => 'Au total';

  @override
  String adminCoverageMisses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count positions',
      one: '1 position',
    );
    return '$_temp0';
  }

  @override
  String adminCoverageMedianKm(int km) {
    return '$km km en médiane';
  }

  @override
  String get adminServiceRadiusKm => 'Rayon de service (km)';

  @override
  String adminServiceRadiusValue(int km) {
    return 'rayon de $km km';
  }

  @override
  String get adminEditCategory => 'Modifier la catégorie';

  @override
  String get adminEditCity => 'Modifier la ville';

  @override
  String get adminEditCommission => 'Modifier la commission';

  @override
  String get adminEditFees => 'Modifier les frais de livraison';

  @override
  String get adminEditStore => 'Corriger les données';

  @override
  String get adminEditZone => 'Modifier le quartier';

  @override
  String get adminExecute => 'Exécuter';

  @override
  String adminExtraPickupFee(String symbol) {
    return 'Ramassage en plus $symbol';
  }

  @override
  String adminFreeThreshold(String symbol) {
    return 'Gratuit dès $symbol';
  }

  @override
  String get adminGeographyHelp =>
      'Saisis les villes et quartiers du pays : les clientes et les vendeuses les retrouvent par recherche ou par position.';

  @override
  String get adminInternalNote =>
      'Note interne (visible par l\'équipe seulement)';

  @override
  String get adminLabelEn => 'Libellé en anglais';

  @override
  String get adminLabelFr => 'Libellé en français';

  @override
  String get adminLatitude => 'Latitude (facultatif)';

  @override
  String get adminLongitude => 'Longitude (facultatif)';

  @override
  String get adminMarkCashRefunded => 'Marquer remis en main propre';

  @override
  String get adminNavAudit => 'Journal';

  @override
  String get adminNavLive => 'En direct';

  @override
  String get adminNavAccounts => 'Comptes';

  @override
  String get adminNavConfig => 'Configuration';

  @override
  String get adminNavDisputes => 'Litiges';

  @override
  String get adminNavFinance => 'Finances';

  @override
  String get adminNoAudit => 'Aucune action.';

  @override
  String get adminNoCities => 'Aucune ville : ajoute la première.';

  @override
  String get adminNoCommission => 'Aucune commission : 0 %.';

  @override
  String get adminNoDisputes => 'Aucun litige ouvert.';

  @override
  String get adminNoFees => 'Aucun frais de livraison.';

  @override
  String get adminNoHistory => 'Aucune action de l\'équipe.';

  @override
  String get adminNoParent => 'Aucune (catégorie principale)';

  @override
  String get adminNoPaymentMethods => 'Aucun moyen de paiement.';

  @override
  String get adminNoPendingPayments => 'Aucun paiement en attente.';

  @override
  String get adminNoRefunds => 'Aucun remboursement.';

  @override
  String get adminNoStores => 'Aucune boutique.';

  @override
  String get adminOffersPickup => 'Retrait sur place';

  @override
  String get adminOnlinePayment => 'Paiement en ligne';

  @override
  String get adminOpenDisputes => 'Litiges ouverts';

  @override
  String get adminOpenDisputesCount => 'Litiges ouverts';

  @override
  String get adminOpenedOn => 'Ouverte depuis le';

  @override
  String get adminOperator => 'Opérateur (facultatif)';

  @override
  String get adminOrders7d => 'Commandes · 7 j';

  @override
  String get adminOver24h => '> 24 h';

  @override
  String adminPaidWith(String amount, String method) {
    return '$amount en $method';
  }

  @override
  String get adminParentCategory => 'Catégorie parente';

  @override
  String get adminPendingPayments => 'Paiements en attente';

  @override
  String get adminPrepMinutes => 'Préparation (minutes)';

  @override
  String get adminProvider => 'Fournisseur';

  @override
  String get adminPublishedProducts => 'Produits publiés';

  @override
  String get adminRatePercent => 'Taux (%)';

  @override
  String adminRateValue(String rate) {
    return '$rate %';
  }

  @override
  String get adminReactivateStore => 'Réactiver la boutique';

  @override
  String adminRefundAll(String amount) {
    return 'Rembourser tout ($amount)';
  }

  @override
  String get adminRefundAmount => 'Montant';

  @override
  String adminRefundMax(String amount) {
    return '$amount au plus';
  }

  @override
  String get adminRefundMethod => 'Moyen';

  @override
  String get adminRefundPart => 'Rembourser une partie';

  @override
  String get adminRefundReason => 'Motif';

  @override
  String get adminRefunds => 'Remboursements';

  @override
  String get adminRefundsDone => 'Effectués';

  @override
  String get adminRefundsFailed => 'Échoués';

  @override
  String get adminReplyHint => 'Écrire à la cliente et à la vendeuse';

  @override
  String get adminRequested => 'Demandé';

  @override
  String get adminResolve => 'Trancher le litige';

  @override
  String get adminRetry => 'Relancer';

  @override
  String get adminSales7d => 'Ventes · 7 j';

  @override
  String get adminSave => 'Enregistrer';

  @override
  String get adminSettingsSubtitle =>
      'Ouvrir un pays est une opération de configuration.';

  @override
  String get adminStoreActive => 'Active';

  @override
  String get adminStoreDescription => 'Description';

  @override
  String get adminStoreDraft => 'Brouillon';

  @override
  String get adminStoreName => 'Nom de la boutique';

  @override
  String get adminStoreSearch => 'Nom de la boutique ou de la vendeuse';

  @override
  String get adminStoreSuspended => 'Suspendue';

  @override
  String adminStoresActive(int n) {
    return 'Actives · $n';
  }

  @override
  String adminStoresDraft(int n) {
    return 'Brouillons · $n';
  }

  @override
  String adminStoresSuspended(int n) {
    return 'Suspendues · $n';
  }

  @override
  String get adminSuspendHelp =>
      'La suspension ferme la boutique et demande une raison.';

  @override
  String get adminSuspendStore => 'Suspendre la boutique';

  @override
  String get adminTabCategories => 'Catégories';

  @override
  String get adminTabCommission => 'Commission';

  @override
  String get adminTabCountries => 'Pays';

  @override
  String get adminTabFees => 'Frais de livraison';

  @override
  String get adminTabGeography => 'Villes et quartiers';

  @override
  String get adminTeamHistory => 'Historique des actions de l\'équipe';

  @override
  String get adminWarnVendor => 'Avertir la vendeuse';

  @override
  String get adminWholeCountry => 'Tout le pays';

  @override
  String get adminZoneName => 'Nom du quartier';

  @override
  String adminZoneStores(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n boutiques',
      one: '1 boutique',
      zero: 'Aucune boutique',
    );
    return '$_temp0';
  }

  @override
  String get adminPaid => 'Payée';

  @override
  String get adminAwaitingPayment => 'En attente de paiement';

  @override
  String get adminActorClient => 'Cliente';

  @override
  String get adminActorVendor => 'Vendeuse';

  @override
  String get adminActorTeam => 'Équipe';

  @override
  String get adminActorSystem => 'Système';

  @override
  String get adminAuditSignedIn => 'Connexion';

  @override
  String get adminAuditStatusForced => 'Statut forcé';

  @override
  String get adminAuditOrderCancelled => 'Commande annulée';

  @override
  String get adminAuditCourierAssigned => 'Livreur assigné';

  @override
  String get adminAuditDisputeResolved => 'Litige tranché';

  @override
  String get adminAuditRefundSucceeded => 'Remboursement effectué';

  @override
  String get adminAuditRefundFailed => 'Remboursement échoué';

  @override
  String get adminAuditStoreSuspended => 'Boutique suspendue';

  @override
  String get adminAuditStoreReactivated => 'Boutique réactivée';

  @override
  String get adminAuditStoreUpdated => 'Données corrigées';

  @override
  String get adminAuditCountryActivated => 'Pays activé';

  @override
  String get adminAuditCountryDeactivated => 'Pays désactivé';

  @override
  String get adminAuditCity => 'Ville modifiée';

  @override
  String get adminAuditZone => 'Quartier modifié';

  @override
  String get adminAuditPaymentMethod => 'Moyen de paiement modifié';

  @override
  String get adminAuditCommission => 'Commission modifiée';

  @override
  String get adminAuditDeliveryFee => 'Frais de livraison modifiés';

  @override
  String get adminAuditCategory => 'Catégorie modifiée';

  @override
  String get adminAuditRole => 'Rôle modifié';

  @override
  String get adminEntityOrder => 'Commande';

  @override
  String get adminEntityDispute => 'Litige';

  @override
  String get adminEntityRefund => 'Remboursement';

  @override
  String get adminEntityStore => 'Boutique';

  @override
  String get adminEntityCountry => 'Pays';

  @override
  String get adminEntityCity => 'Ville';

  @override
  String get adminEntityZone => 'Quartier';

  @override
  String get adminEntityPaymentMethod => 'Moyen de paiement';

  @override
  String get adminEntityCategory => 'Catégorie';

  @override
  String get adminEntityUser => 'Équipe';

  @override
  String get adminOrderClosed =>
      'Cette commande est terminée : passe par un litige.';

  @override
  String get adminPaymentPendingRefusal =>
      'Le paiement de cette commande n\'est pas encore confirmé.';

  @override
  String get adminReasonRequired =>
      'Indique une raison (3 caractères au moins).';

  @override
  String get adminCourierNotAllowed =>
      'Un livreur ne s\'assigne qu\'à une commande en cours de livraison.';

  @override
  String get adminDisputeClosed => 'Ce litige est déjà tranché.';

  @override
  String get adminRefundAmountInvalid =>
      'Montant invalide : entre 1 et le total de la commande.';

  @override
  String get adminRefundNotPending =>
      'Ce remboursement est déjà en cours ou effectué.';

  @override
  String get adminCountryNotReady =>
      'Ce pays n\'est pas prêt : complète ce qui manque.';

  @override
  String get adminProviderInactive => 'Ce fournisseur de paiement est inactif.';

  @override
  String get adminStoreStatusUnchanged => 'La boutique a déjà ce statut.';

  @override
  String adminMinutes(int n) {
    return '$n min';
  }

  @override
  String adminHoursMinutes(int h, String m) {
    return '$h h $m';
  }

  @override
  String get adminSelectItem => 'Choisis un élément dans la liste.';

  @override
  String get adminReasonLabel => 'Raison (obligatoire)';

  @override
  String get adminOrderSearch => 'N° de commande, cliente ou boutique';

  @override
  String get adminFilterAll => 'Toutes';

  @override
  String get adminFilterActive => 'En cours';

  @override
  String adminFilterStuck(int n) {
    return 'Bloquées · $n';
  }

  @override
  String get adminFilterDelivered => 'Livrées';

  @override
  String get adminFilterClosed => 'Annulées ou refusées';

  @override
  String get adminNoOrders => 'Aucune commande.';

  @override
  String get adminColNumber => 'N°';

  @override
  String get adminColStore => 'Boutique';

  @override
  String get adminColCustomer => 'Cliente';

  @override
  String get adminColStatus => 'Statut';

  @override
  String get adminColPayment => 'Paiement';

  @override
  String get adminColAmount => 'Montant';

  @override
  String get adminColSince => 'Depuis';

  @override
  String get adminStuck => 'Bloquée';

  @override
  String adminPageRange(int from, int to, int total) {
    return '$from à $to sur $total';
  }

  @override
  String get adminPrevious => 'Page précédente';

  @override
  String get adminNext => 'Page suivante';

  @override
  String get adminFirstName => 'Prénom';

  @override
  String get adminPhone => 'Téléphone';

  @override
  String get adminAddress => 'Adresse';

  @override
  String adminOrderTitle(String reference) {
    return 'Commande $reference';
  }

  @override
  String adminStuckSince(String duration) {
    return 'Bloquée depuis $duration';
  }

  @override
  String get adminOpenDispute => 'Litige ouvert';

  @override
  String get adminActorPayment => 'Paiement';

  @override
  String adminPaymentLine(String status, String method, String reference) {
    return '$status ($method, $reference)';
  }

  @override
  String adminCourierLine(String name, String phone) {
    return 'Livreur : $name · $phone';
  }

  @override
  String adminRefundLine(String amount, String status) {
    return 'Remboursement de $amount · $status';
  }

  @override
  String get adminTimeline => 'Chronologie';

  @override
  String adminNoStepSince(String duration) {
    return 'Aucune étape depuis $duration';
  }

  @override
  String adminCancelledNote(String reason) {
    return 'Annulée par l\'équipe : $reason';
  }

  @override
  String get adminRefundPending => 'À exécuter';

  @override
  String get adminRefundProcessing => 'En cours';

  @override
  String get adminRefundSucceeded => 'Effectué';

  @override
  String get adminRefundFailed => 'Échoué';

  @override
  String get adminTotal => 'Total';

  @override
  String adminCancelTitle(String reference) {
    return 'Annuler la commande $reference ?';
  }

  @override
  String get adminCancelRefund => 'Annuler et rembourser';

  @override
  String get adminCancelOrder => 'Annuler la commande';

  @override
  String get adminActions => 'Actions';

  @override
  String get adminForceStatus => 'Forcer un statut';

  @override
  String get adminChooseStatus => 'Choisis un statut';

  @override
  String get adminApply => 'Appliquer';

  @override
  String get adminExternalDelivery => 'Livraison externe';

  @override
  String get adminCourierName => 'Nom du livreur';

  @override
  String get adminAssign => 'Assigner';

  @override
  String get adminOrderPlaced => 'Commande passée';

  @override
  String get dashboardTitle => 'Ma journée';

  @override
  String get dashboardDay => 'Aujourd’hui';

  @override
  String get dashboardWeek => 'Semaine';

  @override
  String get dashboardMonth => 'Mois';

  @override
  String get dashboardRevenue => 'Ventes encaissées';

  @override
  String get dashboardRevenueExplanation =>
      'Articles livrés et payés, hors livraison, avant commission. Les remboursements sont déduits.';

  @override
  String get dashboardToDo => 'À traiter';

  @override
  String get dashboardEmpty => 'Aucune commande sur cette période.';

  @override
  String get dashboardOffline =>
      'Hors ligne : les derniers chiffres sont affichés.';

  @override
  String get dashboardRefreshFailed =>
      'Les chiffres n’ont pas pu être actualisés. Tire vers le bas pour réessayer.';

  @override
  String get dashboardRecapHint =>
      'Ton récapitulatif du jour arrive à partir de 19 h.';

  @override
  String dashboardOrderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'commandes',
      one: 'commande',
      zero: 'commande',
    );
    return '$_temp0';
  }

  @override
  String dashboardPendingPayments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'paiements attendus',
      one: 'paiement attendu',
      zero: 'paiement attendu',
    );
    return '$_temp0';
  }

  @override
  String dashboardTotals(int orders, int payments) {
    String _temp0 = intl.Intl.pluralLogic(
      orders,
      locale: localeName,
      other: '$orders commandes',
      one: '1 commande',
      zero: 'Aucune commande',
    );
    String _temp1 = intl.Intl.pluralLogic(
      payments,
      locale: localeName,
      other: '$payments paiements attendus',
      one: '1 paiement attendu',
      zero: 'aucun paiement attendu',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String dashboardNewOrders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouvelles commandes',
      one: '1 nouvelle commande',
      zero: 'Aucune nouvelle commande',
    );
    return '$_temp0';
  }

  @override
  String dashboardActiveOrders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commandes en cours',
      one: '1 commande en cours',
      zero: 'Aucune commande en cours',
    );
    return '$_temp0';
  }

  @override
  String dashboardStock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produits en rupture',
      one: '1 produit en rupture',
      zero: 'Aucun produit en rupture',
    );
    return '$_temp0';
  }

  @override
  String dashboardCritical(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages importants t’attendent',
      one: 'Une cliente attend ta réponse',
    );
    return '$_temp0';
  }

  @override
  String get dashboardCriticalAction => 'Voir les notifications';

  @override
  String get dashboardNewOrdersHint => 'Des clientes ont commandé';

  @override
  String get dashboardActiveOrdersHint => 'À préparer et livrer';

  @override
  String get dashboardStockHint =>
      'À remettre en stock pour continuer à vendre';

  @override
  String get chatMessagesTitle => 'Messages';

  @override
  String chatUnread(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n non lus',
      one: '1 non lu',
      zero: 'Tout est lu',
    );
    return '$_temp0';
  }

  @override
  String get chatEmptyList => 'Aucune conversation pour l\'instant.';

  @override
  String get chatEmptyThread => 'Écris ton premier message.';

  @override
  String get chatPhoto => 'Photo';

  @override
  String chatProductPreview(String name) {
    return 'Produit : $name';
  }

  @override
  String get chatWriteHint => 'Écris ton message…';

  @override
  String get chatSend => 'Envoyer';

  @override
  String get chatSendPhoto => 'Envoyer une photo';

  @override
  String get chatCamera => 'Prendre une photo';

  @override
  String get chatGallery => 'Choisir dans la galerie';

  @override
  String get chatShareProduct => 'Partager un produit';

  @override
  String get chatSearchProducts => 'Chercher dans mes produits';

  @override
  String get chatNoProducts => 'Aucun produit publié.';

  @override
  String get chatShare => 'Partager';

  @override
  String get chatAddToCart => 'Ajouter au panier';

  @override
  String get chatProductUnavailable => 'Ce produit n\'est plus en vente.';

  @override
  String get chatAttachProduct => 'Joindre ce produit';

  @override
  String get chatDismiss => 'Retirer';

  @override
  String get chatSendFailed => 'Message non envoyé. Réessaie.';

  @override
  String get chatOffline => 'Hors ligne : les derniers messages sont affichés.';

  @override
  String get chatWriteToStore => 'Écrire à la boutique';

  @override
  String get chatAskProduct => 'Poser une question';

  @override
  String get chatMyMessages => 'Mes messages';

  @override
  String get chatStoreUnavailable =>
      'Cette boutique n\'accepte pas de messages pour l\'instant.';

  @override
  String dashboardUnreadMessages(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n messages non lus',
      one: '1 message non lu',
      zero: 'Aucun message non lu',
    );
    return '$_temp0';
  }

  @override
  String get dashboardUnreadMessagesHint => 'Réponds à tes clientes';

  @override
  String get notifNewMessageTitle => 'Nouveau message';

  @override
  String notifNewMessageBody(String sender) {
    return '$sender t\'a écrit.';
  }

  @override
  String get reorder => 'Commander à nouveau';

  @override
  String get reorderNothing =>
      'Plus aucun article de cette commande n\'est en vente.';

  @override
  String reorderSkipped(String items) {
    return 'Plus en vente : $items';
  }

  @override
  String reviewAverage(String rating) {
    return '$rating/5';
  }

  @override
  String get reviewCommentLabel => 'Raconte en quelques mots (facultatif)';

  @override
  String reviewCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n avis',
      one: '1 avis',
      zero: 'Aucun avis',
    );
    return '$_temp0';
  }

  @override
  String get reviewEditReply => 'Modifier ma réponse';

  @override
  String get reviewExists => 'Tu as déjà donné ton avis sur cette commande.';

  @override
  String get reviewGive => 'Donner mon avis';

  @override
  String get reviewLater => 'Plus tard';

  @override
  String get reviewMine => 'Mes avis';

  @override
  String reviewMyReply(String reply) {
    return 'Ta réponse : $reply';
  }

  @override
  String get reviewNone => 'Pas encore d\'avis.';

  @override
  String get reviewNoneYet => 'Nouvelle boutique';

  @override
  String get reviewNotAllowed =>
      'Tu pourras donner ton avis après la livraison.';

  @override
  String get reviewPublish => 'Publier mon avis';

  @override
  String get reviewPublishReply => 'Publier la réponse';

  @override
  String get reviewQuestion => 'Comment s\'est passée ta commande ?';

  @override
  String get reviewReplyHint => 'Ta réponse';

  @override
  String reviewReplyTo(String name) {
    return 'Ta réponse à $name';
  }

  @override
  String reviewStarsLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n étoiles',
      one: '1 étoile',
    );
    return '$_temp0';
  }

  @override
  String reviewStoreReply(String store, String reply) {
    return 'Réponse de $store : $reply';
  }

  @override
  String get reviewStoreTitle => 'Avis';

  @override
  String get reviewTagFast => 'Livraison rapide';

  @override
  String get reviewTagFresh => 'Produits frais';

  @override
  String get reviewTagFriendly => 'Bon accueil';

  @override
  String get reviewTagWellPacked => 'Bien emballé';

  @override
  String reviewThanks(int rating) {
    return 'Merci pour ton avis ($rating/5) !';
  }

  @override
  String get reviewTitle => 'Ton avis';

  @override
  String get supportClosed => 'Fermée';

  @override
  String get supportInProgress => 'En cours';

  @override
  String get supportMine => 'Mes demandes';

  @override
  String get supportNew => 'Nouvelle demande';

  @override
  String get supportNoOrder => 'Aucune';

  @override
  String get supportNone => 'Aucune demande pour l\'instant.';

  @override
  String get supportOrder => 'Commande concernée';

  @override
  String get supportPromise => 'L\'équipe DYM te répond en moins d\'une heure.';

  @override
  String get supportSend => 'Envoyer';

  @override
  String get supportSent => 'Demande envoyée : on te répond vite.';

  @override
  String get supportSubject => 'Sujet';

  @override
  String get supportSubjectAccount => 'Mon compte';

  @override
  String get supportSubjectOrder => 'Ma commande';

  @override
  String get supportSubjectOther => 'Autre';

  @override
  String get supportSubjectPayment => 'Un paiement';

  @override
  String get supportSubjectStore => 'Ma boutique';

  @override
  String get supportDescribe => 'Décris ton problème';

  @override
  String reviewSummary(String rating, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n avis',
      one: '1 avis',
    );
    return '$rating/5 · $_temp0';
  }

  @override
  String get adminNavDashboard => 'Tableau de bord';

  @override
  String get adminNavClients => 'Clientes';

  @override
  String get adminNavSupport => 'Support';

  @override
  String get navMore => 'Plus';

  @override
  String adminPercent(int value) {
    return '$value %';
  }

  @override
  String get adminActiveOrders => 'Commandes actives';

  @override
  String get adminRevenueLabel => 'Chiffre d\'affaires';

  @override
  String get adminPaymentsSucceeded => 'Paiements réussis · 24 h';

  @override
  String adminPaymentsLastHour(String value) {
    return 'Dernière heure : $value';
  }

  @override
  String get adminDeliveriesSucceeded => 'Livraisons réussies';

  @override
  String get adminStuckOrders => 'Commandes bloquées';

  @override
  String get adminPendingDisputes => 'Litiges en attente';

  @override
  String adminLateDisputes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hors délai > 48 h',
      one: '1 hors délai > 48 h',
    );
    return '$_temp0';
  }

  @override
  String get adminOpenTickets => 'Tickets ouverts';

  @override
  String adminLateTickets(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sans réponse > 1 h',
      one: '1 sans réponse > 1 h',
    );
    return '$_temp0';
  }

  @override
  String get adminDraftStores => 'Boutiques en brouillon';

  @override
  String get adminOrders30d => 'Commandes · 30 jours';

  @override
  String get adminActiveUsers7d => 'Utilisatrices actives · 7 jours';

  @override
  String get adminNewSignups => 'Nouvelles inscriptions';

  @override
  String get adminTopStores => 'Top boutiques';

  @override
  String get adminTopCategories => 'Top catégories';

  @override
  String get adminNoData => 'Rien pour cette période.';

  @override
  String adminOrdersCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n commandes',
      one: '1 commande',
      zero: 'Aucune commande',
    );
    return '$_temp0';
  }

  @override
  String get adminClientSearch => 'Prénom ou e-mail';

  @override
  String get adminNoClients => 'Aucune cliente trouvée.';

  @override
  String adminSince(String date) {
    return 'depuis le $date';
  }

  @override
  String get adminSpent => 'Dépensé';

  @override
  String get adminTickets => 'Demandes d\'aide';

  @override
  String get adminLastOrders => 'Dernières commandes';

  @override
  String get adminAddresses => 'Adresses';

  @override
  String get adminReviewsLeft => 'Avis laissés';

  @override
  String get adminReadOnlyAudited =>
      'Consultation en lecture seule, inscrite au journal.';

  @override
  String get adminTicketsOpen => 'Ouverts';

  @override
  String get adminTicketsPending => 'En attente';

  @override
  String get adminTicketsClosed => 'Fermés';

  @override
  String get adminNoTickets => 'Aucune demande ici.';

  @override
  String get adminOver1h => '> 1 h';

  @override
  String get adminWriteReply => 'Écrire une réponse…';

  @override
  String get adminCloseTicket => 'Fermer le ticket';

  @override
  String get adminTicketInvalid => 'La réponse est vide ou trop longue.';

  @override
  String get adminTabFlags => 'Fonctionnalités';

  @override
  String get adminFlagsHelp =>
      'Les fonctions coupées restent invisibles dans les apps. Chaque changement est inscrit au journal.';

  @override
  String get adminFlagEverywhere => 'Tous les pays';

  @override
  String get adminViewAsVendor => 'Voir comme elle';

  @override
  String get adminDeleteVendor => 'Supprimer le compte';

  @override
  String get adminVendorHasOrders =>
      'Cette boutique a des commandes : suspends-la plutôt.';

  @override
  String get adminOutOfStock => 'Épuisé';

  @override
  String adminStock(int n) {
    return 'Stock : $n';
  }

  @override
  String get adminRevenue => 'Revenus';

  @override
  String get adminThisMonth => 'Ce mois';

  @override
  String get adminLastMonth => 'Mois dernier';

  @override
  String get admin30Days => '30 jours';

  @override
  String get adminSalesCollected => 'Ventes encaissées';

  @override
  String get adminCommission => 'Commission DYM';

  @override
  String get adminVendorNet => 'Net vendeuses';

  @override
  String get adminByStore => 'Par boutique';

  @override
  String get adminCommissionNote =>
      'Commission calculée par la base au moment de la commande.';

  @override
  String get adminColSales => 'Ventes';

  @override
  String get adminVendors => 'Vendeuses';

  @override
  String get voiceListening => 'Je t\'écoute…';

  @override
  String get voiceTranscribing => 'Je réfléchis…';

  @override
  String get voiceDone => 'C\'est noté.';

  @override
  String get voiceNothing =>
      'Je n\'ai rien entendu. Réessaie ou tape ta recherche.';

  @override
  String get voiceStop => 'J\'ai fini';

  @override
  String get voiceRestart => 'Recommencer';

  @override
  String get voiceHint =>
      'Parle naturellement, par exemple : « des tomates et du gombo pour ce soir »';

  @override
  String get voiceYouSaid => 'Tu as dit : ';

  @override
  String get voiceSearch => 'Chercher';

  @override
  String get voiceMicDenied =>
      'Le micro est refusé. Autorise-le dans les réglages ou tape ta recherche.';

  @override
  String get aiSearchFailed =>
      'Ça n\'a pas marché cette fois. Tape ta recherche.';

  @override
  String get searchHistory => 'Historique';

  @override
  String get searchHistoryClear => 'Effacer';

  @override
  String get searchSuggestions => 'Suggestions';

  @override
  String get photoSearchAnalyzing => 'Je regarde ta photo…';

  @override
  String get photoSearchNothing =>
      'Je n\'ai pas reconnu de produit. Essaie une autre photo ou tape ta recherche.';

  @override
  String get photoTake => 'Prendre une photo';

  @override
  String get photoFromGallery => 'Choisir dans la galerie';

  @override
  String get photoSearchYourPhoto => 'Ta photo';

  @override
  String get photoSearchFrom => 'D\'après ta photo :';

  @override
  String get photoSearchEdit => 'Modifier';

  @override
  String get photoSearchNew => 'Nouvelle photo';

  @override
  String get voiceSearchAction => 'Chercher à la voix';

  @override
  String get photoSearchAction => 'Chercher en photo';

  @override
  String get copilotTitle => 'Dis-moi ce que tu veux cuisiner';

  @override
  String get copilotEntry =>
      'Dis-moi ce que tu veux cuisiner, je compose ton panier.';

  @override
  String get homeCopilotShort => 'Composer mon panier';

  @override
  String get homeCopilotHint => 'Dis ce que tu cuisines';

  @override
  String get copilotExample =>
      'Par exemple : « Une sauce gombo pour 4 personnes ce soir »';

  @override
  String get copilotHint => 'Écris ou parle…';

  @override
  String get copilotSend => 'Envoyer';

  @override
  String get copilotThinking => 'Je compose ton panier…';

  @override
  String get copilotProposal => 'Je te propose ce panier';

  @override
  String copilotMissing(String items) {
    return 'Je n\'ai pas trouvé : $items';
  }

  @override
  String get copilotNothing => 'Je n\'ai rien trouvé pour ça.';

  @override
  String get copilotUnavailable =>
      'Le copilote ne répond pas pour l\'instant. Cherche toi-même, c\'est rapide.';

  @override
  String get copilotPlusDelivery => '+ livraison';

  @override
  String get copilotAddAll => 'Tout ajouter au panier';

  @override
  String get copilotSearchMyself => 'Chercher moi-même';

  @override
  String copilotRemove(String name) {
    return 'Retirer $name';
  }

  @override
  String copilotRefused(String items) {
    return 'Plus disponible, pas ajouté : $items';
  }

  @override
  String get actionClose => 'Fermer';

  @override
  String get adminNavModeration => 'Modération';

  @override
  String get navVideos => 'Vidéos';

  @override
  String get feedForYou => 'Pour toi';

  @override
  String get feedFollowing => 'Abonnements';

  @override
  String get feedEmpty => 'Pas encore de vidéo dans ton quartier.';

  @override
  String get feedEmptyFollowing =>
      'Les vidéos des boutiques où tu as commandé apparaîtront ici.';

  @override
  String get feedAdd => 'Ajouter';

  @override
  String feedAdded(String name) {
    return '$name est dans ton panier.';
  }

  @override
  String get feedLike => 'J\'aime';

  @override
  String get storiesTitle => 'Statuts des boutiques';

  @override
  String storyAddProduct(String name) {
    return 'Ajouter $name';
  }

  @override
  String productVideos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Voir en vidéo ($n)',
      one: 'Voir en vidéo',
    );
    return '$_temp0';
  }

  @override
  String get reportAction => 'Signaler';

  @override
  String get reportTitle => 'Pourquoi signaler ?';

  @override
  String get reportMisleading => 'Contenu trompeur';

  @override
  String get reportOffensive => 'Propos insultants';

  @override
  String get reportForbidden => 'Produit interdit';

  @override
  String get reportSpam => 'Spam';

  @override
  String get reportOther => 'Autre';

  @override
  String get contentMine => 'Mes statuts et vidéos';

  @override
  String get contentPublishTitle => 'Publier';

  @override
  String get contentStory => 'Statut 24 h';

  @override
  String get contentVideo => 'Vidéo';

  @override
  String get contentPickStory =>
      'Filme ou choisis une photo ou une courte vidéo.';

  @override
  String get contentPickVideo =>
      'Filme ou choisis une vidéo de 60 secondes au plus.';

  @override
  String get contentVideoReady => 'Vidéo prête';

  @override
  String get contentFilm => 'Filmer';

  @override
  String get contentGallery => 'Galerie';

  @override
  String get contentTagged => 'Produits tagués';

  @override
  String get contentNoProducts =>
      'Publie d\'abord un produit pour pouvoir le taguer.';

  @override
  String get contentTagLimit => '5 produits au plus.';

  @override
  String get contentCaption => 'Légende (facultatif)';

  @override
  String get contentPublishStory => 'Publier le statut';

  @override
  String get contentPublishVideo => 'Publier la vidéo';

  @override
  String get contentStoryHint => 'Visible 24 h par les clientes de ta zone.';

  @override
  String get contentVideoHint => 'Visible dans le fil des clientes de ta zone.';

  @override
  String get contentNone => 'Pas encore de statut ni de vidéo.';

  @override
  String get contentArchived => 'Archivé';

  @override
  String contentStats(int views, int clicks, int likes) {
    return '$views vues · $clicks clics · $likes j\'aime';
  }

  @override
  String get contentActions => 'Actions';

  @override
  String get contentArchive => 'Archiver';

  @override
  String get contentDelete => 'Supprimer';

  @override
  String get moderationOpen => 'Signalés';

  @override
  String get moderationDecided => 'Traités';

  @override
  String get moderationEmpty => 'Aucun signalement.';

  @override
  String moderationReports(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n signalements',
      one: '1 signalement',
    );
    return '$_temp0';
  }

  @override
  String get moderationKept => 'Gardé';

  @override
  String get moderationRemoved => 'Retiré';

  @override
  String get moderationVideo => 'Vidéo';

  @override
  String get moderationStory => 'Statut';

  @override
  String get moderationProduct => 'Produit';

  @override
  String get moderationReview => 'Avis';

  @override
  String get moderationPreview => 'Aperçu du signalement';

  @override
  String get moderationCaption => 'Légende';

  @override
  String get moderationTagged => 'Produits tagués';

  @override
  String get moderationReason => 'Motif';

  @override
  String get moderationDecision => 'Décision';

  @override
  String get moderationReasonRequired => 'Raison (obligatoire)';

  @override
  String get moderationKeep => 'Garder';

  @override
  String get moderationRemove => 'Retirer';

  @override
  String get adminDashboardOverview => 'Vue générale';

  @override
  String get adminDashboardAi => 'IA et paiements';

  @override
  String get aiUnderstood => 'Requêtes comprises';

  @override
  String get aiLatency => 'Latence moyenne';

  @override
  String aiSeconds(double value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String valueString = valueNumberFormat.format(value);

    return '$valueString s';
  }

  @override
  String get aiFallback => 'Passages à la recherche classique';

  @override
  String get adminPaymentsSucceeded1h => 'Paiements réussis';

  @override
  String get ai24h => '24 h';

  @override
  String get ai1h => '1 h';

  @override
  String get aiSeries => 'Compréhension · 7 jours';

  @override
  String get aiMisses => 'Dernières requêtes non comprises';

  @override
  String get aiOutcomeNoResult => 'Aucun résultat';

  @override
  String get aiOutcomeFailure => 'Panne';

  @override
  String get aiUsageVoice => 'Voix';

  @override
  String get aiUsagePhoto => 'Photo';

  @override
  String get aiUsageText => 'Texte';

  @override
  String get aiNoPersonalData =>
      'Aucune donnée personnelle affichée ni liée à ces requêtes.';

  @override
  String aiPaymentsAlert(String value) {
    return 'Alerte : seulement $value de paiements réussis sur la dernière heure.';
  }

  @override
  String get broadcastTitle => 'Relancer mes clientes';

  @override
  String get broadcastEntry => 'Relancer mes clientes';

  @override
  String get broadcastAudience => 'Choisir mes destinataires';

  @override
  String get broadcastRegular => 'Clientes régulières';

  @override
  String get broadcastRegularHint => '2 commandes ou plus';

  @override
  String get broadcastMonth => 'Clientes du mois';

  @override
  String get broadcastAll => 'Toutes mes clientes';

  @override
  String get broadcastMessage => 'Mon message';

  @override
  String get broadcastMessageHint => 'Gombo frais arrivé ce matin…';

  @override
  String get broadcastAttach => 'Joindre un produit (facultatif)';

  @override
  String get broadcastNoProduct => 'Aucun produit';

  @override
  String get broadcastRules =>
      'Une relance par jour au plus. Les clientes peuvent couper ces messages.';

  @override
  String broadcastSend(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Envoyer à $n clientes',
      one: 'Envoyer à 1 cliente',
      zero: 'Aucune cliente à prévenir',
    );
    return '$_temp0';
  }

  @override
  String broadcastSent(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Message envoyé à $n clientes.',
      one: 'Message envoyé à 1 cliente.',
    );
    return '$_temp0';
  }

  @override
  String get broadcastDailyLimit =>
      'Tu as déjà relancé tes clientes aujourd\'hui. Réessaie demain.';

  @override
  String get lowStockTitle => 'Alerte stock bas';

  @override
  String get lowStockEnabled => 'Me prévenir quand un produit s\'épuise';

  @override
  String get lowStockThreshold => 'Seuil';

  @override
  String lowStockUnder(int n) {
    return 'Me prévenir sous $n unités';
  }

  @override
  String get accountEditName => 'Modifier mon prénom';

  @override
  String get accountSave => 'Enregistrer';

  @override
  String get adminTabAdmins => 'Admins';

  @override
  String get adminAdminsHelp =>
      'Les admins par défaut viennent de la variable ADMIN_EMAILS. Un email invité devient admin à sa première connexion à DYM Admin.';

  @override
  String get adminAdminsInvite => 'Inviter';

  @override
  String get adminAdminsDefault => 'Par défaut';

  @override
  String get adminAdminsActive => 'Actif';

  @override
  String get adminAdminsPending => 'Invitation en attente';

  @override
  String get adminAdminsRemove => 'Retirer l’accès admin';

  @override
  String get authPasswordLabel => 'Mot de passe';

  @override
  String get authSignInPassword => 'Se connecter';

  @override
  String get authUsePassword => 'J’ai un mot de passe';

  @override
  String get authUseCode => 'Recevoir un code à la place';

  @override
  String get authPasswordWrong => 'Email ou mot de passe incorrect.';

  @override
  String get contentMediaMode => 'Photo ou vidéo';

  @override
  String get contentTextMode => 'Écrire un statut';

  @override
  String get contentTextLabel => 'Ton message';

  @override
  String get contentTextHint => 'Écris ton statut…';

  @override
  String get accountWallet => 'Mon wallet';

  @override
  String get walletTitle => 'Mon wallet';

  @override
  String get walletAvailable => 'Disponible';

  @override
  String walletTotal(String amount) {
    return 'Total avec les poches : $amount';
  }

  @override
  String get walletTopup => 'Recharger';

  @override
  String get walletTopupSimulated =>
      'Recharge simulée : aucun argent réel n\'est débité.';

  @override
  String get walletMove => 'Déplacer';

  @override
  String get walletPockets => 'Mes poches';

  @override
  String get walletNewPocket => 'Nouvelle poche';

  @override
  String get walletPocketsEmpty =>
      'Crée une poche pour mettre de côté : courses du mois, fêtes, précommandes.';

  @override
  String walletPocketGoal(String amount) {
    return 'Objectif $amount';
  }

  @override
  String walletPocketRoundUp(String amount) {
    return 'Arrondi à $amount';
  }

  @override
  String get walletPocketArchive => 'Fermer la poche';

  @override
  String get walletMovements => 'Mouvements';

  @override
  String get walletMovementsEmpty => 'Aucun mouvement pour l\'instant.';

  @override
  String get walletKindTopup => 'Recharge';

  @override
  String get walletKindTransfer => 'Transfert entre poches';

  @override
  String get walletKindPayment => 'Paiement d\'une commande';

  @override
  String get walletKindRefund => 'Remboursement';

  @override
  String get walletKindCashback => 'Cashback';

  @override
  String get walletKindOther => 'Mouvement';

  @override
  String get walletAmount => 'Montant';

  @override
  String get walletPocketName => 'Nom de la poche';

  @override
  String get walletPocketGoalField => 'Objectif (facultatif)';

  @override
  String get walletPocketRoundUpField =>
      'Arrondir chaque paiement à (facultatif)';

  @override
  String get walletFrom => 'Depuis';

  @override
  String get walletTo => 'Vers';

  @override
  String get walletMain => 'Wallet';

  @override
  String get walletConfirm => 'Valider';

  @override
  String get walletErrorInsufficient => 'Solde insuffisant.';

  @override
  String get walletErrorAmount => 'Montant invalide.';

  @override
  String get walletErrorTopupDisabled =>
      'La recharge n\'est pas disponible ici.';

  @override
  String get walletErrorPocketLimit =>
      'Tu as atteint le nombre maximum de poches.';

  @override
  String get orderErrorWalletInsufficient =>
      'Solde du wallet insuffisant : recharge-le ou choisis un autre moyen.';

  @override
  String walletToPocket(String name) {
    return 'Vers $name';
  }

  @override
  String walletFromPocket(String name) {
    return 'Depuis $name';
  }

  @override
  String cartDeliveryTo(String zone, String landmark) {
    return '$zone · $landmark';
  }

  @override
  String get cartAddAddress => 'Ajoute une adresse de livraison';

  @override
  String get homeWhatToEat => 'Qu\'est-ce qu\'on mange ?';

  @override
  String get homePopular => 'Les plus demandés près de toi';

  @override
  String get homeFresh => 'Nouveautés';

  @override
  String get homeReorderTitle => 'Recommander tes courses';

  @override
  String homeReorderMeta(String store, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
    );
    return '$store · $_temp0';
  }

  @override
  String get homeReorderAction => 'Recommander';

  @override
  String get copilotReasonSameStore => 'Même boutique : un seul ramassage';

  @override
  String get copilotReasonOpenNow => 'Boutique ouverte maintenant';

  @override
  String get copilotReasonTopRated => 'Boutique la mieux notée';

  @override
  String get copilotReasonBestPrice => 'Le meilleur prix';

  @override
  String get copilotReasonNearby => 'Boutique de ton quartier';

  @override
  String get copilotReasonBestMatch => 'Correspond le mieux à ta demande';

  @override
  String get adminTabSearch => 'Recherche';

  @override
  String get adminRankingHelp =>
      'Poids de 0 à 100 utilisés pour choisir les produits proposés par l\'assistant. Plus un poids est fort, plus le critère compte.';

  @override
  String get adminEditRanking => 'Modifier les poids';

  @override
  String get adminWeightText => 'Correspondance au texte';

  @override
  String get adminWeightSameStore => 'Même boutique (moins de ramassages)';

  @override
  String get adminWeightOpen => 'Boutique ouverte';

  @override
  String get adminWeightRating => 'Note de la boutique';

  @override
  String get adminWeightPrice => 'Prix bas';

  @override
  String get adminWeightSameZone => 'Boutique du quartier';

  @override
  String get adminSynonymsTitle => 'Noms locaux';

  @override
  String get adminAddSynonym => 'Ajouter un nom local';

  @override
  String get adminSynonymTerm => 'Nom local (ex. gboma)';

  @override
  String get adminSynonymList => 'Équivalents, séparés par des virgules';

  @override
  String adminRemoveSynonym(String term) {
    return 'Retirer $term';
  }

  @override
  String get shoppingTitle => 'Mes courses';

  @override
  String get shoppingHomeTile => 'Mes listes de courses';

  @override
  String get shoppingHomeTileHint => 'Refais tes courses en un geste';

  @override
  String get shoppingIntro =>
      'Rien n\'est commandé sans toi : l\'assistant compose, tu vérifies et tu ajoutes au panier.';

  @override
  String get shoppingEmpty =>
      'Pas encore de liste. Crée « Courses du samedi », « Petit-déjeuner »… et l\'assistant composera ton panier.';

  @override
  String get shoppingNew => 'Nouvelle liste';

  @override
  String get shoppingFromHabits => 'Ma liste habituelle';

  @override
  String get shoppingFromHabitsHint => 'Ce que tu achètes souvent';

  @override
  String get shoppingNoHabits =>
      'Pas encore d\'habitudes : il faut avoir commandé au moins deux fois le même produit.';

  @override
  String get shoppingDescribe => 'Décrire mes courses';

  @override
  String get shoppingDescribeHint => 'Ex. la semaine pour 4 personnes';

  @override
  String get shoppingDescribeAction => 'Proposer une liste';

  @override
  String get shoppingAiUnavailable =>
      'L\'assistant ne répond pas. Tu peux créer ta liste à la main.';

  @override
  String get shoppingAiNothing =>
      'Je n\'ai rien trouvé à proposer. Essaie avec d\'autres mots.';

  @override
  String shoppingItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
    );
    return '$_temp0';
  }

  @override
  String get shoppingNoRepeat => 'Pas de rappel';

  @override
  String get shoppingEvery7 => 'Chaque semaine';

  @override
  String get shoppingEvery14 => 'Toutes les 2 semaines';

  @override
  String get shoppingEvery30 => 'Chaque mois';

  @override
  String shoppingNextOn(String date) {
    return 'Prochain rappel : $date';
  }

  @override
  String get shoppingOpen => 'Composer mon panier';

  @override
  String shoppingMore(String name) {
    return 'Plus d\'actions pour $name';
  }

  @override
  String get shoppingEdit => 'Modifier';

  @override
  String get shoppingDelete => 'Supprimer';

  @override
  String shoppingDeleteConfirm(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get shoppingDeleted => 'Liste supprimée';

  @override
  String get shoppingEditTitle => 'Ma liste';

  @override
  String get shoppingName => 'Nom de la liste';

  @override
  String get shoppingNameHint => 'Ex. Courses du samedi';

  @override
  String get shoppingItemsTitle => 'Articles';

  @override
  String get shoppingItemHint => 'Ajouter un article (tomates, riz…)';

  @override
  String get shoppingAddItem => 'Ajouter';

  @override
  String shoppingRemoveItem(String name) {
    return 'Retirer $name';
  }

  @override
  String shoppingLess(String name) {
    return 'Un de moins : $name';
  }

  @override
  String shoppingMoreQty(String name) {
    return 'Un de plus : $name';
  }

  @override
  String get shoppingRepeatTitle => 'Me rappeler';

  @override
  String shoppingStartsOn(String date) {
    return 'Premier rappel le $date';
  }

  @override
  String get shoppingPickDate => 'Changer la date';

  @override
  String get shoppingRepeatNote =>
      'Le jour venu, à 8 h, on te prévient : tu vérifies et tu valides.';

  @override
  String get shoppingSave => 'Enregistrer la liste';

  @override
  String get shoppingSaved => 'Liste enregistrée';

  @override
  String get shoppingErrorName => 'Donne un nom à ta liste.';

  @override
  String get shoppingErrorItems => 'Ajoute au moins un article.';

  @override
  String get shoppingErrorTooMany => '20 listes au plus : supprimes-en une.';

  @override
  String get shoppingErrorTooManyItems => '20 articles au plus par liste.';

  @override
  String get notifShoppingDueTitle => 'Tes courses sont prêtes';

  @override
  String notifShoppingDueBody(String name) {
    return '« $name » : vérifie et valide ton panier.';
  }

  @override
  String get favoriteAdd => 'Ajouter aux favoris';

  @override
  String get favoriteRemove => 'Retirer des favoris';

  @override
  String get favoritesTitle => 'Mes favoris';

  @override
  String get favoritesStores => 'Boutiques';

  @override
  String get favoritesProducts => 'Produits';

  @override
  String get favoritesEmpty =>
      'Touche le cœur d\'une boutique ou d\'un produit pour le retrouver ici.';

  @override
  String get basketsTitle => 'Mes paniers';

  @override
  String get basketsEmpty =>
      'Enregistre ton panier (petit-déjeuner, déjeuner, le mois…) depuis le panier pour le refaire en un geste.';

  @override
  String get basketSave => 'Enregistrer ce panier';

  @override
  String get basketSaveAction => 'Enregistrer';

  @override
  String get basketName => 'Nom du panier';

  @override
  String get basketNameHint => 'Ex. Petit-déjeuner';

  @override
  String get basketSaved =>
      'Panier enregistré : retrouve-le dans « Mes paniers ».';

  @override
  String get basketToCart => 'Remettre au panier';

  @override
  String basketMeta(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
    );
    return '$_temp0 · $total aujourd\'hui';
  }

  @override
  String basketUnavailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles indisponibles',
      one: '1 article indisponible',
    );
    return '$_temp0';
  }

  @override
  String basketSkipped(String items) {
    return 'Pas ajouté (plus disponible) : $items';
  }

  @override
  String basketMore(String name) {
    return 'Plus d\'actions pour $name';
  }

  @override
  String get basketRename => 'Renommer';

  @override
  String get basketDelete => 'Supprimer';

  @override
  String basketDeleteConfirm(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get basketErrorEmpty => 'Ton panier est vide.';

  @override
  String get basketErrorTooMany =>
      '20 paniers de 50 articles au plus : supprimes-en un.';

  @override
  String get basketErrorName => 'Donne un nom à ton panier.';

  @override
  String get accountFavorites => 'Mes favoris';

  @override
  String get accountBaskets => 'Mes paniers';

  @override
  String get spacesTitle => 'Mes espaces';

  @override
  String get spacesIntro =>
      'Un espace réunit ceux qui remplissent et ceux qui valident et paient : la maison, la famille au pays, une tontine…';

  @override
  String get spacesEmpty =>
      'Pas encore d\'espace. Crée-en un ou rejoins celui d\'un proche avec son code.';

  @override
  String get spaceCreate => 'Créer un espace';

  @override
  String get spaceCreateAction => 'Créer';

  @override
  String get spaceJoin => 'Rejoindre';

  @override
  String get spaceJoinAction => 'Rejoindre';

  @override
  String get spaceCodeHint => 'Code reçu (8 caractères)';

  @override
  String get spaceName => 'Nom de l\'espace';

  @override
  String get spaceNameHint => 'Ex. Maison, Famille à Kpalimé';

  @override
  String get spaceBudget => 'Budget du mois (facultatif)';

  @override
  String get spaceBudgetHint => 'Ex. 50 000';

  @override
  String spaceMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '1 membre',
    );
    return '$_temp0';
  }

  @override
  String get spaceRolePayer => 'Valide et paie';

  @override
  String get spaceRoleMember => 'Remplit';

  @override
  String get spaceOwner => 'Responsable · valide et paie';

  @override
  String spaceMe(String name) {
    return '$name (moi)';
  }

  @override
  String spaceManage(String name) {
    return 'Gérer $name';
  }

  @override
  String get spaceMakePayer => 'Peut valider et payer';

  @override
  String get spaceMakeMember => 'Remplit seulement';

  @override
  String get spaceRemoveMember => 'Retirer de l\'espace';

  @override
  String get spaceMembers => 'Membres';

  @override
  String get spaceBasket => 'Panier commun';

  @override
  String get spaceSendCart => 'Envoyer mon panier';

  @override
  String get spaceBasketEmpty =>
      'Vide pour l\'instant : chacun remplit son panier comme d\'habitude, puis l\'envoie ici.';

  @override
  String spaceTotal(String total) {
    return 'Total : $total + livraison';
  }

  @override
  String get spaceValidate => 'Valider et passer au panier';

  @override
  String get spaceWaitPayer => 'Une personne qui valide passera la commande.';

  @override
  String get spaceDelete => 'Supprimer l\'espace';

  @override
  String get spaceLeave => 'Quitter l\'espace';

  @override
  String spaceDeleteConfirm(String name) {
    return 'Supprimer « $name » pour tous ?';
  }

  @override
  String spaceLeaveConfirm(String name) {
    return 'Quitter « $name » ?';
  }

  @override
  String get spaceBudgetTitle => 'Budget du mois';

  @override
  String spaceBudgetMeta(String spent, String budget, String left) {
    return '$spent dépensés sur $budget · reste $left';
  }

  @override
  String get spaceInvite => 'Code pour inviter';

  @override
  String get spaceCopyCode => 'Copier le code';

  @override
  String get spaceCodeCopied => 'Code copié : envoie-le à tes proches.';

  @override
  String spaceAddedBy(String name) {
    return 'ajouté par $name';
  }

  @override
  String get spaceUnavailable => 'indisponible';

  @override
  String get spaceSendCartTitle => 'Envoyer mon panier à…';

  @override
  String get spaceSendToSpace => 'Envoyer à un espace';

  @override
  String spaceCartSent(String name) {
    return 'Panier envoyé à « $name ».';
  }

  @override
  String get spaceErrorName => 'Donne un nom à l\'espace.';

  @override
  String get spaceErrorBudget => 'Budget invalide.';

  @override
  String get spaceErrorUnknownCode => 'Code inconnu : vérifie-le.';

  @override
  String get spaceErrorOtherCountry => 'Cet espace est dans un autre pays.';

  @override
  String get spaceErrorFull => 'Cet espace a déjà 20 membres.';

  @override
  String get spaceErrorTooMany => '20 espaces au plus.';

  @override
  String get spaceErrorCartEmpty => 'Rien à envoyer ou à valider.';

  @override
  String get spaceErrorBudgetExceeded => 'Ce panier dépasse le budget du mois.';

  @override
  String get spaceErrorNotPayer =>
      'Seule une personne qui valide peut le faire.';

  @override
  String get accountSpaces => 'Mes espaces';

  @override
  String get notifSpaceValidatedTitle => 'Panier commun validé';

  @override
  String notifSpaceValidatedBody(String name, String space) {
    return '$name a validé le panier de « $space ».';
  }

  @override
  String get spacePocket => 'Poche commune';

  @override
  String get spaceContribute => 'Verser';

  @override
  String get spaceContributeTitle => 'Verser depuis mon wallet';

  @override
  String spaceContributedMonth(String amount) {
    return 'a versé $amount ce mois';
  }

  @override
  String get spaceUsePocket => 'Payer avec la poche commune';

  @override
  String get spaceUsePocketHint =>
      'Le montant des articles passe sur ton wallet : choisis « Wallet DYM » pour payer.';

  @override
  String get spaceErrorPocketInsufficient =>
      'La poche commune ne suffit pas pour ce panier.';

  @override
  String get spaceErrorSpaceBalance =>
      'La poche commune n\'est pas vide : utilise-la d\'abord.';

  @override
  String get walletKindSpaceContribution => 'Versé à un espace';

  @override
  String get walletKindSpacePayout => 'Reçu d\'un espace';

  @override
  String get slotTitle => 'Quand ?';

  @override
  String get slotAsap => 'Dès que possible';

  @override
  String get slotToday => 'Aujourd\'hui';

  @override
  String get slotTomorrow => 'Demain';

  @override
  String slotWindow(String start, String end) {
    return '$start–$end';
  }

  @override
  String slotRequiredFrom(String date) {
    return 'Ton panier contient un arrivage : livraison à partir du $date.';
  }

  @override
  String get orderErrorSlotRequired => 'Choisis un créneau de livraison.';

  @override
  String get orderErrorSlotInvalid =>
      'Ce créneau n\'est plus possible : choisis-en un autre.';

  @override
  String get orderErrorSlotClosed =>
      'Une boutique est fermée à ce créneau : choisis-en un autre.';

  @override
  String orderScheduled(String day, String start, String end) {
    return 'Prévue $day, $start–$end';
  }

  @override
  String productArrivalBadge(String date) {
    return 'Arrivage le $date · prix bloqué';
  }

  @override
  String productArrivalOn(String date) {
    return 'Arrive le $date · précommandes ouvertes';
  }

  @override
  String get productArrivalSet => 'Indiquer un arrivage';

  @override
  String get productArrivalClear => 'Retirer l\'arrivage';

  @override
  String get productArrivalHint =>
      'Date d\'arrivée : les clientes précommandent à prix bloqué';

  @override
  String vendorOrderScheduled(String day, String start, String end) {
    return 'À livrer $day, $start–$end';
  }

  @override
  String get adjustTitle => 'Remplacements et fraîcheur';

  @override
  String adjustProposed(String item, String proposed) {
    return '$item manque : la vendeuse propose $proposed, même prix.';
  }

  @override
  String adjustAccepted(String item, String proposed) {
    return '$item remplacé par $proposed.';
  }

  @override
  String adjustRefused(String item, String amount) {
    return '$item retiré : $amount rendus sur ton wallet.';
  }

  @override
  String adjustFreshness(String item, String amount) {
    return '$item pas frais : $amount rendus sur ton wallet.';
  }

  @override
  String get adjustAccept => 'Accepter';

  @override
  String get adjustRefuse => 'Refuser et être remboursée';

  @override
  String adjustCreditedNow(String amount) {
    return '$amount sont déjà sur ton wallet.';
  }

  @override
  String get freshnessClaim => 'Un article n\'est pas frais ?';

  @override
  String get freshnessHint =>
      'Garantie fraîcheur : envoie une photo, tu es remboursée tout de suite sur ton wallet.';

  @override
  String get freshnessWhich => 'Quel article ?';

  @override
  String get freshnessWindowClosed =>
      'Le délai de la garantie est passé : utilise « Signaler un problème ».';

  @override
  String get freshnessLimitReached =>
      'Limite du mois atteinte : utilise « Signaler un problème », l\'équipe regarde.';

  @override
  String get freshnessAlreadyCredited => 'Cet article a déjà été remboursé.';

  @override
  String get notifSubstitutionTitle => 'Un remplacement est proposé';

  @override
  String notifSubstitutionBody(String item, String proposed) {
    return '$item manque : la vendeuse propose $proposed.';
  }

  @override
  String get vendorSubstituteTitle => 'Un article manque ?';

  @override
  String get vendorSubstituteHint =>
      'Propose un autre produit avec une photo : même quantité, même prix. La cliente valide.';

  @override
  String vendorSubstitute(String item) {
    return 'Remplacer $item';
  }

  @override
  String vendorSubstituteLine(String item, String proposed) {
    return '$item → $proposed';
  }

  @override
  String get vendorSubstituteWaiting => 'En attente de la cliente';

  @override
  String get vendorSubstituteAccepted => 'Acceptée';

  @override
  String get vendorSubstituteRefunded => 'Remboursée à la cliente';

  @override
  String vendorFreshnessClaimed(String item) {
    return '$item signalé pas frais';
  }

  @override
  String get vendorSubstituteNone =>
      'Aucun autre produit disponible dans ta boutique.';

  @override
  String get vendorSubstituteNote => 'Un mot pour la cliente (facultatif)';

  @override
  String get chatVoiceRecord => 'Enregistrer un vocal';

  @override
  String get chatVoiceRecording => 'Enregistrement… (60 s au plus)';

  @override
  String get chatVoiceSend => 'Envoyer le vocal';

  @override
  String get chatVoiceCancel => 'Annuler le vocal';

  @override
  String get chatVoicePlay => 'Écouter';

  @override
  String get chatVoiceStop => 'Arrêter';

  @override
  String chatVoiceDuration(int seconds) {
    return '$seconds s';
  }

  @override
  String get callAudio => 'Appeler';

  @override
  String get callVideo => 'Appel vidéo « Montre-moi »';

  @override
  String get callRinging => 'Ça sonne…';

  @override
  String get callIncoming => 'Appel entrant';

  @override
  String get callOngoing => 'En communication';

  @override
  String get callDeclined => 'Appel refusé';

  @override
  String get callMissed => 'Appel manqué';

  @override
  String get callEnded => 'Appel terminé';

  @override
  String get callUnavailable => 'Appel impossible pour l\'instant.';

  @override
  String get callSimulated =>
      'Appel simulé : la voix et l\'image passeront par le vrai service avant la mise en production.';

  @override
  String get callAnswer => 'Décrocher';

  @override
  String get callDecline => 'Refuser';

  @override
  String get callHangUp => 'Raccrocher';

  @override
  String get callClose => 'Fermer';

  @override
  String get callOpen => 'Voir';

  @override
  String callIncomingFrom(String name) {
    return '$name t\'appelle';
  }

  @override
  String callSummaryEnded(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '1 min',
    );
    return 'Appel · $_temp0';
  }

  @override
  String get accountCreator => 'Créer et partager';

  @override
  String get creatorTitle => 'Studio créatrice';

  @override
  String get creatorIntro =>
      'Partage tes recettes, tes astuces et tes trouvailles du marché. Tague les produits : on les achète d\'un geste.';

  @override
  String get creatorName => 'Nom de créatrice';

  @override
  String get creatorNameHint => 'Ex. Awa cuisine';

  @override
  String get creatorBio => 'Courte présentation (facultatif)';

  @override
  String get creatorBecome => 'Ouvrir mon studio';

  @override
  String get creatorErrorName => 'Ton nom de créatrice : 2 à 40 caractères.';

  @override
  String get creatorErrorMedia =>
      'Ce média ne peut pas être publié : choisis-en un autre.';

  @override
  String get creatorNewPost => 'Nouveau post';

  @override
  String get creatorMyPosts => 'Mes posts';

  @override
  String get creatorNoPost =>
      'Pas encore de post : partage ta première recette !';

  @override
  String creatorPostStats(int views, int clicks, int tags) {
    String _temp0 = intl.Intl.pluralLogic(
      views,
      locale: localeName,
      other: '$views vues',
      one: '1 vue',
      zero: '0 vue',
    );
    String _temp1 = intl.Intl.pluralLogic(
      clicks,
      locale: localeName,
      other: '$clicks clics',
      one: '1 clic',
      zero: '0 clic',
    );
    String _temp2 = intl.Intl.pluralLogic(
      tags,
      locale: localeName,
      other: '$tags produits',
      one: '1 produit',
    );
    return '$_temp0 · $_temp1 · $_temp2';
  }

  @override
  String get creatorArchive => 'Archiver';

  @override
  String get creatorPickVideo => 'Vidéo (60 s)';

  @override
  String get creatorCaption => 'Légende';

  @override
  String get creatorCaptionHint => 'Ex. Ma sauce gombo du dimanche';

  @override
  String get creatorCategory => 'Catégorie';

  @override
  String get creatorSuggestCategory => 'Laisser l\'IA choisir';

  @override
  String get creatorCategoryHint => 'Sans choix, ton post va dans « Autre ».';

  @override
  String creatorTagProducts(int count, int max) {
    return 'Produits tagués ($count/$max)';
  }

  @override
  String get creatorSearchProducts => 'Chercher un produit à taguer';

  @override
  String get creatorPublish => 'Publier';

  @override
  String get feedGrid => 'Vue en grille';

  @override
  String get feedFullScreen => 'Plein écran';

  @override
  String get feedAllCategories => 'Tout';

  @override
  String get feedFollow => 'S\'abonner';

  @override
  String get feedFollowingOne => 'Abonnée';

  @override
  String get feedComments => 'Commentaires';

  @override
  String get feedNoComment =>
      'Pas encore de commentaire : lance la conversation !';

  @override
  String get feedCommentHint => 'Ajouter un commentaire';

  @override
  String get feedDeleteComment => 'Supprimer mon commentaire';

  @override
  String get moderationComment => 'Commentaire';

  @override
  String get recipeIngredients => 'Ingrédients';

  @override
  String get recipeFindIngredients => 'Repérer avec l\'IA';

  @override
  String get recipeAddIngredient => 'Ajouter un ingrédient (tomate, gombo…)';

  @override
  String get recipeAllForIt => 'Tout pour la recette';

  @override
  String get feedInThisVideo => 'Dans cette vidéo';

  @override
  String feedProductCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produits',
      one: '1 produit',
    );
    return '$_temp0';
  }

  @override
  String get feedCreator => 'Créatrice';

  @override
  String get feedSeeCart => 'Voir';

  @override
  String recipeAllForTotal(String total) {
    return 'Tout pour la recette · $total';
  }

  @override
  String recipeForPeople(int count) {
    return 'pour $count';
  }

  @override
  String recipeServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pour $count personnes',
      one: 'Pour 1 personne',
    );
    return '$_temp0';
  }

  @override
  String get recipeServingsLess => 'Une personne de moins';

  @override
  String get recipeServingsMore => 'Une personne de plus';

  @override
  String recipeAddLines(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ajouter $count articles',
      one: 'Ajouter 1 article',
    );
    return '$_temp0 · $total';
  }

  @override
  String recipeAddSome(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ajouter $count articles',
      one: 'Ajouter 1 article',
    );
    return '$_temp0';
  }

  @override
  String recipeAddedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles ajoutés au panier',
      one: '1 article ajouté au panier',
    );
    return '$_temp0';
  }

  @override
  String recipeStores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count boutiques',
      one: '1 boutique',
    );
    return '$_temp0 · livraison calculée au panier';
  }

  @override
  String get creatorEarnings => 'Mes gains';

  @override
  String get creatorEarningsPending => 'En attente';

  @override
  String get creatorEarningsPaid => 'Versés sur mon wallet';

  @override
  String get creatorEarningsHint =>
      'Quand une cliente achète depuis ton contenu, tu touches une commission à la livraison.';

  @override
  String get creatorEarningsEmpty =>
      'Tague des produits ou ajoute les ingrédients : chaque achat livré depuis ton post te rapporte une commission.';

  @override
  String get creatorCommissionPending => 'En attente de livraison';

  @override
  String get creatorCommissionPaid => 'Versée';

  @override
  String get creatorCommissionCancelled => 'Annulée (commande non livrée)';

  @override
  String get walletKindAffiliate => 'Commission de créatrice';

  @override
  String get affiliateRateTitle => 'Commission des créatrices';

  @override
  String affiliatePercent(double value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return '$valueString %';
  }

  @override
  String affiliateRateHint(String min) {
    return 'Versée sur chaque vente livrée venue du contenu d\'une créatrice. Minimum du pays : $min.';
  }

  @override
  String get affiliateProductRate => 'Taux d\'un produit';

  @override
  String get affiliateLikeStore => 'Comme la boutique';

  @override
  String get paidContent => 'Contenu rémunéré';

  @override
  String get shareAction => 'Partager';

  @override
  String get shareCopied =>
      'Lien copié : colle-le dans ta vidéo TikTok ou un message.';

  @override
  String get shareFailed => 'Partage impossible pour le moment.';

  @override
  String shareText(String caption, String link) {
    return '$caption\nTout pour la faire : $link';
  }

  @override
  String get tiktokSeeOriginal => 'Voir sur TikTok';

  @override
  String get tiktokSection => 'TikTok';

  @override
  String get tiktokHandle => 'Mon compte TikTok';

  @override
  String get tiktokHandleHint => '@moncompte';

  @override
  String get tiktokSaveHandle => 'Relier mon compte';

  @override
  String get tiktokUnverified =>
      'Compte déclaré : la vérification par connexion TikTok arrive bientôt. N\'importe que tes propres vidéos.';

  @override
  String get tiktokImportTitle => 'Importer une vidéo TikTok';

  @override
  String get tiktokLink => 'Lien de la vidéo TikTok';

  @override
  String get tiktokImport => 'Importer';

  @override
  String get tiktokHandleRequired => 'Relie d\'abord ton compte TikTok.';

  @override
  String get tiktokNotOwner =>
      'Cette vidéo vient d\'un autre compte TikTok que le tien.';

  @override
  String get tiktokNotFound => 'Vidéo introuvable ou privée.';

  @override
  String get tiktokInvalidUrl => 'Ce lien n\'est pas une vidéo TikTok.';

  @override
  String get tiktokNoCover =>
      'TikTok n\'a pas donné de couverture pour cette vidéo.';

  @override
  String get tiktokPickCover => 'Choisir une photo de couverture';

  @override
  String get appNameDelivery => 'DYM Livreur';

  @override
  String get deliveryTagline => 'Tes courses, tes gains, sans dispute.';

  @override
  String get deliveryWelcomeBody =>
      'Livre les commandes de ton quartier, à ton rythme.';

  @override
  String get deliveryPoint1 => 'Accepte les courses près de toi';

  @override
  String get deliveryPoint2 => 'Adresse et téléphone après acceptation';

  @override
  String get deliveryPoint3 => 'Un seul compte DYM pour tout';

  @override
  String get missionsTitle => 'Missions';

  @override
  String get myRunsTitle => 'Mes courses';

  @override
  String get runsActiveTitle => 'Course en cours';

  @override
  String get runsHistoryTitle => 'Historique';

  @override
  String get runsHistoryNone => 'Pas encore de course terminée.';

  @override
  String get courierOnline => 'En ligne';

  @override
  String get courierOffline => 'Hors ligne';

  @override
  String get courierOnlineHint => 'Les courses de tes zones te sont proposées.';

  @override
  String get courierOfflineHint =>
      'Mets-toi en ligne pour recevoir des courses.';

  @override
  String get missionsNone => 'Aucune course pour le moment';

  @override
  String get missionsNoneHint =>
      'Tu seras prévenu dès qu\'une commande de tes zones attend un livreur.';

  @override
  String get missionsGoOnline => 'Tu es hors ligne';

  @override
  String get missionAccept => 'Accepter la course';

  @override
  String get missionTaken => 'Un autre livreur a déjà pris cette course.';

  @override
  String get missionTooMany => 'Termine d\'abord tes courses en cours.';

  @override
  String get courierSuspended =>
      'Ton compte livreur est suspendu. Contacte l\'équipe DYM.';

  @override
  String get courierInvalidPhone => 'Numéro de téléphone invalide.';

  @override
  String get courierInvalidZones => 'Choisis au moins une zone de ton pays.';

  @override
  String get courierVehicleFoot => 'À pied';

  @override
  String get courierVehicleBike => 'Vélo';

  @override
  String get courierVehicleMoto => 'Moto';

  @override
  String get courierVehicleCar => 'Voiture';

  @override
  String get courierBecomeTitle => 'Devenir livreur';

  @override
  String get courierBecomeBody =>
      'Même compte DYM : ajoute ton téléphone, ton moyen et les zones où tu livres.';

  @override
  String get courierName => 'Nom affiché aux clientes';

  @override
  String get courierPhone => 'Téléphone';

  @override
  String get courierVehicle => 'Mon moyen';

  @override
  String get courierZones => 'Mes zones';

  @override
  String get courierBecomeAction => 'Commencer à livrer';

  @override
  String missionItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
    );
    return '$_temp0';
  }

  @override
  String get missionPickup => 'Récupérer chez';

  @override
  String get missionFeeLabel => 'Ta course';

  @override
  String missionSlot(String slot) {
    return 'Créneau : $slot';
  }

  @override
  String missionCashToCollect(String amount) {
    return 'À encaisser : $amount en cash';
  }

  @override
  String get missionDropoff => 'Livrer à';

  @override
  String get missionPreparing => 'En préparation';

  @override
  String get missionReady => 'Prête à récupérer';

  @override
  String get missionOnTheWay => 'En route';

  @override
  String get missionDelivered => 'Livrée';

  @override
  String get myRunsNone => 'Aucune course en cours';

  @override
  String get myRunsNoneHint => 'Accepte une mission pour la voir ici.';

  @override
  String get missionPickedUp => 'Commande récupérée';

  @override
  String get missionHandedOver => 'Commande remise';

  @override
  String get missionWaitReady => 'La boutique prépare la commande.';

  @override
  String get missionRelease => 'Rendre la course';

  @override
  String get retryHint => 'Vérifie ta connexion puis réessaie.';

  @override
  String missionRun(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tournée · $count boutiques',
      one: '1 boutique',
    );
    return '$_temp0';
  }

  @override
  String get storageAmbient => 'Température ambiante';

  @override
  String get storageCool => 'Au frais';

  @override
  String get storageFrozen => 'Surgelé';

  @override
  String get storageFragile => 'Fragile';

  @override
  String get handoverTitle => 'Code de remise';

  @override
  String get handoverBody =>
      'Demande à la cliente le code à 4 chiffres affiché dans son app.';

  @override
  String get handoverCode => 'Code';

  @override
  String get handoverCancel => 'Annuler';

  @override
  String get handoverConfirm => 'Valider la remise';

  @override
  String handoverWrong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Code incorrect : encore $count essais.',
      one: 'Code incorrect : encore 1 essai.',
      zero: 'Code incorrect. Contacte l\'équipe DYM.',
    );
    return '$_temp0';
  }

  @override
  String get handoverLocked =>
      'Trop d\'essais : l\'équipe DYM va t\'aider à terminer la remise.';

  @override
  String get trackHandoverCode => 'Code de remise';

  @override
  String trackCourier(String name) {
    return '$name te livre';
  }

  @override
  String get trackHandoverHint =>
      'Donne ce code au livreur quand il te remet la commande.';

  @override
  String get walletWithdraw => 'Retirer';

  @override
  String get walletWithdrawSimulated =>
      'Retrait simulé : aucun versement réel tant que le fournisseur n\'est pas branché.';

  @override
  String get walletKindCourierFee => 'Frais de livraison';

  @override
  String get walletKindCashTopup => 'Recharge en cash';

  @override
  String get walletKindWithdrawal => 'Retrait';

  @override
  String get walletCashTopup => 'Recharger en cash auprès d\'un livreur';

  @override
  String get walletCashTopupShort => 'Recharge cash';

  @override
  String get walletCashTopupHint =>
      'Montre ce code au livreur DYM et donne-lui le cash : ton wallet est crédité aussitôt.';

  @override
  String walletCashTopupExpires(String time) {
    return 'Valable jusqu\'à $time';
  }

  @override
  String get earningsTitle => 'Gains';

  @override
  String earningsToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count courses aujourd\'hui',
      one: '1 course aujourd\'hui',
      zero: 'Aucune course aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String get earningsWallet => 'Sur mon wallet';

  @override
  String get earningsWithdraw => 'Retirer mes gains';

  @override
  String get earningsWithdrawDisabled =>
      'Le retrait n\'est pas encore ouvert dans ton pays.';

  @override
  String get earningsAmount => 'Montant';

  @override
  String get earningsCashTitle => 'Cash à remettre';

  @override
  String get earningsCashNone => 'Tu ne dois aucun cash.';

  @override
  String get earningsCashToDym => 'Équipe DYM';

  @override
  String get earningsCashToDymHint =>
      'Recharges en cash, à remettre à l\'équipe.';

  @override
  String get earningsCashToStoreHint =>
      'Prix des articles encaissés, à remettre à la boutique.';

  @override
  String get cashTopupTitle => 'Point de recharge';

  @override
  String get cashTopupHint =>
      'La cliente te montre son code de recharge ; tu prends son cash et son wallet est crédité.';

  @override
  String get cashTopupCode => 'Code de la cliente';

  @override
  String get cashTopupConfirm => 'Créditer son wallet';

  @override
  String get cashTopupInvalidCode => 'Code inconnu, expiré ou déjà utilisé.';

  @override
  String get courierCashTitle => 'Cash des livreurs';

  @override
  String get courierCashHint =>
      'Les livreurs DYM encaissent tes commandes payées en cash ; confirme quand ils te remettent l\'argent.';

  @override
  String get courierCashNone => 'Aucun cash à recevoir';

  @override
  String get courierCashNoneHint =>
      'Le cash encaissé par les livreurs pour toi apparaîtra ici.';

  @override
  String get courierCashReceived => 'Reçu';

  @override
  String get tillTitle => 'Ma caisse';

  @override
  String get tillTodayLabel => 'Aujourd\'hui';

  @override
  String get tillOpen => 'Ma caisse : ventes du jour';

  @override
  String get tillNewSale => 'Nouvelle vente';

  @override
  String tillToday(String amount) {
    return 'Aujourd\'hui : $amount';
  }

  @override
  String tillInApp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'En app · $count ventes',
      one: 'En app · 1 vente',
      zero: 'En app',
    );
    return '$_temp0';
  }

  @override
  String tillOffApp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hors app · $count ventes',
      one: 'Hors app · 1 vente',
      zero: 'Hors app',
    );
    return '$_temp0';
  }

  @override
  String get tillBalance => 'Mon solde chez DYM';

  @override
  String get tillPayout => 'Verser mon solde';

  @override
  String get tillPayoutSimulated =>
      'Versement simulé : aucun argent ne part tant que le versement réel n\'est pas branché.';

  @override
  String get tillBalanceInsufficient =>
      'Ton solde ne suffit pas pour ce versement.';

  @override
  String get tillSales => 'Ventes hors app';

  @override
  String get tillNoSale => 'Aucune vente hors app enregistrée.';

  @override
  String get tillVoid => 'Annuler la vente';

  @override
  String get tillPayouts => 'Versements';

  @override
  String get tillVoice => 'Dicter la vente';

  @override
  String get tillVoiceStop => 'J\'ai fini';

  @override
  String get tillVoiceDisabled =>
      'La dictée n\'est pas ouverte dans ton pays : tape la vente.';

  @override
  String get tillNothingHeard => 'Rien entendu : réessaie ou tape la vente.';

  @override
  String get tillLabel => 'Ce que tu as vendu';

  @override
  String get tillLabelHint => '3 tas de tomates 1500';

  @override
  String get tillAmount => 'Montant';

  @override
  String get tillSave => 'Enregistrer la vente';

  @override
  String get tillMethodCash => 'Cash';

  @override
  String get tillMethodMobileMoney => 'Mobile money';

  @override
  String get tillMethodOther => 'Autre';

  @override
  String get tillLoadError => 'Ta caisse n\'a pas pu être chargée.';

  @override
  String get orderTimeline => 'Frise de la commande';

  @override
  String get actorVendor => 'Toi';

  @override
  String get actorClient => 'La cliente';

  @override
  String get actorCourier => 'Le livreur';

  @override
  String get actorAdmin => 'L\'équipe DYM';

  @override
  String get actorSystem => 'DYM';

  @override
  String get tillMethodDym => 'Wallet DYM (QR)';

  @override
  String get qrChargeTitle => 'Encaisser par QR';

  @override
  String get qrChargeHint =>
      'La cliente scanne le QR (ou tape le code) et paie depuis son wallet DYM.';

  @override
  String get qrChargeLabel => 'Libellé (facultatif)';

  @override
  String get qrChargeShow => 'Afficher le QR';

  @override
  String get tillErase => 'Effacer le dernier chiffre';

  @override
  String get qrChargeCode => 'Code à taper';

  @override
  String get qrChargeWaiting => 'En attente du paiement… (valable 10 minutes)';

  @override
  String get qrChargeCancel => 'Annuler';

  @override
  String get qrChargePaid => 'Payé !';

  @override
  String get qrChargeExpired => 'Demande expirée ou annulée.';

  @override
  String get qrChargeAnother => 'Nouvel encaissement';

  @override
  String get walletQrPay => 'Payer par QR';

  @override
  String get qrPayTitle => 'Payer par QR';

  @override
  String get qrPayHint =>
      'Scanne le QR de la vendeuse, ou tape son code à 6 chiffres.';

  @override
  String get qrPayCode => 'Code de la vendeuse';

  @override
  String get qrPayContinue => 'Continuer';

  @override
  String qrPayConfirm(String amount) {
    return 'Payer $amount';
  }

  @override
  String qrPayDone(String amount, String store) {
    return '$amount payés à $store.';
  }

  @override
  String get qrPayClose => 'Terminer';

  @override
  String get qrPayInvalidCode => 'Code inconnu, expiré ou déjà payé.';

  @override
  String get qrPayOwnStore => 'C\'est ta propre boutique.';

  @override
  String get qrPayCurrency => 'Cette boutique n\'est pas dans ton pays.';

  @override
  String get creditTitle => 'Ardoise';

  @override
  String get creditOwedLabel => 'On te doit';

  @override
  String get creditNew => 'Nouvelle cliente';

  @override
  String creditTotal(String amount) {
    return 'On te doit $amount';
  }

  @override
  String get creditNone => 'Ardoise vide';

  @override
  String get creditNoneHint =>
      'Note ici ce que tes clientes te doivent : tu ne perds plus rien.';

  @override
  String get creditLoadError => 'L\'ardoise n\'a pas pu être chargée.';

  @override
  String creditLimit(String amount) {
    return 'Plafond $amount';
  }

  @override
  String creditOwes(String amount) {
    return 'Doit $amount';
  }

  @override
  String get creditAddDebt => 'Elle prend à crédit';

  @override
  String get creditAddPayment => 'Elle rembourse';

  @override
  String get creditRemind => 'Relancer sur WhatsApp';

  @override
  String get creditArchive => 'Ardoise soldée : la retirer';

  @override
  String get creditDebt => 'Crédit';

  @override
  String get creditPayment => 'Remboursement';

  @override
  String get creditName => 'Nom de la cliente';

  @override
  String get creditLimitField => 'Plafond (facultatif)';

  @override
  String get creditCreate => 'Ouvrir l\'ardoise';

  @override
  String get creditNote => 'Note (facultatif)';

  @override
  String get creditLimitReached =>
      'Plafond dépassé : elle doit d\'abord rembourser.';

  @override
  String get creditPaymentTooHigh => 'Plus que ce qu\'elle doit.';

  @override
  String get creditAlreadyReminded => 'Déjà relancée aujourd\'hui.';

  @override
  String creditReminderText(String name, String amount, String store) {
    return 'Bonjour $name, petit rappel de $store : il reste $amount sur ton ardoise. Merci !';
  }

  @override
  String get studioTitle => 'Faire connaître ma boutique';

  @override
  String get studioShareTitle => 'Partager ma boutique';

  @override
  String get studioShareHint =>
      'Envoie le lien de ta boutique sur WhatsApp : tes clientes commandent en un geste.';

  @override
  String get studioShare => 'Partager sur WhatsApp';

  @override
  String studioShareText(String link) {
    return 'Mes produits frais sont sur DYM, commande ici : $link';
  }

  @override
  String get eomTitle => 'Prix de fin de marché';

  @override
  String get eomHint =>
      'Baisse tes prix quelques heures pour écouler le frais du jour. Le prix réduit s\'affiche partout et s\'applique aux commandes.';

  @override
  String get eomPercent => 'Remise';

  @override
  String get eomDuration => 'Pendant';

  @override
  String eomHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count heures',
      one: '1 heure',
    );
    return '$_temp0';
  }

  @override
  String eomStart(int percent) {
    return 'Lancer -$percent %';
  }

  @override
  String eomActive(int percent, int count, String time) {
    return '-$percent % sur $count produits jusqu\'à $time';
  }

  @override
  String get eomStop => 'Arrêter la fin de marché';

  @override
  String endOfMarketBadge(int percent) {
    return 'Fin de marché -$percent %';
  }

  @override
  String get wholesaleTitle => 'Achats de gros';

  @override
  String get wholesaleHint =>
      'Achetez à plusieurs chez un grossiste : le prix de gros, même pour de petites quantités. Le règlement se fait avec le grossiste.';

  @override
  String get wholesaleOpen => 'Offres en cours';

  @override
  String get wholesaleNoOffer => 'Aucune offre de gros pour le moment.';

  @override
  String get wholesaleMine => 'Mes offres de grossiste';

  @override
  String get wholesaleBecome => 'Je suis grossiste : proposer des offres';

  @override
  String get wholesaleNewOffer => 'Nouvelle offre';

  @override
  String wholesaleUnitPrice(String price) {
    return '$price l\'unité';
  }

  @override
  String wholesaleProgress(int committed, int min, int buyers) {
    String _temp0 = intl.Intl.pluralLogic(
      buyers,
      locale: localeName,
      other: '$buyers acheteuses',
      one: '1 acheteuse',
      zero: 'aucune acheteuse',
    );
    return '$committed sur $min réservés · $_temp0';
  }

  @override
  String wholesaleUntil(String date) {
    return 'Ouverte jusqu\'au $date';
  }

  @override
  String get wholesaleConfirmed => 'Confirmée';

  @override
  String get wholesaleCancelled => 'Annulée';

  @override
  String get wholesaleClosed => 'Close';

  @override
  String wholesaleMyQuantity(int quantity) {
    return 'Ma réservation : $quantity';
  }

  @override
  String get wholesaleCommit => 'Réserver';

  @override
  String get wholesaleChange => 'Changer ma réservation';

  @override
  String get wholesaleConfirm => 'Confirmer l\'achat';

  @override
  String get wholesaleCancel => 'Annuler l\'offre';

  @override
  String get wholesaleQuantity => 'Quantité';

  @override
  String get wholesaleQuantityHint => '0 pour retirer ta réservation.';

  @override
  String get wholesaleUnitPriceField => 'Prix de gros à l\'unité';

  @override
  String get wholesaleMinQuantity => 'Quantité minimale';

  @override
  String wholesaleDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get wholesalePublish => 'Publier l\'offre';

  @override
  String get wholesaleMinimumNotReached =>
      'Le minimum n\'est pas encore atteint.';

  @override
  String get haggleAction => 'Marchander';

  @override
  String get haggleTitle => 'Marchander avec la vendeuse';

  @override
  String haggleCurrent(String price) {
    return 'Prix affiché : $price';
  }

  @override
  String haggleHint(int quantity) {
    String _temp0 = intl.Intl.pluralLogic(
      quantity,
      locale: localeName,
      other: '$quantity articles',
      one: '1 article',
    );
    return 'Propose ton prix à l\'unité pour $_temp0. La vendeuse répond tout de suite.';
  }

  @override
  String get haggleOfferField => 'Ton prix à l\'unité';

  @override
  String get haggleSubmit => 'Proposer';

  @override
  String haggleAccepted(String price) {
    return 'Marché conclu : $price l\'unité. C\'est dans ton panier pour 2 heures.';
  }

  @override
  String haggleCountered(String price) {
    return 'La vendeuse propose $price l\'unité (valable 15 minutes).';
  }

  @override
  String get haggleAcceptCounter => 'Accepter ce prix';

  @override
  String haggleAttemptsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Encore $count essais aujourd\'hui',
      one: 'Encore 1 essai aujourd\'hui',
      zero: 'Plus d\'essai aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String get haggleClose => 'C\'est bon';

  @override
  String get haggleCartBadge => 'Prix marchandé';

  @override
  String get groupBuyCartBadge => 'Prix de groupe';

  @override
  String get haggleErrorTooMany =>
      'Tu as déjà marchandé 3 fois ce produit aujourd\'hui.';

  @override
  String get haggleErrorNotLower =>
      'Propose un prix plus bas que le prix affiché.';

  @override
  String get haggleErrorOff => 'Cette vendeuse ne marchande pas ce produit.';

  @override
  String get haggleErrorExpired =>
      'Ce prix n\'est plus valable : propose à nouveau.';

  @override
  String get hagglingTitle => 'Marchandage';

  @override
  String get hagglingHint =>
      'Fixe jusqu\'où tu acceptes de baisser. DYM répond à ta place, tout de suite ; la cliente ne voit jamais ta limite.';

  @override
  String get hagglingStoreLimit => 'Remise maximale';

  @override
  String get hagglingOff => 'Pas de marchandage';

  @override
  String hagglingPercent(int percent) {
    return '$percent %';
  }

  @override
  String get hagglingProducts => 'Par produit';

  @override
  String get hagglingLikeStore => 'Comme la boutique';

  @override
  String get hagglingNever => 'Jamais';

  @override
  String hagglingWeek(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count marchés conclus cette semaine',
      one: '1 marché conclu cette semaine',
      zero: 'Aucun marché conclu cette semaine',
    );
    return '$_temp0';
  }

  @override
  String get hagglingRecent => 'Derniers marchandages';

  @override
  String get hagglingEmpty => 'Aucun marchandage pour le moment.';

  @override
  String hagglingLine(int quantity, String offer, String price) {
    return '$quantity × $offer proposé → $price';
  }

  @override
  String get hagglingStatusAccepted => 'Conclu';

  @override
  String get hagglingStatusCountered => 'Contre-prix';

  @override
  String get hagglingStatusUsed => 'Commandé';

  @override
  String get hagglingStatusExpired => 'Expiré';

  @override
  String get accountGroupBuys => 'Achats groupés';

  @override
  String get groupBuyTitle => 'Achats groupés entre voisins';

  @override
  String get groupBuyHint =>
      'Rejoins tes voisins chez une vendeuse : quand le groupe est complet, chacun paie le prix de groupe et la livraison est partagée.';

  @override
  String get groupBuyEmpty =>
      'Pas encore d\'achat groupé près de chez toi. Ce sont les vendeuses qui les lancent depuis leur boutique : reviens bientôt.';

  @override
  String groupBuyPrice(String group, String price) {
    return '$group au lieu de $price';
  }

  @override
  String groupBuySharedDelivery(String fee) {
    return 'Livraison partagée : $fee';
  }

  @override
  String groupBuyProgress(int committed, int min, int members) {
    String _temp0 = intl.Intl.pluralLogic(
      members,
      locale: localeName,
      other: '$members voisins',
      one: '1 voisin',
      zero: 'personne encore',
    );
    return '$committed sur $min · $_temp0';
  }

  @override
  String groupBuyUntil(String date) {
    return 'Ouvert jusqu\'au $date';
  }

  @override
  String get groupBuyUnlocked => 'Groupe complet : prix de groupe débloqué';

  @override
  String groupBuyMine(int quantity) {
    return 'Ma part : $quantity';
  }

  @override
  String get groupBuyJoin => 'Rejoindre le groupe';

  @override
  String get groupBuyChange => 'Changer ma part';

  @override
  String get groupBuyAddToCart => 'Mettre ma part au panier';

  @override
  String get groupBuyQuantity => 'Quantité';

  @override
  String get groupBuyQuantityHint => '0 pour quitter le groupe.';

  @override
  String get groupBuyLockedHint =>
      'Le groupe est complet : tu peux augmenter ta part, pas la réduire.';

  @override
  String get groupBuyClosed => 'Cet achat groupé est fermé.';

  @override
  String get groupBuyLocked =>
      'Le groupe est complet : ta part ne peut plus baisser.';

  @override
  String get groupOfferTitle => 'Offres groupées';

  @override
  String get groupOfferHint =>
      'Propose un prix de groupe aux clientes de tes quartiers : quand la quantité est atteinte, chacune l\'obtient, avec des frais de livraison réduits si tu veux.';

  @override
  String get groupOfferEmpty => 'Aucune offre groupée.';

  @override
  String get groupOfferNew => 'Nouvelle offre groupée';

  @override
  String get groupOfferPrice => 'Prix de groupe à l\'unité';

  @override
  String get groupOfferMin => 'Quantité totale minimale';

  @override
  String get groupOfferFee => 'Frais de livraison des membres (facultatif)';

  @override
  String get groupOfferCancel => 'Annuler l\'offre';

  @override
  String get groupOfferCancelled => 'Annulée';

  @override
  String get groupOfferInvalid =>
      'Vérifie le prix (plus bas que le prix du jour), la quantité (au moins 2) et les frais.';

  @override
  String get accountMembership => 'DYM+';

  @override
  String get membershipClientTitle => 'DYM+';

  @override
  String get membershipVendorTitle => 'Pro et visibilité';

  @override
  String membershipWallet(String balance) {
    return 'Payé depuis ton wallet · solde : $balance';
  }

  @override
  String get membershipWalletInsufficient =>
      'Solde du wallet insuffisant : recharge-le, puis réessaie.';

  @override
  String membershipStoreBalance(String store, String wallet) {
    return 'Payé depuis le solde de ta boutique ($store), sinon ton wallet ($wallet)';
  }

  @override
  String get membershipStoreInsufficient =>
      'Ni le solde de ta boutique ni ton wallet ne suffisent : vends ou recharge ton wallet, puis réessaie.';

  @override
  String get membershipNone => 'Aucune formule dans ton pays pour le moment.';

  @override
  String get membershipDeliveryRefund =>
      'Frais de livraison remboursés sur ton wallet à chaque livraison';

  @override
  String membershipCashback(num percent) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);

    return '$percentString % de cashback en plus sur tes courses';
  }

  @override
  String membershipCommission(num percent) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);

    return 'Commission DYM réduite de $percentString %';
  }

  @override
  String get membershipSponsored =>
      'Ta boutique « À la une » de l\'accueil de tes quartiers, signalée comme sponsorisée';

  @override
  String membershipPrice(String price, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '1 jour',
    );
    return '$price pour $_temp0';
  }

  @override
  String membershipActiveUntil(String date) {
    return 'Active jusqu\'au $date';
  }

  @override
  String get membershipSubscribe => 'Prendre la formule';

  @override
  String get membershipExtend => 'Prolonger';

  @override
  String get homeSponsored => 'À la une';

  @override
  String get homeSponsoredLabel => 'Sponsorisé';

  @override
  String get opsTitle => 'Opérations';

  @override
  String get opsSubtitle =>
      'En direct : commandes, retards, livreurs, cash à recevoir.';

  @override
  String get opsNoCountry => 'Aucun pays dans ton périmètre.';

  @override
  String get opsLiveTab => 'En direct';

  @override
  String get opsSettingsTab => 'Réglages';

  @override
  String get opsLast24h => 'Dernières 24 heures';

  @override
  String get opsDelivered => 'Livré';

  @override
  String get opsCouriersOnline => 'Livreurs en ligne';

  @override
  String get opsMissionsWaiting => 'Livraisons sans livreur';

  @override
  String get opsAlerts => 'Commandes en retard';

  @override
  String get opsNoAlert => 'Aucune commande en retard.';

  @override
  String get opsNoCourier => 'sans livreur';

  @override
  String opsMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String opsDelayHours(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String opsDelayDays(int days, int hours) {
    return '$days j $hours h';
  }

  @override
  String get opsCourierCash => 'Cash des livreurs à recevoir';

  @override
  String get opsNoCourierCash => 'Aucun cash à recevoir.';

  @override
  String get opsCashReceived => 'Cash reçu';

  @override
  String get opsThresholds => 'Seuils d\'alerte (minutes)';

  @override
  String get opsThresholdPending => 'En attente de la vendeuse';

  @override
  String get opsThresholdReady => 'Prête, au-delà de la préparation';

  @override
  String get opsThresholdTransit => 'En route';

  @override
  String get opsFeedWeights => 'Poids du fil des contenus';

  @override
  String get opsWeightRecency => 'Fraîcheur';

  @override
  String get opsWeightEngagement => 'Engagement';

  @override
  String get opsWeightFollowed => 'Abonnements';

  @override
  String get opsWeightLocal => 'Proximité';

  @override
  String get opsWeightAffinity => 'Affinité';

  @override
  String get opsWeightShoppable => 'Achetable';

  @override
  String get opsPlans => 'Formules (DYM+, Pro, À la une)';

  @override
  String opsPeriod(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get opsPrice => 'Prix';

  @override
  String get opsSave => 'Enregistrer';

  @override
  String get opsScopes => 'Admins limités à des pays';

  @override
  String get opsScopesHint =>
      'Un admin limité ne pilote que ses pays. Sans limite, il pilote tous les pays.';

  @override
  String get opsScopeEmail => 'E-mail de l\'admin';

  @override
  String opsScopeAdd(String country) {
    return 'Limiter à $country';
  }

  @override
  String opsScopeRemove(String country) {
    return 'Retirer $country';
  }

  @override
  String get opsInvalid => 'Valeur invalide.';

  @override
  String get opsOutOfScope => 'Ce pays n\'est pas dans ton périmètre.';

  @override
  String get opsNothingOwed => 'Ce livreur ne doit plus rien.';

  @override
  String get opsNotAdmin => 'Cette adresse n\'est pas celle d\'un admin.';

  @override
  String get adminSupportDraft => 'Brouillon IA';

  @override
  String get moderationAi => 'Avis de l\'IA';

  @override
  String get moderationAiRemove => 'à retirer';

  @override
  String get moderationAiKeep => 'à garder';

  @override
  String get moderationAiUnsure => 'incertain';

  @override
  String get opsFraud => 'Signaux de fraude';

  @override
  String get opsNoFraud => 'Aucun signal ouvert.';

  @override
  String get opsFraudDismiss => 'Écarter';

  @override
  String get opsFraudConfirm => 'Confirmer';

  @override
  String get fraudClientCancelBurst => 'Annulations répétées (cliente)';

  @override
  String get fraudStoreRefusalBurst => 'Refus répétés (boutique)';

  @override
  String get fraudSharedDevice => 'Appareil partagé par plusieurs comptes';

  @override
  String get fraudHandoverFailures => 'Codes de remise faux (livreur)';

  @override
  String get fraudHaggleBurst => 'Marchandage en rafale sans achat';

  @override
  String get chatToday => 'aujourd\'hui';

  @override
  String get chatQuickIsAvailable => 'C\'est disponible ?';

  @override
  String get chatQuickPrice => 'Quel est le prix ?';

  @override
  String get chatQuickDeliveryToday => 'Vous livrez aujourd\'hui ?';

  @override
  String get chatQuickThanks => 'Merci !';

  @override
  String get chatQuickYesAvailable => 'Oui, c\'est disponible.';

  @override
  String get chatQuickSoldOut => 'Désolée, ce n\'est plus disponible.';

  @override
  String get chatQuickPreparing => 'Je prépare votre commande.';

  @override
  String get chatQuickThanksOrder => 'Merci pour votre commande !';

  @override
  String get chatSending => 'Envoi…';

  @override
  String get chatNotSent => 'Non envoyé';

  @override
  String get chatSent => 'Envoyé';

  @override
  String get chatSeen => 'Vu';

  @override
  String get chatDiscard => 'Supprimer';

  @override
  String get chatActiveOrder => 'Commande en cours';

  @override
  String get chatSeeOrder => 'Voir la commande';

  @override
  String get chatSeeStore => 'Voir la boutique';

  @override
  String get chatAttach => 'Joindre';

  @override
  String get chatSearchConversations => 'Chercher une conversation';

  @override
  String chatYou(String text) {
    return 'Toi : $text';
  }

  @override
  String get chatVoicePreview => 'Message vocal';

  @override
  String get chatCallPreview => 'Appel';

  @override
  String chatEmptyThreadStore(String name) {
    return 'Pose ta question à $name : disponibilité, prix, livraison.';
  }

  @override
  String chatEmptyThreadClient(String name) {
    return '$name t\'a ouvert une conversation. Réponds-lui ici.';
  }

  @override
  String chatShareSelected(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Envoyer $n produits',
      one: 'Envoyer 1 produit',
    );
    return '$_temp0';
  }

  @override
  String get chatSearchStoreProducts => 'Chercher dans la boutique';

  @override
  String get prefQuietNightTitle => 'Nuit calme';

  @override
  String get prefQuietNightBody =>
      'De 22 h à 7 h, pas de messages ni d\'offres sur le téléphone. Les commandes et les paiements passent toujours.';

  @override
  String get pushChannelOrders => 'Commandes et paiements';

  @override
  String get pushChannelMessages => 'Messages';

  @override
  String get pushChannelMissions => 'Courses à livrer';

  @override
  String get pushChannelGeneral => 'Infos et offres';

  @override
  String get adminExchangesTitle => 'Échanges';

  @override
  String get adminMessagesSent => 'Messages envoyés';

  @override
  String get adminMessagesWithOrder => 'Sur commande';

  @override
  String get adminConversationsActive => 'Conversations actives';

  @override
  String get adminPushSent => 'Notifications';

  @override
  String get adminPushSkipped => 'Retenues';

  @override
  String get adminPushFailed => 'Échecs d\'envoi';

  @override
  String get adminQuietNightUsers => 'Nuit calme activée';

  @override
  String get adminStoresByOrigin => 'Boutiques actives par type';

  @override
  String get adminKpiSales => 'Ventes encaissées';

  @override
  String get adminKpiOrders => 'Commandes';

  @override
  String get adminKpiBasket => 'Panier moyen';

  @override
  String get adminKpiDeliveries => 'Livraisons réussies';

  @override
  String get adminKpiPayments => 'Paiements réussis';

  @override
  String get adminKpiSignups => 'Nouvelles inscriptions';

  @override
  String get adminVsDay => 'vs hier à la même heure';

  @override
  String get adminVsWeek => 'vs semaine dernière';

  @override
  String get adminVsMonth => 'vs mois dernier';

  @override
  String get adminDeltaNew => 'nouveau';

  @override
  String get adminTrendTitle => 'Évolution';

  @override
  String get adminTrendOrders => 'Commandes';

  @override
  String get adminTrendSales => 'Ventes';

  @override
  String get adminTrendDelivered => 'Livrées';

  @override
  String get adminFunnelTitle => 'Parcours d\'achat';

  @override
  String get adminFunnelActive => 'Clientes actives';

  @override
  String get adminFunnelViewed => 'Ont vu un produit';

  @override
  String get adminFunnelAdded => 'Ont rempli un panier';

  @override
  String get adminFunnelOrdered => 'Ont commandé';

  @override
  String get adminFunnelDelivered => 'Ont été livrées';

  @override
  String get adminFunnelHelp =>
      'Personnes distinctes à chaque étape ; le pourcentage est le passage depuis l\'étape précédente.';

  @override
  String get adminTodoTitle => 'À traiter';

  @override
  String get adminTodoNone => 'Rien à traiter pour l\'instant.';

  @override
  String get adminOutcomesTitle => 'Issue des commandes';

  @override
  String get adminOutcomeDelivered => 'Livrées';

  @override
  String get adminOutcomeInProgress => 'En cours';

  @override
  String get adminOutcomeRefused => 'Refusées';

  @override
  String get adminOutcomeCancelled => 'Annulées';

  @override
  String get adminOutcomesCenter => 'commandes';

  @override
  String get adminStoresCenter => 'boutiques';

  @override
  String get adminSeeAll => 'Tout voir';

  @override
  String get adminColOrders => 'Commandes';

  @override
  String get adminColRating => 'Note';

  @override
  String get adminStatOnline => 'En ligne';

  @override
  String get adminStatWaiting => 'Sans livreur';

  @override
  String get adminStatMedian => 'Prise médiane';

  @override
  String get adminStatMessages => 'Messages';

  @override
  String get adminStatConversations => 'Conversations';

  @override
  String get adminPushLegendSent => 'Envoyées';

  @override
  String get adminPushLegendHeld => 'Retenues';

  @override
  String get adminPushLegendFailed => 'En échec';

  @override
  String get adminTopProducts => 'Produits les plus vendus';

  @override
  String get adminActiveUsersShort => 'Actives sur 7 jours';

  @override
  String adminPoints(int n) {
    return '$n pt';
  }

  @override
  String get trackPhaseWaiting => 'En attente de la boutique';

  @override
  String trackPhaseWaitingHint(String store) {
    return '$store va confirmer ta commande.';
  }

  @override
  String get trackPhasePreparing => 'En préparation';

  @override
  String trackPhasePreparingHint(String store) {
    return '$store prépare ta commande.';
  }

  @override
  String get trackPhaseReady => 'Prête';

  @override
  String get trackPhaseReadyHint => 'Un livreur va la récupérer.';

  @override
  String trackPhaseReadyPickupHint(String store) {
    return 'Passe la récupérer chez $store.';
  }

  @override
  String get trackPhaseOnTheWay => 'En route';

  @override
  String get trackPhaseOnTheWayHint =>
      'Ta commande arrive, garde ton téléphone près de toi.';

  @override
  String get trackPhaseDelivered => 'Livrée';

  @override
  String get trackPhaseDeliveredHint =>
      'Bon appétit ! Dis-nous si tout va bien.';

  @override
  String get trackPhaseCollected => 'Récupérée';

  @override
  String trackInMinutes(int minutes) {
    return 'dans $minutes min';
  }

  @override
  String get trackSent => 'Envoyée';

  @override
  String get trackCallCourier => 'Appeler';

  @override
  String get trackSummary => 'Récapitulatif';

  @override
  String get trackPickupFee => 'Retrait en boutique';

  @override
  String get trackFree => 'Gratuit';

  @override
  String trackPaidWith(String method) {
    return 'Payée · $method';
  }

  @override
  String trackPayWith(String method) {
    return 'Paiement · $method';
  }

  @override
  String trackOrderedOn(String date, String time) {
    return 'Commandée le $date à $time';
  }

  @override
  String get vendorAlertTitle => 'Nouvelle commande !';

  @override
  String get vendorAlertOpen => 'Voir la commande';

  @override
  String get vendorAlertLater => 'Plus tard';

  @override
  String vendorAlertMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count autres commandes attendent',
      one: '1 autre commande attend',
    );
    return '$_temp0';
  }

  @override
  String vendorRespondBefore(String time) {
    return 'Réponds avant $time';
  }

  @override
  String vendorMinutesLeft(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min restantes',
      one: '1 min restante',
      zero: 'délai dépassé',
    );
    return '$_temp0';
  }

  @override
  String vendorAutoRefuseAt(String time) {
    return 'Sans réponse, la commande sera refusée à $time.';
  }

  @override
  String vendorUrgentTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commandes attendent ta réponse',
      one: '1 commande attend ta réponse',
    );
    return '$_temp0';
  }

  @override
  String get vendorUrgentAction => 'Répondre';

  @override
  String get vendorVsDay => 'vs hier à la même heure';

  @override
  String get vendorVsWeek => 'vs semaine dernière';

  @override
  String get vendorVsMonth => 'vs mois dernier';

  @override
  String get productOutOfStockShort => 'Rupture';

  @override
  String get vendorPublishStatus => 'Publier un statut';

  @override
  String get missionCall => 'Appeler';

  @override
  String get missionRoute => 'Itinéraire';

  @override
  String searchFuzzy(String query) {
    return 'Résultats proches de « $query »';
  }

  @override
  String get notifCartReminderTitle => 'Ton panier t\'attend';

  @override
  String notifCartReminderBody(String summary) {
    return '$summary : finalise ta commande en un geste.';
  }

  @override
  String get importTitle => 'Importer des produits';

  @override
  String get importAction => 'Importer';

  @override
  String get importHelp =>
      'Colle tes lignes depuis un tableur : une ligne par produit, dans l\'ordre nom, prix, unité, rayon, stock. Les produits arrivent en brouillon : ajoute les photos, puis publie.';

  @override
  String get importExample =>
      'Tomates ; 500 ; tas ; Légumes ; 40\nHuile rouge ; 1 200 ; ; Huiles et condiments ;';

  @override
  String get importPasteLabel => 'Tes lignes';

  @override
  String get importCheck => 'Vérifier';

  @override
  String importSummary(int count, int errors) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lignes prêtes',
      one: '1 ligne prête',
      zero: 'Aucune ligne prête',
    );
    String _temp1 = intl.Intl.pluralLogic(
      errors,
      locale: localeName,
      other: '$errors erreurs',
      one: '1 erreur',
      zero: 'aucune erreur',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String importLineError(int line, String reason) {
    return 'Ligne $line : $reason';
  }

  @override
  String get importNameInvalid => 'nom manquant ou trop long';

  @override
  String get importPriceInvalid => 'prix illisible';

  @override
  String get importCategoryUnknown => 'rayon inconnu';

  @override
  String get importUnitUnknown => 'unité inconnue';

  @override
  String get importStockInvalid => 'stock illisible';

  @override
  String importRun(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importer $count produits',
      one: 'Importer 1 produit',
    );
    return '$_temp0';
  }

  @override
  String importDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brouillons créés',
      one: '1 brouillon créé',
    );
    return '$_temp0';
  }

  @override
  String get importDoneHint =>
      'Ajoute les photos, puis publie depuis le catalogue.';

  @override
  String get importBackToCatalog => 'Voir le catalogue';

  @override
  String get callMicrophoneOn => 'Micro ouvert';

  @override
  String get callMicrophoneOff => 'Micro coupé';

  @override
  String get callSpeakerOn => 'Haut-parleur';

  @override
  String get callSpeakerOff => 'Écouteur';

  @override
  String get callMediaFailed =>
      'Son indisponible : vérifie ta connexion, puis rappelle.';

  @override
  String get adminRoleLabel => 'Rôle';

  @override
  String get adminRoleSuperAdmin => 'Super-admin';

  @override
  String get adminRoleOperations => 'Opérations';

  @override
  String get adminRoleSupport => 'Support';

  @override
  String get adminRoleFinance => 'Finance';

  @override
  String get adminRoleContent => 'Contenu';

  @override
  String get adminRoleAnalyst => 'Analyste';

  @override
  String get adminSettingsNoneForRole =>
      'Aucun réglage n\'est ouvert à ton rôle.';

  @override
  String get adminTabMcp => 'MCP';

  @override
  String get adminMcpHelp =>
      'Une clé MCP permet à un assistant (Claude, par exemple) de piloter l\'admin et d\'interroger les analytics avec tes droits. Chaque action est journalisée.';

  @override
  String get adminMcpName => 'Nom de la clé';

  @override
  String get adminMcpCreate => 'Créer une clé';

  @override
  String get adminMcpNewKeyTitle =>
      'Copie ta clé maintenant : elle ne sera plus jamais montrée.';

  @override
  String get adminMcpKeyLabel => 'Clé';

  @override
  String get adminMcpEndpoint => 'Adresse du serveur MCP';

  @override
  String get adminMcpCopy => 'Copier';

  @override
  String get adminMcpCopied => 'Copié';

  @override
  String get adminMcpDone => 'J\'ai copié la clé';

  @override
  String get adminMcpRevoke => 'Révoquer';

  @override
  String get adminMcpRevoked => 'Révoquée';

  @override
  String adminMcpLastUsed(String date) {
    return 'Dernière utilisation : $date';
  }

  @override
  String get adminMcpNeverUsed => 'Jamais utilisée';

  @override
  String get staffTitle => 'Équipe';

  @override
  String get staffHelp =>
      'Invite les personnes qui t\'aident. Chacune a son compte et ne voit que son travail ; l\'argent, les réglages et l\'équipe restent à toi.';

  @override
  String get staffRoleLabel => 'Rôle';

  @override
  String get staffRoleOwner => 'Propriétaire';

  @override
  String get staffRoleManager => 'Gérante';

  @override
  String get staffRolePreparer => 'Préparatrice';

  @override
  String get staffRoleCashier => 'Caissière';

  @override
  String get staffRoleManagerHint =>
      'Commandes, catalogue, prix, messages, caisse et offres.';

  @override
  String get staffRolePreparerHint => 'Commandes et messages des clientes.';

  @override
  String get staffRoleCashierHint => 'Caisse, encaissements et commandes.';

  @override
  String get staffInvite => 'Inviter';

  @override
  String get staffInvited => 'Invitation envoyée';

  @override
  String get staffRemove => 'Retirer de l\'équipe';

  @override
  String get staffEmpty => 'Personne dans l\'équipe';

  @override
  String get staffEmptyHint =>
      'Invite une personne par son email : elle se connecte à DYM Vendeuse avec ce compte.';

  @override
  String get staffGroupTeam => 'Équipe';

  @override
  String get staffSwitchStore => 'Changer de boutique';

  @override
  String staffYouAre(String role) {
    return 'Tu travailles ici comme $role.';
  }

  @override
  String get authEmailHint => 'prenom@exemple.com';

  @override
  String get cartMoreActions => 'Plus d\'actions';

  @override
  String get adminGroupPilot => 'Pilotage';

  @override
  String get adminGroupCommerce => 'Commerce';

  @override
  String get adminGroupMoney => 'Argent';

  @override
  String get adminGroupQuality => 'Qualité';

  @override
  String get adminGroupSettings => 'Réglages';

  @override
  String get adminBrandSub => 'Console de l\'équipe';

  @override
  String get adminCrumbRoot => 'DYM';

  @override
  String get adminOpenMenu => 'Ouvrir le menu';

  @override
  String get adminDashboardSubtitle =>
      'Ventes, livraisons et incidents. Chaque chiffre vient des mêmes données que le reste de DYM.';

  @override
  String get adminCardSales => 'Ventes';

  @override
  String get adminCardStores => 'Boutiques';

  @override
  String get adminCardDelivery => 'Livraison';

  @override
  String get adminCardDaily => 'Commandes dans le temps';

  @override
  String get adminCardJourney => 'Parcours des clientes';

  @override
  String get adminMetricSales => 'Ventes livrées';

  @override
  String get adminMetricDelivered => 'Livrées';

  @override
  String get adminMetricBasket => 'Panier moyen';

  @override
  String get adminMetricActive => 'Actives';

  @override
  String get adminMetricToValidate => 'À valider';

  @override
  String get adminMetricActiveClients => 'Clientes actives';

  @override
  String get adminMetricDeliveryRate => 'Livraisons réussies';

  @override
  String get adminMetricCouriers => 'Livreurs en ligne';

  @override
  String get adminMetricAccept => 'Prise en charge';

  @override
  String get adminMetricOrders => 'Commandes';

  @override
  String get adminMetricPeak => 'Pic';

  @override
  String get adminMetricDisputes => 'Litiges ouverts';

  @override
  String get adminMetricTickets => 'Demandes ouvertes';

  @override
  String get adminMetricStuck => 'Bloquées';

  @override
  String get adminMetricVisitors => 'Clientes venues';

  @override
  String get adminMetricConversion => 'Conversion';

  @override
  String get adminSoldByAisle => 'Articles vendus par rayon';

  @override
  String get adminMostActiveStores => 'Les plus actives';

  @override
  String get adminOrdersOutcome => 'Issue des commandes';

  @override
  String get adminNoteSales =>
      'Commandes livrées · comparées à la période précédente';

  @override
  String get adminNoteStores => 'Ventes livrées par boutique sur la période';

  @override
  String adminNoteDelivery(String relaunches, String refused) {
    return '$relaunches relances · $refused refus automatiques';
  }

  @override
  String get adminNoteTodo => 'Touchez une ligne pour ouvrir l\'écran où agir';

  @override
  String get adminNoteDaily =>
      'Toutes boutiques · une barre par point de la période';

  @override
  String get adminPillDispute => 'Litige';

  @override
  String get adminPillTicket => 'Support';

  @override
  String get adminPillOrder => 'Commande';

  @override
  String get adminPillStore => 'Boutique';

  @override
  String get adminPillCourier => 'Livraison';

  @override
  String get adminSignInHeroTitle =>
      'Le marché du quartier, piloté en un coup d\'œil.';

  @override
  String get adminSignInHeroBody =>
      'Commandes, boutiques, livreurs et paiements : toute l\'activité de DYM au même endroit.';

  @override
  String adminStoresSubtitle(int total, String active, String drafts) {
    return '$total boutiques · $active actives · $drafts à valider';
  }

  @override
  String get adminColType => 'Type';

  @override
  String get adminUnitMinutes => 'min';

  @override
  String get adminUnitHours => 'h';

  @override
  String get adminUnitDays => 'j';
}
