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
}
