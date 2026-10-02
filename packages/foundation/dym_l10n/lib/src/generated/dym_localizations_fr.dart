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
  String get authZoneLabel => 'Ton quartier';

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
      'Position indisponible : choisis ton quartier dans la liste.';

  @override
  String zoneSuggestion(String zone) {
    return 'Tu es à $zone ?';
  }

  @override
  String get zoneConfirm => 'Oui, c\'est ça';

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
}
