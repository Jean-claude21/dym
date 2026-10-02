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
}
