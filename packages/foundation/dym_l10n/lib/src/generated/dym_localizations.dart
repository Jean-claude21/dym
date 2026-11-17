import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'dym_localizations_en.dart';
import 'dym_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of DymLocalizations
/// returned by `DymLocalizations.of(context)`.
///
/// Applications need to include `DymLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/dym_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: DymLocalizations.localizationsDelegates,
///   supportedLocales: DymLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the DymLocalizations.supportedLocales
/// property.
abstract class DymLocalizations {
  DymLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static DymLocalizations of(BuildContext context) {
    return Localizations.of<DymLocalizations>(context, DymLocalizations)!;
  }

  static const LocalizationsDelegate<DymLocalizations> delegate =
      _DymLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('en'),
  ];

  /// Nom de l'app cliente.
  ///
  /// In fr, this message translates to:
  /// **'DYM'**
  String get appNameClient;

  /// Nom de l'app vendeuse.
  ///
  /// In fr, this message translates to:
  /// **'DYM Vendeuse'**
  String get appNameVendor;

  /// Nom de l'app d'administration.
  ///
  /// In fr, this message translates to:
  /// **'DYM Admin'**
  String get appNameAdmin;

  /// Accroche générique (sans ville : la ville vient de la configuration).
  ///
  /// In fr, this message translates to:
  /// **'Le marché près de chez toi, livré chez toi'**
  String get tagline;

  /// Accroche de l'app vendeuse.
  ///
  /// In fr, this message translates to:
  /// **'Ta boutique, tes commandes, ta caisse'**
  String get vendorTagline;

  /// Accroche de l'admin.
  ///
  /// In fr, this message translates to:
  /// **'Résoudre chaque incident en moins d\'une heure'**
  String get adminTagline;

  /// Démarrage de l'app.
  ///
  /// In fr, this message translates to:
  /// **'Préparation…'**
  String get startupPreparing;

  /// Environnement technique affiché hors production.
  ///
  /// In fr, this message translates to:
  /// **'Environnement : {name}'**
  String environmentLabel(String name);

  /// L'app est compilée sans configuration valide.
  ///
  /// In fr, this message translates to:
  /// **'Configuration manquante'**
  String get configErrorTitle;

  /// Explication de l'erreur de configuration.
  ///
  /// In fr, this message translates to:
  /// **'Cette version de l\'app n\'est pas configurée. Installe la version officielle.'**
  String get configErrorMessage;

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navOrders.
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get navOrders;

  /// No description provided for @navStores.
  ///
  /// In fr, this message translates to:
  /// **'Boutiques'**
  String get navStores;

  /// No description provided for @navSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get navSettings;

  /// Passer l'introduction
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get welcomeSkip;

  /// Bienvenue, écran 1
  ///
  /// In fr, this message translates to:
  /// **'Le marché de ton quartier, livré chez toi'**
  String get welcomeSlide1Title;

  /// Bienvenue, écran 1
  ///
  /// In fr, this message translates to:
  /// **'Les boutiques de ton quartier, un seul panier, livré chez toi.'**
  String get welcomeSlide1Body;

  /// Bienvenue, écran 2
  ///
  /// In fr, this message translates to:
  /// **'Plusieurs boutiques, un seul panier'**
  String get welcomeSlide2Title;

  /// Bienvenue, écran 2
  ///
  /// In fr, this message translates to:
  /// **'Les tomates du marché, le poisson fumé, les épices : tu commandes tout en une fois.'**
  String get welcomeSlide2Body;

  /// Bienvenue, écran 3
  ///
  /// In fr, this message translates to:
  /// **'Cash ou Mobile Money'**
  String get welcomeSlide3Title;

  /// Bienvenue, écran 3
  ///
  /// In fr, this message translates to:
  /// **'Tu paies à la livraison ou par Mobile Money, et tu suis ton livreur.'**
  String get welcomeSlide3Body;

  /// Indicateur de page (lecteur d'écran)
  ///
  /// In fr, this message translates to:
  /// **'Écran {current} sur {total}'**
  String welcomePage(int current, int total);

  /// Bouton Google
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get authContinueGoogle;

  /// Bouton email
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec mon email'**
  String get authContinueEmail;

  /// Mention légale
  ///
  /// In fr, this message translates to:
  /// **'En continuant, tu acceptes les conditions d\'utilisation et la politique de confidentialité.'**
  String get authLegal;

  /// Bouton retour
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get authBack;

  /// Titre écran email
  ///
  /// In fr, this message translates to:
  /// **'Ton email'**
  String get authEmailTitle;

  /// Sous-titre écran email
  ///
  /// In fr, this message translates to:
  /// **'On t\'envoie un code à 6 chiffres. Pas de mot de passe à retenir.'**
  String get authEmailSubtitle;

  /// Champ email
  ///
  /// In fr, this message translates to:
  /// **'Adresse email'**
  String get authEmailLabel;

  /// Email valide
  ///
  /// In fr, this message translates to:
  /// **'Adresse valide'**
  String get authEmailValid;

  /// Email invalide
  ///
  /// In fr, this message translates to:
  /// **'Vérifie ton adresse email'**
  String get authEmailInvalid;

  /// Confidentialité de l'email
  ///
  /// In fr, this message translates to:
  /// **'Ton email reste privé : il n\'est montré à personne.'**
  String get authEmailPrivacy;

  /// Bouton envoyer le code
  ///
  /// In fr, this message translates to:
  /// **'Recevoir mon code'**
  String get authSendCode;

  /// Titre écran code
  ///
  /// In fr, this message translates to:
  /// **'Entre le code'**
  String get authCodeTitle;

  /// Code envoyé à
  ///
  /// In fr, this message translates to:
  /// **'Envoyé à {email}'**
  String authCodeSentTo(String email);

  /// Modifier l'email
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get authChangeEmail;

  /// Champ du code (lecteur d'écran)
  ///
  /// In fr, this message translates to:
  /// **'Code à 6 chiffres'**
  String get authCodeLabel;

  /// Compte à rebours
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code dans {seconds} s'**
  String authResendIn(int seconds);

  /// Bouton renvoyer
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get authResend;

  /// Astuce code
  ///
  /// In fr, this message translates to:
  /// **'Astuce : le code arrive en moins d\'une minute. Regarde aussi dans les spams.'**
  String get authCodeTip;

  /// Code faux
  ///
  /// In fr, this message translates to:
  /// **'Ce code ne marche pas. Vérifie-le ou demande-en un nouveau.'**
  String get authCodeWrong;

  /// Titre profil
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur DYM !'**
  String get authProfileTitle;

  /// Sous-titre profil
  ///
  /// In fr, this message translates to:
  /// **'Deux questions et c\'est parti.'**
  String get authProfileSubtitle;

  /// Champ prénom
  ///
  /// In fr, this message translates to:
  /// **'Ton prénom'**
  String get authFirstNameLabel;

  /// Prénom invalide
  ///
  /// In fr, this message translates to:
  /// **'Entre ton prénom (40 caractères au plus)'**
  String get authFirstNameInvalid;

  /// Photo facultative
  ///
  /// In fr, this message translates to:
  /// **'Photo (facultatif)'**
  String get authPhotoOptional;

  /// Choix du quartier
  ///
  /// In fr, this message translates to:
  /// **'Ton adresse'**
  String get authZoneLabel;

  /// Explication du quartier
  ///
  /// In fr, this message translates to:
  /// **'Ton quartier sert à te proposer ce qui est près de toi.'**
  String get authZoneHint;

  /// Quartier manquant
  ///
  /// In fr, this message translates to:
  /// **'Choisis ton quartier'**
  String get authZoneRequired;

  /// Bouton terminer le profil
  ///
  /// In fr, this message translates to:
  /// **'C\'est parti'**
  String get authStart;

  /// Hors ligne
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion. Vérifie ton réseau et réessaie.'**
  String get errorOffline;

  /// Erreur générique
  ///
  /// In fr, this message translates to:
  /// **'Un problème est survenu. Réessaie dans un instant.'**
  String get errorGeneric;

  /// Session expirée
  ///
  /// In fr, this message translates to:
  /// **'Ta session a expiré. Reconnecte-toi.'**
  String get errorSessionExpired;

  /// Bouton réessayer
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// Titre du compte
  ///
  /// In fr, this message translates to:
  /// **'Moi'**
  String get accountTitle;

  /// Ligne adresses
  ///
  /// In fr, this message translates to:
  /// **'Mes adresses'**
  String get accountAddresses;

  /// Ligne notifications
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get accountNotifications;

  /// Ligne langue
  ///
  /// In fr, this message translates to:
  /// **'Langue · {language}'**
  String accountLanguage(String language);

  /// Nom de la langue courante
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageName;

  /// Ligne aide
  ///
  /// In fr, this message translates to:
  /// **'Aide et contact'**
  String get accountHelp;

  /// Déconnexion
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get accountSignOut;

  /// Suppression
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get accountDelete;

  /// Titre confirmation
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ton compte ?'**
  String get accountDeleteTitle;

  /// Texte confirmation
  ///
  /// In fr, this message translates to:
  /// **'Ton profil, tes adresses et ton historique seront effacés. Tes commandes en cours doivent d\'abord être livrées ou annulées. Cette action est définitive.'**
  String get accountDeleteBody;

  /// Bouton confirmer
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement'**
  String get accountDeleteConfirm;

  /// Annuler
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// Fonction à venir
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get comingSoon;

  /// Bienvenue vendeuse
  ///
  /// In fr, this message translates to:
  /// **'Ta boutique, tes commandes, ta caisse. Au marché, chez toi ou dans ta boutique.'**
  String get vendorWelcomeBody;

  /// Avantage 1
  ///
  /// In fr, this message translates to:
  /// **'Publie un produit en moins d\'une minute'**
  String get vendorPoint1;

  /// Avantage 2
  ///
  /// In fr, this message translates to:
  /// **'Reçois des commandes claires, sans DM'**
  String get vendorPoint2;

  /// Avantage 3
  ///
  /// In fr, this message translates to:
  /// **'Encaisse en cash ou Mobile Money'**
  String get vendorPoint3;

  /// Après connexion vendeuse
  ///
  /// In fr, this message translates to:
  /// **'Ton compte est prêt. Prochaine étape : ta boutique.'**
  String get vendorNextStep;

  /// Accueil provisoire
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {name} !'**
  String homeHello(String name);

  /// Titre connexion admin
  ///
  /// In fr, this message translates to:
  /// **'Connexion de l\'équipe'**
  String get adminSignInTitle;

  /// Texte connexion admin
  ///
  /// In fr, this message translates to:
  /// **'Accès réservé à l\'équipe DYM : reçois un code sur ton email d\'admin.'**
  String get adminSignInBody;

  /// Bouton admin
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get adminContinueGoogle;

  /// Note sécurité admin
  ///
  /// In fr, this message translates to:
  /// **'Accès réservé à l\'équipe · Déconnexion après 30 min d\'inactivité'**
  String get adminSecurityNote;

  /// Note audit
  ///
  /// In fr, this message translates to:
  /// **'Chaque action est enregistrée dans le journal d\'audit.'**
  String get adminAuditNote;

  /// Accès refusé
  ///
  /// In fr, this message translates to:
  /// **'Accès réservé à l\'équipe DYM. Ce compte n\'a pas les droits d\'administration.'**
  String get adminAccessDenied;

  /// Connexion Google : aucun compte sur l'appareil
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte Google sur ce téléphone. Ajoute-en un dans les réglages, ou continue avec ton email.'**
  String get authGoogleNoAccount;

  /// Google non configuré
  ///
  /// In fr, this message translates to:
  /// **'La connexion Google n\'est pas configurée pour cet environnement.'**
  String get adminGoogleUnavailable;

  /// Déconnexion pour inactivité
  ///
  /// In fr, this message translates to:
  /// **'Tu as été déconnecté après 30 minutes d\'inactivité.'**
  String get adminSignedOutInactive;

  /// Onglet boutique
  ///
  /// In fr, this message translates to:
  /// **'Boutique'**
  String get navStore;

  /// Onglet de la vendeuse
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get navToday;

  /// Onglet de la vendeuse
  ///
  /// In fr, this message translates to:
  /// **'Catalogue'**
  String get navCatalog;

  /// No description provided for @vendorGreeting.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {name}'**
  String vendorGreeting(String name);

  /// QR ou code pour la cliente
  ///
  /// In fr, this message translates to:
  /// **'Encaisser'**
  String get vendorCharge;

  /// Vente hors app, dans la caisse
  ///
  /// In fr, this message translates to:
  /// **'Vente cash'**
  String get vendorCashSale;

  /// Compte, aide, langue, déconnexion
  ///
  /// In fr, this message translates to:
  /// **'Mon compte'**
  String get storeMyAccount;

  /// Groupe de Boutique
  ///
  /// In fr, this message translates to:
  /// **'Argent'**
  String get storeGroupMoney;

  /// Groupe de Boutique
  ///
  /// In fr, this message translates to:
  /// **'Vendre plus'**
  String get storeGroupSell;

  /// Groupe de Boutique
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get storeGroupSettings;

  /// Progression de l'onboarding
  ///
  /// In fr, this message translates to:
  /// **'Étape {current} sur {total}'**
  String storeStepLabel(int current, int total);

  /// Étape suivante
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get storeContinue;

  /// Enregistrer un réglage
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get storeSave;

  /// Échec d'enregistrement
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement impossible. Vérifie ta connexion et réessaie.'**
  String get storeSaveError;

  /// Ouverture refusée : boutique incomplète
  ///
  /// In fr, this message translates to:
  /// **'Il manque encore des informations.'**
  String get storeIncomplete;

  /// Étape 1
  ///
  /// In fr, this message translates to:
  /// **'Comment s\'appelle ta boutique ?'**
  String get storeNameTitle;

  /// Étape 1
  ///
  /// In fr, this message translates to:
  /// **'C\'est le nom que verront les clientes. Tu pourras le changer.'**
  String get storeNameSubtitle;

  /// Champ nom
  ///
  /// In fr, this message translates to:
  /// **'Nom de la boutique'**
  String get storeNameLabel;

  /// Nom invalide
  ///
  /// In fr, this message translates to:
  /// **'De 2 à 60 caractères.'**
  String get storeNameInvalid;

  /// Champ présentation
  ///
  /// In fr, this message translates to:
  /// **'Présente ta boutique (facultatif)'**
  String get storeDescriptionLabel;

  /// Indication présentation
  ///
  /// In fr, this message translates to:
  /// **'Ce que tu vends, ce qui te rend unique'**
  String get storeDescriptionHint;

  /// Compteur de caractères
  ///
  /// In fr, this message translates to:
  /// **'{count}/{max}'**
  String storeCharCount(int count, int max);

  /// Aperçu
  ///
  /// In fr, this message translates to:
  /// **'Aperçu pour les clientes'**
  String get storePreviewTitle;

  /// Aperçu : quartier et état
  ///
  /// In fr, this message translates to:
  /// **'{zone} · ouvert'**
  String storePreviewPlace(String zone);

  /// Étape 2
  ///
  /// In fr, this message translates to:
  /// **'Où vends-tu ?'**
  String get storeOriginTitle;

  /// Étape 2
  ///
  /// In fr, this message translates to:
  /// **'Chaque boutique a sa place sur DYM. Tu pourras changer plus tard.'**
  String get storeOriginSubtitle;

  /// Note fait maison
  ///
  /// In fr, this message translates to:
  /// **'Ton adresse reste privée : les clientes voient seulement ton quartier.'**
  String get storeOriginPrivacy;

  /// Étape 3
  ///
  /// In fr, this message translates to:
  /// **'Où récupérer tes commandes ?'**
  String get storeAddressTitle;

  /// Étape 3
  ///
  /// In fr, this message translates to:
  /// **'Le livreur passe chercher les commandes ici.'**
  String get storeAddressSubtitle;

  /// Quartier de la boutique
  ///
  /// In fr, this message translates to:
  /// **'Ton quartier'**
  String get storeZoneLabel;

  /// Quartier public
  ///
  /// In fr, this message translates to:
  /// **'(visible par les clientes)'**
  String get storeZoneVisible;

  /// Champ adresse
  ///
  /// In fr, this message translates to:
  /// **'Adresse de ramassage'**
  String get storeAddressLabel;

  /// Indication adresse
  ///
  /// In fr, this message translates to:
  /// **'Rue, maison, portail…'**
  String get storeAddressHint;

  /// Champ repère
  ///
  /// In fr, this message translates to:
  /// **'Repère'**
  String get storeLandmarkLabel;

  /// Indication repère
  ///
  /// In fr, this message translates to:
  /// **'Ex. : derrière la pharmacie'**
  String get storeLandmarkHint;

  /// Adresse privée
  ///
  /// In fr, this message translates to:
  /// **'Ton adresse reste privée : les clientes voient seulement ton quartier. Seul le livreur de la commande la reçoit.'**
  String get storeAddressPrivacy;

  /// Étape 4
  ///
  /// In fr, this message translates to:
  /// **'Que vends-tu surtout ?'**
  String get storeCategoryTitle;

  /// Étape 4
  ///
  /// In fr, this message translates to:
  /// **'Ta boutique apparaîtra dans ce rayon.'**
  String get storeCategorySubtitle;

  /// Étape 5
  ///
  /// In fr, this message translates to:
  /// **'Où livres-tu ?'**
  String get storeDeliveryTitle;

  /// Titre de la liste des quartiers de livraison (inscription vendeuse)
  ///
  /// In fr, this message translates to:
  /// **'Quartiers desservis'**
  String get storeDeliveryZonesTitle;

  /// Étape 5
  ///
  /// In fr, this message translates to:
  /// **'Les quartiers où tu acceptes les commandes. DYM s\'occupe du livreur.'**
  String get storeDeliverySubtitle;

  /// Tous les quartiers
  ///
  /// In fr, this message translates to:
  /// **'Tout sélectionner'**
  String get storeSelectAll;

  /// Délai
  ///
  /// In fr, this message translates to:
  /// **'Temps de préparation'**
  String get storePrepTitle;

  /// Délai en minutes
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min'**
  String storePrepMinutes(int minutes);

  /// Délai en heures
  ///
  /// In fr, this message translates to:
  /// **'{hours} h'**
  String storePrepHours(int hours);

  /// Retrait sur place
  ///
  /// In fr, this message translates to:
  /// **'Les clientes peuvent venir chercher'**
  String get storePickupTitle;

  /// Retrait sur place
  ///
  /// In fr, this message translates to:
  /// **'Retrait sur place, sans frais de livraison'**
  String get storePickupSubtitle;

  /// Étape 6
  ///
  /// In fr, this message translates to:
  /// **'Comment veux-tu être payée ?'**
  String get storePaymentTitle;

  /// Étape 6
  ///
  /// In fr, this message translates to:
  /// **'Les clientes choisissent parmi ces moyens.'**
  String get storePaymentSubtitle;

  /// Cash
  ///
  /// In fr, this message translates to:
  /// **'Le livreur te remet l\'argent.'**
  String get storePaymentCashHint;

  /// Badge moyen inactif
  ///
  /// In fr, this message translates to:
  /// **'Bientôt'**
  String get storePaymentSoon;

  /// Moyen inactif
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible.'**
  String get storePaymentSoonHint;

  /// Note Mobile Money
  ///
  /// In fr, this message translates to:
  /// **'Le paiement Mobile Money arrive dès que DYM l\'active dans ton pays.'**
  String get storePaymentMomoNote;

  /// Étape 7
  ///
  /// In fr, this message translates to:
  /// **'Quand es-tu ouverte ?'**
  String get storeHoursTitle;

  /// Étape 7
  ///
  /// In fr, this message translates to:
  /// **'Les commandes arrivent seulement pendant tes horaires.'**
  String get storeHoursSubtitle;

  /// Jour fermé
  ///
  /// In fr, this message translates to:
  /// **'Fermé'**
  String get storeHoursClosed;

  /// Heure d'ouverture
  ///
  /// In fr, this message translates to:
  /// **'Ouverture'**
  String get storeHoursOpens;

  /// Heure de fermeture
  ///
  /// In fr, this message translates to:
  /// **'Fermeture'**
  String get storeHoursCloses;

  /// Copier le premier jour
  ///
  /// In fr, this message translates to:
  /// **'Mêmes horaires tous les jours ouverts'**
  String get storeHoursSameEveryDay;

  /// Horaires inversés
  ///
  /// In fr, this message translates to:
  /// **'L\'ouverture doit précéder la fermeture.'**
  String get storeHoursInvalid;

  /// Jour 1
  ///
  /// In fr, this message translates to:
  /// **'Lundi'**
  String get weekday1;

  /// Jour 2
  ///
  /// In fr, this message translates to:
  /// **'Mardi'**
  String get weekday2;

  /// Jour 3
  ///
  /// In fr, this message translates to:
  /// **'Mercredi'**
  String get weekday3;

  /// Jour 4
  ///
  /// In fr, this message translates to:
  /// **'Jeudi'**
  String get weekday4;

  /// Jour 5
  ///
  /// In fr, this message translates to:
  /// **'Vendredi'**
  String get weekday5;

  /// Jour 6
  ///
  /// In fr, this message translates to:
  /// **'Samedi'**
  String get weekday6;

  /// Jour 7
  ///
  /// In fr, this message translates to:
  /// **'Dimanche'**
  String get weekday7;

  /// Publier la boutique
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir ma boutique'**
  String get storeOpenAction;

  /// Écran de réussite
  ///
  /// In fr, this message translates to:
  /// **'Ta boutique est ouverte !'**
  String get storeOpenedTitle;

  /// Nom et quartier
  ///
  /// In fr, this message translates to:
  /// **'{name} · {zone}'**
  String storeNamePlace(String name, String zone);

  /// Résumé
  ///
  /// In fr, this message translates to:
  /// **'Nom et présentation'**
  String get storeSummaryName;

  /// Résumé origine
  ///
  /// In fr, this message translates to:
  /// **'{origin} · adresse privée'**
  String storeSummaryOrigin(String origin);

  /// Résumé livraison
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Livraison dans 1 quartier} other{Livraison dans {count} quartiers}}'**
  String storeSummaryDelivery(int count);

  /// Horaires identiques sur des jours consécutifs (last : numéro du dernier jour, 1 = lundi)
  ///
  /// In fr, this message translates to:
  /// **'{first} au {last, select, 1{lundi} 2{mardi} 3{mercredi} 4{jeudi} 5{vendredi} 6{samedi} other{dimanche}}, {opens} – {closes}'**
  String storeHoursRange(
    String first,
    String last,
    String opens,
    String closes,
  );

  /// Un seul jour
  ///
  /// In fr, this message translates to:
  /// **'{day}, {opens} – {closes}'**
  String storeHoursSingle(String day, String opens, String closes);

  /// Horaires variés
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 jour par semaine} other{{count} jours par semaine}}'**
  String storeHoursDays(int count);

  /// Après ouverture
  ///
  /// In fr, this message translates to:
  /// **'Ajouter mon premier produit'**
  String get storeAddFirstProduct;

  /// Après ouverture
  ///
  /// In fr, this message translates to:
  /// **'Voir ma boutique'**
  String get storeSeeMine;

  /// Réglages de la boutique
  ///
  /// In fr, this message translates to:
  /// **'Ma boutique'**
  String get myStoreTitle;

  /// Boutique ouverte
  ///
  /// In fr, this message translates to:
  /// **'Ouverte'**
  String get myStoreOpen;

  /// Boutique ouverte
  ///
  /// In fr, this message translates to:
  /// **'Les clientes peuvent commander'**
  String get myStoreOpenHint;

  /// Boutique fermée
  ///
  /// In fr, this message translates to:
  /// **'Fermée'**
  String get myStoreClosed;

  /// Boutique active mais hors de ses horaires
  ///
  /// In fr, this message translates to:
  /// **'Fermée pour l\'instant'**
  String get myStoreClosedByHours;

  /// Détail de la fermeture selon les horaires
  ///
  /// In fr, this message translates to:
  /// **'Hors de tes horaires : les clientes peuvent commander pour un créneau où tu es ouverte'**
  String get myStoreClosedByHoursHint;

  /// Fiche produit d'une boutique fermée
  ///
  /// In fr, this message translates to:
  /// **'Cette boutique est fermée pour le moment. Tu peux commander pour un créneau où elle est ouverte.'**
  String get productStoreClosed;

  /// Boutique fermée
  ///
  /// In fr, this message translates to:
  /// **'Les clientes ne peuvent pas commander'**
  String get myStoreClosedHint;

  /// Boutique suspendue
  ///
  /// In fr, this message translates to:
  /// **'Ta boutique est suspendue par l\'équipe DYM. Contacte-nous pour la rouvrir.'**
  String get myStoreSuspended;

  /// Ligne origine
  ///
  /// In fr, this message translates to:
  /// **'Où vends-tu'**
  String get myStoreRowOrigin;

  /// Adresse privée
  ///
  /// In fr, this message translates to:
  /// **'privée'**
  String get myStoreAddressPrivate;

  /// Ligne livraison
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get myStoreRowDelivery;

  /// Valeur livraison
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 quartier} other{{count} quartiers}} · {prep}'**
  String myStoreDeliveryValue(int count, String prep);

  /// Ligne paiement
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get myStoreRowPayment;

  /// Ligne horaires
  ///
  /// In fr, this message translates to:
  /// **'Horaires'**
  String get myStoreRowHours;

  /// Ligne rayon principal
  ///
  /// In fr, this message translates to:
  /// **'Rayon'**
  String get myStoreRowCategory;

  /// Onglet produits
  ///
  /// In fr, this message translates to:
  /// **'Produits'**
  String get navProducts;

  /// Liste des produits
  ///
  /// In fr, this message translates to:
  /// **'Mes produits'**
  String get productsTitle;

  /// Filtre : tous les produits
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get productsAll;

  /// Filtre : produits archivés
  ///
  /// In fr, this message translates to:
  /// **'Archivés'**
  String get productsArchived;

  /// Liste vide
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit pour l\'instant.'**
  String get productsEmpty;

  /// Liste vide
  ///
  /// In fr, this message translates to:
  /// **'Ajoute ton premier produit : une photo suffit pour commencer.'**
  String get productsEmptyHint;

  /// Bouton d'ajout
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un produit'**
  String get productsAdd;

  /// Interrupteur de stock
  ///
  /// In fr, this message translates to:
  /// **'En stock'**
  String get productInStock;

  /// Produit en rupture
  ///
  /// In fr, this message translates to:
  /// **'Rupture'**
  String get productOutOfStock;

  /// Produit non publié
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get productDraft;

  /// Stock suivi
  ///
  /// In fr, this message translates to:
  /// **'{count} en stock'**
  String productStockCount(int count);

  /// Nombre de variantes
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 variante} other{{count} variantes}}'**
  String productVariantCount(int count);

  /// Restaurer un produit archivé
  ///
  /// In fr, this message translates to:
  /// **'Restaurer'**
  String get productRestore;

  /// Archiver un produit
  ///
  /// In fr, this message translates to:
  /// **'Archiver'**
  String get productArchive;

  /// Supprimer un brouillon
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le brouillon'**
  String get productDeleteDraft;

  /// Modifier un produit
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get productEdit;

  /// Menu d'un produit
  ///
  /// In fr, this message translates to:
  /// **'Actions sur {name}'**
  String productActions(String name);

  /// Éditeur, étape 1
  ///
  /// In fr, this message translates to:
  /// **'Nouveau produit'**
  String get productNewTitle;

  /// Éditeur d'un produit existant
  ///
  /// In fr, this message translates to:
  /// **'Modifier le produit'**
  String get productEditTitle;

  /// Éditeur, étape 1
  ///
  /// In fr, this message translates to:
  /// **'Prends une photo, DYM remplit la fiche.'**
  String get productPhotoSubtitle;

  /// Appareil photo
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get productTakePhoto;

  /// Galerie
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get productChoosePhoto;

  /// Ajouter une photo
  ///
  /// In fr, this message translates to:
  /// **'Photo'**
  String get productAddPhoto;

  /// Nombre de photos
  ///
  /// In fr, this message translates to:
  /// **'{count}/{max} photos'**
  String productPhotoCount(int count, int max);

  /// Retirer une photo
  ///
  /// In fr, this message translates to:
  /// **'Retirer la photo'**
  String get productRemovePhoto;

  /// Envoi en cours
  ///
  /// In fr, this message translates to:
  /// **'Envoi de la photo…'**
  String get productPhotoUploading;

  /// Échec d'envoi
  ///
  /// In fr, this message translates to:
  /// **'La photo n\'a pas pu être envoyée. Réessaie.'**
  String get productPhotoFailed;

  /// Proposition en cours
  ///
  /// In fr, this message translates to:
  /// **'DYM prépare la fiche…'**
  String get productSuggesting;

  /// Proposition reçue
  ///
  /// In fr, this message translates to:
  /// **'Proposé par DYM'**
  String get productSuggestedBy;

  /// Proposition reçue
  ///
  /// In fr, this message translates to:
  /// **'Vérifie et corrige si besoin.'**
  String get productSuggestionCheck;

  /// Proposition indisponible
  ///
  /// In fr, this message translates to:
  /// **'Remplis la fiche toi-même.'**
  String get productSuggestionUnavailable;

  /// Champ nom
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get productNameLabel;

  /// Indication nom
  ///
  /// In fr, this message translates to:
  /// **'Ex. : Jus de bissap 50 cl'**
  String get productNameHint;

  /// Nom invalide
  ///
  /// In fr, this message translates to:
  /// **'De 2 à 80 caractères.'**
  String get productNameInvalid;

  /// Rayon du produit
  ///
  /// In fr, this message translates to:
  /// **'Rayon'**
  String get productAisleLabel;

  /// Champ description
  ///
  /// In fr, this message translates to:
  /// **'Description (facultatif)'**
  String get productDescriptionLabel;

  /// Éditeur, étape 2
  ///
  /// In fr, this message translates to:
  /// **'Prix et stock'**
  String get productPriceTitle;

  /// Champ prix
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get productPriceLabel;

  /// Prix invalide
  ///
  /// In fr, this message translates to:
  /// **'Saisis un prix supérieur à zéro.'**
  String get productPriceInvalid;

  /// Unité du marché
  ///
  /// In fr, this message translates to:
  /// **'Unité'**
  String get productUnitLabel;

  /// Bloc des variantes
  ///
  /// In fr, this message translates to:
  /// **'Variantes'**
  String get productVariantsTitle;

  /// Stock suivi
  ///
  /// In fr, this message translates to:
  /// **'Je compte mon stock'**
  String get productTrackStock;

  /// Stock non suivi
  ///
  /// In fr, this message translates to:
  /// **'Sinon, le produit reste disponible tant que tu ne le mets pas en rupture.'**
  String get productTrackStockHint;

  /// Stock d'une variante
  ///
  /// In fr, this message translates to:
  /// **'Stock'**
  String get productStockLabel;

  /// Libellé de variante
  ///
  /// In fr, this message translates to:
  /// **'Variante (ex. : 1 L)'**
  String get productVariantLabel;

  /// Prix d'une variante
  ///
  /// In fr, this message translates to:
  /// **'Prix (facultatif)'**
  String get productVariantPrice;

  /// Ajout de variante
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une variante'**
  String get productVariantAdd;

  /// Retrait de variante
  ///
  /// In fr, this message translates to:
  /// **'Retirer la variante'**
  String get productVariantRemove;

  /// Lecteur d'écran
  ///
  /// In fr, this message translates to:
  /// **'Variante {label}'**
  String productVariantNamed(String label);

  /// Stock moins un
  ///
  /// In fr, this message translates to:
  /// **'Un de moins'**
  String get productStockDecrease;

  /// Stock plus un
  ///
  /// In fr, this message translates to:
  /// **'Un de plus'**
  String get productStockIncrease;

  /// Catégories de la boutique
  ///
  /// In fr, this message translates to:
  /// **'Catégorie de ma boutique'**
  String get productStoreCategoryTitle;

  /// Nouvelle catégorie
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle'**
  String get productStoreCategoryNew;

  /// Publication
  ///
  /// In fr, this message translates to:
  /// **'Publier le produit'**
  String get productPublish;

  /// Photo manquante
  ///
  /// In fr, this message translates to:
  /// **'Ajoute au moins une photo pour publier.'**
  String get productMissingPhoto;

  /// Libellés manquants
  ///
  /// In fr, this message translates to:
  /// **'Donne un nom à chaque variante.'**
  String get productVariantLabelsRequired;

  /// Catégories de la boutique
  ///
  /// In fr, this message translates to:
  /// **'Mes catégories'**
  String get categoriesTitle;

  /// Catégories
  ///
  /// In fr, this message translates to:
  /// **'Range tes produits pour les clientes.'**
  String get categoriesSubtitle;

  /// Champ nouvelle catégorie
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle catégorie'**
  String get categoriesNewHint;

  /// Ajouter une catégorie
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get categoriesAdd;

  /// Produits d'une catégorie
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun produit} =1{1 produit} other{{count} produits}}'**
  String categoriesProductCount(int count);

  /// Catégorie archivée
  ///
  /// In fr, this message translates to:
  /// **'archivée'**
  String get categoriesArchived;

  /// Restaurer une catégorie
  ///
  /// In fr, this message translates to:
  /// **'Réactiver'**
  String get categoriesRestore;

  /// Renommer une catégorie
  ///
  /// In fr, this message translates to:
  /// **'Renommer'**
  String get categoriesRename;

  /// Archiver une catégorie
  ///
  /// In fr, this message translates to:
  /// **'Archiver'**
  String get categoriesArchive;

  /// Nom en double
  ///
  /// In fr, this message translates to:
  /// **'Cette catégorie existe déjà.'**
  String get categoriesDuplicate;

  /// Poignée de déplacement
  ///
  /// In fr, this message translates to:
  /// **'Déplacer {name}'**
  String categoriesMove(String name);

  /// Liste vide
  ///
  /// In fr, this message translates to:
  /// **'Aucune catégorie : crée la première.'**
  String get categoriesEmpty;

  /// Onglet rayons
  ///
  /// In fr, this message translates to:
  /// **'Rayons'**
  String get navAisles;

  /// No description provided for @navMarket.
  ///
  /// In fr, this message translates to:
  /// **'Marché'**
  String get navMarket;

  /// No description provided for @navCuisine.
  ///
  /// In fr, this message translates to:
  /// **'Cuisine'**
  String get navCuisine;

  /// No description provided for @navCart.
  ///
  /// In fr, this message translates to:
  /// **'Panier'**
  String get navCart;

  /// No description provided for @homeDeliverTo.
  ///
  /// In fr, this message translates to:
  /// **'Livraison à'**
  String get homeDeliverTo;

  /// No description provided for @homeActiveOrder.
  ///
  /// In fr, this message translates to:
  /// **'Commande en cours'**
  String get homeActiveOrder;

  /// Estimation de livraison
  ///
  /// In fr, this message translates to:
  /// **'Livré en {minutes} min'**
  String homeDeliveredIn(int minutes);

  /// Barre de recherche de l'accueil
  ///
  /// In fr, this message translates to:
  /// **'Cherche tomates, gari, jus maison…'**
  String get homeSearchHint;

  /// Section accueil
  ///
  /// In fr, this message translates to:
  /// **'Boutiques près de toi'**
  String get homeOpenStores;

  /// Boutiques fermées qui livrent le quartier
  ///
  /// In fr, this message translates to:
  /// **'Les autres boutiques du quartier'**
  String get homeOtherStores;

  /// Aucune boutique ouverte
  ///
  /// In fr, this message translates to:
  /// **'Aucune boutique ouverte pour l\'instant dans ton quartier.'**
  String get homeNoOpenStore;

  /// Section accueil
  ///
  /// In fr, this message translates to:
  /// **'Rayons'**
  String get homeAisles;

  /// Lecteur d'écran : sélecteur de quartier
  ///
  /// In fr, this message translates to:
  /// **'Changer de quartier : {zone}'**
  String homeChangeZone(String zone);

  /// Boutique ouverte
  ///
  /// In fr, this message translates to:
  /// **'Ouvert jusqu\'à {time}'**
  String storeOpenUntil(String time);

  /// Boutique ouverte
  ///
  /// In fr, this message translates to:
  /// **'Ouvert'**
  String get storeOpenNow;

  /// Boutique fermée
  ///
  /// In fr, this message translates to:
  /// **'Fermé'**
  String get storeClosedNow;

  /// Distance courte, en mètres (ex. « 350 m »)
  ///
  /// In fr, this message translates to:
  /// **'{meters} m'**
  String distanceMeters(String meters);

  /// Distance en kilomètres (texte déjà formaté)
  ///
  /// In fr, this message translates to:
  /// **'{km} km'**
  String distanceKm(String km);

  /// Quartier et information
  ///
  /// In fr, this message translates to:
  /// **'{place} · {meta}'**
  String placeAndMeta(String place, String meta);

  /// Choix du quartier
  ///
  /// In fr, this message translates to:
  /// **'Où te livrer ?'**
  String get zonePickerTitle;

  /// Proposer le quartier
  ///
  /// In fr, this message translates to:
  /// **'Utiliser ma position'**
  String get zoneUseLocation;

  /// Position en cours
  ///
  /// In fr, this message translates to:
  /// **'Recherche de ta position…'**
  String get zoneLocating;

  /// Position refusée
  ///
  /// In fr, this message translates to:
  /// **'Position indisponible : cherche ton quartier.'**
  String get zoneLocationUnavailable;

  /// Quartier proposé
  ///
  /// In fr, this message translates to:
  /// **'Tu es à {zone} ?'**
  String zoneSuggestion(String zone);

  /// Confirmer le quartier
  ///
  /// In fr, this message translates to:
  /// **'Oui, c\'est ça'**
  String get zoneConfirm;

  /// Recherche de quartier
  ///
  /// In fr, this message translates to:
  /// **'Cherche ton quartier'**
  String get zoneSearchLabel;

  /// Aide de la recherche de quartier
  ///
  /// In fr, this message translates to:
  /// **'Quartier ou ville'**
  String get zoneSearchHint;

  /// Recherche de quartier vide
  ///
  /// In fr, this message translates to:
  /// **'Aucun quartier trouvé. Essaie un autre nom ou utilise ta position.'**
  String get zoneNoResult;

  /// Position hors zone
  ///
  /// In fr, this message translates to:
  /// **'DYM n\'est pas encore chez toi. Tu peux choisir un quartier desservi, par exemple pour commander pour un proche.'**
  String get zoneOutsideArea;

  /// Filtre de rayon
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get aisleAll;

  /// Filtre d'origine de la vendeuse dans un rayon
  ///
  /// In fr, this message translates to:
  /// **'Où acheter'**
  String get aisleWhere;

  /// Toutes les origines
  ///
  /// In fr, this message translates to:
  /// **'Partout'**
  String get aisleAnywhere;

  /// Rayon vide
  ///
  /// In fr, this message translates to:
  /// **'Rien dans ce rayon pour ton quartier pour l\'instant.'**
  String get aisleEmpty;

  /// Champ de recherche
  ///
  /// In fr, this message translates to:
  /// **'Cherche un produit ou une boutique'**
  String get searchHint;

  /// Bouton effacer
  ///
  /// In fr, this message translates to:
  /// **'Effacer la recherche'**
  String get searchClear;

  /// Onglet de résultats
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get searchTabAll;

  /// Onglet de résultats
  ///
  /// In fr, this message translates to:
  /// **'Produits'**
  String get searchTabProducts;

  /// Onglet de résultats
  ///
  /// In fr, this message translates to:
  /// **'Boutiques'**
  String get searchTabStores;

  /// Bouton filtres
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get searchFilters;

  /// Lecteur d'écran
  ///
  /// In fr, this message translates to:
  /// **'Filtres, {count} actifs'**
  String searchFiltersActive(int count);

  /// Nombre de résultats
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun résultat} =1{1 résultat} other{{count} résultats}}'**
  String searchResultCount(int count);

  /// Aucun résultat
  ///
  /// In fr, this message translates to:
  /// **'Rien trouvé. Essaie un autre mot.'**
  String get searchEmpty;

  /// Recherche trop courte
  ///
  /// In fr, this message translates to:
  /// **'Tape au moins 2 lettres.'**
  String get searchPrompt;

  /// Pagination
  ///
  /// In fr, this message translates to:
  /// **'Voir plus'**
  String get searchLoadMore;

  /// Tri
  ///
  /// In fr, this message translates to:
  /// **'Pertinence'**
  String get sortRelevance;

  /// Tri
  ///
  /// In fr, this message translates to:
  /// **'Prix croissant'**
  String get sortPriceAsc;

  /// Tri
  ///
  /// In fr, this message translates to:
  /// **'Prix décroissant'**
  String get sortPriceDesc;

  /// Feuille des filtres
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get filtersTitle;

  /// Effacer les filtres
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get filtersClear;

  /// Section tri
  ///
  /// In fr, this message translates to:
  /// **'Trier par'**
  String get filtersSort;

  /// Section origine
  ///
  /// In fr, this message translates to:
  /// **'Origine'**
  String get filtersOrigin;

  /// Section prix
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get filtersPrice;

  /// Prix minimum
  ///
  /// In fr, this message translates to:
  /// **'Min'**
  String get filtersMin;

  /// Prix maximum
  ///
  /// In fr, this message translates to:
  /// **'Max'**
  String get filtersMax;

  /// Section rayon
  ///
  /// In fr, this message translates to:
  /// **'Rayon'**
  String get filtersAisle;

  /// Filtre de disponibilité
  ///
  /// In fr, this message translates to:
  /// **'Disponible seulement'**
  String get filtersAvailable;

  /// Appliquer les filtres
  ///
  /// In fr, this message translates to:
  /// **'Voir les résultats'**
  String get filtersApply;

  /// Prix incohérents
  ///
  /// In fr, this message translates to:
  /// **'Le minimum dépasse le maximum.'**
  String get filtersPriceInvalid;

  /// Prix le plus bas
  ///
  /// In fr, this message translates to:
  /// **'dès {price}'**
  String productFrom(String price);

  /// Choix de variante
  ///
  /// In fr, this message translates to:
  /// **'Choisis'**
  String get productChoose;

  /// No description provided for @productAddPrice.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter · {price}'**
  String productAddPrice(String price);

  /// Choix de la variante
  ///
  /// In fr, this message translates to:
  /// **'Format'**
  String get productFormat;

  /// Autres produits de la boutique
  ///
  /// In fr, this message translates to:
  /// **'De la même boutique'**
  String get productSameStore;

  /// No description provided for @storeFactMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{count} min'**
  String storeFactMinutes(int count);

  /// Fait de la boutique
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get storeFactDelivery;

  /// Fait de la boutique
  ///
  /// In fr, this message translates to:
  /// **'Retrait possible'**
  String get storeFactPickup;

  /// Délai estimé
  ///
  /// In fr, this message translates to:
  /// **'Livré en {minutes} min environ à {zone}'**
  String productDeliveryEstimate(int minutes, String zone);

  /// Délai estimé
  ///
  /// In fr, this message translates to:
  /// **'Livré en {minutes} min environ'**
  String productDeliveryEstimateShort(int minutes);

  /// Quartier non desservi
  ///
  /// In fr, this message translates to:
  /// **'Cette boutique ne livre pas {zone}.'**
  String productNotServed(String zone);

  /// Galerie
  ///
  /// In fr, this message translates to:
  /// **'Photo {index} sur {count}'**
  String productPhotoPosition(int index, int count);

  /// Fiche retirée
  ///
  /// In fr, this message translates to:
  /// **'Ce produit n\'est plus proposé.'**
  String get productUnavailableTitle;

  /// Page boutique
  ///
  /// In fr, this message translates to:
  /// **'Retrait possible à {zone} · adresse partagée avec le livreur uniquement'**
  String storePagePickupNote(String zone);

  /// Page boutique
  ///
  /// In fr, this message translates to:
  /// **'Ses produits'**
  String get storePageProducts;

  /// Page boutique vide
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de produit publié.'**
  String get storePageEmpty;

  /// Boutique retirée
  ///
  /// In fr, this message translates to:
  /// **'Cette boutique n\'est plus disponible.'**
  String get storePageUnavailable;

  /// Partager
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get shareLabel;

  /// Titre du panier
  ///
  /// In fr, this message translates to:
  /// **'Ton panier'**
  String get cartTitle;

  /// Boutiques et articles du panier
  ///
  /// In fr, this message translates to:
  /// **'{stores, plural, =1{1 boutique} other{{stores} boutiques}} · {items, plural, =1{1 article} other{{items} articles}}'**
  String cartSummary(int stores, int items);

  /// Résumé du mini-panier
  ///
  /// In fr, this message translates to:
  /// **'{items, plural, =1{1 article} other{{items} articles}} · {stores, plural, =1{1 boutique} other{{stores} boutiques}}'**
  String cartMiniSummary(int stores, int items);

  /// Ouvrir le panier
  ///
  /// In fr, this message translates to:
  /// **'Voir le panier'**
  String get cartView;

  /// Bouton d'ajout
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au panier'**
  String get cartAdd;

  /// Confirmation d'ajout
  ///
  /// In fr, this message translates to:
  /// **'Ajouté au panier'**
  String get cartAdded;

  /// Jauge de livraison offerte (avant le montant)
  ///
  /// In fr, this message translates to:
  /// **'Plus que'**
  String get cartFreeLead;

  /// Jauge de livraison offerte (après le montant)
  ///
  /// In fr, this message translates to:
  /// **'pour la livraison offerte'**
  String get cartFreeTrail;

  /// Seuil de gratuité atteint
  ///
  /// In fr, this message translates to:
  /// **'Livraison offerte !'**
  String get cartFreeReached;

  /// Préférence de remplacement
  ///
  /// In fr, this message translates to:
  /// **'Si un produit manque'**
  String get cartSubstitutionTitle;

  /// Explication du remplacement
  ///
  /// In fr, this message translates to:
  /// **'La boutique propose un équivalent au même prix'**
  String get cartSubstitutionSubtitle;

  /// Ligne livraison
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get cartDelivery;

  /// Ramassages et délai
  ///
  /// In fr, this message translates to:
  /// **'{pickups, plural, =0{Retrait sur place} =1{1 boutique} other{{pickups} boutiques}} · {minutes} min'**
  String cartDeliveryMeta(int pickups, int minutes);

  /// Modifier la livraison
  ///
  /// In fr, this message translates to:
  /// **'Changer'**
  String get cartChange;

  /// Choix du paiement
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get cartPayment;

  /// Sous-total
  ///
  /// In fr, this message translates to:
  /// **'Sous-total'**
  String get cartSubtotal;

  /// Total
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get cartTotal;

  /// Bouton commander
  ///
  /// In fr, this message translates to:
  /// **'Commander · {total}'**
  String cartOrder(String total);

  /// Panier vide
  ///
  /// In fr, this message translates to:
  /// **'Ton panier est vide'**
  String get cartEmptyTitle;

  /// Panier vide : piste
  ///
  /// In fr, this message translates to:
  /// **'Ajoute des produits des boutiques ouvertes près de toi.'**
  String get cartEmptyMessage;

  /// Retour à l'accueil depuis le panier vide
  ///
  /// In fr, this message translates to:
  /// **'Voir les boutiques'**
  String get cartBrowse;

  /// Retirer une ligne
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get cartRemove;

  /// Ligne en rupture
  ///
  /// In fr, this message translates to:
  /// **'Rupture'**
  String get cartIssueUnavailable;

  /// Stock insuffisant
  ///
  /// In fr, this message translates to:
  /// **'Plus que {count} en stock'**
  String cartIssueStock(int count);

  /// Prix changé depuis l'ajout
  ///
  /// In fr, this message translates to:
  /// **'Prix modifié'**
  String get cartIssuePriceChanged;

  /// Boutique fermée
  ///
  /// In fr, this message translates to:
  /// **'Fermée maintenant'**
  String get cartIssueClosed;

  /// Boutique suspendue
  ///
  /// In fr, this message translates to:
  /// **'Boutique indisponible'**
  String get cartIssueSuspended;

  /// Quartier non livré
  ///
  /// In fr, this message translates to:
  /// **'Ne livre pas ton adresse : choisis le retrait ou une autre adresse'**
  String get cartIssueNotDelivered;

  /// Retrait impossible
  ///
  /// In fr, this message translates to:
  /// **'Retrait non proposé par cette boutique'**
  String get cartIssuePickupUnavailable;

  /// Paiement refusé par la boutique
  ///
  /// In fr, this message translates to:
  /// **'Paiement non accepté par cette boutique'**
  String get cartIssuePaymentNotAccepted;

  /// Commande bloquée
  ///
  /// In fr, this message translates to:
  /// **'Corrige les points signalés pour commander.'**
  String get cartBlocked;

  /// Ajout refusé : rupture
  ///
  /// In fr, this message translates to:
  /// **'Ce produit n\'est plus disponible.'**
  String get cartUnavailable;

  /// Ajout refusé : autre pays
  ///
  /// In fr, this message translates to:
  /// **'Ce produit vient d\'un autre pays que ton panier.'**
  String get cartOtherCountry;

  /// Refus : adresse manquante
  ///
  /// In fr, this message translates to:
  /// **'Choisis une adresse de livraison.'**
  String get orderErrorAddressRequired;

  /// Refus : total modifié
  ///
  /// In fr, this message translates to:
  /// **'Le panier a changé : vérifie le nouveau total.'**
  String get orderErrorTotalChanged;

  /// Refus : paiement indisponible
  ///
  /// In fr, this message translates to:
  /// **'Ce moyen de paiement n\'est pas encore disponible.'**
  String get orderErrorPaymentUnavailable;

  /// Refus : achat dans sa propre boutique
  ///
  /// In fr, this message translates to:
  /// **'Tu ne peux pas commander dans ta propre boutique.'**
  String get orderErrorOwnStore;

  /// Refus : panier vide
  ///
  /// In fr, this message translates to:
  /// **'Ton panier est vide.'**
  String get orderErrorEmpty;

  /// Titre de l'écran livraison
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get deliveryTitle;

  /// Choix de l'adresse
  ///
  /// In fr, this message translates to:
  /// **'Où te livrer ?'**
  String get deliveryWhere;

  /// Nouvelle adresse
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une adresse'**
  String get deliveryAddAddress;

  /// Livraison ou retrait par boutique
  ///
  /// In fr, this message translates to:
  /// **'Mode par boutique'**
  String get deliveryModes;

  /// Mode livraison
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get deliveryModeDelivery;

  /// Mode retrait
  ///
  /// In fr, this message translates to:
  /// **'Je récupère'**
  String get deliveryModePickup;

  /// Valider l'écran livraison
  ///
  /// In fr, this message translates to:
  /// **'Valider la livraison'**
  String get deliveryConfirm;

  /// Aucune adresse
  ///
  /// In fr, this message translates to:
  /// **'Ajoute une adresse pour être livrée.'**
  String get deliveryNoAddress;

  /// Titre des adresses
  ///
  /// In fr, this message translates to:
  /// **'Mes adresses'**
  String get addressesTitle;

  /// Adresse par défaut
  ///
  /// In fr, this message translates to:
  /// **'Par défaut'**
  String get addressDefault;

  /// Position conservée
  ///
  /// In fr, this message translates to:
  /// **'Position enregistrée'**
  String get addressPositionSaved;

  /// Action : adresse par défaut
  ///
  /// In fr, this message translates to:
  /// **'Choisir par défaut'**
  String get addressSetDefault;

  /// Action : modifier
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get addressEdit;

  /// Action : supprimer
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get addressDelete;

  /// Menu d'une adresse
  ///
  /// In fr, this message translates to:
  /// **'Options de l\'adresse'**
  String get addressMenu;

  /// Aucune adresse
  ///
  /// In fr, this message translates to:
  /// **'Aucune adresse'**
  String get addressesEmptyTitle;

  /// Aucune adresse : piste
  ///
  /// In fr, this message translates to:
  /// **'Ajoute ton adresse pour être livrée plus vite.'**
  String get addressesEmptyMessage;

  /// Adresse maison
  ///
  /// In fr, this message translates to:
  /// **'Maison'**
  String get addressKindHome;

  /// Adresse bureau
  ///
  /// In fr, this message translates to:
  /// **'Bureau'**
  String get addressKindWork;

  /// Autre adresse
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get addressKindOther;

  /// Titre : nouvelle adresse
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle adresse'**
  String get addressNewTitle;

  /// Titre : modifier l'adresse
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'adresse'**
  String get addressEditTitle;

  /// Choix du quartier
  ///
  /// In fr, this message translates to:
  /// **'Où ?'**
  String get addressWhere;

  /// Libellé libre
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'adresse (facultatif)'**
  String get addressLabel;

  /// Repère
  ///
  /// In fr, this message translates to:
  /// **'Repère'**
  String get addressLandmark;

  /// Exemple de repère
  ///
  /// In fr, this message translates to:
  /// **'Ex. portail bleu après la pharmacie'**
  String get addressLandmarkHint;

  /// Repère invalide
  ///
  /// In fr, this message translates to:
  /// **'Décris un repère (3 à 200 caractères)'**
  String get addressLandmarkInvalid;

  /// Téléphone de contact
  ///
  /// In fr, this message translates to:
  /// **'Téléphone pour la livraison'**
  String get addressPhone;

  /// Téléphone invalide
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone invalide'**
  String get addressPhoneInvalid;

  /// Interrupteur adresse par défaut
  ///
  /// In fr, this message translates to:
  /// **'Adresse par défaut'**
  String get addressMakeDefault;

  /// Enregistrer
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer l\'adresse'**
  String get addressSave;

  /// Confirmation
  ///
  /// In fr, this message translates to:
  /// **'Commande envoyée !'**
  String get orderSentTitle;

  /// Suite de la commande
  ///
  /// In fr, this message translates to:
  /// **'Les vendeuses vont l\'accepter. Tu seras prévenue.'**
  String get orderSentSubtitle;

  /// Statut en attente
  ///
  /// In fr, this message translates to:
  /// **'En attente d\'acceptation'**
  String get orderPending;

  /// Nombre d'articles d'une commande
  ///
  /// In fr, this message translates to:
  /// **'{items, plural, =1{1 article} other{{items} articles}}'**
  String orderItems(int items);

  /// Adresse de livraison
  ///
  /// In fr, this message translates to:
  /// **'Livraison : {place}'**
  String orderDeliveryTo(String place);

  /// Retour
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get orderBackHome;

  /// Bouton d'ajout d'une carte produit
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get cartAddShort;

  /// Titre de l'écran de paiement
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get paymentTitle;

  /// Paiement en cours
  ///
  /// In fr, this message translates to:
  /// **'En attente du paiement'**
  String get paymentWaitingTitle;

  /// Explication de l'attente
  ///
  /// In fr, this message translates to:
  /// **'Valide le paiement sur la page qui vient de s\'ouvrir, puis reviens ici.'**
  String get paymentWaitingBody;

  /// Montant du paiement
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get paymentAmount;

  /// Référence du paiement
  ///
  /// In fr, this message translates to:
  /// **'Référence'**
  String get paymentReference;

  /// Relecture du statut
  ///
  /// In fr, this message translates to:
  /// **'Vérification automatique…'**
  String get paymentChecking;

  /// Rouvrir la page du fournisseur
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir la page de paiement'**
  String get paymentOpenPage;

  /// Passer au cash pendant l'attente
  ///
  /// In fr, this message translates to:
  /// **'Payer à la livraison à la place'**
  String get paymentPayOnDeliveryInstead;

  /// Paiement échoué
  ///
  /// In fr, this message translates to:
  /// **'Le paiement n\'a pas abouti'**
  String get paymentFailedTitle;

  /// Explication de l'échec
  ///
  /// In fr, this message translates to:
  /// **'Aucun montant n\'a été débité. Ta commande est gardée : réessaie ou paie à la livraison.'**
  String get paymentFailedBody;

  /// Nouvelle tentative
  ///
  /// In fr, this message translates to:
  /// **'Réessayer le paiement'**
  String get paymentRetry;

  /// Passer au cash après un échec
  ///
  /// In fr, this message translates to:
  /// **'Payer à la livraison'**
  String get paymentPayOnDelivery;

  /// Badge paiement confirmé
  ///
  /// In fr, this message translates to:
  /// **'Paiement confirmé'**
  String get paymentConfirmed;

  /// Badge cash
  ///
  /// In fr, this message translates to:
  /// **'Cash à la livraison'**
  String get paymentCashOnDelivery;

  /// Refus du cash
  ///
  /// In fr, this message translates to:
  /// **'Une boutique n\'accepte pas le paiement à la livraison.'**
  String get paymentCashNotAccepted;

  /// Page de paiement non ouverte
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir la page de paiement.'**
  String get paymentOpenFailed;

  /// Liste vendeuse vide
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande pour l\'instant'**
  String get ordersEmptyTitle;

  /// Liste vendeuse vide : explication
  ///
  /// In fr, this message translates to:
  /// **'Les commandes payées ou en cash apparaissent ici.'**
  String get ordersEmptyMessage;

  /// Titre d'une commande
  ///
  /// In fr, this message translates to:
  /// **'Commande de {name}'**
  String vendorOrderOf(String name);

  /// Heure de réception
  ///
  /// In fr, this message translates to:
  /// **'Reçue à {time}'**
  String vendorOrderReceivedAt(String time);

  /// Bandeau payé
  ///
  /// In fr, this message translates to:
  /// **'Paiement confirmé'**
  String get vendorPaidTitle;

  /// Bandeau payé : explication
  ///
  /// In fr, this message translates to:
  /// **'Tu peux préparer la commande.'**
  String get vendorPaidBody;

  /// Bandeau cash
  ///
  /// In fr, this message translates to:
  /// **'Cash à la livraison'**
  String get vendorCashTitle;

  /// Bandeau cash : explication
  ///
  /// In fr, this message translates to:
  /// **'Encaisse {amount} à la remise de la commande.'**
  String vendorCashBody(String amount);

  /// Cash encaissé par le livreur DYM (spec 068)
  ///
  /// In fr, this message translates to:
  /// **'Le livreur DYM encaisse {amount} et te remet {due}, le prix des articles.'**
  String vendorCashBodyCourier(String amount, String due);

  /// Livreur DYM assigné
  ///
  /// In fr, this message translates to:
  /// **'Livreur DYM : {name}'**
  String vendorCourierDym(String name);

  /// Livreur externe assigné par l'équipe
  ///
  /// In fr, this message translates to:
  /// **'Livreur : {name}'**
  String vendorCourierExternal(String name);

  /// Section articles
  ///
  /// In fr, this message translates to:
  /// **'Articles'**
  String get vendorItems;

  /// Section paiement
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get vendorPayment;

  /// Moyen de paiement
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get vendorPaymentMethod;

  /// Date du paiement
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get vendorPaymentDate;

  /// Section livraison
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get vendorDelivery;

  /// Commande en retrait
  ///
  /// In fr, this message translates to:
  /// **'Retrait sur place'**
  String get vendorPickup;

  /// Repère de livraison
  ///
  /// In fr, this message translates to:
  /// **'Repère : {landmark}'**
  String vendorLandmark(String landmark);

  /// Appeler la cliente
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get vendorCall;

  /// Quantité d'une ligne
  ///
  /// In fr, this message translates to:
  /// **'× {count}'**
  String vendorQuantity(int count);

  /// Statut : en attente
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get orderStatusPending;

  /// Statut : acceptée
  ///
  /// In fr, this message translates to:
  /// **'Acceptée'**
  String get orderStatusAccepted;

  /// Statut : en préparation
  ///
  /// In fr, this message translates to:
  /// **'En préparation'**
  String get orderStatusPreparing;

  /// Statut : prête
  ///
  /// In fr, this message translates to:
  /// **'Prête'**
  String get orderStatusReady;

  /// Statut : en route
  ///
  /// In fr, this message translates to:
  /// **'En route'**
  String get orderStatusOutForDelivery;

  /// Statut : livrée
  ///
  /// In fr, this message translates to:
  /// **'Livrée'**
  String get orderStatusDelivered;

  /// Statut : retrait récupéré
  ///
  /// In fr, this message translates to:
  /// **'Récupérée'**
  String get orderStatusCollected;

  /// Statut : refusée
  ///
  /// In fr, this message translates to:
  /// **'Refusée'**
  String get orderStatusRefused;

  /// Statut : annulée
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get orderStatusCancelled;

  /// Titre de l'onglet commandes (cliente)
  ///
  /// In fr, this message translates to:
  /// **'Mes commandes'**
  String get ordersMineTitle;

  /// Section en cours
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get ordersActive;

  /// Section terminées
  ///
  /// In fr, this message translates to:
  /// **'Terminées'**
  String get ordersDone;

  /// Liste cliente vide
  ///
  /// In fr, this message translates to:
  /// **'Tes commandes apparaissent ici.'**
  String get ordersMineEmptyMessage;

  /// Heure de livraison estimée
  ///
  /// In fr, this message translates to:
  /// **'Prévue vers {time}'**
  String orderEtaAt(String time);

  /// Heure de retrait estimée
  ///
  /// In fr, this message translates to:
  /// **'Prête vers {time}'**
  String orderPickupAt(String time);

  /// Date d'une commande terminée
  ///
  /// In fr, this message translates to:
  /// **'Le {date}'**
  String orderOn(String date);

  /// Titre du suivi
  ///
  /// In fr, this message translates to:
  /// **'Suivi de commande'**
  String get trackTitle;

  /// Frise : confirmée
  ///
  /// In fr, this message translates to:
  /// **'Confirmée'**
  String get trackConfirmed;

  /// Frise : préparée
  ///
  /// In fr, this message translates to:
  /// **'Préparée'**
  String get trackPrepared;

  /// Heure d'arrivée estimée
  ///
  /// In fr, this message translates to:
  /// **'Arrive vers {time}'**
  String trackArrives(String time);

  /// Heure de retrait estimée (suivi)
  ///
  /// In fr, this message translates to:
  /// **'Prête vers {time}'**
  String trackReadyAt(String time);

  /// Cash à payer
  ///
  /// In fr, this message translates to:
  /// **'À payer à la livraison'**
  String get trackPayOnDelivery;

  /// Montant cash
  ///
  /// In fr, this message translates to:
  /// **'{amount} en cash'**
  String trackCashAmount(String amount);

  /// Bouton annuler
  ///
  /// In fr, this message translates to:
  /// **'Annuler la commande'**
  String get trackCancel;

  /// Confirmation d'annulation
  ///
  /// In fr, this message translates to:
  /// **'Annuler la commande ?'**
  String get trackCancelTitle;

  /// Explication de l'annulation
  ///
  /// In fr, this message translates to:
  /// **'La boutique sera prévenue. La commande ne pourra pas être reprise.'**
  String get trackCancelBody;

  /// Ne pas annuler
  ///
  /// In fr, this message translates to:
  /// **'Garder la commande'**
  String get trackCancelKeep;

  /// Commande refusée
  ///
  /// In fr, this message translates to:
  /// **'Refusée par la boutique : {reason}'**
  String trackRefused(String reason);

  /// Annulée par la cliente
  ///
  /// In fr, this message translates to:
  /// **'Tu as annulé cette commande.'**
  String get trackCancelledByYou;

  /// Remboursement à venir
  ///
  /// In fr, this message translates to:
  /// **'Un remboursement est en cours.'**
  String get trackRefundDue;

  /// Conflit d'état
  ///
  /// In fr, this message translates to:
  /// **'La commande a changé : elle vient d\'être mise à jour.'**
  String get orderStatusChanged;

  /// Raison : rupture
  ///
  /// In fr, this message translates to:
  /// **'Produit en rupture'**
  String get reasonOutOfStock;

  /// Raison : trop chargée
  ///
  /// In fr, this message translates to:
  /// **'Boutique trop chargée'**
  String get reasonTooBusy;

  /// Raison : quartier
  ///
  /// In fr, this message translates to:
  /// **'Livraison impossible dans ce quartier'**
  String get reasonAreaNotServed;

  /// Raison : autre
  ///
  /// In fr, this message translates to:
  /// **'Autre raison'**
  String get reasonOther;

  /// Motif de refus automatique (spec 066)
  ///
  /// In fr, this message translates to:
  /// **'La boutique n\'a pas répondu à temps'**
  String get reasonNoResponse;

  /// Titre du centre
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// Tout marquer lu
  ///
  /// In fr, this message translates to:
  /// **'Tout lire'**
  String get notificationsReadAll;

  /// Centre vide
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification'**
  String get notificationsEmptyTitle;

  /// Centre vide : explication
  ///
  /// In fr, this message translates to:
  /// **'Tu seras prévenue à chaque étape de tes commandes.'**
  String get notificationsEmptyMessage;

  /// Compteur de non-lues
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 non lue} other{{count} non lues}}'**
  String notificationsUnread(int count);

  /// Notification vendeuse
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle commande !'**
  String get notifNewOrderTitle;

  /// Notification vendeuse : texte
  ///
  /// In fr, this message translates to:
  /// **'{name} a commandé.'**
  String notifNewOrderBody(String name);

  /// Annulée par la cliente
  ///
  /// In fr, this message translates to:
  /// **'Commande annulée'**
  String get notifCancelledByClientTitle;

  /// Annulée par la cliente : texte
  ///
  /// In fr, this message translates to:
  /// **'La cliente a annulé sa commande.'**
  String get notifCancelledByClientBody;

  /// Notification acceptée
  ///
  /// In fr, this message translates to:
  /// **'Commande acceptée'**
  String get notifAcceptedTitle;

  /// Acceptée : texte
  ///
  /// In fr, this message translates to:
  /// **'{store} a accepté ta commande.'**
  String notifAcceptedBody(String store);

  /// Notification refusée
  ///
  /// In fr, this message translates to:
  /// **'Commande refusée'**
  String get notifRefusedTitle;

  /// Refusée : texte
  ///
  /// In fr, this message translates to:
  /// **'{store} ne peut pas honorer ta commande.'**
  String notifRefusedBody(String store);

  /// En préparation : texte
  ///
  /// In fr, this message translates to:
  /// **'{store} prépare ta commande.'**
  String notifPreparingBody(String store);

  /// Notification prête
  ///
  /// In fr, this message translates to:
  /// **'Commande prête'**
  String get notifReadyTitle;

  /// Prête : texte
  ///
  /// In fr, this message translates to:
  /// **'Ta commande chez {store} est prête.'**
  String notifReadyBody(String store);

  /// En route : texte
  ///
  /// In fr, this message translates to:
  /// **'Ta commande arrive bientôt.'**
  String get notifOnTheWayBody;

  /// Livrée : texte
  ///
  /// In fr, this message translates to:
  /// **'Bon appétit ! Dis-nous si tout va bien.'**
  String get notifDeliveredBody;

  /// Paiement confirmé : texte
  ///
  /// In fr, this message translates to:
  /// **'Ta commande est payée.'**
  String get notifPaidBody;

  /// Notification paiement échoué
  ///
  /// In fr, this message translates to:
  /// **'Paiement échoué'**
  String get notifPaymentFailedTitle;

  /// Paiement échoué : texte
  ///
  /// In fr, this message translates to:
  /// **'Ton paiement n\'a pas abouti : réessaie ou paie à la livraison.'**
  String get notifPaymentFailedBody;

  /// Il y a moins d'une minute
  ///
  /// In fr, this message translates to:
  /// **'à l\'instant'**
  String get timeJustNow;

  /// Il y a n minutes
  ///
  /// In fr, this message translates to:
  /// **'il y a {count} min'**
  String timeMinutesAgo(int count);

  /// Il y a n heures
  ///
  /// In fr, this message translates to:
  /// **'il y a {count} h'**
  String timeHoursAgo(int count);

  /// Hier
  ///
  /// In fr, this message translates to:
  /// **'hier'**
  String get timeYesterday;

  /// Il y a n jours
  ///
  /// In fr, this message translates to:
  /// **'il y a {count} j'**
  String timeDaysAgo(int count);

  /// Titre des réglages
  ///
  /// In fr, this message translates to:
  /// **'Réglages des notifications'**
  String get notifSettingsTitle;

  /// Explication des réglages
  ///
  /// In fr, this message translates to:
  /// **'Choisis ce que DYM peut t\'envoyer sur ce téléphone.'**
  String get notifSettingsIntro;

  /// Catégorie commandes
  ///
  /// In fr, this message translates to:
  /// **'Suivi de mes commandes'**
  String get prefOrdersTitle;

  /// Catégorie commandes : détail
  ///
  /// In fr, this message translates to:
  /// **'Acceptée, en préparation, en route, livrée'**
  String get prefOrdersBody;

  /// Catégorie paiements
  ///
  /// In fr, this message translates to:
  /// **'Paiements'**
  String get prefPaymentsTitle;

  /// Catégorie paiements : détail
  ///
  /// In fr, this message translates to:
  /// **'Paiement confirmé ou échoué'**
  String get prefPaymentsBody;

  /// Catégorie messages
  ///
  /// In fr, this message translates to:
  /// **'Messages des boutiques'**
  String get prefMessagesTitle;

  /// Catégorie messages : détail
  ///
  /// In fr, this message translates to:
  /// **'Réponses des vendeuses'**
  String get prefMessagesBody;

  /// Catégorie bons plans
  ///
  /// In fr, this message translates to:
  /// **'Bons plans'**
  String get prefPromotionsTitle;

  /// Catégorie bons plans : détail
  ///
  /// In fr, this message translates to:
  /// **'Promotions de mes boutiques'**
  String get prefPromotionsBody;

  /// Note des réglages
  ///
  /// In fr, this message translates to:
  /// **'Les notifications importantes restent visibles dans l\'app.'**
  String get notifSettingsNote;

  /// Onglet nouvelles
  ///
  /// In fr, this message translates to:
  /// **'Nouvelles'**
  String get vendorScopeNew;

  /// Onglet en cours
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get vendorScopeActive;

  /// Onglet terminées
  ///
  /// In fr, this message translates to:
  /// **'Terminées'**
  String get vendorScopeDone;

  /// Rappel de réponse
  ///
  /// In fr, this message translates to:
  /// **'Réponds vite : la cliente attend.'**
  String get vendorReplyQuickly;

  /// Montant encaissé
  ///
  /// In fr, this message translates to:
  /// **'Tu encaisses'**
  String get vendorYouCollect;

  /// Accepter la commande
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get vendorAccept;

  /// Refuser la commande
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get vendorRefuse;

  /// Titre du refus
  ///
  /// In fr, this message translates to:
  /// **'Refuser la commande ?'**
  String get vendorRefuseTitle;

  /// Explication du refus
  ///
  /// In fr, this message translates to:
  /// **'La cliente sera prévenue. Choisis une raison.'**
  String get vendorRefuseBody;

  /// Précision du refus
  ///
  /// In fr, this message translates to:
  /// **'Précise (facultatif)'**
  String get vendorRefuseNote;

  /// Confirmer le refus
  ///
  /// In fr, this message translates to:
  /// **'Refuser la commande'**
  String get vendorRefuseConfirm;

  /// Geste préparation
  ///
  /// In fr, this message translates to:
  /// **'Commencer la préparation'**
  String get vendorStartPreparing;

  /// Geste prête
  ///
  /// In fr, this message translates to:
  /// **'Marquer prête'**
  String get vendorMarkReady;

  /// Geste en route
  ///
  /// In fr, this message translates to:
  /// **'Partir livrer'**
  String get vendorOutForDelivery;

  /// Geste livrée
  ///
  /// In fr, this message translates to:
  /// **'Marquer livrée'**
  String get vendorMarkDelivered;

  /// Geste récupérée
  ///
  /// In fr, this message translates to:
  /// **'Marquer récupérée'**
  String get vendorMarkCollected;

  /// Confirmer l'encaissement
  ///
  /// In fr, this message translates to:
  /// **'J\'ai encaissé {amount}'**
  String vendorConfirmCash(String amount);

  /// Encaissement fait
  ///
  /// In fr, this message translates to:
  /// **'Encaissement confirmé'**
  String get vendorCashCollected;

  /// Alerte d'arrivée
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle commande reçue'**
  String get vendorNewOrderAlert;

  /// Remboursement à faire
  ///
  /// In fr, this message translates to:
  /// **'Remboursement à faire par l\'équipe DYM.'**
  String get vendorRefundDue;

  /// Raison du refus (vendeuse)
  ///
  /// In fr, this message translates to:
  /// **'Refusée : {reason}'**
  String vendorOrderRefusedReason(String reason);

  /// Bouton et titre du signalement
  ///
  /// In fr, this message translates to:
  /// **'Signaler un problème'**
  String get disputeReport;

  /// Choix de la raison
  ///
  /// In fr, this message translates to:
  /// **'Que s\'est-il passé ?'**
  String get disputeWhatHappened;

  /// Récit du problème
  ///
  /// In fr, this message translates to:
  /// **'Raconte-nous'**
  String get disputeTellUs;

  /// Récit invalide
  ///
  /// In fr, this message translates to:
  /// **'Décris le problème (3 à 500 caractères)'**
  String get disputeDescriptionInvalid;

  /// Qui répond
  ///
  /// In fr, this message translates to:
  /// **'La boutique et l\'équipe DYM vont te répondre.'**
  String get disputeWhoAnswers;

  /// Envoyer
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le signalement'**
  String get disputeSend;

  /// Raison : article manquant
  ///
  /// In fr, this message translates to:
  /// **'Il manque un article'**
  String get disputeReasonMissingItem;

  /// Raison : mauvais article
  ///
  /// In fr, this message translates to:
  /// **'Mauvais article'**
  String get disputeReasonWrongItem;

  /// Raison : abîmé
  ///
  /// In fr, this message translates to:
  /// **'Article abîmé'**
  String get disputeReasonDamaged;

  /// Raison : qualité
  ///
  /// In fr, this message translates to:
  /// **'Qualité décevante'**
  String get disputeReasonQuality;

  /// Raison : jamais reçue
  ///
  /// In fr, this message translates to:
  /// **'Commande jamais reçue'**
  String get disputeReasonNotDelivered;

  /// Raison : autre
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get disputeReasonOther;

  /// Titre du suivi du litige
  ///
  /// In fr, this message translates to:
  /// **'Mon signalement'**
  String get disputeMine;

  /// Litige ouvert
  ///
  /// In fr, this message translates to:
  /// **'En cours de traitement'**
  String get disputeOpenStatus;

  /// Litige résolu
  ///
  /// In fr, this message translates to:
  /// **'Traité'**
  String get disputeResolvedStatus;

  /// Auteur : la cliente elle-même
  ///
  /// In fr, this message translates to:
  /// **'Toi'**
  String get disputeYou;

  /// Auteur : l'équipe
  ///
  /// In fr, this message translates to:
  /// **'Équipe DYM'**
  String get disputeTeam;

  /// Auteur : la cliente (vue vendeuse)
  ///
  /// In fr, this message translates to:
  /// **'Cliente'**
  String get disputeCustomer;

  /// Champ de message
  ///
  /// In fr, this message translates to:
  /// **'Écris un message…'**
  String get disputeWriteMessage;

  /// Envoyer un message
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get disputeSendMessage;

  /// Décision : remboursement
  ///
  /// In fr, this message translates to:
  /// **'Remboursement de {amount} décidé.'**
  String disputeRefunded(String amount);

  /// Décision : sans suite
  ///
  /// In fr, this message translates to:
  /// **'Signalement clos sans remboursement.'**
  String get disputeNoAction;

  /// Refus : déjà ouvert
  ///
  /// In fr, this message translates to:
  /// **'Un signalement est déjà en cours pour cette commande.'**
  String get disputeAlreadyOpen;

  /// Refus : hors délai
  ///
  /// In fr, this message translates to:
  /// **'Cette commande ne peut plus être signalée.'**
  String get disputeNotAllowed;

  /// Bandeau vendeuse
  ///
  /// In fr, this message translates to:
  /// **'Problème signalé : {reason}'**
  String disputeVendorBanner(String reason);

  /// Répondre au litige
  ///
  /// In fr, this message translates to:
  /// **'Répondre'**
  String get disputeReply;

  /// Champ de réponse vendeuse
  ///
  /// In fr, this message translates to:
  /// **'Ta réponse à la cliente'**
  String get disputeReplyHint;

  /// Ouvrir le fil
  ///
  /// In fr, this message translates to:
  /// **'Voir le signalement'**
  String get disputeSeeThread;

  /// Ligne du fil de litige (auteur, message)
  ///
  /// In fr, this message translates to:
  /// **'{author} : {body}'**
  String disputeMessageLine(String author, String body);

  /// Notification : réponse au litige
  ///
  /// In fr, this message translates to:
  /// **'Réponse à ton signalement'**
  String get notifDisputeRepliedTitle;

  /// Notification : qui a répondu au litige
  ///
  /// In fr, this message translates to:
  /// **'{author} t\'a répondu.'**
  String notifDisputeRepliedBody(String author);

  /// Notification : litige tranché
  ///
  /// In fr, this message translates to:
  /// **'Signalement traité'**
  String get notifDisputeResolvedTitle;

  /// Notification : litige tranché (texte)
  ///
  /// In fr, this message translates to:
  /// **'L\'équipe DYM a traité ton signalement.'**
  String get notifDisputeResolvedBody;

  /// Interrupteur : actif
  ///
  /// In fr, this message translates to:
  /// **'Active'**
  String get adminActive;

  /// Bouton : catégorie
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une catégorie'**
  String get adminAddCategory;

  /// Bouton : ville
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une ville'**
  String get adminAddCity;

  /// Bouton : moyen de paiement
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un moyen de paiement'**
  String get adminAddPaymentMethod;

  /// Bouton : quartier
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un quartier'**
  String get adminAddZone;

  /// Journal : après
  ///
  /// In fr, this message translates to:
  /// **'Après'**
  String get adminAfter;

  /// Filtre : toutes les valeurs
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get adminAll;

  /// Filtre du journal : action
  ///
  /// In fr, this message translates to:
  /// **'Action'**
  String get adminAuditAction;

  /// Filtre du journal : entité
  ///
  /// In fr, this message translates to:
  /// **'Entité'**
  String get adminAuditEntity;

  /// Recherche du journal
  ///
  /// In fr, this message translates to:
  /// **'Rechercher (action, entité, raison)'**
  String get adminAuditSearch;

  /// Sous-titre du journal
  ///
  /// In fr, this message translates to:
  /// **'Toutes les actions de l\'équipe, en ajout seul.'**
  String get adminAuditSubtitle;

  /// Titre du journal
  ///
  /// In fr, this message translates to:
  /// **'Journal d\'audit'**
  String get adminAuditTitle;

  /// Auteur d'un message : la cliente
  ///
  /// In fr, this message translates to:
  /// **'{name} (cliente)'**
  String adminAuthorClient(String name);

  /// Auteur d'un message : la vendeuse
  ///
  /// In fr, this message translates to:
  /// **'{name} (vendeuse)'**
  String adminAuthorVendor(String name);

  /// Champ : frais de base (symbole de la devise)
  ///
  /// In fr, this message translates to:
  /// **'Frais de base {symbol}'**
  String adminBaseFee(String symbol);

  /// Journal : avant
  ///
  /// In fr, this message translates to:
  /// **'Avant'**
  String get adminBefore;

  /// Journal : détail
  ///
  /// In fr, this message translates to:
  /// **'Avant / après'**
  String get adminBeforeAfter;

  /// Motif de remboursement : annulation
  ///
  /// In fr, this message translates to:
  /// **'Annulation'**
  String get adminCancellation;

  /// Moyen : cash
  ///
  /// In fr, this message translates to:
  /// **'Cash'**
  String get adminCash;

  /// Champ : ville
  ///
  /// In fr, this message translates to:
  /// **'Nom de la ville'**
  String get adminCityName;

  /// Fermer le détail
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get adminClose;

  /// Décision : sans suite
  ///
  /// In fr, this message translates to:
  /// **'Clore sans suite'**
  String get adminCloseNoAction;

  /// Liste de contrôle d'un pays
  ///
  /// In fr, this message translates to:
  /// **'Avant d\'activer un pays : au moins une ville avec des quartiers, un moyen de paiement et des frais de livraison.'**
  String get adminCountryChecklist;

  /// Carte : décision
  ///
  /// In fr, this message translates to:
  /// **'Décision'**
  String get adminDecision;

  /// Champ : délai
  ///
  /// In fr, this message translates to:
  /// **'Délai de livraison (minutes)'**
  String get adminDeliveryMinutes;

  /// Délai d'une ville
  ///
  /// In fr, this message translates to:
  /// **'Livraison en {n} min environ'**
  String adminDeliveryMinutesValue(int n);

  /// Carte du tableau de bord : positions hors zone (spec 065)
  ///
  /// In fr, this message translates to:
  /// **'Hors zone desservie'**
  String get adminCoverageTitle;

  /// Carte des réglages : refus automatique et relances (spec 066)
  ///
  /// In fr, this message translates to:
  /// **'Livraison automatique'**
  String get opsAutoDispatch;

  /// Délai avant refus automatique
  ///
  /// In fr, this message translates to:
  /// **'Refus automatique sans réponse (minutes)'**
  String get opsAutoRefuse;

  /// Délai entre deux relances
  ///
  /// In fr, this message translates to:
  /// **'Relance des livreurs (minutes)'**
  String get opsRelaunch;

  /// Relances maximum ; la ville entière dès la deuxième
  ///
  /// In fr, this message translates to:
  /// **'Nombre de relances (0 : aucune)'**
  String get opsRelaunchMax;

  /// Carte du tableau de bord : livreurs et relances (spec 066)
  ///
  /// In fr, this message translates to:
  /// **'Livraisons'**
  String get adminDispatchTitle;

  /// Livreurs en ligne sur les actifs
  ///
  /// In fr, this message translates to:
  /// **'Livreurs en ligne'**
  String get adminCouriersOnline;

  /// Livreurs en ligne / actifs
  ///
  /// In fr, this message translates to:
  /// **'{online} sur {active}'**
  String adminCouriersOnlineValue(int online, int active);

  /// Courses acceptées sans livreur
  ///
  /// In fr, this message translates to:
  /// **'Sans livreur'**
  String get adminMissionsWaiting;

  /// Minutes entre la commande et la prise par un livreur
  ///
  /// In fr, this message translates to:
  /// **'Prise médiane'**
  String get adminMedianAccept;

  /// Durée en minutes
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min'**
  String adminMinutesValue(int minutes);

  /// Relances de livreurs
  ///
  /// In fr, this message translates to:
  /// **'Relances'**
  String get adminRelaunches;

  /// Relances et élargissements
  ///
  /// In fr, this message translates to:
  /// **'{count} dont {widened} à toute la ville'**
  String adminRelaunchesValue(int count, int widened);

  /// Commandes refusées automatiquement
  ///
  /// In fr, this message translates to:
  /// **'Refus auto'**
  String get adminAutoRefused;

  /// Livreurs prévenus que la commande est prête
  ///
  /// In fr, this message translates to:
  /// **'Alertes « prête »'**
  String get adminReadyAlerts;

  /// Aide de la carte couverture
  ///
  /// In fr, this message translates to:
  /// **'Positions d\'utilisatrices trop loin de tout quartier desservi, par pays le plus proche.'**
  String get adminCoverageHelp;

  /// Total des positions hors zone
  ///
  /// In fr, this message translates to:
  /// **'Au total'**
  String get adminCoverageTotal;

  /// Positions hors zone d'un pays
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 position} other{{count} positions}}'**
  String adminCoverageMisses(int count);

  /// Distance médiane au quartier desservi
  ///
  /// In fr, this message translates to:
  /// **'{km} km en médiane'**
  String adminCoverageMedianKm(int km);

  /// Champ : rayon de service de la ville
  ///
  /// In fr, this message translates to:
  /// **'Rayon de service (km)'**
  String get adminServiceRadiusKm;

  /// Rayon de service affiché sous la ville
  ///
  /// In fr, this message translates to:
  /// **'rayon de {km} km'**
  String adminServiceRadiusValue(int km);

  /// Titre : catégorie
  ///
  /// In fr, this message translates to:
  /// **'Modifier la catégorie'**
  String get adminEditCategory;

  /// Titre : ville
  ///
  /// In fr, this message translates to:
  /// **'Modifier la ville'**
  String get adminEditCity;

  /// Titre : commission
  ///
  /// In fr, this message translates to:
  /// **'Modifier la commission'**
  String get adminEditCommission;

  /// Titre : frais
  ///
  /// In fr, this message translates to:
  /// **'Modifier les frais de livraison'**
  String get adminEditFees;

  /// Bouton : correction de boutique
  ///
  /// In fr, this message translates to:
  /// **'Corriger les données'**
  String get adminEditStore;

  /// Titre : quartier
  ///
  /// In fr, this message translates to:
  /// **'Modifier le quartier'**
  String get adminEditZone;

  /// Exécuter un remboursement
  ///
  /// In fr, this message translates to:
  /// **'Exécuter'**
  String get adminExecute;

  /// Champ : supplément par boutique
  ///
  /// In fr, this message translates to:
  /// **'Ramassage en plus {symbol}'**
  String adminExtraPickupFee(String symbol);

  /// Champ : seuil de gratuité
  ///
  /// In fr, this message translates to:
  /// **'Gratuit dès {symbol}'**
  String adminFreeThreshold(String symbol);

  /// Aide : villes et quartiers
  ///
  /// In fr, this message translates to:
  /// **'Saisis les villes et quartiers du pays : les clientes et les vendeuses les retrouvent par recherche ou par position.'**
  String get adminGeographyHelp;

  /// Champ : note interne
  ///
  /// In fr, this message translates to:
  /// **'Note interne (visible par l\'équipe seulement)'**
  String get adminInternalNote;

  /// Champ : libellé anglais
  ///
  /// In fr, this message translates to:
  /// **'Libellé en anglais'**
  String get adminLabelEn;

  /// Champ : libellé français
  ///
  /// In fr, this message translates to:
  /// **'Libellé en français'**
  String get adminLabelFr;

  /// Champ : latitude
  ///
  /// In fr, this message translates to:
  /// **'Latitude (facultatif)'**
  String get adminLatitude;

  /// Champ : longitude
  ///
  /// In fr, this message translates to:
  /// **'Longitude (facultatif)'**
  String get adminLongitude;

  /// Remboursement cash
  ///
  /// In fr, this message translates to:
  /// **'Marquer remis en main propre'**
  String get adminMarkCashRefunded;

  /// Onglet : journal
  ///
  /// In fr, this message translates to:
  /// **'Journal'**
  String get adminNavAudit;

  /// Domaine des opérations
  ///
  /// In fr, this message translates to:
  /// **'En direct'**
  String get adminNavLive;

  /// Domaine : boutiques, clientes
  ///
  /// In fr, this message translates to:
  /// **'Comptes'**
  String get adminNavAccounts;

  /// Domaine : référentiels et réglages
  ///
  /// In fr, this message translates to:
  /// **'Configuration'**
  String get adminNavConfig;

  /// Onglet : litiges
  ///
  /// In fr, this message translates to:
  /// **'Litiges'**
  String get adminNavDisputes;

  /// Onglet : finances
  ///
  /// In fr, this message translates to:
  /// **'Finances'**
  String get adminNavFinance;

  /// Journal vide
  ///
  /// In fr, this message translates to:
  /// **'Aucune action.'**
  String get adminNoAudit;

  /// Aucune ville
  ///
  /// In fr, this message translates to:
  /// **'Aucune ville : ajoute la première.'**
  String get adminNoCities;

  /// Aucune commission
  ///
  /// In fr, this message translates to:
  /// **'Aucune commission : 0 %.'**
  String get adminNoCommission;

  /// Aucun litige
  ///
  /// In fr, this message translates to:
  /// **'Aucun litige ouvert.'**
  String get adminNoDisputes;

  /// Aucun frais
  ///
  /// In fr, this message translates to:
  /// **'Aucun frais de livraison.'**
  String get adminNoFees;

  /// Historique vide
  ///
  /// In fr, this message translates to:
  /// **'Aucune action de l\'équipe.'**
  String get adminNoHistory;

  /// Catégorie parente : aucune
  ///
  /// In fr, this message translates to:
  /// **'Aucune (catégorie principale)'**
  String get adminNoParent;

  /// Aucun moyen
  ///
  /// In fr, this message translates to:
  /// **'Aucun moyen de paiement.'**
  String get adminNoPaymentMethods;

  /// Aucun paiement
  ///
  /// In fr, this message translates to:
  /// **'Aucun paiement en attente.'**
  String get adminNoPendingPayments;

  /// Aucun remboursement
  ///
  /// In fr, this message translates to:
  /// **'Aucun remboursement.'**
  String get adminNoRefunds;

  /// Aucune boutique
  ///
  /// In fr, this message translates to:
  /// **'Aucune boutique.'**
  String get adminNoStores;

  /// Champ : retrait
  ///
  /// In fr, this message translates to:
  /// **'Retrait sur place'**
  String get adminOffersPickup;

  /// Moyen : en ligne
  ///
  /// In fr, this message translates to:
  /// **'Paiement en ligne'**
  String get adminOnlinePayment;

  /// Titre : litiges
  ///
  /// In fr, this message translates to:
  /// **'Litiges ouverts'**
  String get adminOpenDisputes;

  /// Indicateur : litiges
  ///
  /// In fr, this message translates to:
  /// **'Litiges ouverts'**
  String get adminOpenDisputesCount;

  /// Champ : date d'ouverture
  ///
  /// In fr, this message translates to:
  /// **'Ouverte depuis le'**
  String get adminOpenedOn;

  /// Champ : opérateur
  ///
  /// In fr, this message translates to:
  /// **'Opérateur (facultatif)'**
  String get adminOperator;

  /// Indicateur : commandes
  ///
  /// In fr, this message translates to:
  /// **'Commandes · 7 j'**
  String get adminOrders7d;

  /// Litige de plus de 24 h
  ///
  /// In fr, this message translates to:
  /// **'> 24 h'**
  String get adminOver24h;

  /// Total et moyen de paiement
  ///
  /// In fr, this message translates to:
  /// **'{amount} en {method}'**
  String adminPaidWith(String amount, String method);

  /// Champ : parente
  ///
  /// In fr, this message translates to:
  /// **'Catégorie parente'**
  String get adminParentCategory;

  /// Carte : paiements en attente
  ///
  /// In fr, this message translates to:
  /// **'Paiements en attente'**
  String get adminPendingPayments;

  /// Champ : préparation
  ///
  /// In fr, this message translates to:
  /// **'Préparation (minutes)'**
  String get adminPrepMinutes;

  /// Champ : fournisseur
  ///
  /// In fr, this message translates to:
  /// **'Fournisseur'**
  String get adminProvider;

  /// Indicateur : produits
  ///
  /// In fr, this message translates to:
  /// **'Produits publiés'**
  String get adminPublishedProducts;

  /// Champ : taux
  ///
  /// In fr, this message translates to:
  /// **'Taux (%)'**
  String get adminRatePercent;

  /// Taux affiché
  ///
  /// In fr, this message translates to:
  /// **'{rate} %'**
  String adminRateValue(String rate);

  /// Bouton : réactiver
  ///
  /// In fr, this message translates to:
  /// **'Réactiver la boutique'**
  String get adminReactivateStore;

  /// Décision : tout
  ///
  /// In fr, this message translates to:
  /// **'Rembourser tout ({amount})'**
  String adminRefundAll(String amount);

  /// Champ : montant
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get adminRefundAmount;

  /// Plafond du remboursement
  ///
  /// In fr, this message translates to:
  /// **'{amount} au plus'**
  String adminRefundMax(String amount);

  /// Colonne : moyen
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get adminRefundMethod;

  /// Décision : partiel
  ///
  /// In fr, this message translates to:
  /// **'Rembourser une partie'**
  String get adminRefundPart;

  /// Colonne : motif
  ///
  /// In fr, this message translates to:
  /// **'Motif'**
  String get adminRefundReason;

  /// Carte : remboursements
  ///
  /// In fr, this message translates to:
  /// **'Remboursements'**
  String get adminRefunds;

  /// Filtre : effectués
  ///
  /// In fr, this message translates to:
  /// **'Effectués'**
  String get adminRefundsDone;

  /// Filtre : échoués
  ///
  /// In fr, this message translates to:
  /// **'Échoués'**
  String get adminRefundsFailed;

  /// Champ : message de l'équipe
  ///
  /// In fr, this message translates to:
  /// **'Écrire à la cliente et à la vendeuse'**
  String get adminReplyHint;

  /// Colonne : demandé
  ///
  /// In fr, this message translates to:
  /// **'Demandé'**
  String get adminRequested;

  /// Bouton : trancher
  ///
  /// In fr, this message translates to:
  /// **'Trancher le litige'**
  String get adminResolve;

  /// Relancer un remboursement échoué
  ///
  /// In fr, this message translates to:
  /// **'Relancer'**
  String get adminRetry;

  /// Indicateur : ventes
  ///
  /// In fr, this message translates to:
  /// **'Ventes · 7 j'**
  String get adminSales7d;

  /// Bouton : enregistrer
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get adminSave;

  /// Sous-titre des réglages
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir un pays est une opération de configuration.'**
  String get adminSettingsSubtitle;

  /// Boutique : active
  ///
  /// In fr, this message translates to:
  /// **'Active'**
  String get adminStoreActive;

  /// Champ : description
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get adminStoreDescription;

  /// Boutique : brouillon
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get adminStoreDraft;

  /// Champ : nom
  ///
  /// In fr, this message translates to:
  /// **'Nom de la boutique'**
  String get adminStoreName;

  /// Recherche des boutiques
  ///
  /// In fr, this message translates to:
  /// **'Nom de la boutique ou de la vendeuse'**
  String get adminStoreSearch;

  /// Boutique : suspendue
  ///
  /// In fr, this message translates to:
  /// **'Suspendue'**
  String get adminStoreSuspended;

  /// Filtre : actives
  ///
  /// In fr, this message translates to:
  /// **'Actives · {n}'**
  String adminStoresActive(int n);

  /// Filtre : brouillons
  ///
  /// In fr, this message translates to:
  /// **'Brouillons · {n}'**
  String adminStoresDraft(int n);

  /// Filtre : suspendues
  ///
  /// In fr, this message translates to:
  /// **'Suspendues · {n}'**
  String adminStoresSuspended(int n);

  /// Aide : suspension
  ///
  /// In fr, this message translates to:
  /// **'La suspension ferme la boutique et demande une raison.'**
  String get adminSuspendHelp;

  /// Bouton : suspendre
  ///
  /// In fr, this message translates to:
  /// **'Suspendre la boutique'**
  String get adminSuspendStore;

  /// Onglet : catégories
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get adminTabCategories;

  /// Onglet : commission
  ///
  /// In fr, this message translates to:
  /// **'Commission'**
  String get adminTabCommission;

  /// Onglet : pays
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get adminTabCountries;

  /// Onglet : frais
  ///
  /// In fr, this message translates to:
  /// **'Frais de livraison'**
  String get adminTabFees;

  /// Onglet : villes et quartiers
  ///
  /// In fr, this message translates to:
  /// **'Villes et quartiers'**
  String get adminTabGeography;

  /// Titre : historique
  ///
  /// In fr, this message translates to:
  /// **'Historique des actions de l\'équipe'**
  String get adminTeamHistory;

  /// Case : avertir
  ///
  /// In fr, this message translates to:
  /// **'Avertir la vendeuse'**
  String get adminWarnVendor;

  /// Portée : pays entier
  ///
  /// In fr, this message translates to:
  /// **'Tout le pays'**
  String get adminWholeCountry;

  /// Champ : quartier
  ///
  /// In fr, this message translates to:
  /// **'Nom du quartier'**
  String get adminZoneName;

  /// Boutiques d'un quartier
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucune boutique} =1{1 boutique} other{{n} boutiques}}'**
  String adminZoneStores(int n);

  /// Paiement d'un achat : payé en ligne
  ///
  /// In fr, this message translates to:
  /// **'Payée'**
  String get adminPaid;

  /// Paiement d'un achat : en attente
  ///
  /// In fr, this message translates to:
  /// **'En attente de paiement'**
  String get adminAwaitingPayment;

  /// Auteur d'une étape : la cliente
  ///
  /// In fr, this message translates to:
  /// **'Cliente'**
  String get adminActorClient;

  /// Auteur d'une étape : la vendeuse
  ///
  /// In fr, this message translates to:
  /// **'Vendeuse'**
  String get adminActorVendor;

  /// Auteur d'une étape : l'équipe DYM
  ///
  /// In fr, this message translates to:
  /// **'Équipe'**
  String get adminActorTeam;

  /// Auteur d'une étape : automatique
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get adminActorSystem;

  /// Journal : connexion d'un membre
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get adminAuditSignedIn;

  /// Journal : statut forcé
  ///
  /// In fr, this message translates to:
  /// **'Statut forcé'**
  String get adminAuditStatusForced;

  /// Journal : annulation
  ///
  /// In fr, this message translates to:
  /// **'Commande annulée'**
  String get adminAuditOrderCancelled;

  /// Journal : livreur
  ///
  /// In fr, this message translates to:
  /// **'Livreur assigné'**
  String get adminAuditCourierAssigned;

  /// Journal : litige
  ///
  /// In fr, this message translates to:
  /// **'Litige tranché'**
  String get adminAuditDisputeResolved;

  /// Journal : remboursement réussi
  ///
  /// In fr, this message translates to:
  /// **'Remboursement effectué'**
  String get adminAuditRefundSucceeded;

  /// Journal : remboursement échoué
  ///
  /// In fr, this message translates to:
  /// **'Remboursement échoué'**
  String get adminAuditRefundFailed;

  /// Journal : suspension
  ///
  /// In fr, this message translates to:
  /// **'Boutique suspendue'**
  String get adminAuditStoreSuspended;

  /// Journal : réactivation
  ///
  /// In fr, this message translates to:
  /// **'Boutique réactivée'**
  String get adminAuditStoreReactivated;

  /// Journal : correction de boutique
  ///
  /// In fr, this message translates to:
  /// **'Données corrigées'**
  String get adminAuditStoreUpdated;

  /// Journal : pays activé
  ///
  /// In fr, this message translates to:
  /// **'Pays activé'**
  String get adminAuditCountryActivated;

  /// Journal : pays désactivé
  ///
  /// In fr, this message translates to:
  /// **'Pays désactivé'**
  String get adminAuditCountryDeactivated;

  /// Journal : ville
  ///
  /// In fr, this message translates to:
  /// **'Ville modifiée'**
  String get adminAuditCity;

  /// Journal : quartier
  ///
  /// In fr, this message translates to:
  /// **'Quartier modifié'**
  String get adminAuditZone;

  /// Journal : moyen de paiement
  ///
  /// In fr, this message translates to:
  /// **'Moyen de paiement modifié'**
  String get adminAuditPaymentMethod;

  /// Journal : commission
  ///
  /// In fr, this message translates to:
  /// **'Commission modifiée'**
  String get adminAuditCommission;

  /// Journal : frais
  ///
  /// In fr, this message translates to:
  /// **'Frais de livraison modifiés'**
  String get adminAuditDeliveryFee;

  /// Journal : catégorie
  ///
  /// In fr, this message translates to:
  /// **'Catégorie modifiée'**
  String get adminAuditCategory;

  /// Journal : rôle
  ///
  /// In fr, this message translates to:
  /// **'Rôle modifié'**
  String get adminAuditRole;

  /// Entité : commande
  ///
  /// In fr, this message translates to:
  /// **'Commande'**
  String get adminEntityOrder;

  /// Entité : litige
  ///
  /// In fr, this message translates to:
  /// **'Litige'**
  String get adminEntityDispute;

  /// Entité : remboursement
  ///
  /// In fr, this message translates to:
  /// **'Remboursement'**
  String get adminEntityRefund;

  /// Entité : boutique
  ///
  /// In fr, this message translates to:
  /// **'Boutique'**
  String get adminEntityStore;

  /// Entité : pays
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get adminEntityCountry;

  /// Entité : ville
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get adminEntityCity;

  /// Entité : quartier
  ///
  /// In fr, this message translates to:
  /// **'Quartier'**
  String get adminEntityZone;

  /// Entité : moyen de paiement
  ///
  /// In fr, this message translates to:
  /// **'Moyen de paiement'**
  String get adminEntityPaymentMethod;

  /// Entité : catégorie
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get adminEntityCategory;

  /// Entité : membre
  ///
  /// In fr, this message translates to:
  /// **'Équipe'**
  String get adminEntityUser;

  /// Refus : commande terminée
  ///
  /// In fr, this message translates to:
  /// **'Cette commande est terminée : passe par un litige.'**
  String get adminOrderClosed;

  /// Refus : paiement en attente
  ///
  /// In fr, this message translates to:
  /// **'Le paiement de cette commande n\'est pas encore confirmé.'**
  String get adminPaymentPendingRefusal;

  /// Refus : raison
  ///
  /// In fr, this message translates to:
  /// **'Indique une raison (3 caractères au moins).'**
  String get adminReasonRequired;

  /// Refus : livreur
  ///
  /// In fr, this message translates to:
  /// **'Un livreur ne s\'assigne qu\'à une commande en cours de livraison.'**
  String get adminCourierNotAllowed;

  /// Refus : litige clos
  ///
  /// In fr, this message translates to:
  /// **'Ce litige est déjà tranché.'**
  String get adminDisputeClosed;

  /// Refus : montant
  ///
  /// In fr, this message translates to:
  /// **'Montant invalide : entre 1 et le total de la commande.'**
  String get adminRefundAmountInvalid;

  /// Refus : remboursement
  ///
  /// In fr, this message translates to:
  /// **'Ce remboursement est déjà en cours ou effectué.'**
  String get adminRefundNotPending;

  /// Refus : pays incomplet
  ///
  /// In fr, this message translates to:
  /// **'Ce pays n\'est pas prêt : complète ce qui manque.'**
  String get adminCountryNotReady;

  /// Refus : fournisseur
  ///
  /// In fr, this message translates to:
  /// **'Ce fournisseur de paiement est inactif.'**
  String get adminProviderInactive;

  /// Refus : statut inchangé
  ///
  /// In fr, this message translates to:
  /// **'La boutique a déjà ce statut.'**
  String get adminStoreStatusUnchanged;

  /// Durée en minutes
  ///
  /// In fr, this message translates to:
  /// **'{n} min'**
  String adminMinutes(int n);

  /// Durée en heures et minutes
  ///
  /// In fr, this message translates to:
  /// **'{h} h {m}'**
  String adminHoursMinutes(int h, String m);

  /// Vue scindée : rien de sélectionné
  ///
  /// In fr, this message translates to:
  /// **'Choisis un élément dans la liste.'**
  String get adminSelectItem;

  /// Champ de raison
  ///
  /// In fr, this message translates to:
  /// **'Raison (obligatoire)'**
  String get adminReasonLabel;

  /// Recherche des commandes
  ///
  /// In fr, this message translates to:
  /// **'N° de commande, cliente ou boutique'**
  String get adminOrderSearch;

  /// Filtre : toutes
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get adminFilterAll;

  /// Filtre : en cours
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get adminFilterActive;

  /// Filtre : bloquées, avec leur nombre
  ///
  /// In fr, this message translates to:
  /// **'Bloquées · {n}'**
  String adminFilterStuck(int n);

  /// Filtre : livrées
  ///
  /// In fr, this message translates to:
  /// **'Livrées'**
  String get adminFilterDelivered;

  /// Filtre : annulées ou refusées
  ///
  /// In fr, this message translates to:
  /// **'Annulées ou refusées'**
  String get adminFilterClosed;

  /// Liste vide
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande.'**
  String get adminNoOrders;

  /// Colonne : numéro
  ///
  /// In fr, this message translates to:
  /// **'N°'**
  String get adminColNumber;

  /// Pilotage : colonne
  ///
  /// In fr, this message translates to:
  /// **'Boutique'**
  String get adminColStore;

  /// Colonne : cliente
  ///
  /// In fr, this message translates to:
  /// **'Cliente'**
  String get adminColCustomer;

  /// Colonne : statut
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get adminColStatus;

  /// Colonne : paiement
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get adminColPayment;

  /// Colonne : montant
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get adminColAmount;

  /// Colonne : ancienneté de la dernière étape
  ///
  /// In fr, this message translates to:
  /// **'Depuis'**
  String get adminColSince;

  /// Commande sans étape depuis trop longtemps
  ///
  /// In fr, this message translates to:
  /// **'Bloquée'**
  String get adminStuck;

  /// Pagination
  ///
  /// In fr, this message translates to:
  /// **'{from} à {to} sur {total}'**
  String adminPageRange(int from, int to, int total);

  /// Pagination : précédente
  ///
  /// In fr, this message translates to:
  /// **'Page précédente'**
  String get adminPrevious;

  /// Pagination : suivante
  ///
  /// In fr, this message translates to:
  /// **'Page suivante'**
  String get adminNext;

  /// Champ : prénom
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get adminFirstName;

  /// Champ : téléphone
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get adminPhone;

  /// Champ : adresse
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get adminAddress;

  /// Titre du détail d'une commande
  ///
  /// In fr, this message translates to:
  /// **'Commande {reference}'**
  String adminOrderTitle(String reference);

  /// Pastille : bloquée
  ///
  /// In fr, this message translates to:
  /// **'Bloquée depuis {duration}'**
  String adminStuckSince(String duration);

  /// Pastille : litige
  ///
  /// In fr, this message translates to:
  /// **'Litige ouvert'**
  String get adminOpenDispute;

  /// Chronologie : paiement
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get adminActorPayment;

  /// Chronologie : ligne de paiement
  ///
  /// In fr, this message translates to:
  /// **'{status} ({method}, {reference})'**
  String adminPaymentLine(String status, String method, String reference);

  /// Livreur assigné
  ///
  /// In fr, this message translates to:
  /// **'Livreur : {name} · {phone}'**
  String adminCourierLine(String name, String phone);

  /// Chronologie : remboursement
  ///
  /// In fr, this message translates to:
  /// **'Remboursement de {amount} · {status}'**
  String adminRefundLine(String amount, String status);

  /// Carte : chronologie
  ///
  /// In fr, this message translates to:
  /// **'Chronologie'**
  String get adminTimeline;

  /// Chronologie : commande bloquée
  ///
  /// In fr, this message translates to:
  /// **'Aucune étape depuis {duration}'**
  String adminNoStepSince(String duration);

  /// Annulation par l'équipe
  ///
  /// In fr, this message translates to:
  /// **'Annulée par l\'équipe : {reason}'**
  String adminCancelledNote(String reason);

  /// Remboursement : à exécuter
  ///
  /// In fr, this message translates to:
  /// **'À exécuter'**
  String get adminRefundPending;

  /// Remboursement : en cours
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get adminRefundProcessing;

  /// Remboursement : effectué
  ///
  /// In fr, this message translates to:
  /// **'Effectué'**
  String get adminRefundSucceeded;

  /// Remboursement : échoué
  ///
  /// In fr, this message translates to:
  /// **'Échoué'**
  String get adminRefundFailed;

  /// Total d'une commande
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get adminTotal;

  /// Confirmation d'annulation
  ///
  /// In fr, this message translates to:
  /// **'Annuler la commande {reference} ?'**
  String adminCancelTitle(String reference);

  /// Annuler une commande payée
  ///
  /// In fr, this message translates to:
  /// **'Annuler et rembourser'**
  String get adminCancelRefund;

  /// Annuler une commande en cash
  ///
  /// In fr, this message translates to:
  /// **'Annuler la commande'**
  String get adminCancelOrder;

  /// Carte : actions
  ///
  /// In fr, this message translates to:
  /// **'Actions'**
  String get adminActions;

  /// Forcer un statut
  ///
  /// In fr, this message translates to:
  /// **'Forcer un statut'**
  String get adminForceStatus;

  /// Liste des statuts
  ///
  /// In fr, this message translates to:
  /// **'Choisis un statut'**
  String get adminChooseStatus;

  /// Appliquer le statut
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get adminApply;

  /// Assigner un livreur
  ///
  /// In fr, this message translates to:
  /// **'Livraison externe'**
  String get adminExternalDelivery;

  /// Champ : livreur
  ///
  /// In fr, this message translates to:
  /// **'Nom du livreur'**
  String get adminCourierName;

  /// Assigner le livreur
  ///
  /// In fr, this message translates to:
  /// **'Assigner'**
  String get adminAssign;

  /// Chronologie : création
  ///
  /// In fr, this message translates to:
  /// **'Commande passée'**
  String get adminOrderPlaced;

  /// No description provided for @dashboardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ma journée'**
  String get dashboardTitle;

  /// No description provided for @dashboardDay.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd’hui'**
  String get dashboardDay;

  /// No description provided for @dashboardWeek.
  ///
  /// In fr, this message translates to:
  /// **'Semaine'**
  String get dashboardWeek;

  /// No description provided for @dashboardMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois'**
  String get dashboardMonth;

  /// No description provided for @dashboardRevenue.
  ///
  /// In fr, this message translates to:
  /// **'Ventes encaissées'**
  String get dashboardRevenue;

  /// No description provided for @dashboardRevenueExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Articles livrés et payés, hors livraison, avant commission. Les remboursements sont déduits.'**
  String get dashboardRevenueExplanation;

  /// No description provided for @dashboardToDo.
  ///
  /// In fr, this message translates to:
  /// **'À traiter'**
  String get dashboardToDo;

  /// No description provided for @dashboardEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande sur cette période.'**
  String get dashboardEmpty;

  /// No description provided for @dashboardOffline.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne : les derniers chiffres sont affichés.'**
  String get dashboardOffline;

  /// No description provided for @dashboardRefreshFailed.
  ///
  /// In fr, this message translates to:
  /// **'Les chiffres n’ont pas pu être actualisés. Tire vers le bas pour réessayer.'**
  String get dashboardRefreshFailed;

  /// No description provided for @dashboardRecapHint.
  ///
  /// In fr, this message translates to:
  /// **'Ton récapitulatif du jour arrive à partir de 19 h.'**
  String get dashboardRecapHint;

  /// No description provided for @dashboardOrderCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{commande} =1{commande} other{commandes}}'**
  String dashboardOrderCount(int count);

  /// No description provided for @dashboardPendingPayments.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{paiement attendu} =1{paiement attendu} other{paiements attendus}}'**
  String dashboardPendingPayments(int count);

  /// No description provided for @dashboardTotals.
  ///
  /// In fr, this message translates to:
  /// **'{orders, plural, =0{Aucune commande} =1{1 commande} other{{orders} commandes}} · {payments, plural, =0{aucun paiement attendu} =1{1 paiement attendu} other{{payments} paiements attendus}}'**
  String dashboardTotals(int orders, int payments);

  /// No description provided for @dashboardNewOrders.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune nouvelle commande} =1{1 nouvelle commande} other{{count} nouvelles commandes}}'**
  String dashboardNewOrders(int count);

  /// No description provided for @dashboardActiveOrders.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune commande en cours} =1{1 commande en cours} other{{count} commandes en cours}}'**
  String dashboardActiveOrders(int count);

  /// No description provided for @dashboardStock.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun produit en rupture} =1{1 produit en rupture} other{{count} produits en rupture}}'**
  String dashboardStock(int count);

  /// No description provided for @dashboardCritical.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Une cliente attend ta réponse} other{{count} messages importants t’attendent}}'**
  String dashboardCritical(int count);

  /// Accueil vendeuse : ouvrir les notifications importantes
  ///
  /// In fr, this message translates to:
  /// **'Voir les notifications'**
  String get dashboardCriticalAction;

  /// Accueil vendeuse : sous-titre des nouvelles commandes
  ///
  /// In fr, this message translates to:
  /// **'Des clientes ont commandé'**
  String get dashboardNewOrdersHint;

  /// Accueil vendeuse : sous-titre des commandes en cours
  ///
  /// In fr, this message translates to:
  /// **'À préparer et livrer'**
  String get dashboardActiveOrdersHint;

  /// Accueil vendeuse : sous-titre des ruptures
  ///
  /// In fr, this message translates to:
  /// **'À remettre en stock pour continuer à vendre'**
  String get dashboardStockHint;

  /// Titre des conversations
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get chatMessagesTitle;

  /// Nombre de messages non lus
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Tout est lu} =1{1 non lu} other{{n} non lus}}'**
  String chatUnread(int n);

  /// Liste vide
  ///
  /// In fr, this message translates to:
  /// **'Aucune conversation pour l\'instant.'**
  String get chatEmptyList;

  /// Conversation vide
  ///
  /// In fr, this message translates to:
  /// **'Écris ton premier message.'**
  String get chatEmptyThread;

  /// Aperçu : photo
  ///
  /// In fr, this message translates to:
  /// **'Photo'**
  String get chatPhoto;

  /// Aperçu : produit partagé
  ///
  /// In fr, this message translates to:
  /// **'Produit : {name}'**
  String chatProductPreview(String name);

  /// Champ de saisie
  ///
  /// In fr, this message translates to:
  /// **'Écris ton message…'**
  String get chatWriteHint;

  /// Envoyer le message
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get chatSend;

  /// Bouton photo
  ///
  /// In fr, this message translates to:
  /// **'Envoyer une photo'**
  String get chatSendPhoto;

  /// Source : appareil photo
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get chatCamera;

  /// Source : galerie
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get chatGallery;

  /// Bouton et titre du partage
  ///
  /// In fr, this message translates to:
  /// **'Partager un produit'**
  String get chatShareProduct;

  /// Recherche du partage
  ///
  /// In fr, this message translates to:
  /// **'Chercher dans mes produits'**
  String get chatSearchProducts;

  /// Partage : aucun produit
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit publié.'**
  String get chatNoProducts;

  /// Partager ce produit
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get chatShare;

  /// Produit partagé : ajouter
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au panier'**
  String get chatAddToCart;

  /// Produit partagé retiré
  ///
  /// In fr, this message translates to:
  /// **'Ce produit n\'est plus en vente.'**
  String get chatProductUnavailable;

  /// Joindre le produit consulté
  ///
  /// In fr, this message translates to:
  /// **'Joindre ce produit'**
  String get chatAttachProduct;

  /// Retirer le produit joint
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get chatDismiss;

  /// Échec d'envoi
  ///
  /// In fr, this message translates to:
  /// **'Message non envoyé. Réessaie.'**
  String get chatSendFailed;

  /// Hors ligne
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne : les derniers messages sont affichés.'**
  String get chatOffline;

  /// Ouvrir la conversation
  ///
  /// In fr, this message translates to:
  /// **'Écrire à la boutique'**
  String get chatWriteToStore;

  /// Question sur un produit
  ///
  /// In fr, this message translates to:
  /// **'Poser une question'**
  String get chatAskProduct;

  /// Entrée du compte
  ///
  /// In fr, this message translates to:
  /// **'Mes messages'**
  String get chatMyMessages;

  /// Boutique inactive
  ///
  /// In fr, this message translates to:
  /// **'Cette boutique n\'accepte pas de messages pour l\'instant.'**
  String get chatStoreUnavailable;

  /// Accueil vendeuse : messages
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucun message non lu} =1{1 message non lu} other{{n} messages non lus}}'**
  String dashboardUnreadMessages(int n);

  /// Accueil vendeuse : sous-titre messages
  ///
  /// In fr, this message translates to:
  /// **'Réponds à tes clientes'**
  String get dashboardUnreadMessagesHint;

  /// Notification : message
  ///
  /// In fr, this message translates to:
  /// **'Nouveau message'**
  String get notifNewMessageTitle;

  /// Notification : expéditrice
  ///
  /// In fr, this message translates to:
  /// **'{sender} t\'a écrit.'**
  String notifNewMessageBody(String sender);

  /// Réachat en un tap
  ///
  /// In fr, this message translates to:
  /// **'Commander à nouveau'**
  String get reorder;

  /// Réachat : rien ajouté
  ///
  /// In fr, this message translates to:
  /// **'Plus aucun article de cette commande n\'est en vente.'**
  String get reorderNothing;

  /// Réachat : articles écartés
  ///
  /// In fr, this message translates to:
  /// **'Plus en vente : {items}'**
  String reorderSkipped(String items);

  /// Note moyenne
  ///
  /// In fr, this message translates to:
  /// **'{rating}/5'**
  String reviewAverage(String rating);

  /// Champ du commentaire
  ///
  /// In fr, this message translates to:
  /// **'Raconte en quelques mots (facultatif)'**
  String get reviewCommentLabel;

  /// Nombre d'avis
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucun avis} =1{1 avis} other{{n} avis}}'**
  String reviewCount(int n);

  /// Modifier la réponse
  ///
  /// In fr, this message translates to:
  /// **'Modifier ma réponse'**
  String get reviewEditReply;

  /// Avis déjà donné
  ///
  /// In fr, this message translates to:
  /// **'Tu as déjà donné ton avis sur cette commande.'**
  String get reviewExists;

  /// Bouton d'avis
  ///
  /// In fr, this message translates to:
  /// **'Donner mon avis'**
  String get reviewGive;

  /// Reporter l'avis
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get reviewLater;

  /// Avis de la boutique (vendeuse)
  ///
  /// In fr, this message translates to:
  /// **'Mes avis'**
  String get reviewMine;

  /// Réponse de la vendeuse
  ///
  /// In fr, this message translates to:
  /// **'Ta réponse : {reply}'**
  String reviewMyReply(String reply);

  /// Aucun avis
  ///
  /// In fr, this message translates to:
  /// **'Pas encore d\'avis.'**
  String get reviewNone;

  /// Boutique sans avis
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle boutique'**
  String get reviewNoneYet;

  /// Avis trop tôt
  ///
  /// In fr, this message translates to:
  /// **'Tu pourras donner ton avis après la livraison.'**
  String get reviewNotAllowed;

  /// Publier l'avis
  ///
  /// In fr, this message translates to:
  /// **'Publier mon avis'**
  String get reviewPublish;

  /// Publier la réponse
  ///
  /// In fr, this message translates to:
  /// **'Publier la réponse'**
  String get reviewPublishReply;

  /// Question de l'avis
  ///
  /// In fr, this message translates to:
  /// **'Comment s\'est passée ta commande ?'**
  String get reviewQuestion;

  /// Champ de réponse
  ///
  /// In fr, this message translates to:
  /// **'Ta réponse'**
  String get reviewReplyHint;

  /// Titre de la réponse
  ///
  /// In fr, this message translates to:
  /// **'Ta réponse à {name}'**
  String reviewReplyTo(String name);

  /// Étoiles (accessibilité)
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 étoile} other{{n} étoiles}}'**
  String reviewStarsLabel(int n);

  /// Réponse de la boutique
  ///
  /// In fr, this message translates to:
  /// **'Réponse de {store} : {reply}'**
  String reviewStoreReply(String store, String reply);

  /// Titre des avis d'une boutique
  ///
  /// In fr, this message translates to:
  /// **'Avis'**
  String get reviewStoreTitle;

  /// Étiquette d'avis
  ///
  /// In fr, this message translates to:
  /// **'Livraison rapide'**
  String get reviewTagFast;

  /// Étiquette d'avis
  ///
  /// In fr, this message translates to:
  /// **'Produits frais'**
  String get reviewTagFresh;

  /// Étiquette d'avis
  ///
  /// In fr, this message translates to:
  /// **'Bon accueil'**
  String get reviewTagFriendly;

  /// Étiquette d'avis
  ///
  /// In fr, this message translates to:
  /// **'Bien emballé'**
  String get reviewTagWellPacked;

  /// Avis donné
  ///
  /// In fr, this message translates to:
  /// **'Merci pour ton avis ({rating}/5) !'**
  String reviewThanks(int rating);

  /// Titre de l'écran d'avis
  ///
  /// In fr, this message translates to:
  /// **'Ton avis'**
  String get reviewTitle;

  /// Demande fermée
  ///
  /// In fr, this message translates to:
  /// **'Fermée'**
  String get supportClosed;

  /// Demande en cours
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get supportInProgress;

  /// Liste des demandes
  ///
  /// In fr, this message translates to:
  /// **'Mes demandes'**
  String get supportMine;

  /// Formulaire d'aide
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle demande'**
  String get supportNew;

  /// Pas de commande liée
  ///
  /// In fr, this message translates to:
  /// **'Aucune'**
  String get supportNoOrder;

  /// Aucune demande
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande pour l\'instant.'**
  String get supportNone;

  /// Commande liée
  ///
  /// In fr, this message translates to:
  /// **'Commande concernée'**
  String get supportOrder;

  /// Promesse du support
  ///
  /// In fr, this message translates to:
  /// **'L\'équipe DYM te répond en moins d\'une heure.'**
  String get supportPromise;

  /// Envoyer la demande
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get supportSend;

  /// Demande envoyée
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée : on te répond vite.'**
  String get supportSent;

  /// Sujet de la demande
  ///
  /// In fr, this message translates to:
  /// **'Sujet'**
  String get supportSubject;

  /// Sujet : compte
  ///
  /// In fr, this message translates to:
  /// **'Mon compte'**
  String get supportSubjectAccount;

  /// Sujet : commande
  ///
  /// In fr, this message translates to:
  /// **'Ma commande'**
  String get supportSubjectOrder;

  /// Sujet : autre
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get supportSubjectOther;

  /// Sujet : paiement
  ///
  /// In fr, this message translates to:
  /// **'Un paiement'**
  String get supportSubjectPayment;

  /// Sujet : boutique
  ///
  /// In fr, this message translates to:
  /// **'Ma boutique'**
  String get supportSubjectStore;

  /// Champ de la demande
  ///
  /// In fr, this message translates to:
  /// **'Décris ton problème'**
  String get supportDescribe;

  /// Note et nombre d'avis
  ///
  /// In fr, this message translates to:
  /// **'{rating}/5 · {n, plural, =1{1 avis} other{{n} avis}}'**
  String reviewSummary(String rating, int n);

  /// Onglet admin : tableau de bord
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get adminNavDashboard;

  /// Onglet admin : clientes
  ///
  /// In fr, this message translates to:
  /// **'Clientes'**
  String get adminNavClients;

  /// Onglet admin : support
  ///
  /// In fr, this message translates to:
  /// **'Support'**
  String get adminNavSupport;

  /// Entrée « Plus » de la barre basse
  ///
  /// In fr, this message translates to:
  /// **'Plus'**
  String get navMore;

  /// Pourcentage
  ///
  /// In fr, this message translates to:
  /// **'{value} %'**
  String adminPercent(int value);

  /// Tuile du tableau de bord
  ///
  /// In fr, this message translates to:
  /// **'Commandes actives'**
  String get adminActiveOrders;

  /// Tuile du tableau de bord
  ///
  /// In fr, this message translates to:
  /// **'Chiffre d\'affaires'**
  String get adminRevenueLabel;

  /// Tuile du tableau de bord
  ///
  /// In fr, this message translates to:
  /// **'Paiements réussis · 24 h'**
  String get adminPaymentsSucceeded;

  /// Taux de la dernière heure
  ///
  /// In fr, this message translates to:
  /// **'Dernière heure : {value}'**
  String adminPaymentsLastHour(String value);

  /// Tuile du tableau de bord
  ///
  /// In fr, this message translates to:
  /// **'Livraisons réussies'**
  String get adminDeliveriesSucceeded;

  /// Alerte du tableau de bord
  ///
  /// In fr, this message translates to:
  /// **'Commandes bloquées'**
  String get adminStuckOrders;

  /// Alerte du tableau de bord
  ///
  /// In fr, this message translates to:
  /// **'Litiges en attente'**
  String get adminPendingDisputes;

  /// Litiges en retard
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 hors délai > 48 h} other{{n} hors délai > 48 h}}'**
  String adminLateDisputes(int n);

  /// Alerte du tableau de bord
  ///
  /// In fr, this message translates to:
  /// **'Tickets ouverts'**
  String get adminOpenTickets;

  /// Tickets en retard
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 sans réponse > 1 h} other{{n} sans réponse > 1 h}}'**
  String adminLateTickets(int n);

  /// Alerte du tableau de bord
  ///
  /// In fr, this message translates to:
  /// **'Boutiques en brouillon'**
  String get adminDraftStores;

  /// Graphique du tableau de bord
  ///
  /// In fr, this message translates to:
  /// **'Commandes · 30 jours'**
  String get adminOrders30d;

  /// Carte du tableau de bord
  ///
  /// In fr, this message translates to:
  /// **'Utilisatrices actives · 7 jours'**
  String get adminActiveUsers7d;

  /// Inscriptions de la période
  ///
  /// In fr, this message translates to:
  /// **'Nouvelles inscriptions'**
  String get adminNewSignups;

  /// Classement des boutiques
  ///
  /// In fr, this message translates to:
  /// **'Top boutiques'**
  String get adminTopStores;

  /// Classement des catégories
  ///
  /// In fr, this message translates to:
  /// **'Top catégories'**
  String get adminTopCategories;

  /// Aucune donnée
  ///
  /// In fr, this message translates to:
  /// **'Rien pour cette période.'**
  String get adminNoData;

  /// Nombre de commandes
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucune commande} =1{1 commande} other{{n} commandes}}'**
  String adminOrdersCount(int n);

  /// Recherche de clientes
  ///
  /// In fr, this message translates to:
  /// **'Prénom ou e-mail'**
  String get adminClientSearch;

  /// Liste vide
  ///
  /// In fr, this message translates to:
  /// **'Aucune cliente trouvée.'**
  String get adminNoClients;

  /// Date d'inscription
  ///
  /// In fr, this message translates to:
  /// **'depuis le {date}'**
  String adminSince(String date);

  /// Montant dépensé
  ///
  /// In fr, this message translates to:
  /// **'Dépensé'**
  String get adminSpent;

  /// Nombre de demandes
  ///
  /// In fr, this message translates to:
  /// **'Demandes d\'aide'**
  String get adminTickets;

  /// Titre de section
  ///
  /// In fr, this message translates to:
  /// **'Dernières commandes'**
  String get adminLastOrders;

  /// Titre de section
  ///
  /// In fr, this message translates to:
  /// **'Adresses'**
  String get adminAddresses;

  /// Titre de section
  ///
  /// In fr, this message translates to:
  /// **'Avis laissés'**
  String get adminReviewsLeft;

  /// Mention d'audit
  ///
  /// In fr, this message translates to:
  /// **'Consultation en lecture seule, inscrite au journal.'**
  String get adminReadOnlyAudited;

  /// Filtre des tickets
  ///
  /// In fr, this message translates to:
  /// **'Ouverts'**
  String get adminTicketsOpen;

  /// Filtre des tickets
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get adminTicketsPending;

  /// Filtre des tickets
  ///
  /// In fr, this message translates to:
  /// **'Fermés'**
  String get adminTicketsClosed;

  /// Liste vide
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande ici.'**
  String get adminNoTickets;

  /// Ticket sans réponse depuis plus d'une heure
  ///
  /// In fr, this message translates to:
  /// **'> 1 h'**
  String get adminOver1h;

  /// Champ de réponse
  ///
  /// In fr, this message translates to:
  /// **'Écrire une réponse…'**
  String get adminWriteReply;

  /// Bouton de clôture
  ///
  /// In fr, this message translates to:
  /// **'Fermer le ticket'**
  String get adminCloseTicket;

  /// Refus de réponse
  ///
  /// In fr, this message translates to:
  /// **'La réponse est vide ou trop longue.'**
  String get adminTicketInvalid;

  /// Onglet des drapeaux
  ///
  /// In fr, this message translates to:
  /// **'Fonctionnalités'**
  String get adminTabFlags;

  /// Aide des drapeaux
  ///
  /// In fr, this message translates to:
  /// **'Les fonctions coupées restent invisibles dans les apps. Chaque changement est inscrit au journal.'**
  String get adminFlagsHelp;

  /// Portée d'un drapeau
  ///
  /// In fr, this message translates to:
  /// **'Tous les pays'**
  String get adminFlagEverywhere;

  /// Vue de la vendeuse
  ///
  /// In fr, this message translates to:
  /// **'Voir comme elle'**
  String get adminViewAsVendor;

  /// Suppression du compte vendeuse
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte'**
  String get adminDeleteVendor;

  /// Refus de suppression
  ///
  /// In fr, this message translates to:
  /// **'Cette boutique a des commandes : suspends-la plutôt.'**
  String get adminVendorHasOrders;

  /// Produit indisponible
  ///
  /// In fr, this message translates to:
  /// **'Épuisé'**
  String get adminOutOfStock;

  /// Stock d'un produit
  ///
  /// In fr, this message translates to:
  /// **'Stock : {n}'**
  String adminStock(int n);

  /// Section des finances
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get adminRevenue;

  /// Période
  ///
  /// In fr, this message translates to:
  /// **'Ce mois'**
  String get adminThisMonth;

  /// Période
  ///
  /// In fr, this message translates to:
  /// **'Mois dernier'**
  String get adminLastMonth;

  /// Période
  ///
  /// In fr, this message translates to:
  /// **'30 jours'**
  String get admin30Days;

  /// Tuile des revenus
  ///
  /// In fr, this message translates to:
  /// **'Ventes encaissées'**
  String get adminSalesCollected;

  /// Tuile des revenus
  ///
  /// In fr, this message translates to:
  /// **'Commission DYM'**
  String get adminCommission;

  /// Tuile des revenus
  ///
  /// In fr, this message translates to:
  /// **'Net vendeuses'**
  String get adminVendorNet;

  /// Tableau des revenus
  ///
  /// In fr, this message translates to:
  /// **'Par boutique'**
  String get adminByStore;

  /// Note des revenus
  ///
  /// In fr, this message translates to:
  /// **'Commission calculée par la base au moment de la commande.'**
  String get adminCommissionNote;

  /// Pilotage : colonne
  ///
  /// In fr, this message translates to:
  /// **'Ventes'**
  String get adminColSales;

  /// Nombre de vendeuses actives
  ///
  /// In fr, this message translates to:
  /// **'Vendeuses'**
  String get adminVendors;

  /// Écoute en cours (71)
  ///
  /// In fr, this message translates to:
  /// **'Je t\'écoute…'**
  String get voiceListening;

  /// Transcription en cours
  ///
  /// In fr, this message translates to:
  /// **'Je réfléchis…'**
  String get voiceTranscribing;

  /// Transcription terminée
  ///
  /// In fr, this message translates to:
  /// **'C\'est noté.'**
  String get voiceDone;

  /// Rien compris
  ///
  /// In fr, this message translates to:
  /// **'Je n\'ai rien entendu. Réessaie ou tape ta recherche.'**
  String get voiceNothing;

  /// Arrêter l'écoute
  ///
  /// In fr, this message translates to:
  /// **'J\'ai fini'**
  String get voiceStop;

  /// Relancer l'écoute
  ///
  /// In fr, this message translates to:
  /// **'Recommencer'**
  String get voiceRestart;

  /// Exemple de recherche vocale
  ///
  /// In fr, this message translates to:
  /// **'Parle naturellement, par exemple : « des tomates et du gombo pour ce soir »'**
  String get voiceHint;

  /// Texte entendu (suivi du texte)
  ///
  /// In fr, this message translates to:
  /// **'Tu as dit : '**
  String get voiceYouSaid;

  /// Lancer la recherche entendue
  ///
  /// In fr, this message translates to:
  /// **'Chercher'**
  String get voiceSearch;

  /// Micro refusé
  ///
  /// In fr, this message translates to:
  /// **'Le micro est refusé. Autorise-le dans les réglages ou tape ta recherche.'**
  String get voiceMicDenied;

  /// Échec de la voix ou de la photo
  ///
  /// In fr, this message translates to:
  /// **'Ça n\'a pas marché cette fois. Tape ta recherche.'**
  String get aiSearchFailed;

  /// Recherches récentes
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get searchHistory;

  /// Effacer l'historique
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get searchHistoryClear;

  /// Complétions pendant la saisie
  ///
  /// In fr, this message translates to:
  /// **'Suggestions'**
  String get searchSuggestions;

  /// Photo en cours d'analyse
  ///
  /// In fr, this message translates to:
  /// **'Je regarde ta photo…'**
  String get photoSearchAnalyzing;

  /// Photo non reconnue
  ///
  /// In fr, this message translates to:
  /// **'Je n\'ai pas reconnu de produit. Essaie une autre photo ou tape ta recherche.'**
  String get photoSearchNothing;

  /// Source : appareil photo
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get photoTake;

  /// Source : galerie
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get photoFromGallery;

  /// Vignette de la photo cherchée
  ///
  /// In fr, this message translates to:
  /// **'Ta photo'**
  String get photoSearchYourPhoto;

  /// En-tête des résultats photo (72)
  ///
  /// In fr, this message translates to:
  /// **'D\'après ta photo :'**
  String get photoSearchFrom;

  /// Modifier le texte reconnu
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get photoSearchEdit;

  /// Chercher avec une autre photo
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle photo'**
  String get photoSearchNew;

  /// Bouton micro
  ///
  /// In fr, this message translates to:
  /// **'Chercher à la voix'**
  String get voiceSearchAction;

  /// Bouton appareil photo
  ///
  /// In fr, this message translates to:
  /// **'Chercher en photo'**
  String get photoSearchAction;

  /// Titre du copilote (73)
  ///
  /// In fr, this message translates to:
  /// **'Dis-moi ce que tu veux cuisiner'**
  String get copilotTitle;

  /// Point d'entrée du copilote (accueil)
  ///
  /// In fr, this message translates to:
  /// **'Dis-moi ce que tu veux cuisiner, je compose ton panier.'**
  String get copilotEntry;

  /// Raccourci du copilote sur l'Accueil
  ///
  /// In fr, this message translates to:
  /// **'Composer mon panier'**
  String get homeCopilotShort;

  /// Précision du raccourci copilote
  ///
  /// In fr, this message translates to:
  /// **'Dis ce que tu cuisines'**
  String get homeCopilotHint;

  /// Exemple d'intention
  ///
  /// In fr, this message translates to:
  /// **'Par exemple : « Une sauce gombo pour 4 personnes ce soir »'**
  String get copilotExample;

  /// Champ de l'intention
  ///
  /// In fr, this message translates to:
  /// **'Écris ou parle…'**
  String get copilotHint;

  /// Envoyer l'intention
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get copilotSend;

  /// Proposition en cours
  ///
  /// In fr, this message translates to:
  /// **'Je compose ton panier…'**
  String get copilotThinking;

  /// Titre de la proposition
  ///
  /// In fr, this message translates to:
  /// **'Je te propose ce panier'**
  String get copilotProposal;

  /// Besoins sans produit
  ///
  /// In fr, this message translates to:
  /// **'Je n\'ai pas trouvé : {items}'**
  String copilotMissing(String items);

  /// Aucun produit trouvé
  ///
  /// In fr, this message translates to:
  /// **'Je n\'ai rien trouvé pour ça.'**
  String get copilotNothing;

  /// IA indisponible
  ///
  /// In fr, this message translates to:
  /// **'Le copilote ne répond pas pour l\'instant. Cherche toi-même, c\'est rapide.'**
  String get copilotUnavailable;

  /// Total hors livraison
  ///
  /// In fr, this message translates to:
  /// **'+ livraison'**
  String get copilotPlusDelivery;

  /// Ajouter la proposition
  ///
  /// In fr, this message translates to:
  /// **'Tout ajouter au panier'**
  String get copilotAddAll;

  /// Retour à la recherche classique
  ///
  /// In fr, this message translates to:
  /// **'Chercher moi-même'**
  String get copilotSearchMyself;

  /// Retirer une ligne
  ///
  /// In fr, this message translates to:
  /// **'Retirer {name}'**
  String copilotRemove(String name);

  /// Lignes refusées par le panier
  ///
  /// In fr, this message translates to:
  /// **'Plus disponible, pas ajouté : {items}'**
  String copilotRefused(String items);

  /// Fermer (générique)
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get actionClose;

  /// Onglet admin : modération
  ///
  /// In fr, this message translates to:
  /// **'Modération'**
  String get adminNavModeration;

  /// Onglet du fil de vidéos
  ///
  /// In fr, this message translates to:
  /// **'Vidéos'**
  String get navVideos;

  /// Onglet du fil (74)
  ///
  /// In fr, this message translates to:
  /// **'Pour toi'**
  String get feedForYou;

  /// Onglet du fil : boutiques où la cliente a commandé
  ///
  /// In fr, this message translates to:
  /// **'Abonnements'**
  String get feedFollowing;

  /// Fil vide
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de vidéo dans ton quartier.'**
  String get feedEmpty;

  /// Fil des boutiques suivies vide
  ///
  /// In fr, this message translates to:
  /// **'Les vidéos des boutiques où tu as commandé apparaîtront ici.'**
  String get feedEmptyFollowing;

  /// Ajouter le produit tagué
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get feedAdd;

  /// Produit ajouté depuis un contenu
  ///
  /// In fr, this message translates to:
  /// **'{name} est dans ton panier.'**
  String feedAdded(String name);

  /// Aimer un contenu
  ///
  /// In fr, this message translates to:
  /// **'J\'aime'**
  String get feedLike;

  /// Rangée de stories (accueil)
  ///
  /// In fr, this message translates to:
  /// **'Statuts des boutiques'**
  String get storiesTitle;

  /// Ajouter le produit d'une story
  ///
  /// In fr, this message translates to:
  /// **'Ajouter {name}'**
  String storyAddProduct(String name);

  /// Vidéos d'un produit (fiche)
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{Voir en vidéo} other{Voir en vidéo ({n})}}'**
  String productVideos(int n);

  /// Signaler un contenu, un produit ou un avis
  ///
  /// In fr, this message translates to:
  /// **'Signaler'**
  String get reportAction;

  /// Titre de la feuille de signalement
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi signaler ?'**
  String get reportTitle;

  /// Motif
  ///
  /// In fr, this message translates to:
  /// **'Contenu trompeur'**
  String get reportMisleading;

  /// Motif
  ///
  /// In fr, this message translates to:
  /// **'Propos insultants'**
  String get reportOffensive;

  /// Motif
  ///
  /// In fr, this message translates to:
  /// **'Produit interdit'**
  String get reportForbidden;

  /// Motif
  ///
  /// In fr, this message translates to:
  /// **'Spam'**
  String get reportSpam;

  /// Motif
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get reportOther;

  /// Contenus de la vendeuse
  ///
  /// In fr, this message translates to:
  /// **'Mes statuts et vidéos'**
  String get contentMine;

  /// Titre de la publication (75)
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get contentPublishTitle;

  /// Type de contenu
  ///
  /// In fr, this message translates to:
  /// **'Statut 24 h'**
  String get contentStory;

  /// Type de contenu
  ///
  /// In fr, this message translates to:
  /// **'Vidéo'**
  String get contentVideo;

  /// Média d'une story
  ///
  /// In fr, this message translates to:
  /// **'Filme ou choisis une photo ou une courte vidéo.'**
  String get contentPickStory;

  /// Média d'une vidéo
  ///
  /// In fr, this message translates to:
  /// **'Filme ou choisis une vidéo de 60 secondes au plus.'**
  String get contentPickVideo;

  /// Vidéo choisie
  ///
  /// In fr, this message translates to:
  /// **'Vidéo prête'**
  String get contentVideoReady;

  /// Filmer une vidéo
  ///
  /// In fr, this message translates to:
  /// **'Filmer'**
  String get contentFilm;

  /// Choisir dans la galerie
  ///
  /// In fr, this message translates to:
  /// **'Galerie'**
  String get contentGallery;

  /// Produits du contenu
  ///
  /// In fr, this message translates to:
  /// **'Produits tagués'**
  String get contentTagged;

  /// Aucun produit à taguer
  ///
  /// In fr, this message translates to:
  /// **'Publie d\'abord un produit pour pouvoir le taguer.'**
  String get contentNoProducts;

  /// Limite des produits tagués
  ///
  /// In fr, this message translates to:
  /// **'5 produits au plus.'**
  String get contentTagLimit;

  /// Légende d'un contenu
  ///
  /// In fr, this message translates to:
  /// **'Légende (facultatif)'**
  String get contentCaption;

  /// Publier une story
  ///
  /// In fr, this message translates to:
  /// **'Publier le statut'**
  String get contentPublishStory;

  /// Publier une vidéo
  ///
  /// In fr, this message translates to:
  /// **'Publier la vidéo'**
  String get contentPublishVideo;

  /// Aide d'une story
  ///
  /// In fr, this message translates to:
  /// **'Visible 24 h par les clientes de ta zone.'**
  String get contentStoryHint;

  /// Aide d'une vidéo
  ///
  /// In fr, this message translates to:
  /// **'Visible dans le fil des clientes de ta zone.'**
  String get contentVideoHint;

  /// Aucun contenu
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de statut ni de vidéo.'**
  String get contentNone;

  /// Contenu archivé
  ///
  /// In fr, this message translates to:
  /// **'Archivé'**
  String get contentArchived;

  /// Statistiques d'un contenu
  ///
  /// In fr, this message translates to:
  /// **'{views} vues · {clicks} clics · {likes} j\'aime'**
  String contentStats(int views, int clicks, int likes);

  /// Menu d'un contenu
  ///
  /// In fr, this message translates to:
  /// **'Actions'**
  String get contentActions;

  /// Archiver un contenu
  ///
  /// In fr, this message translates to:
  /// **'Archiver'**
  String get contentArchive;

  /// Supprimer un contenu
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get contentDelete;

  /// Filtre de modération
  ///
  /// In fr, this message translates to:
  /// **'Signalés'**
  String get moderationOpen;

  /// Filtre de modération
  ///
  /// In fr, this message translates to:
  /// **'Traités'**
  String get moderationDecided;

  /// File vide
  ///
  /// In fr, this message translates to:
  /// **'Aucun signalement.'**
  String get moderationEmpty;

  /// Nombre de signalements
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 signalement} other{{n} signalements}}'**
  String moderationReports(int n);

  /// Décision
  ///
  /// In fr, this message translates to:
  /// **'Gardé'**
  String get moderationKept;

  /// Décision
  ///
  /// In fr, this message translates to:
  /// **'Retiré'**
  String get moderationRemoved;

  /// Type de cible
  ///
  /// In fr, this message translates to:
  /// **'Vidéo'**
  String get moderationVideo;

  /// Type de cible
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get moderationStory;

  /// Type de cible
  ///
  /// In fr, this message translates to:
  /// **'Produit'**
  String get moderationProduct;

  /// Type de cible
  ///
  /// In fr, this message translates to:
  /// **'Avis'**
  String get moderationReview;

  /// Titre de l'aperçu
  ///
  /// In fr, this message translates to:
  /// **'Aperçu du signalement'**
  String get moderationPreview;

  /// Champ de l'aperçu
  ///
  /// In fr, this message translates to:
  /// **'Légende'**
  String get moderationCaption;

  /// Champ de l'aperçu
  ///
  /// In fr, this message translates to:
  /// **'Produits tagués'**
  String get moderationTagged;

  /// Champ de l'aperçu
  ///
  /// In fr, this message translates to:
  /// **'Motif'**
  String get moderationReason;

  /// Champ de l'aperçu
  ///
  /// In fr, this message translates to:
  /// **'Décision'**
  String get moderationDecision;

  /// Raison de la décision
  ///
  /// In fr, this message translates to:
  /// **'Raison (obligatoire)'**
  String get moderationReasonRequired;

  /// Garder le contenu
  ///
  /// In fr, this message translates to:
  /// **'Garder'**
  String get moderationKeep;

  /// Retirer le contenu
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get moderationRemove;

  /// Section du tableau de bord
  ///
  /// In fr, this message translates to:
  /// **'Vue générale'**
  String get adminDashboardOverview;

  /// Section du tableau de bord (77)
  ///
  /// In fr, this message translates to:
  /// **'IA et paiements'**
  String get adminDashboardAi;

  /// Tuile IA
  ///
  /// In fr, this message translates to:
  /// **'Requêtes comprises'**
  String get aiUnderstood;

  /// Tuile IA
  ///
  /// In fr, this message translates to:
  /// **'Latence moyenne'**
  String get aiLatency;

  /// Durée en secondes
  ///
  /// In fr, this message translates to:
  /// **'{value} s'**
  String aiSeconds(double value);

  /// Tuile IA (copilote sans proposition)
  ///
  /// In fr, this message translates to:
  /// **'Passages à la recherche classique'**
  String get aiFallback;

  /// Tuile paiements (1 h)
  ///
  /// In fr, this message translates to:
  /// **'Paiements réussis'**
  String get adminPaymentsSucceeded1h;

  /// Période
  ///
  /// In fr, this message translates to:
  /// **'24 h'**
  String get ai24h;

  /// Période
  ///
  /// In fr, this message translates to:
  /// **'1 h'**
  String get ai1h;

  /// Série IA
  ///
  /// In fr, this message translates to:
  /// **'Compréhension · 7 jours'**
  String get aiSeries;

  /// Tableau IA
  ///
  /// In fr, this message translates to:
  /// **'Dernières requêtes non comprises'**
  String get aiMisses;

  /// Résultat IA
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get aiOutcomeNoResult;

  /// Résultat IA
  ///
  /// In fr, this message translates to:
  /// **'Panne'**
  String get aiOutcomeFailure;

  /// Type de requête
  ///
  /// In fr, this message translates to:
  /// **'Voix'**
  String get aiUsageVoice;

  /// Type de requête
  ///
  /// In fr, this message translates to:
  /// **'Photo'**
  String get aiUsagePhoto;

  /// Type de requête
  ///
  /// In fr, this message translates to:
  /// **'Texte'**
  String get aiUsageText;

  /// Mention de confidentialité
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée personnelle affichée ni liée à ces requêtes.'**
  String get aiNoPersonalData;

  /// Alerte paiements < 90 %
  ///
  /// In fr, this message translates to:
  /// **'Alerte : seulement {value} de paiements réussis sur la dernière heure.'**
  String aiPaymentsAlert(String value);

  /// Titre de l'écran 78
  ///
  /// In fr, this message translates to:
  /// **'Relancer mes clientes'**
  String get broadcastTitle;

  /// Entrée depuis Ma boutique
  ///
  /// In fr, this message translates to:
  /// **'Relancer mes clientes'**
  String get broadcastEntry;

  /// Segments
  ///
  /// In fr, this message translates to:
  /// **'Choisir mes destinataires'**
  String get broadcastAudience;

  /// Segment
  ///
  /// In fr, this message translates to:
  /// **'Clientes régulières'**
  String get broadcastRegular;

  /// Aide du segment
  ///
  /// In fr, this message translates to:
  /// **'2 commandes ou plus'**
  String get broadcastRegularHint;

  /// Segment
  ///
  /// In fr, this message translates to:
  /// **'Clientes du mois'**
  String get broadcastMonth;

  /// Segment
  ///
  /// In fr, this message translates to:
  /// **'Toutes mes clientes'**
  String get broadcastAll;

  /// Message
  ///
  /// In fr, this message translates to:
  /// **'Mon message'**
  String get broadcastMessage;

  /// Champ du message
  ///
  /// In fr, this message translates to:
  /// **'Gombo frais arrivé ce matin…'**
  String get broadcastMessageHint;

  /// Produit joint
  ///
  /// In fr, this message translates to:
  /// **'Joindre un produit (facultatif)'**
  String get broadcastAttach;

  /// Pas de produit joint
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit'**
  String get broadcastNoProduct;

  /// Règles de la relance
  ///
  /// In fr, this message translates to:
  /// **'Une relance par jour au plus. Les clientes peuvent couper ces messages.'**
  String get broadcastRules;

  /// Bouton d'envoi
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucune cliente à prévenir} =1{Envoyer à 1 cliente} other{Envoyer à {n} clientes}}'**
  String broadcastSend(int n);

  /// Relance envoyée
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{Message envoyé à 1 cliente.} other{Message envoyé à {n} clientes.}}'**
  String broadcastSent(int n);

  /// Limite d'une relance par jour
  ///
  /// In fr, this message translates to:
  /// **'Tu as déjà relancé tes clientes aujourd\'hui. Réessaie demain.'**
  String get broadcastDailyLimit;

  /// Réglage du stock bas
  ///
  /// In fr, this message translates to:
  /// **'Alerte stock bas'**
  String get lowStockTitle;

  /// Interrupteur du stock bas
  ///
  /// In fr, this message translates to:
  /// **'Me prévenir quand un produit s\'épuise'**
  String get lowStockEnabled;

  /// Seuil d'alerte
  ///
  /// In fr, this message translates to:
  /// **'Seuil'**
  String get lowStockThreshold;

  /// Valeur du seuil
  ///
  /// In fr, this message translates to:
  /// **'Me prévenir sous {n} unités'**
  String lowStockUnder(int n);

  /// Ligne de l'écran Moi
  ///
  /// In fr, this message translates to:
  /// **'Modifier mon prénom'**
  String get accountEditName;

  /// Enregistrer le profil
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get accountSave;

  /// No description provided for @adminTabAdmins.
  ///
  /// In fr, this message translates to:
  /// **'Admins'**
  String get adminTabAdmins;

  /// No description provided for @adminAdminsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Les admins par défaut viennent de la variable ADMIN_EMAILS. Un email invité devient admin à sa première connexion à DYM Admin.'**
  String get adminAdminsHelp;

  /// No description provided for @adminAdminsInvite.
  ///
  /// In fr, this message translates to:
  /// **'Inviter'**
  String get adminAdminsInvite;

  /// No description provided for @adminAdminsDefault.
  ///
  /// In fr, this message translates to:
  /// **'Par défaut'**
  String get adminAdminsDefault;

  /// No description provided for @adminAdminsActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get adminAdminsActive;

  /// No description provided for @adminAdminsPending.
  ///
  /// In fr, this message translates to:
  /// **'Invitation en attente'**
  String get adminAdminsPending;

  /// No description provided for @adminAdminsRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer l’accès admin'**
  String get adminAdminsRemove;

  /// No description provided for @authPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get authPasswordLabel;

  /// No description provided for @authSignInPassword.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get authSignInPassword;

  /// No description provided for @authUsePassword.
  ///
  /// In fr, this message translates to:
  /// **'J’ai un mot de passe'**
  String get authUsePassword;

  /// No description provided for @authUseCode.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir un code à la place'**
  String get authUseCode;

  /// No description provided for @authPasswordWrong.
  ///
  /// In fr, this message translates to:
  /// **'Email ou mot de passe incorrect.'**
  String get authPasswordWrong;

  /// No description provided for @contentMediaMode.
  ///
  /// In fr, this message translates to:
  /// **'Photo ou vidéo'**
  String get contentMediaMode;

  /// No description provided for @contentTextMode.
  ///
  /// In fr, this message translates to:
  /// **'Écrire un statut'**
  String get contentTextMode;

  /// No description provided for @contentTextLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ton message'**
  String get contentTextLabel;

  /// No description provided for @contentTextHint.
  ///
  /// In fr, this message translates to:
  /// **'Écris ton statut…'**
  String get contentTextHint;

  /// Ligne wallet du compte
  ///
  /// In fr, this message translates to:
  /// **'Mon wallet'**
  String get accountWallet;

  /// Titre de l'écran wallet
  ///
  /// In fr, this message translates to:
  /// **'Mon wallet'**
  String get walletTitle;

  /// Solde disponible
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get walletAvailable;

  /// Total wallet + poches
  ///
  /// In fr, this message translates to:
  /// **'Total avec les poches : {amount}'**
  String walletTotal(String amount);

  /// Action recharger
  ///
  /// In fr, this message translates to:
  /// **'Recharger'**
  String get walletTopup;

  /// Mention de simulation
  ///
  /// In fr, this message translates to:
  /// **'Recharge simulée : aucun argent réel n\'est débité.'**
  String get walletTopupSimulated;

  /// Action déplacer de l'argent
  ///
  /// In fr, this message translates to:
  /// **'Déplacer'**
  String get walletMove;

  /// Titre des poches
  ///
  /// In fr, this message translates to:
  /// **'Mes poches'**
  String get walletPockets;

  /// Action nouvelle poche
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle poche'**
  String get walletNewPocket;

  /// Aucune poche
  ///
  /// In fr, this message translates to:
  /// **'Crée une poche pour mettre de côté : courses du mois, fêtes, précommandes.'**
  String get walletPocketsEmpty;

  /// Objectif d'une poche
  ///
  /// In fr, this message translates to:
  /// **'Objectif {amount}'**
  String walletPocketGoal(String amount);

  /// Arrondi d'une poche
  ///
  /// In fr, this message translates to:
  /// **'Arrondi à {amount}'**
  String walletPocketRoundUp(String amount);

  /// Archiver une poche
  ///
  /// In fr, this message translates to:
  /// **'Fermer la poche'**
  String get walletPocketArchive;

  /// Titre des mouvements
  ///
  /// In fr, this message translates to:
  /// **'Mouvements'**
  String get walletMovements;

  /// Aucun mouvement
  ///
  /// In fr, this message translates to:
  /// **'Aucun mouvement pour l\'instant.'**
  String get walletMovementsEmpty;

  /// Mouvement : recharge
  ///
  /// In fr, this message translates to:
  /// **'Recharge'**
  String get walletKindTopup;

  /// Mouvement : transfert
  ///
  /// In fr, this message translates to:
  /// **'Transfert entre poches'**
  String get walletKindTransfer;

  /// Mouvement : paiement
  ///
  /// In fr, this message translates to:
  /// **'Paiement d\'une commande'**
  String get walletKindPayment;

  /// Mouvement : remboursement
  ///
  /// In fr, this message translates to:
  /// **'Remboursement'**
  String get walletKindRefund;

  /// Mouvement : cashback
  ///
  /// In fr, this message translates to:
  /// **'Cashback'**
  String get walletKindCashback;

  /// Mouvement inconnu
  ///
  /// In fr, this message translates to:
  /// **'Mouvement'**
  String get walletKindOther;

  /// Champ montant
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get walletAmount;

  /// Champ nom de poche
  ///
  /// In fr, this message translates to:
  /// **'Nom de la poche'**
  String get walletPocketName;

  /// Champ objectif
  ///
  /// In fr, this message translates to:
  /// **'Objectif (facultatif)'**
  String get walletPocketGoalField;

  /// Champ arrondi
  ///
  /// In fr, this message translates to:
  /// **'Arrondir chaque paiement à (facultatif)'**
  String get walletPocketRoundUpField;

  /// Origine d'un transfert
  ///
  /// In fr, this message translates to:
  /// **'Depuis'**
  String get walletFrom;

  /// Destination d'un transfert
  ///
  /// In fr, this message translates to:
  /// **'Vers'**
  String get walletTo;

  /// Le wallet principal
  ///
  /// In fr, this message translates to:
  /// **'Wallet'**
  String get walletMain;

  /// Bouton valider
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get walletConfirm;

  /// Erreur solde
  ///
  /// In fr, this message translates to:
  /// **'Solde insuffisant.'**
  String get walletErrorInsufficient;

  /// Erreur montant
  ///
  /// In fr, this message translates to:
  /// **'Montant invalide.'**
  String get walletErrorAmount;

  /// Erreur recharge coupée
  ///
  /// In fr, this message translates to:
  /// **'La recharge n\'est pas disponible ici.'**
  String get walletErrorTopupDisabled;

  /// Erreur limite de poches
  ///
  /// In fr, this message translates to:
  /// **'Tu as atteint le nombre maximum de poches.'**
  String get walletErrorPocketLimit;

  /// Refus : wallet insuffisant
  ///
  /// In fr, this message translates to:
  /// **'Solde du wallet insuffisant : recharge-le ou choisis un autre moyen.'**
  String get orderErrorWalletInsufficient;

  /// Mouvement vers une poche
  ///
  /// In fr, this message translates to:
  /// **'Vers {name}'**
  String walletToPocket(String name);

  /// Mouvement depuis une poche
  ///
  /// In fr, this message translates to:
  /// **'Depuis {name}'**
  String walletFromPocket(String name);

  /// Adresse choisie dans le panier
  ///
  /// In fr, this message translates to:
  /// **'{zone} · {landmark}'**
  String cartDeliveryTo(String zone, String landmark);

  /// Invitation à ajouter une adresse dans le panier
  ///
  /// In fr, this message translates to:
  /// **'Ajoute une adresse de livraison'**
  String get cartAddAddress;

  /// Question en tête de l'accueil
  ///
  /// In fr, this message translates to:
  /// **'Qu\'est-ce qu\'on mange ?'**
  String get homeWhatToEat;

  /// Section des produits populaires
  ///
  /// In fr, this message translates to:
  /// **'Les plus demandés près de toi'**
  String get homePopular;

  /// Section des nouveautés
  ///
  /// In fr, this message translates to:
  /// **'Nouveautés'**
  String get homeFresh;

  /// Titre de la carte de réachat
  ///
  /// In fr, this message translates to:
  /// **'Recommander tes courses'**
  String get homeReorderTitle;

  /// Boutique et articles de la dernière commande
  ///
  /// In fr, this message translates to:
  /// **'{store} · {count, plural, =1{1 article} other{{count} articles}}'**
  String homeReorderMeta(String store, int count);

  /// Bouton recommander
  ///
  /// In fr, this message translates to:
  /// **'Recommander'**
  String get homeReorderAction;

  /// Raison : même boutique
  ///
  /// In fr, this message translates to:
  /// **'Même boutique : un seul ramassage'**
  String get copilotReasonSameStore;

  /// Raison : ouverte
  ///
  /// In fr, this message translates to:
  /// **'Boutique ouverte maintenant'**
  String get copilotReasonOpenNow;

  /// Raison : mieux notée
  ///
  /// In fr, this message translates to:
  /// **'Boutique la mieux notée'**
  String get copilotReasonTopRated;

  /// Raison : prix
  ///
  /// In fr, this message translates to:
  /// **'Le meilleur prix'**
  String get copilotReasonBestPrice;

  /// Raison : quartier
  ///
  /// In fr, this message translates to:
  /// **'Boutique de ton quartier'**
  String get copilotReasonNearby;

  /// Raison : correspondance
  ///
  /// In fr, this message translates to:
  /// **'Correspond le mieux à ta demande'**
  String get copilotReasonBestMatch;

  /// Onglet réglages de la recherche
  ///
  /// In fr, this message translates to:
  /// **'Recherche'**
  String get adminTabSearch;

  /// Aide des poids de classement
  ///
  /// In fr, this message translates to:
  /// **'Poids de 0 à 100 utilisés pour choisir les produits proposés par l\'assistant. Plus un poids est fort, plus le critère compte.'**
  String get adminRankingHelp;

  /// Bouton modifier les poids
  ///
  /// In fr, this message translates to:
  /// **'Modifier les poids'**
  String get adminEditRanking;

  /// Poids : texte
  ///
  /// In fr, this message translates to:
  /// **'Correspondance au texte'**
  String get adminWeightText;

  /// Poids : même boutique
  ///
  /// In fr, this message translates to:
  /// **'Même boutique (moins de ramassages)'**
  String get adminWeightSameStore;

  /// Poids : ouverte
  ///
  /// In fr, this message translates to:
  /// **'Boutique ouverte'**
  String get adminWeightOpen;

  /// Poids : note
  ///
  /// In fr, this message translates to:
  /// **'Note de la boutique'**
  String get adminWeightRating;

  /// Poids : prix
  ///
  /// In fr, this message translates to:
  /// **'Prix bas'**
  String get adminWeightPrice;

  /// Poids : quartier
  ///
  /// In fr, this message translates to:
  /// **'Boutique du quartier'**
  String get adminWeightSameZone;

  /// Titre des synonymes
  ///
  /// In fr, this message translates to:
  /// **'Noms locaux'**
  String get adminSynonymsTitle;

  /// Bouton ajouter un synonyme
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un nom local'**
  String get adminAddSynonym;

  /// Champ terme
  ///
  /// In fr, this message translates to:
  /// **'Nom local (ex. gboma)'**
  String get adminSynonymTerm;

  /// Champ synonymes
  ///
  /// In fr, this message translates to:
  /// **'Équivalents, séparés par des virgules'**
  String get adminSynonymList;

  /// Retirer un synonyme
  ///
  /// In fr, this message translates to:
  /// **'Retirer {term}'**
  String adminRemoveSynonym(String term);

  /// Titre de l'assistant de courses
  ///
  /// In fr, this message translates to:
  /// **'Mes courses'**
  String get shoppingTitle;

  /// Tuile de l'accueil
  ///
  /// In fr, this message translates to:
  /// **'Mes listes de courses'**
  String get shoppingHomeTile;

  /// Sous-titre de la tuile
  ///
  /// In fr, this message translates to:
  /// **'Refais tes courses en un geste'**
  String get shoppingHomeTileHint;

  /// Promesse de validation
  ///
  /// In fr, this message translates to:
  /// **'Rien n\'est commandé sans toi : l\'assistant compose, tu vérifies et tu ajoutes au panier.'**
  String get shoppingIntro;

  /// État vide
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de liste. Crée « Courses du samedi », « Petit-déjeuner »… et l\'assistant composera ton panier.'**
  String get shoppingEmpty;

  /// Créer une liste
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle liste'**
  String get shoppingNew;

  /// Liste depuis les habitudes
  ///
  /// In fr, this message translates to:
  /// **'Ma liste habituelle'**
  String get shoppingFromHabits;

  /// Sous-titre habitudes
  ///
  /// In fr, this message translates to:
  /// **'Ce que tu achètes souvent'**
  String get shoppingFromHabitsHint;

  /// Aucune habitude
  ///
  /// In fr, this message translates to:
  /// **'Pas encore d\'habitudes : il faut avoir commandé au moins deux fois le même produit.'**
  String get shoppingNoHabits;

  /// Liste proposée par l'IA
  ///
  /// In fr, this message translates to:
  /// **'Décrire mes courses'**
  String get shoppingDescribe;

  /// Exemple de description
  ///
  /// In fr, this message translates to:
  /// **'Ex. la semaine pour 4 personnes'**
  String get shoppingDescribeHint;

  /// Bouton de l'IA
  ///
  /// In fr, this message translates to:
  /// **'Proposer une liste'**
  String get shoppingDescribeAction;

  /// IA indisponible
  ///
  /// In fr, this message translates to:
  /// **'L\'assistant ne répond pas. Tu peux créer ta liste à la main.'**
  String get shoppingAiUnavailable;

  /// IA sans résultat
  ///
  /// In fr, this message translates to:
  /// **'Je n\'ai rien trouvé à proposer. Essaie avec d\'autres mots.'**
  String get shoppingAiNothing;

  /// Nombre d'articles
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 article} other{{count} articles}}'**
  String shoppingItemsCount(int count);

  /// Sans récurrence
  ///
  /// In fr, this message translates to:
  /// **'Pas de rappel'**
  String get shoppingNoRepeat;

  /// Récurrence 7 jours
  ///
  /// In fr, this message translates to:
  /// **'Chaque semaine'**
  String get shoppingEvery7;

  /// Récurrence 14 jours
  ///
  /// In fr, this message translates to:
  /// **'Toutes les 2 semaines'**
  String get shoppingEvery14;

  /// Récurrence 30 jours
  ///
  /// In fr, this message translates to:
  /// **'Chaque mois'**
  String get shoppingEvery30;

  /// Date du prochain rappel
  ///
  /// In fr, this message translates to:
  /// **'Prochain rappel : {date}'**
  String shoppingNextOn(String date);

  /// Ouvrir la proposition
  ///
  /// In fr, this message translates to:
  /// **'Composer mon panier'**
  String get shoppingOpen;

  /// Menu d'une liste
  ///
  /// In fr, this message translates to:
  /// **'Plus d\'actions pour {name}'**
  String shoppingMore(String name);

  /// Modifier une liste
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get shoppingEdit;

  /// Supprimer une liste
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get shoppingDelete;

  /// Confirmation de suppression
  ///
  /// In fr, this message translates to:
  /// **'Supprimer « {name} » ?'**
  String shoppingDeleteConfirm(String name);

  /// Après suppression
  ///
  /// In fr, this message translates to:
  /// **'Liste supprimée'**
  String get shoppingDeleted;

  /// Titre de l'édition
  ///
  /// In fr, this message translates to:
  /// **'Ma liste'**
  String get shoppingEditTitle;

  /// Champ nom
  ///
  /// In fr, this message translates to:
  /// **'Nom de la liste'**
  String get shoppingName;

  /// Exemple de nom
  ///
  /// In fr, this message translates to:
  /// **'Ex. Courses du samedi'**
  String get shoppingNameHint;

  /// Titre des articles
  ///
  /// In fr, this message translates to:
  /// **'Articles'**
  String get shoppingItemsTitle;

  /// Champ d'ajout
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un article (tomates, riz…)'**
  String get shoppingItemHint;

  /// Bouton ajouter un article
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get shoppingAddItem;

  /// Retirer un article
  ///
  /// In fr, this message translates to:
  /// **'Retirer {name}'**
  String shoppingRemoveItem(String name);

  /// Diminuer la quantité
  ///
  /// In fr, this message translates to:
  /// **'Un de moins : {name}'**
  String shoppingLess(String name);

  /// Augmenter la quantité
  ///
  /// In fr, this message translates to:
  /// **'Un de plus : {name}'**
  String shoppingMoreQty(String name);

  /// Titre de la récurrence
  ///
  /// In fr, this message translates to:
  /// **'Me rappeler'**
  String get shoppingRepeatTitle;

  /// Date du premier rappel
  ///
  /// In fr, this message translates to:
  /// **'Premier rappel le {date}'**
  String shoppingStartsOn(String date);

  /// Choisir la date
  ///
  /// In fr, this message translates to:
  /// **'Changer la date'**
  String get shoppingPickDate;

  /// Explication du rappel
  ///
  /// In fr, this message translates to:
  /// **'Le jour venu, à 8 h, on te prévient : tu vérifies et tu valides.'**
  String get shoppingRepeatNote;

  /// Enregistrer
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la liste'**
  String get shoppingSave;

  /// Après enregistrement
  ///
  /// In fr, this message translates to:
  /// **'Liste enregistrée'**
  String get shoppingSaved;

  /// Nom manquant
  ///
  /// In fr, this message translates to:
  /// **'Donne un nom à ta liste.'**
  String get shoppingErrorName;

  /// Liste vide
  ///
  /// In fr, this message translates to:
  /// **'Ajoute au moins un article.'**
  String get shoppingErrorItems;

  /// Trop de listes
  ///
  /// In fr, this message translates to:
  /// **'20 listes au plus : supprimes-en une.'**
  String get shoppingErrorTooMany;

  /// Trop d'articles
  ///
  /// In fr, this message translates to:
  /// **'20 articles au plus par liste.'**
  String get shoppingErrorTooManyItems;

  /// Notification de rappel
  ///
  /// In fr, this message translates to:
  /// **'Tes courses sont prêtes'**
  String get notifShoppingDueTitle;

  /// Notification de rappel
  ///
  /// In fr, this message translates to:
  /// **'« {name} » : vérifie et valide ton panier.'**
  String notifShoppingDueBody(String name);

  /// Cœur vide
  ///
  /// In fr, this message translates to:
  /// **'Ajouter aux favoris'**
  String get favoriteAdd;

  /// Cœur plein
  ///
  /// In fr, this message translates to:
  /// **'Retirer des favoris'**
  String get favoriteRemove;

  /// Titre des favoris
  ///
  /// In fr, this message translates to:
  /// **'Mes favoris'**
  String get favoritesTitle;

  /// Section boutiques
  ///
  /// In fr, this message translates to:
  /// **'Boutiques'**
  String get favoritesStores;

  /// Section produits
  ///
  /// In fr, this message translates to:
  /// **'Produits'**
  String get favoritesProducts;

  /// Favoris vides
  ///
  /// In fr, this message translates to:
  /// **'Touche le cœur d\'une boutique ou d\'un produit pour le retrouver ici.'**
  String get favoritesEmpty;

  /// Titre des paniers enregistrés
  ///
  /// In fr, this message translates to:
  /// **'Mes paniers'**
  String get basketsTitle;

  /// Paniers vides
  ///
  /// In fr, this message translates to:
  /// **'Enregistre ton panier (petit-déjeuner, déjeuner, le mois…) depuis le panier pour le refaire en un geste.'**
  String get basketsEmpty;

  /// Bouton du panier
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer ce panier'**
  String get basketSave;

  /// Valider le nom
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get basketSaveAction;

  /// Titre du dialogue
  ///
  /// In fr, this message translates to:
  /// **'Nom du panier'**
  String get basketName;

  /// Exemple de nom
  ///
  /// In fr, this message translates to:
  /// **'Ex. Petit-déjeuner'**
  String get basketNameHint;

  /// Après enregistrement
  ///
  /// In fr, this message translates to:
  /// **'Panier enregistré : retrouve-le dans « Mes paniers ».'**
  String get basketSaved;

  /// Remise au panier
  ///
  /// In fr, this message translates to:
  /// **'Remettre au panier'**
  String get basketToCart;

  /// Résumé du panier
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 article} other{{count} articles}} · {total} aujourd\'hui'**
  String basketMeta(int count, String total);

  /// Articles indisponibles
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 article indisponible} other{{count} articles indisponibles}}'**
  String basketUnavailable(int count);

  /// Articles non ajoutés
  ///
  /// In fr, this message translates to:
  /// **'Pas ajouté (plus disponible) : {items}'**
  String basketSkipped(String items);

  /// Menu du panier
  ///
  /// In fr, this message translates to:
  /// **'Plus d\'actions pour {name}'**
  String basketMore(String name);

  /// Renommer
  ///
  /// In fr, this message translates to:
  /// **'Renommer'**
  String get basketRename;

  /// Supprimer
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get basketDelete;

  /// Confirmation
  ///
  /// In fr, this message translates to:
  /// **'Supprimer « {name} » ?'**
  String basketDeleteConfirm(String name);

  /// Panier vide
  ///
  /// In fr, this message translates to:
  /// **'Ton panier est vide.'**
  String get basketErrorEmpty;

  /// Limite
  ///
  /// In fr, this message translates to:
  /// **'20 paniers de 50 articles au plus : supprimes-en un.'**
  String get basketErrorTooMany;

  /// Nom manquant
  ///
  /// In fr, this message translates to:
  /// **'Donne un nom à ton panier.'**
  String get basketErrorName;

  /// Menu Moi
  ///
  /// In fr, this message translates to:
  /// **'Mes favoris'**
  String get accountFavorites;

  /// Menu Moi
  ///
  /// In fr, this message translates to:
  /// **'Mes paniers'**
  String get accountBaskets;

  /// Titre des espaces
  ///
  /// In fr, this message translates to:
  /// **'Mes espaces'**
  String get spacesTitle;

  /// Explication
  ///
  /// In fr, this message translates to:
  /// **'Un espace réunit ceux qui remplissent et ceux qui valident et paient : la maison, la famille au pays, une tontine…'**
  String get spacesIntro;

  /// Aucun espace
  ///
  /// In fr, this message translates to:
  /// **'Pas encore d\'espace. Crée-en un ou rejoins celui d\'un proche avec son code.'**
  String get spacesEmpty;

  /// Créer
  ///
  /// In fr, this message translates to:
  /// **'Créer un espace'**
  String get spaceCreate;

  /// Valider la création
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get spaceCreateAction;

  /// Rejoindre
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre'**
  String get spaceJoin;

  /// Valider le code
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre'**
  String get spaceJoinAction;

  /// Champ code
  ///
  /// In fr, this message translates to:
  /// **'Code reçu (8 caractères)'**
  String get spaceCodeHint;

  /// Champ nom
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'espace'**
  String get spaceName;

  /// Exemple de nom
  ///
  /// In fr, this message translates to:
  /// **'Ex. Maison, Famille à Kpalimé'**
  String get spaceNameHint;

  /// Champ budget
  ///
  /// In fr, this message translates to:
  /// **'Budget du mois (facultatif)'**
  String get spaceBudget;

  /// Exemple de budget
  ///
  /// In fr, this message translates to:
  /// **'Ex. 50 000'**
  String get spaceBudgetHint;

  /// Nombre de membres
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 membre} other{{count} membres}}'**
  String spaceMembersCount(int count);

  /// Rôle payeur
  ///
  /// In fr, this message translates to:
  /// **'Valide et paie'**
  String get spaceRolePayer;

  /// Rôle membre
  ///
  /// In fr, this message translates to:
  /// **'Remplit'**
  String get spaceRoleMember;

  /// Responsable
  ///
  /// In fr, this message translates to:
  /// **'Responsable · valide et paie'**
  String get spaceOwner;

  /// Soi-même
  ///
  /// In fr, this message translates to:
  /// **'{name} (moi)'**
  String spaceMe(String name);

  /// Menu d'un membre
  ///
  /// In fr, this message translates to:
  /// **'Gérer {name}'**
  String spaceManage(String name);

  /// Promouvoir
  ///
  /// In fr, this message translates to:
  /// **'Peut valider et payer'**
  String get spaceMakePayer;

  /// Rétrograder
  ///
  /// In fr, this message translates to:
  /// **'Remplit seulement'**
  String get spaceMakeMember;

  /// Retirer
  ///
  /// In fr, this message translates to:
  /// **'Retirer de l\'espace'**
  String get spaceRemoveMember;

  /// Section membres
  ///
  /// In fr, this message translates to:
  /// **'Membres'**
  String get spaceMembers;

  /// Section panier
  ///
  /// In fr, this message translates to:
  /// **'Panier commun'**
  String get spaceBasket;

  /// Envoyer le panier
  ///
  /// In fr, this message translates to:
  /// **'Envoyer mon panier'**
  String get spaceSendCart;

  /// Panier commun vide
  ///
  /// In fr, this message translates to:
  /// **'Vide pour l\'instant : chacun remplit son panier comme d\'habitude, puis l\'envoie ici.'**
  String get spaceBasketEmpty;

  /// Total
  ///
  /// In fr, this message translates to:
  /// **'Total : {total} + livraison'**
  String spaceTotal(String total);

  /// Valider
  ///
  /// In fr, this message translates to:
  /// **'Valider et passer au panier'**
  String get spaceValidate;

  /// Attente
  ///
  /// In fr, this message translates to:
  /// **'Une personne qui valide passera la commande.'**
  String get spaceWaitPayer;

  /// Supprimer
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'espace'**
  String get spaceDelete;

  /// Quitter
  ///
  /// In fr, this message translates to:
  /// **'Quitter l\'espace'**
  String get spaceLeave;

  /// Confirmation
  ///
  /// In fr, this message translates to:
  /// **'Supprimer « {name} » pour tous ?'**
  String spaceDeleteConfirm(String name);

  /// Confirmation
  ///
  /// In fr, this message translates to:
  /// **'Quitter « {name} » ?'**
  String spaceLeaveConfirm(String name);

  /// Titre du budget
  ///
  /// In fr, this message translates to:
  /// **'Budget du mois'**
  String get spaceBudgetTitle;

  /// Budget
  ///
  /// In fr, this message translates to:
  /// **'{spent} dépensés sur {budget} · reste {left}'**
  String spaceBudgetMeta(String spent, String budget, String left);

  /// Code
  ///
  /// In fr, this message translates to:
  /// **'Code pour inviter'**
  String get spaceInvite;

  /// Copier
  ///
  /// In fr, this message translates to:
  /// **'Copier le code'**
  String get spaceCopyCode;

  /// Après copie
  ///
  /// In fr, this message translates to:
  /// **'Code copié : envoie-le à tes proches.'**
  String get spaceCodeCopied;

  /// Qui a ajouté
  ///
  /// In fr, this message translates to:
  /// **'ajouté par {name}'**
  String spaceAddedBy(String name);

  /// Indisponible
  ///
  /// In fr, this message translates to:
  /// **'indisponible'**
  String get spaceUnavailable;

  /// Choix de l'espace
  ///
  /// In fr, this message translates to:
  /// **'Envoyer mon panier à…'**
  String get spaceSendCartTitle;

  /// Bouton du panier
  ///
  /// In fr, this message translates to:
  /// **'Envoyer à un espace'**
  String get spaceSendToSpace;

  /// Après envoi
  ///
  /// In fr, this message translates to:
  /// **'Panier envoyé à « {name} ».'**
  String spaceCartSent(String name);

  /// Nom manquant
  ///
  /// In fr, this message translates to:
  /// **'Donne un nom à l\'espace.'**
  String get spaceErrorName;

  /// Budget invalide
  ///
  /// In fr, this message translates to:
  /// **'Budget invalide.'**
  String get spaceErrorBudget;

  /// Code inconnu
  ///
  /// In fr, this message translates to:
  /// **'Code inconnu : vérifie-le.'**
  String get spaceErrorUnknownCode;

  /// Autre pays
  ///
  /// In fr, this message translates to:
  /// **'Cet espace est dans un autre pays.'**
  String get spaceErrorOtherCountry;

  /// Complet
  ///
  /// In fr, this message translates to:
  /// **'Cet espace a déjà 20 membres.'**
  String get spaceErrorFull;

  /// Trop d'espaces
  ///
  /// In fr, this message translates to:
  /// **'20 espaces au plus.'**
  String get spaceErrorTooMany;

  /// Vide
  ///
  /// In fr, this message translates to:
  /// **'Rien à envoyer ou à valider.'**
  String get spaceErrorCartEmpty;

  /// Budget dépassé
  ///
  /// In fr, this message translates to:
  /// **'Ce panier dépasse le budget du mois.'**
  String get spaceErrorBudgetExceeded;

  /// Pas payeur
  ///
  /// In fr, this message translates to:
  /// **'Seule une personne qui valide peut le faire.'**
  String get spaceErrorNotPayer;

  /// Menu Moi
  ///
  /// In fr, this message translates to:
  /// **'Mes espaces'**
  String get accountSpaces;

  /// Notification
  ///
  /// In fr, this message translates to:
  /// **'Panier commun validé'**
  String get notifSpaceValidatedTitle;

  /// Notification
  ///
  /// In fr, this message translates to:
  /// **'{name} a validé le panier de « {space} ».'**
  String notifSpaceValidatedBody(String name, String space);

  /// Titre de la poche
  ///
  /// In fr, this message translates to:
  /// **'Poche commune'**
  String get spacePocket;

  /// Verser dans la poche
  ///
  /// In fr, this message translates to:
  /// **'Verser'**
  String get spaceContribute;

  /// Dialogue de versement
  ///
  /// In fr, this message translates to:
  /// **'Verser depuis mon wallet'**
  String get spaceContributeTitle;

  /// Part de chacun
  ///
  /// In fr, this message translates to:
  /// **'a versé {amount} ce mois'**
  String spaceContributedMonth(String amount);

  /// Interrupteur
  ///
  /// In fr, this message translates to:
  /// **'Payer avec la poche commune'**
  String get spaceUsePocket;

  /// Explication
  ///
  /// In fr, this message translates to:
  /// **'Le montant des articles passe sur ton wallet : choisis « Wallet DYM » pour payer.'**
  String get spaceUsePocketHint;

  /// Poche insuffisante
  ///
  /// In fr, this message translates to:
  /// **'La poche commune ne suffit pas pour ce panier.'**
  String get spaceErrorPocketInsufficient;

  /// Poche non vide
  ///
  /// In fr, this message translates to:
  /// **'La poche commune n\'est pas vide : utilise-la d\'abord.'**
  String get spaceErrorSpaceBalance;

  /// Mouvement
  ///
  /// In fr, this message translates to:
  /// **'Versé à un espace'**
  String get walletKindSpaceContribution;

  /// Mouvement
  ///
  /// In fr, this message translates to:
  /// **'Reçu d\'un espace'**
  String get walletKindSpacePayout;

  /// Choix du créneau
  ///
  /// In fr, this message translates to:
  /// **'Quand ?'**
  String get slotTitle;

  /// Sans créneau
  ///
  /// In fr, this message translates to:
  /// **'Dès que possible'**
  String get slotAsap;

  /// Jour
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get slotToday;

  /// Jour
  ///
  /// In fr, this message translates to:
  /// **'Demain'**
  String get slotTomorrow;

  /// Créneau
  ///
  /// In fr, this message translates to:
  /// **'{start}–{end}'**
  String slotWindow(String start, String end);

  /// Arrivage
  ///
  /// In fr, this message translates to:
  /// **'Ton panier contient un arrivage : livraison à partir du {date}.'**
  String slotRequiredFrom(String date);

  /// Créneau manquant
  ///
  /// In fr, this message translates to:
  /// **'Choisis un créneau de livraison.'**
  String get orderErrorSlotRequired;

  /// Créneau invalide
  ///
  /// In fr, this message translates to:
  /// **'Ce créneau n\'est plus possible : choisis-en un autre.'**
  String get orderErrorSlotInvalid;

  /// Boutique fermée
  ///
  /// In fr, this message translates to:
  /// **'Une boutique est fermée à ce créneau : choisis-en un autre.'**
  String get orderErrorSlotClosed;

  /// Commande programmée
  ///
  /// In fr, this message translates to:
  /// **'Prévue {day}, {start}–{end}'**
  String orderScheduled(String day, String start, String end);

  /// Badge fiche
  ///
  /// In fr, this message translates to:
  /// **'Arrivage le {date} · prix bloqué'**
  String productArrivalBadge(String date);

  /// Liste vendeuse
  ///
  /// In fr, this message translates to:
  /// **'Arrive le {date} · précommandes ouvertes'**
  String productArrivalOn(String date);

  /// Bouton vendeuse
  ///
  /// In fr, this message translates to:
  /// **'Indiquer un arrivage'**
  String get productArrivalSet;

  /// Bouton vendeuse
  ///
  /// In fr, this message translates to:
  /// **'Retirer l\'arrivage'**
  String get productArrivalClear;

  /// Aide du calendrier
  ///
  /// In fr, this message translates to:
  /// **'Date d\'arrivée : les clientes précommandent à prix bloqué'**
  String get productArrivalHint;

  /// Commande programmée (vendeuse)
  ///
  /// In fr, this message translates to:
  /// **'À livrer {day}, {start}–{end}'**
  String vendorOrderScheduled(String day, String start, String end);

  /// Titre du panneau
  ///
  /// In fr, this message translates to:
  /// **'Remplacements et fraîcheur'**
  String get adjustTitle;

  /// Proposition
  ///
  /// In fr, this message translates to:
  /// **'{item} manque : la vendeuse propose {proposed}, même prix.'**
  String adjustProposed(String item, String proposed);

  /// Accepté
  ///
  /// In fr, this message translates to:
  /// **'{item} remplacé par {proposed}.'**
  String adjustAccepted(String item, String proposed);

  /// Refusé
  ///
  /// In fr, this message translates to:
  /// **'{item} retiré : {amount} rendus sur ton wallet.'**
  String adjustRefused(String item, String amount);

  /// Fraîcheur
  ///
  /// In fr, this message translates to:
  /// **'{item} pas frais : {amount} rendus sur ton wallet.'**
  String adjustFreshness(String item, String amount);

  /// Bouton
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get adjustAccept;

  /// Bouton
  ///
  /// In fr, this message translates to:
  /// **'Refuser et être remboursée'**
  String get adjustRefuse;

  /// Après crédit
  ///
  /// In fr, this message translates to:
  /// **'{amount} sont déjà sur ton wallet.'**
  String adjustCreditedNow(String amount);

  /// Bouton garantie
  ///
  /// In fr, this message translates to:
  /// **'Un article n\'est pas frais ?'**
  String get freshnessClaim;

  /// Explication
  ///
  /// In fr, this message translates to:
  /// **'Garantie fraîcheur : envoie une photo, tu es remboursée tout de suite sur ton wallet.'**
  String get freshnessHint;

  /// Choix de la ligne
  ///
  /// In fr, this message translates to:
  /// **'Quel article ?'**
  String get freshnessWhich;

  /// Délai dépassé
  ///
  /// In fr, this message translates to:
  /// **'Le délai de la garantie est passé : utilise « Signaler un problème ».'**
  String get freshnessWindowClosed;

  /// Limite
  ///
  /// In fr, this message translates to:
  /// **'Limite du mois atteinte : utilise « Signaler un problème », l\'équipe regarde.'**
  String get freshnessLimitReached;

  /// Déjà rendu
  ///
  /// In fr, this message translates to:
  /// **'Cet article a déjà été remboursé.'**
  String get freshnessAlreadyCredited;

  /// Notification
  ///
  /// In fr, this message translates to:
  /// **'Un remplacement est proposé'**
  String get notifSubstitutionTitle;

  /// Notification
  ///
  /// In fr, this message translates to:
  /// **'{item} manque : la vendeuse propose {proposed}.'**
  String notifSubstitutionBody(String item, String proposed);

  /// Titre vendeuse
  ///
  /// In fr, this message translates to:
  /// **'Un article manque ?'**
  String get vendorSubstituteTitle;

  /// Aide
  ///
  /// In fr, this message translates to:
  /// **'Propose un autre produit avec une photo : même quantité, même prix. La cliente valide.'**
  String get vendorSubstituteHint;

  /// Bouton
  ///
  /// In fr, this message translates to:
  /// **'Remplacer {item}'**
  String vendorSubstitute(String item);

  /// Ligne
  ///
  /// In fr, this message translates to:
  /// **'{item} → {proposed}'**
  String vendorSubstituteLine(String item, String proposed);

  /// Statut
  ///
  /// In fr, this message translates to:
  /// **'En attente de la cliente'**
  String get vendorSubstituteWaiting;

  /// Statut
  ///
  /// In fr, this message translates to:
  /// **'Acceptée'**
  String get vendorSubstituteAccepted;

  /// Statut
  ///
  /// In fr, this message translates to:
  /// **'Remboursée à la cliente'**
  String get vendorSubstituteRefunded;

  /// Réclamation
  ///
  /// In fr, this message translates to:
  /// **'{item} signalé pas frais'**
  String vendorFreshnessClaimed(String item);

  /// Vide
  ///
  /// In fr, this message translates to:
  /// **'Aucun autre produit disponible dans ta boutique.'**
  String get vendorSubstituteNone;

  /// Champ
  ///
  /// In fr, this message translates to:
  /// **'Un mot pour la cliente (facultatif)'**
  String get vendorSubstituteNote;

  /// Micro
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer un vocal'**
  String get chatVoiceRecord;

  /// En cours
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement… (60 s au plus)'**
  String get chatVoiceRecording;

  /// Envoi
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le vocal'**
  String get chatVoiceSend;

  /// Annulation
  ///
  /// In fr, this message translates to:
  /// **'Annuler le vocal'**
  String get chatVoiceCancel;

  /// Lecture
  ///
  /// In fr, this message translates to:
  /// **'Écouter'**
  String get chatVoicePlay;

  /// Arrêt
  ///
  /// In fr, this message translates to:
  /// **'Arrêter'**
  String get chatVoiceStop;

  /// Durée
  ///
  /// In fr, this message translates to:
  /// **'{seconds} s'**
  String chatVoiceDuration(int seconds);

  /// Appel audio
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get callAudio;

  /// Appel vidéo
  ///
  /// In fr, this message translates to:
  /// **'Appel vidéo « Montre-moi »'**
  String get callVideo;

  /// Sonnerie
  ///
  /// In fr, this message translates to:
  /// **'Ça sonne…'**
  String get callRinging;

  /// Entrant
  ///
  /// In fr, this message translates to:
  /// **'Appel entrant'**
  String get callIncoming;

  /// En cours
  ///
  /// In fr, this message translates to:
  /// **'En communication'**
  String get callOngoing;

  /// Refusé
  ///
  /// In fr, this message translates to:
  /// **'Appel refusé'**
  String get callDeclined;

  /// Manqué
  ///
  /// In fr, this message translates to:
  /// **'Appel manqué'**
  String get callMissed;

  /// Terminé
  ///
  /// In fr, this message translates to:
  /// **'Appel terminé'**
  String get callEnded;

  /// Indisponible
  ///
  /// In fr, this message translates to:
  /// **'Appel impossible pour l\'instant.'**
  String get callUnavailable;

  /// Bandeau simulation
  ///
  /// In fr, this message translates to:
  /// **'Appel simulé : la voix et l\'image passeront par le vrai service avant la mise en production.'**
  String get callSimulated;

  /// Décrocher
  ///
  /// In fr, this message translates to:
  /// **'Décrocher'**
  String get callAnswer;

  /// Refuser
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get callDecline;

  /// Raccrocher
  ///
  /// In fr, this message translates to:
  /// **'Raccrocher'**
  String get callHangUp;

  /// Fermer
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get callClose;

  /// Ouvrir l'appel
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get callOpen;

  /// Bandeau entrant
  ///
  /// In fr, this message translates to:
  /// **'{name} t\'appelle'**
  String callIncomingFrom(String name);

  /// Résumé
  ///
  /// In fr, this message translates to:
  /// **'Appel · {minutes, plural, =1{1 min} other{{minutes} min}}'**
  String callSummaryEnded(int minutes);

  /// Menu Moi
  ///
  /// In fr, this message translates to:
  /// **'Créer et partager'**
  String get accountCreator;

  /// Titre
  ///
  /// In fr, this message translates to:
  /// **'Studio créatrice'**
  String get creatorTitle;

  /// Explication
  ///
  /// In fr, this message translates to:
  /// **'Partage tes recettes, tes astuces et tes trouvailles du marché. Tague les produits : on les achète d\'un geste.'**
  String get creatorIntro;

  /// Champ
  ///
  /// In fr, this message translates to:
  /// **'Nom de créatrice'**
  String get creatorName;

  /// Exemple
  ///
  /// In fr, this message translates to:
  /// **'Ex. Awa cuisine'**
  String get creatorNameHint;

  /// Champ
  ///
  /// In fr, this message translates to:
  /// **'Courte présentation (facultatif)'**
  String get creatorBio;

  /// Bouton
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir mon studio'**
  String get creatorBecome;

  /// Erreur
  ///
  /// In fr, this message translates to:
  /// **'Ton nom de créatrice : 2 à 40 caractères.'**
  String get creatorErrorName;

  /// Erreur
  ///
  /// In fr, this message translates to:
  /// **'Ce média ne peut pas être publié : choisis-en un autre.'**
  String get creatorErrorMedia;

  /// Bouton
  ///
  /// In fr, this message translates to:
  /// **'Nouveau post'**
  String get creatorNewPost;

  /// Section
  ///
  /// In fr, this message translates to:
  /// **'Mes posts'**
  String get creatorMyPosts;

  /// Vide
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de post : partage ta première recette !'**
  String get creatorNoPost;

  /// Stats
  ///
  /// In fr, this message translates to:
  /// **'{views, plural, =0{0 vue} =1{1 vue} other{{views} vues}} · {clicks, plural, =0{0 clic} =1{1 clic} other{{clicks} clics}} · {tags, plural, =1{1 produit} other{{tags} produits}}'**
  String creatorPostStats(int views, int clicks, int tags);

  /// Archiver
  ///
  /// In fr, this message translates to:
  /// **'Archiver'**
  String get creatorArchive;

  /// Choix vidéo
  ///
  /// In fr, this message translates to:
  /// **'Vidéo (60 s)'**
  String get creatorPickVideo;

  /// Champ
  ///
  /// In fr, this message translates to:
  /// **'Légende'**
  String get creatorCaption;

  /// Exemple
  ///
  /// In fr, this message translates to:
  /// **'Ex. Ma sauce gombo du dimanche'**
  String get creatorCaptionHint;

  /// Section
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get creatorCategory;

  /// Bouton IA
  ///
  /// In fr, this message translates to:
  /// **'Laisser l\'IA choisir'**
  String get creatorSuggestCategory;

  /// Aide
  ///
  /// In fr, this message translates to:
  /// **'Sans choix, ton post va dans « Autre ».'**
  String get creatorCategoryHint;

  /// Section
  ///
  /// In fr, this message translates to:
  /// **'Produits tagués ({count}/{max})'**
  String creatorTagProducts(int count, int max);

  /// Champ
  ///
  /// In fr, this message translates to:
  /// **'Chercher un produit à taguer'**
  String get creatorSearchProducts;

  /// Bouton
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get creatorPublish;

  /// Bascule
  ///
  /// In fr, this message translates to:
  /// **'Vue en grille'**
  String get feedGrid;

  /// Bascule
  ///
  /// In fr, this message translates to:
  /// **'Plein écran'**
  String get feedFullScreen;

  /// Puce
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get feedAllCategories;

  /// Bouton
  ///
  /// In fr, this message translates to:
  /// **'S\'abonner'**
  String get feedFollow;

  /// Bouton
  ///
  /// In fr, this message translates to:
  /// **'Abonnée'**
  String get feedFollowingOne;

  /// Titre
  ///
  /// In fr, this message translates to:
  /// **'Commentaires'**
  String get feedComments;

  /// Vide
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de commentaire : lance la conversation !'**
  String get feedNoComment;

  /// Champ
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un commentaire'**
  String get feedCommentHint;

  /// Bouton
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon commentaire'**
  String get feedDeleteComment;

  /// Cible de modération
  ///
  /// In fr, this message translates to:
  /// **'Commentaire'**
  String get moderationComment;

  /// Section
  ///
  /// In fr, this message translates to:
  /// **'Ingrédients'**
  String get recipeIngredients;

  /// Bouton IA
  ///
  /// In fr, this message translates to:
  /// **'Repérer avec l\'IA'**
  String get recipeFindIngredients;

  /// Champ
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un ingrédient (tomate, gombo…)'**
  String get recipeAddIngredient;

  /// Bouton du fil
  ///
  /// In fr, this message translates to:
  /// **'Tout pour la recette'**
  String get recipeAllForIt;

  /// Feuille des produits d'une vidéo
  ///
  /// In fr, this message translates to:
  /// **'Dans cette vidéo'**
  String get feedInThisVideo;

  /// No description provided for @feedProductCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 produit} other{{count} produits}}'**
  String feedProductCount(int count);

  /// Rôle sous le nom de l'autrice
  ///
  /// In fr, this message translates to:
  /// **'Créatrice'**
  String get feedCreator;

  /// Ouvre le panier après un ajout
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get feedSeeCart;

  /// No description provided for @recipeAllForTotal.
  ///
  /// In fr, this message translates to:
  /// **'Tout pour la recette · {total}'**
  String recipeAllForTotal(String total);

  /// No description provided for @recipeForPeople.
  ///
  /// In fr, this message translates to:
  /// **'pour {count}'**
  String recipeForPeople(int count);

  /// No description provided for @recipeServings.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Pour 1 personne} other{Pour {count} personnes}}'**
  String recipeServings(int count);

  /// Bouton moins des portions
  ///
  /// In fr, this message translates to:
  /// **'Une personne de moins'**
  String get recipeServingsLess;

  /// Bouton plus des portions
  ///
  /// In fr, this message translates to:
  /// **'Une personne de plus'**
  String get recipeServingsMore;

  /// No description provided for @recipeAddLines.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Ajouter 1 article} other{Ajouter {count} articles}} · {total}'**
  String recipeAddLines(int count, String total);

  /// No description provided for @recipeAddSome.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Ajouter 1 article} other{Ajouter {count} articles}}'**
  String recipeAddSome(int count);

  /// No description provided for @recipeAddedLines.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 article ajouté au panier} other{{count} articles ajoutés au panier}}'**
  String recipeAddedLines(int count);

  /// No description provided for @recipeStores.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 boutique} other{{count} boutiques}} · livraison calculée au panier'**
  String recipeStores(int count);

  /// No description provided for @creatorEarnings.
  ///
  /// In fr, this message translates to:
  /// **'Mes gains'**
  String get creatorEarnings;

  /// No description provided for @creatorEarningsPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get creatorEarningsPending;

  /// No description provided for @creatorEarningsPaid.
  ///
  /// In fr, this message translates to:
  /// **'Versés sur mon wallet'**
  String get creatorEarningsPaid;

  /// No description provided for @creatorEarningsHint.
  ///
  /// In fr, this message translates to:
  /// **'Quand une cliente achète depuis ton contenu, tu touches une commission à la livraison.'**
  String get creatorEarningsHint;

  /// No description provided for @creatorEarningsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Tague des produits ou ajoute les ingrédients : chaque achat livré depuis ton post te rapporte une commission.'**
  String get creatorEarningsEmpty;

  /// No description provided for @creatorCommissionPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente de livraison'**
  String get creatorCommissionPending;

  /// No description provided for @creatorCommissionPaid.
  ///
  /// In fr, this message translates to:
  /// **'Versée'**
  String get creatorCommissionPaid;

  /// No description provided for @creatorCommissionCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée (commande non livrée)'**
  String get creatorCommissionCancelled;

  /// No description provided for @walletKindAffiliate.
  ///
  /// In fr, this message translates to:
  /// **'Commission de créatrice'**
  String get walletKindAffiliate;

  /// No description provided for @affiliateRateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Commission des créatrices'**
  String get affiliateRateTitle;

  /// Taux en pour cent (affichage)
  ///
  /// In fr, this message translates to:
  /// **'{value} %'**
  String affiliatePercent(double value);

  /// No description provided for @affiliateRateHint.
  ///
  /// In fr, this message translates to:
  /// **'Versée sur chaque vente livrée venue du contenu d\'une créatrice. Minimum du pays : {min}.'**
  String affiliateRateHint(String min);

  /// No description provided for @affiliateProductRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux d\'un produit'**
  String get affiliateProductRate;

  /// No description provided for @affiliateLikeStore.
  ///
  /// In fr, this message translates to:
  /// **'Comme la boutique'**
  String get affiliateLikeStore;

  /// No description provided for @paidContent.
  ///
  /// In fr, this message translates to:
  /// **'Contenu rémunéré'**
  String get paidContent;

  /// No description provided for @shareAction.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get shareAction;

  /// No description provided for @shareCopied.
  ///
  /// In fr, this message translates to:
  /// **'Lien copié : colle-le dans ta vidéo TikTok ou un message.'**
  String get shareCopied;

  /// No description provided for @shareFailed.
  ///
  /// In fr, this message translates to:
  /// **'Partage impossible pour le moment.'**
  String get shareFailed;

  /// No description provided for @shareText.
  ///
  /// In fr, this message translates to:
  /// **'{caption}\nTout pour la faire : {link}'**
  String shareText(String caption, String link);

  /// No description provided for @tiktokSeeOriginal.
  ///
  /// In fr, this message translates to:
  /// **'Voir sur TikTok'**
  String get tiktokSeeOriginal;

  /// No description provided for @tiktokSection.
  ///
  /// In fr, this message translates to:
  /// **'TikTok'**
  String get tiktokSection;

  /// No description provided for @tiktokHandle.
  ///
  /// In fr, this message translates to:
  /// **'Mon compte TikTok'**
  String get tiktokHandle;

  /// No description provided for @tiktokHandleHint.
  ///
  /// In fr, this message translates to:
  /// **'@moncompte'**
  String get tiktokHandleHint;

  /// No description provided for @tiktokSaveHandle.
  ///
  /// In fr, this message translates to:
  /// **'Relier mon compte'**
  String get tiktokSaveHandle;

  /// No description provided for @tiktokUnverified.
  ///
  /// In fr, this message translates to:
  /// **'Compte déclaré : la vérification par connexion TikTok arrive bientôt. N\'importe que tes propres vidéos.'**
  String get tiktokUnverified;

  /// No description provided for @tiktokImportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Importer une vidéo TikTok'**
  String get tiktokImportTitle;

  /// No description provided for @tiktokLink.
  ///
  /// In fr, this message translates to:
  /// **'Lien de la vidéo TikTok'**
  String get tiktokLink;

  /// No description provided for @tiktokImport.
  ///
  /// In fr, this message translates to:
  /// **'Importer'**
  String get tiktokImport;

  /// No description provided for @tiktokHandleRequired.
  ///
  /// In fr, this message translates to:
  /// **'Relie d\'abord ton compte TikTok.'**
  String get tiktokHandleRequired;

  /// No description provided for @tiktokNotOwner.
  ///
  /// In fr, this message translates to:
  /// **'Cette vidéo vient d\'un autre compte TikTok que le tien.'**
  String get tiktokNotOwner;

  /// No description provided for @tiktokNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo introuvable ou privée.'**
  String get tiktokNotFound;

  /// No description provided for @tiktokInvalidUrl.
  ///
  /// In fr, this message translates to:
  /// **'Ce lien n\'est pas une vidéo TikTok.'**
  String get tiktokInvalidUrl;

  /// No description provided for @tiktokNoCover.
  ///
  /// In fr, this message translates to:
  /// **'TikTok n\'a pas donné de couverture pour cette vidéo.'**
  String get tiktokNoCover;

  /// No description provided for @tiktokPickCover.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une photo de couverture'**
  String get tiktokPickCover;

  /// No description provided for @appNameDelivery.
  ///
  /// In fr, this message translates to:
  /// **'DYM Livreur'**
  String get appNameDelivery;

  /// No description provided for @deliveryTagline.
  ///
  /// In fr, this message translates to:
  /// **'Tes courses, tes gains, sans dispute.'**
  String get deliveryTagline;

  /// No description provided for @deliveryWelcomeBody.
  ///
  /// In fr, this message translates to:
  /// **'Livre les commandes de ton quartier, à ton rythme.'**
  String get deliveryWelcomeBody;

  /// No description provided for @deliveryPoint1.
  ///
  /// In fr, this message translates to:
  /// **'Accepte les courses près de toi'**
  String get deliveryPoint1;

  /// No description provided for @deliveryPoint2.
  ///
  /// In fr, this message translates to:
  /// **'Adresse et téléphone après acceptation'**
  String get deliveryPoint2;

  /// No description provided for @deliveryPoint3.
  ///
  /// In fr, this message translates to:
  /// **'Un seul compte DYM pour tout'**
  String get deliveryPoint3;

  /// No description provided for @missionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Missions'**
  String get missionsTitle;

  /// No description provided for @myRunsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes courses'**
  String get myRunsTitle;

  /// Section des missions acceptées
  ///
  /// In fr, this message translates to:
  /// **'Course en cours'**
  String get runsActiveTitle;

  /// Onglet du livreur : courses terminées
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get runsHistoryTitle;

  /// Historique vide
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de course terminée.'**
  String get runsHistoryNone;

  /// No description provided for @courierOnline.
  ///
  /// In fr, this message translates to:
  /// **'En ligne'**
  String get courierOnline;

  /// No description provided for @courierOffline.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get courierOffline;

  /// No description provided for @courierOnlineHint.
  ///
  /// In fr, this message translates to:
  /// **'Les courses de tes zones te sont proposées.'**
  String get courierOnlineHint;

  /// No description provided for @courierOfflineHint.
  ///
  /// In fr, this message translates to:
  /// **'Mets-toi en ligne pour recevoir des courses.'**
  String get courierOfflineHint;

  /// No description provided for @missionsNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune course pour le moment'**
  String get missionsNone;

  /// No description provided for @missionsNoneHint.
  ///
  /// In fr, this message translates to:
  /// **'Tu seras prévenu dès qu\'une commande de tes zones attend un livreur.'**
  String get missionsNoneHint;

  /// No description provided for @missionsGoOnline.
  ///
  /// In fr, this message translates to:
  /// **'Tu es hors ligne'**
  String get missionsGoOnline;

  /// No description provided for @missionAccept.
  ///
  /// In fr, this message translates to:
  /// **'Accepter la course'**
  String get missionAccept;

  /// No description provided for @missionTaken.
  ///
  /// In fr, this message translates to:
  /// **'Un autre livreur a déjà pris cette course.'**
  String get missionTaken;

  /// No description provided for @missionTooMany.
  ///
  /// In fr, this message translates to:
  /// **'Termine d\'abord tes courses en cours.'**
  String get missionTooMany;

  /// No description provided for @courierSuspended.
  ///
  /// In fr, this message translates to:
  /// **'Ton compte livreur est suspendu. Contacte l\'équipe DYM.'**
  String get courierSuspended;

  /// No description provided for @courierInvalidPhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone invalide.'**
  String get courierInvalidPhone;

  /// No description provided for @courierInvalidZones.
  ///
  /// In fr, this message translates to:
  /// **'Choisis au moins une zone de ton pays.'**
  String get courierInvalidZones;

  /// No description provided for @courierVehicleFoot.
  ///
  /// In fr, this message translates to:
  /// **'À pied'**
  String get courierVehicleFoot;

  /// No description provided for @courierVehicleBike.
  ///
  /// In fr, this message translates to:
  /// **'Vélo'**
  String get courierVehicleBike;

  /// No description provided for @courierVehicleMoto.
  ///
  /// In fr, this message translates to:
  /// **'Moto'**
  String get courierVehicleMoto;

  /// No description provided for @courierVehicleCar.
  ///
  /// In fr, this message translates to:
  /// **'Voiture'**
  String get courierVehicleCar;

  /// No description provided for @courierBecomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Devenir livreur'**
  String get courierBecomeTitle;

  /// No description provided for @courierBecomeBody.
  ///
  /// In fr, this message translates to:
  /// **'Même compte DYM : ajoute ton téléphone, ton moyen et les zones où tu livres.'**
  String get courierBecomeBody;

  /// No description provided for @courierName.
  ///
  /// In fr, this message translates to:
  /// **'Nom affiché aux clientes'**
  String get courierName;

  /// No description provided for @courierPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get courierPhone;

  /// No description provided for @courierVehicle.
  ///
  /// In fr, this message translates to:
  /// **'Mon moyen'**
  String get courierVehicle;

  /// No description provided for @courierZones.
  ///
  /// In fr, this message translates to:
  /// **'Mes zones'**
  String get courierZones;

  /// No description provided for @courierBecomeAction.
  ///
  /// In fr, this message translates to:
  /// **'Commencer à livrer'**
  String get courierBecomeAction;

  /// No description provided for @missionItems.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 article} other{{count} articles}}'**
  String missionItems(int count);

  /// No description provided for @missionPickup.
  ///
  /// In fr, this message translates to:
  /// **'Récupérer chez'**
  String get missionPickup;

  /// No description provided for @missionFeeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ta course'**
  String get missionFeeLabel;

  /// No description provided for @missionSlot.
  ///
  /// In fr, this message translates to:
  /// **'Créneau : {slot}'**
  String missionSlot(String slot);

  /// No description provided for @missionCashToCollect.
  ///
  /// In fr, this message translates to:
  /// **'À encaisser : {amount} en cash'**
  String missionCashToCollect(String amount);

  /// No description provided for @missionDropoff.
  ///
  /// In fr, this message translates to:
  /// **'Livrer à'**
  String get missionDropoff;

  /// No description provided for @missionPreparing.
  ///
  /// In fr, this message translates to:
  /// **'En préparation'**
  String get missionPreparing;

  /// No description provided for @missionReady.
  ///
  /// In fr, this message translates to:
  /// **'Prête à récupérer'**
  String get missionReady;

  /// No description provided for @missionOnTheWay.
  ///
  /// In fr, this message translates to:
  /// **'En route'**
  String get missionOnTheWay;

  /// No description provided for @missionDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Livrée'**
  String get missionDelivered;

  /// No description provided for @myRunsNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune course en cours'**
  String get myRunsNone;

  /// No description provided for @myRunsNoneHint.
  ///
  /// In fr, this message translates to:
  /// **'Accepte une mission pour la voir ici.'**
  String get myRunsNoneHint;

  /// No description provided for @missionPickedUp.
  ///
  /// In fr, this message translates to:
  /// **'Commande récupérée'**
  String get missionPickedUp;

  /// No description provided for @missionHandedOver.
  ///
  /// In fr, this message translates to:
  /// **'Commande remise'**
  String get missionHandedOver;

  /// No description provided for @missionWaitReady.
  ///
  /// In fr, this message translates to:
  /// **'La boutique prépare la commande.'**
  String get missionWaitReady;

  /// No description provided for @missionRelease.
  ///
  /// In fr, this message translates to:
  /// **'Rendre la course'**
  String get missionRelease;

  /// No description provided for @retryHint.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie ta connexion puis réessaie.'**
  String get retryHint;

  /// No description provided for @missionRun.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 boutique} other{Tournée · {count} boutiques}}'**
  String missionRun(int count);

  /// No description provided for @storageAmbient.
  ///
  /// In fr, this message translates to:
  /// **'Température ambiante'**
  String get storageAmbient;

  /// No description provided for @storageCool.
  ///
  /// In fr, this message translates to:
  /// **'Au frais'**
  String get storageCool;

  /// No description provided for @storageFrozen.
  ///
  /// In fr, this message translates to:
  /// **'Surgelé'**
  String get storageFrozen;

  /// No description provided for @storageFragile.
  ///
  /// In fr, this message translates to:
  /// **'Fragile'**
  String get storageFragile;

  /// No description provided for @handoverTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code de remise'**
  String get handoverTitle;

  /// No description provided for @handoverBody.
  ///
  /// In fr, this message translates to:
  /// **'Demande à la cliente le code à 4 chiffres affiché dans son app.'**
  String get handoverBody;

  /// No description provided for @handoverCode.
  ///
  /// In fr, this message translates to:
  /// **'Code'**
  String get handoverCode;

  /// No description provided for @handoverCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get handoverCancel;

  /// No description provided for @handoverConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Valider la remise'**
  String get handoverConfirm;

  /// No description provided for @handoverWrong.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Code incorrect. Contacte l\'équipe DYM.} =1{Code incorrect : encore 1 essai.} other{Code incorrect : encore {count} essais.}}'**
  String handoverWrong(int count);

  /// No description provided for @handoverLocked.
  ///
  /// In fr, this message translates to:
  /// **'Trop d\'essais : l\'équipe DYM va t\'aider à terminer la remise.'**
  String get handoverLocked;

  /// No description provided for @trackHandoverCode.
  ///
  /// In fr, this message translates to:
  /// **'Code de remise'**
  String get trackHandoverCode;

  /// Livreur dans le suivi de la cliente (spec 068)
  ///
  /// In fr, this message translates to:
  /// **'{name} te livre'**
  String trackCourier(String name);

  /// No description provided for @trackHandoverHint.
  ///
  /// In fr, this message translates to:
  /// **'Donne ce code au livreur quand il te remet la commande.'**
  String get trackHandoverHint;

  /// No description provided for @walletWithdraw.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get walletWithdraw;

  /// No description provided for @walletWithdrawSimulated.
  ///
  /// In fr, this message translates to:
  /// **'Retrait simulé : aucun versement réel tant que le fournisseur n\'est pas branché.'**
  String get walletWithdrawSimulated;

  /// No description provided for @walletKindCourierFee.
  ///
  /// In fr, this message translates to:
  /// **'Frais de livraison'**
  String get walletKindCourierFee;

  /// No description provided for @walletKindCashTopup.
  ///
  /// In fr, this message translates to:
  /// **'Recharge en cash'**
  String get walletKindCashTopup;

  /// No description provided for @walletKindWithdrawal.
  ///
  /// In fr, this message translates to:
  /// **'Retrait'**
  String get walletKindWithdrawal;

  /// No description provided for @walletCashTopup.
  ///
  /// In fr, this message translates to:
  /// **'Recharger en cash auprès d\'un livreur'**
  String get walletCashTopup;

  /// Tuile : recharge en cash auprès d'un livreur
  ///
  /// In fr, this message translates to:
  /// **'Recharge cash'**
  String get walletCashTopupShort;

  /// No description provided for @walletCashTopupHint.
  ///
  /// In fr, this message translates to:
  /// **'Montre ce code au livreur DYM et donne-lui le cash : ton wallet est crédité aussitôt.'**
  String get walletCashTopupHint;

  /// No description provided for @walletCashTopupExpires.
  ///
  /// In fr, this message translates to:
  /// **'Valable jusqu\'à {time}'**
  String walletCashTopupExpires(String time);

  /// No description provided for @earningsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Gains'**
  String get earningsTitle;

  /// No description provided for @earningsToday.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune course aujourd\'hui} =1{1 course aujourd\'hui} other{{count} courses aujourd\'hui}}'**
  String earningsToday(int count);

  /// No description provided for @earningsWallet.
  ///
  /// In fr, this message translates to:
  /// **'Sur mon wallet'**
  String get earningsWallet;

  /// No description provided for @earningsWithdraw.
  ///
  /// In fr, this message translates to:
  /// **'Retirer mes gains'**
  String get earningsWithdraw;

  /// No description provided for @earningsWithdrawDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Le retrait n\'est pas encore ouvert dans ton pays.'**
  String get earningsWithdrawDisabled;

  /// No description provided for @earningsAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get earningsAmount;

  /// No description provided for @earningsCashTitle.
  ///
  /// In fr, this message translates to:
  /// **'Cash à remettre'**
  String get earningsCashTitle;

  /// No description provided for @earningsCashNone.
  ///
  /// In fr, this message translates to:
  /// **'Tu ne dois aucun cash.'**
  String get earningsCashNone;

  /// No description provided for @earningsCashToDym.
  ///
  /// In fr, this message translates to:
  /// **'Équipe DYM'**
  String get earningsCashToDym;

  /// No description provided for @earningsCashToDymHint.
  ///
  /// In fr, this message translates to:
  /// **'Recharges en cash, à remettre à l\'équipe.'**
  String get earningsCashToDymHint;

  /// No description provided for @earningsCashToStoreHint.
  ///
  /// In fr, this message translates to:
  /// **'Prix des articles encaissés, à remettre à la boutique.'**
  String get earningsCashToStoreHint;

  /// No description provided for @cashTopupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Point de recharge'**
  String get cashTopupTitle;

  /// No description provided for @cashTopupHint.
  ///
  /// In fr, this message translates to:
  /// **'La cliente te montre son code de recharge ; tu prends son cash et son wallet est crédité.'**
  String get cashTopupHint;

  /// No description provided for @cashTopupCode.
  ///
  /// In fr, this message translates to:
  /// **'Code de la cliente'**
  String get cashTopupCode;

  /// No description provided for @cashTopupConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Créditer son wallet'**
  String get cashTopupConfirm;

  /// No description provided for @cashTopupInvalidCode.
  ///
  /// In fr, this message translates to:
  /// **'Code inconnu, expiré ou déjà utilisé.'**
  String get cashTopupInvalidCode;

  /// No description provided for @courierCashTitle.
  ///
  /// In fr, this message translates to:
  /// **'Cash des livreurs'**
  String get courierCashTitle;

  /// No description provided for @courierCashHint.
  ///
  /// In fr, this message translates to:
  /// **'Les livreurs DYM encaissent tes commandes payées en cash ; confirme quand ils te remettent l\'argent.'**
  String get courierCashHint;

  /// No description provided for @courierCashNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun cash à recevoir'**
  String get courierCashNone;

  /// No description provided for @courierCashNoneHint.
  ///
  /// In fr, this message translates to:
  /// **'Le cash encaissé par les livreurs pour toi apparaîtra ici.'**
  String get courierCashNoneHint;

  /// No description provided for @courierCashReceived.
  ///
  /// In fr, this message translates to:
  /// **'Reçu'**
  String get courierCashReceived;

  /// No description provided for @tillTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ma caisse'**
  String get tillTitle;

  /// Libellé du total du jour de la caisse
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get tillTodayLabel;

  /// No description provided for @tillOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ma caisse : ventes du jour'**
  String get tillOpen;

  /// No description provided for @tillNewSale.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle vente'**
  String get tillNewSale;

  /// No description provided for @tillToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui : {amount}'**
  String tillToday(String amount);

  /// No description provided for @tillInApp.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{En app} =1{En app · 1 vente} other{En app · {count} ventes}}'**
  String tillInApp(int count);

  /// No description provided for @tillOffApp.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Hors app} =1{Hors app · 1 vente} other{Hors app · {count} ventes}}'**
  String tillOffApp(int count);

  /// No description provided for @tillBalance.
  ///
  /// In fr, this message translates to:
  /// **'Mon solde chez DYM'**
  String get tillBalance;

  /// No description provided for @tillPayout.
  ///
  /// In fr, this message translates to:
  /// **'Verser mon solde'**
  String get tillPayout;

  /// No description provided for @tillPayoutSimulated.
  ///
  /// In fr, this message translates to:
  /// **'Versement simulé : aucun argent ne part tant que le versement réel n\'est pas branché.'**
  String get tillPayoutSimulated;

  /// No description provided for @tillBalanceInsufficient.
  ///
  /// In fr, this message translates to:
  /// **'Ton solde ne suffit pas pour ce versement.'**
  String get tillBalanceInsufficient;

  /// No description provided for @tillSales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes hors app'**
  String get tillSales;

  /// No description provided for @tillNoSale.
  ///
  /// In fr, this message translates to:
  /// **'Aucune vente hors app enregistrée.'**
  String get tillNoSale;

  /// No description provided for @tillVoid.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la vente'**
  String get tillVoid;

  /// No description provided for @tillPayouts.
  ///
  /// In fr, this message translates to:
  /// **'Versements'**
  String get tillPayouts;

  /// No description provided for @tillVoice.
  ///
  /// In fr, this message translates to:
  /// **'Dicter la vente'**
  String get tillVoice;

  /// No description provided for @tillVoiceStop.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai fini'**
  String get tillVoiceStop;

  /// No description provided for @tillVoiceDisabled.
  ///
  /// In fr, this message translates to:
  /// **'La dictée n\'est pas ouverte dans ton pays : tape la vente.'**
  String get tillVoiceDisabled;

  /// No description provided for @tillNothingHeard.
  ///
  /// In fr, this message translates to:
  /// **'Rien entendu : réessaie ou tape la vente.'**
  String get tillNothingHeard;

  /// No description provided for @tillLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ce que tu as vendu'**
  String get tillLabel;

  /// No description provided for @tillLabelHint.
  ///
  /// In fr, this message translates to:
  /// **'3 tas de tomates 1500'**
  String get tillLabelHint;

  /// No description provided for @tillAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get tillAmount;

  /// No description provided for @tillSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la vente'**
  String get tillSave;

  /// No description provided for @tillMethodCash.
  ///
  /// In fr, this message translates to:
  /// **'Cash'**
  String get tillMethodCash;

  /// No description provided for @tillMethodMobileMoney.
  ///
  /// In fr, this message translates to:
  /// **'Mobile money'**
  String get tillMethodMobileMoney;

  /// No description provided for @tillMethodOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get tillMethodOther;

  /// No description provided for @tillLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Ta caisse n\'a pas pu être chargée.'**
  String get tillLoadError;

  /// No description provided for @orderTimeline.
  ///
  /// In fr, this message translates to:
  /// **'Frise de la commande'**
  String get orderTimeline;

  /// No description provided for @actorVendor.
  ///
  /// In fr, this message translates to:
  /// **'Toi'**
  String get actorVendor;

  /// No description provided for @actorClient.
  ///
  /// In fr, this message translates to:
  /// **'La cliente'**
  String get actorClient;

  /// No description provided for @actorCourier.
  ///
  /// In fr, this message translates to:
  /// **'Le livreur'**
  String get actorCourier;

  /// No description provided for @actorAdmin.
  ///
  /// In fr, this message translates to:
  /// **'L\'équipe DYM'**
  String get actorAdmin;

  /// No description provided for @actorSystem.
  ///
  /// In fr, this message translates to:
  /// **'DYM'**
  String get actorSystem;

  /// No description provided for @tillMethodDym.
  ///
  /// In fr, this message translates to:
  /// **'Wallet DYM (QR)'**
  String get tillMethodDym;

  /// No description provided for @qrChargeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Encaisser par QR'**
  String get qrChargeTitle;

  /// No description provided for @qrChargeHint.
  ///
  /// In fr, this message translates to:
  /// **'La cliente scanne le QR (ou tape le code) et paie depuis son wallet DYM.'**
  String get qrChargeHint;

  /// No description provided for @qrChargeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Libellé (facultatif)'**
  String get qrChargeLabel;

  /// No description provided for @qrChargeShow.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le QR'**
  String get qrChargeShow;

  /// Touche retour du clavier
  ///
  /// In fr, this message translates to:
  /// **'Effacer le dernier chiffre'**
  String get tillErase;

  /// No description provided for @qrChargeCode.
  ///
  /// In fr, this message translates to:
  /// **'Code à taper'**
  String get qrChargeCode;

  /// No description provided for @qrChargeWaiting.
  ///
  /// In fr, this message translates to:
  /// **'En attente du paiement… (valable 10 minutes)'**
  String get qrChargeWaiting;

  /// No description provided for @qrChargeCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get qrChargeCancel;

  /// No description provided for @qrChargePaid.
  ///
  /// In fr, this message translates to:
  /// **'Payé !'**
  String get qrChargePaid;

  /// No description provided for @qrChargeExpired.
  ///
  /// In fr, this message translates to:
  /// **'Demande expirée ou annulée.'**
  String get qrChargeExpired;

  /// No description provided for @qrChargeAnother.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel encaissement'**
  String get qrChargeAnother;

  /// No description provided for @walletQrPay.
  ///
  /// In fr, this message translates to:
  /// **'Payer par QR'**
  String get walletQrPay;

  /// No description provided for @qrPayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Payer par QR'**
  String get qrPayTitle;

  /// No description provided for @qrPayHint.
  ///
  /// In fr, this message translates to:
  /// **'Scanne le QR de la vendeuse, ou tape son code à 6 chiffres.'**
  String get qrPayHint;

  /// No description provided for @qrPayCode.
  ///
  /// In fr, this message translates to:
  /// **'Code de la vendeuse'**
  String get qrPayCode;

  /// No description provided for @qrPayContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get qrPayContinue;

  /// No description provided for @qrPayConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Payer {amount}'**
  String qrPayConfirm(String amount);

  /// No description provided for @qrPayDone.
  ///
  /// In fr, this message translates to:
  /// **'{amount} payés à {store}.'**
  String qrPayDone(String amount, String store);

  /// No description provided for @qrPayClose.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get qrPayClose;

  /// No description provided for @qrPayInvalidCode.
  ///
  /// In fr, this message translates to:
  /// **'Code inconnu, expiré ou déjà payé.'**
  String get qrPayInvalidCode;

  /// No description provided for @qrPayOwnStore.
  ///
  /// In fr, this message translates to:
  /// **'C\'est ta propre boutique.'**
  String get qrPayOwnStore;

  /// No description provided for @qrPayCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Cette boutique n\'est pas dans ton pays.'**
  String get qrPayCurrency;

  /// No description provided for @creditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ardoise'**
  String get creditTitle;

  /// Libellé du total de l'ardoise
  ///
  /// In fr, this message translates to:
  /// **'On te doit'**
  String get creditOwedLabel;

  /// No description provided for @creditNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle cliente'**
  String get creditNew;

  /// No description provided for @creditTotal.
  ///
  /// In fr, this message translates to:
  /// **'On te doit {amount}'**
  String creditTotal(String amount);

  /// No description provided for @creditNone.
  ///
  /// In fr, this message translates to:
  /// **'Ardoise vide'**
  String get creditNone;

  /// No description provided for @creditNoneHint.
  ///
  /// In fr, this message translates to:
  /// **'Note ici ce que tes clientes te doivent : tu ne perds plus rien.'**
  String get creditNoneHint;

  /// No description provided for @creditLoadError.
  ///
  /// In fr, this message translates to:
  /// **'L\'ardoise n\'a pas pu être chargée.'**
  String get creditLoadError;

  /// No description provided for @creditLimit.
  ///
  /// In fr, this message translates to:
  /// **'Plafond {amount}'**
  String creditLimit(String amount);

  /// No description provided for @creditOwes.
  ///
  /// In fr, this message translates to:
  /// **'Doit {amount}'**
  String creditOwes(String amount);

  /// No description provided for @creditAddDebt.
  ///
  /// In fr, this message translates to:
  /// **'Elle prend à crédit'**
  String get creditAddDebt;

  /// No description provided for @creditAddPayment.
  ///
  /// In fr, this message translates to:
  /// **'Elle rembourse'**
  String get creditAddPayment;

  /// No description provided for @creditRemind.
  ///
  /// In fr, this message translates to:
  /// **'Relancer sur WhatsApp'**
  String get creditRemind;

  /// No description provided for @creditArchive.
  ///
  /// In fr, this message translates to:
  /// **'Ardoise soldée : la retirer'**
  String get creditArchive;

  /// No description provided for @creditDebt.
  ///
  /// In fr, this message translates to:
  /// **'Crédit'**
  String get creditDebt;

  /// No description provided for @creditPayment.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement'**
  String get creditPayment;

  /// No description provided for @creditName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la cliente'**
  String get creditName;

  /// No description provided for @creditLimitField.
  ///
  /// In fr, this message translates to:
  /// **'Plafond (facultatif)'**
  String get creditLimitField;

  /// No description provided for @creditCreate.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir l\'ardoise'**
  String get creditCreate;

  /// No description provided for @creditNote.
  ///
  /// In fr, this message translates to:
  /// **'Note (facultatif)'**
  String get creditNote;

  /// No description provided for @creditLimitReached.
  ///
  /// In fr, this message translates to:
  /// **'Plafond dépassé : elle doit d\'abord rembourser.'**
  String get creditLimitReached;

  /// No description provided for @creditPaymentTooHigh.
  ///
  /// In fr, this message translates to:
  /// **'Plus que ce qu\'elle doit.'**
  String get creditPaymentTooHigh;

  /// No description provided for @creditAlreadyReminded.
  ///
  /// In fr, this message translates to:
  /// **'Déjà relancée aujourd\'hui.'**
  String get creditAlreadyReminded;

  /// No description provided for @creditReminderText.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {name}, petit rappel de {store} : il reste {amount} sur ton ardoise. Merci !'**
  String creditReminderText(String name, String amount, String store);

  /// No description provided for @studioTitle.
  ///
  /// In fr, this message translates to:
  /// **'Faire connaître ma boutique'**
  String get studioTitle;

  /// No description provided for @studioShareTitle.
  ///
  /// In fr, this message translates to:
  /// **'Partager ma boutique'**
  String get studioShareTitle;

  /// No description provided for @studioShareHint.
  ///
  /// In fr, this message translates to:
  /// **'Envoie le lien de ta boutique sur WhatsApp : tes clientes commandent en un geste.'**
  String get studioShareHint;

  /// No description provided for @studioShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager sur WhatsApp'**
  String get studioShare;

  /// No description provided for @studioShareText.
  ///
  /// In fr, this message translates to:
  /// **'Mes produits frais sont sur DYM, commande ici : {link}'**
  String studioShareText(String link);

  /// No description provided for @eomTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prix de fin de marché'**
  String get eomTitle;

  /// No description provided for @eomHint.
  ///
  /// In fr, this message translates to:
  /// **'Baisse tes prix quelques heures pour écouler le frais du jour. Le prix réduit s\'affiche partout et s\'applique aux commandes.'**
  String get eomHint;

  /// No description provided for @eomPercent.
  ///
  /// In fr, this message translates to:
  /// **'Remise'**
  String get eomPercent;

  /// No description provided for @eomDuration.
  ///
  /// In fr, this message translates to:
  /// **'Pendant'**
  String get eomDuration;

  /// No description provided for @eomHours.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 heure} other{{count} heures}}'**
  String eomHours(int count);

  /// No description provided for @eomStart.
  ///
  /// In fr, this message translates to:
  /// **'Lancer -{percent} %'**
  String eomStart(int percent);

  /// No description provided for @eomActive.
  ///
  /// In fr, this message translates to:
  /// **'-{percent} % sur {count} produits jusqu\'à {time}'**
  String eomActive(int percent, int count, String time);

  /// No description provided for @eomStop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter la fin de marché'**
  String get eomStop;

  /// No description provided for @endOfMarketBadge.
  ///
  /// In fr, this message translates to:
  /// **'Fin de marché -{percent} %'**
  String endOfMarketBadge(int percent);

  /// No description provided for @wholesaleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Achats de gros'**
  String get wholesaleTitle;

  /// No description provided for @wholesaleHint.
  ///
  /// In fr, this message translates to:
  /// **'Achetez à plusieurs chez un grossiste : le prix de gros, même pour de petites quantités. Le règlement se fait avec le grossiste.'**
  String get wholesaleHint;

  /// No description provided for @wholesaleOpen.
  ///
  /// In fr, this message translates to:
  /// **'Offres en cours'**
  String get wholesaleOpen;

  /// No description provided for @wholesaleNoOffer.
  ///
  /// In fr, this message translates to:
  /// **'Aucune offre de gros pour le moment.'**
  String get wholesaleNoOffer;

  /// No description provided for @wholesaleMine.
  ///
  /// In fr, this message translates to:
  /// **'Mes offres de grossiste'**
  String get wholesaleMine;

  /// No description provided for @wholesaleBecome.
  ///
  /// In fr, this message translates to:
  /// **'Je suis grossiste : proposer des offres'**
  String get wholesaleBecome;

  /// No description provided for @wholesaleNewOffer.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle offre'**
  String get wholesaleNewOffer;

  /// No description provided for @wholesaleUnitPrice.
  ///
  /// In fr, this message translates to:
  /// **'{price} l\'unité'**
  String wholesaleUnitPrice(String price);

  /// No description provided for @wholesaleProgress.
  ///
  /// In fr, this message translates to:
  /// **'{committed} sur {min} réservés · {buyers, plural, =0{aucune acheteuse} =1{1 acheteuse} other{{buyers} acheteuses}}'**
  String wholesaleProgress(int committed, int min, int buyers);

  /// No description provided for @wholesaleUntil.
  ///
  /// In fr, this message translates to:
  /// **'Ouverte jusqu\'au {date}'**
  String wholesaleUntil(String date);

  /// No description provided for @wholesaleConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmée'**
  String get wholesaleConfirmed;

  /// No description provided for @wholesaleCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get wholesaleCancelled;

  /// No description provided for @wholesaleClosed.
  ///
  /// In fr, this message translates to:
  /// **'Close'**
  String get wholesaleClosed;

  /// No description provided for @wholesaleMyQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Ma réservation : {quantity}'**
  String wholesaleMyQuantity(int quantity);

  /// No description provided for @wholesaleCommit.
  ///
  /// In fr, this message translates to:
  /// **'Réserver'**
  String get wholesaleCommit;

  /// No description provided for @wholesaleChange.
  ///
  /// In fr, this message translates to:
  /// **'Changer ma réservation'**
  String get wholesaleChange;

  /// No description provided for @wholesaleConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer l\'achat'**
  String get wholesaleConfirm;

  /// No description provided for @wholesaleCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler l\'offre'**
  String get wholesaleCancel;

  /// No description provided for @wholesaleQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité'**
  String get wholesaleQuantity;

  /// No description provided for @wholesaleQuantityHint.
  ///
  /// In fr, this message translates to:
  /// **'0 pour retirer ta réservation.'**
  String get wholesaleQuantityHint;

  /// No description provided for @wholesaleUnitPriceField.
  ///
  /// In fr, this message translates to:
  /// **'Prix de gros à l\'unité'**
  String get wholesaleUnitPriceField;

  /// No description provided for @wholesaleMinQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité minimale'**
  String get wholesaleMinQuantity;

  /// No description provided for @wholesaleDays.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 jour} other{{count} jours}}'**
  String wholesaleDays(int count);

  /// No description provided for @wholesalePublish.
  ///
  /// In fr, this message translates to:
  /// **'Publier l\'offre'**
  String get wholesalePublish;

  /// No description provided for @wholesaleMinimumNotReached.
  ///
  /// In fr, this message translates to:
  /// **'Le minimum n\'est pas encore atteint.'**
  String get wholesaleMinimumNotReached;

  /// No description provided for @haggleAction.
  ///
  /// In fr, this message translates to:
  /// **'Marchander'**
  String get haggleAction;

  /// No description provided for @haggleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Marchander avec la vendeuse'**
  String get haggleTitle;

  /// No description provided for @haggleCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Prix affiché : {price}'**
  String haggleCurrent(String price);

  /// No description provided for @haggleHint.
  ///
  /// In fr, this message translates to:
  /// **'Propose ton prix à l\'unité pour {quantity, plural, =1{1 article} other{{quantity} articles}}. La vendeuse répond tout de suite.'**
  String haggleHint(int quantity);

  /// No description provided for @haggleOfferField.
  ///
  /// In fr, this message translates to:
  /// **'Ton prix à l\'unité'**
  String get haggleOfferField;

  /// No description provided for @haggleSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Proposer'**
  String get haggleSubmit;

  /// No description provided for @haggleAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Marché conclu : {price} l\'unité. C\'est dans ton panier pour 2 heures.'**
  String haggleAccepted(String price);

  /// No description provided for @haggleCountered.
  ///
  /// In fr, this message translates to:
  /// **'La vendeuse propose {price} l\'unité (valable 15 minutes).'**
  String haggleCountered(String price);

  /// No description provided for @haggleAcceptCounter.
  ///
  /// In fr, this message translates to:
  /// **'Accepter ce prix'**
  String get haggleAcceptCounter;

  /// No description provided for @haggleAttemptsLeft.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Plus d\'essai aujourd\'hui} =1{Encore 1 essai aujourd\'hui} other{Encore {count} essais aujourd\'hui}}'**
  String haggleAttemptsLeft(int count);

  /// No description provided for @haggleClose.
  ///
  /// In fr, this message translates to:
  /// **'C\'est bon'**
  String get haggleClose;

  /// No description provided for @haggleCartBadge.
  ///
  /// In fr, this message translates to:
  /// **'Prix marchandé'**
  String get haggleCartBadge;

  /// No description provided for @groupBuyCartBadge.
  ///
  /// In fr, this message translates to:
  /// **'Prix de groupe'**
  String get groupBuyCartBadge;

  /// No description provided for @haggleErrorTooMany.
  ///
  /// In fr, this message translates to:
  /// **'Tu as déjà marchandé 3 fois ce produit aujourd\'hui.'**
  String get haggleErrorTooMany;

  /// No description provided for @haggleErrorNotLower.
  ///
  /// In fr, this message translates to:
  /// **'Propose un prix plus bas que le prix affiché.'**
  String get haggleErrorNotLower;

  /// No description provided for @haggleErrorOff.
  ///
  /// In fr, this message translates to:
  /// **'Cette vendeuse ne marchande pas ce produit.'**
  String get haggleErrorOff;

  /// No description provided for @haggleErrorExpired.
  ///
  /// In fr, this message translates to:
  /// **'Ce prix n\'est plus valable : propose à nouveau.'**
  String get haggleErrorExpired;

  /// No description provided for @hagglingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Marchandage'**
  String get hagglingTitle;

  /// No description provided for @hagglingHint.
  ///
  /// In fr, this message translates to:
  /// **'Fixe jusqu\'où tu acceptes de baisser. DYM répond à ta place, tout de suite ; la cliente ne voit jamais ta limite.'**
  String get hagglingHint;

  /// No description provided for @hagglingStoreLimit.
  ///
  /// In fr, this message translates to:
  /// **'Remise maximale'**
  String get hagglingStoreLimit;

  /// No description provided for @hagglingOff.
  ///
  /// In fr, this message translates to:
  /// **'Pas de marchandage'**
  String get hagglingOff;

  /// No description provided for @hagglingPercent.
  ///
  /// In fr, this message translates to:
  /// **'{percent} %'**
  String hagglingPercent(int percent);

  /// No description provided for @hagglingProducts.
  ///
  /// In fr, this message translates to:
  /// **'Par produit'**
  String get hagglingProducts;

  /// No description provided for @hagglingLikeStore.
  ///
  /// In fr, this message translates to:
  /// **'Comme la boutique'**
  String get hagglingLikeStore;

  /// No description provided for @hagglingNever.
  ///
  /// In fr, this message translates to:
  /// **'Jamais'**
  String get hagglingNever;

  /// No description provided for @hagglingWeek.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun marché conclu cette semaine} =1{1 marché conclu cette semaine} other{{count} marchés conclus cette semaine}}'**
  String hagglingWeek(int count);

  /// No description provided for @hagglingRecent.
  ///
  /// In fr, this message translates to:
  /// **'Derniers marchandages'**
  String get hagglingRecent;

  /// No description provided for @hagglingEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun marchandage pour le moment.'**
  String get hagglingEmpty;

  /// No description provided for @hagglingLine.
  ///
  /// In fr, this message translates to:
  /// **'{quantity} × {offer} proposé → {price}'**
  String hagglingLine(int quantity, String offer, String price);

  /// No description provided for @hagglingStatusAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Conclu'**
  String get hagglingStatusAccepted;

  /// No description provided for @hagglingStatusCountered.
  ///
  /// In fr, this message translates to:
  /// **'Contre-prix'**
  String get hagglingStatusCountered;

  /// No description provided for @hagglingStatusUsed.
  ///
  /// In fr, this message translates to:
  /// **'Commandé'**
  String get hagglingStatusUsed;

  /// No description provided for @hagglingStatusExpired.
  ///
  /// In fr, this message translates to:
  /// **'Expiré'**
  String get hagglingStatusExpired;

  /// No description provided for @accountGroupBuys.
  ///
  /// In fr, this message translates to:
  /// **'Achats groupés'**
  String get accountGroupBuys;

  /// No description provided for @groupBuyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Achats groupés entre voisins'**
  String get groupBuyTitle;

  /// No description provided for @groupBuyHint.
  ///
  /// In fr, this message translates to:
  /// **'Rejoins tes voisins chez une vendeuse : quand le groupe est complet, chacun paie le prix de groupe et la livraison est partagée.'**
  String get groupBuyHint;

  /// No description provided for @groupBuyEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore d\'achat groupé près de chez toi. Ce sont les vendeuses qui les lancent depuis leur boutique : reviens bientôt.'**
  String get groupBuyEmpty;

  /// No description provided for @groupBuyPrice.
  ///
  /// In fr, this message translates to:
  /// **'{group} au lieu de {price}'**
  String groupBuyPrice(String group, String price);

  /// No description provided for @groupBuySharedDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Livraison partagée : {fee}'**
  String groupBuySharedDelivery(String fee);

  /// No description provided for @groupBuyProgress.
  ///
  /// In fr, this message translates to:
  /// **'{committed} sur {min} · {members, plural, =0{personne encore} =1{1 voisin} other{{members} voisins}}'**
  String groupBuyProgress(int committed, int min, int members);

  /// No description provided for @groupBuyUntil.
  ///
  /// In fr, this message translates to:
  /// **'Ouvert jusqu\'au {date}'**
  String groupBuyUntil(String date);

  /// No description provided for @groupBuyUnlocked.
  ///
  /// In fr, this message translates to:
  /// **'Groupe complet : prix de groupe débloqué'**
  String get groupBuyUnlocked;

  /// No description provided for @groupBuyMine.
  ///
  /// In fr, this message translates to:
  /// **'Ma part : {quantity}'**
  String groupBuyMine(int quantity);

  /// No description provided for @groupBuyJoin.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre le groupe'**
  String get groupBuyJoin;

  /// No description provided for @groupBuyChange.
  ///
  /// In fr, this message translates to:
  /// **'Changer ma part'**
  String get groupBuyChange;

  /// No description provided for @groupBuyAddToCart.
  ///
  /// In fr, this message translates to:
  /// **'Mettre ma part au panier'**
  String get groupBuyAddToCart;

  /// No description provided for @groupBuyQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité'**
  String get groupBuyQuantity;

  /// No description provided for @groupBuyQuantityHint.
  ///
  /// In fr, this message translates to:
  /// **'0 pour quitter le groupe.'**
  String get groupBuyQuantityHint;

  /// No description provided for @groupBuyLockedHint.
  ///
  /// In fr, this message translates to:
  /// **'Le groupe est complet : tu peux augmenter ta part, pas la réduire.'**
  String get groupBuyLockedHint;

  /// No description provided for @groupBuyClosed.
  ///
  /// In fr, this message translates to:
  /// **'Cet achat groupé est fermé.'**
  String get groupBuyClosed;

  /// No description provided for @groupBuyLocked.
  ///
  /// In fr, this message translates to:
  /// **'Le groupe est complet : ta part ne peut plus baisser.'**
  String get groupBuyLocked;

  /// No description provided for @groupOfferTitle.
  ///
  /// In fr, this message translates to:
  /// **'Offres groupées'**
  String get groupOfferTitle;

  /// No description provided for @groupOfferHint.
  ///
  /// In fr, this message translates to:
  /// **'Propose un prix de groupe aux clientes de tes quartiers : quand la quantité est atteinte, chacune l\'obtient, avec des frais de livraison réduits si tu veux.'**
  String get groupOfferHint;

  /// No description provided for @groupOfferEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune offre groupée.'**
  String get groupOfferEmpty;

  /// No description provided for @groupOfferNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle offre groupée'**
  String get groupOfferNew;

  /// No description provided for @groupOfferPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix de groupe à l\'unité'**
  String get groupOfferPrice;

  /// No description provided for @groupOfferMin.
  ///
  /// In fr, this message translates to:
  /// **'Quantité totale minimale'**
  String get groupOfferMin;

  /// No description provided for @groupOfferFee.
  ///
  /// In fr, this message translates to:
  /// **'Frais de livraison des membres (facultatif)'**
  String get groupOfferFee;

  /// No description provided for @groupOfferCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler l\'offre'**
  String get groupOfferCancel;

  /// No description provided for @groupOfferCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get groupOfferCancelled;

  /// No description provided for @groupOfferInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie le prix (plus bas que le prix du jour), la quantité (au moins 2) et les frais.'**
  String get groupOfferInvalid;

  /// No description provided for @accountMembership.
  ///
  /// In fr, this message translates to:
  /// **'DYM+'**
  String get accountMembership;

  /// No description provided for @membershipClientTitle.
  ///
  /// In fr, this message translates to:
  /// **'DYM+'**
  String get membershipClientTitle;

  /// No description provided for @membershipVendorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pro et visibilité'**
  String get membershipVendorTitle;

  /// No description provided for @membershipWallet.
  ///
  /// In fr, this message translates to:
  /// **'Payé depuis ton wallet · solde : {balance}'**
  String membershipWallet(String balance);

  /// No description provided for @membershipWalletInsufficient.
  ///
  /// In fr, this message translates to:
  /// **'Solde du wallet insuffisant : recharge-le, puis réessaie.'**
  String get membershipWalletInsufficient;

  /// No description provided for @membershipStoreBalance.
  ///
  /// In fr, this message translates to:
  /// **'Payé depuis le solde de ta boutique ({store}), sinon ton wallet ({wallet})'**
  String membershipStoreBalance(String store, String wallet);

  /// No description provided for @membershipStoreInsufficient.
  ///
  /// In fr, this message translates to:
  /// **'Ni le solde de ta boutique ni ton wallet ne suffisent : vends ou recharge ton wallet, puis réessaie.'**
  String get membershipStoreInsufficient;

  /// No description provided for @membershipNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune formule dans ton pays pour le moment.'**
  String get membershipNone;

  /// No description provided for @membershipDeliveryRefund.
  ///
  /// In fr, this message translates to:
  /// **'Frais de livraison remboursés sur ton wallet à chaque livraison'**
  String get membershipDeliveryRefund;

  /// No description provided for @membershipCashback.
  ///
  /// In fr, this message translates to:
  /// **'{percent} % de cashback en plus sur tes courses'**
  String membershipCashback(num percent);

  /// No description provided for @membershipCommission.
  ///
  /// In fr, this message translates to:
  /// **'Commission DYM réduite de {percent} %'**
  String membershipCommission(num percent);

  /// No description provided for @membershipSponsored.
  ///
  /// In fr, this message translates to:
  /// **'Ta boutique « À la une » de l\'accueil de tes quartiers, signalée comme sponsorisée'**
  String get membershipSponsored;

  /// No description provided for @membershipPrice.
  ///
  /// In fr, this message translates to:
  /// **'{price} pour {days, plural, =1{1 jour} other{{days} jours}}'**
  String membershipPrice(String price, int days);

  /// No description provided for @membershipActiveUntil.
  ///
  /// In fr, this message translates to:
  /// **'Active jusqu\'au {date}'**
  String membershipActiveUntil(String date);

  /// No description provided for @membershipSubscribe.
  ///
  /// In fr, this message translates to:
  /// **'Prendre la formule'**
  String get membershipSubscribe;

  /// No description provided for @membershipExtend.
  ///
  /// In fr, this message translates to:
  /// **'Prolonger'**
  String get membershipExtend;

  /// No description provided for @homeSponsored.
  ///
  /// In fr, this message translates to:
  /// **'À la une'**
  String get homeSponsored;

  /// No description provided for @homeSponsoredLabel.
  ///
  /// In fr, this message translates to:
  /// **'Sponsorisé'**
  String get homeSponsoredLabel;

  /// No description provided for @opsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Opérations'**
  String get opsTitle;

  /// No description provided for @opsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'En direct : commandes, retards, livreurs, cash à recevoir.'**
  String get opsSubtitle;

  /// No description provided for @opsNoCountry.
  ///
  /// In fr, this message translates to:
  /// **'Aucun pays dans ton périmètre.'**
  String get opsNoCountry;

  /// No description provided for @opsLiveTab.
  ///
  /// In fr, this message translates to:
  /// **'En direct'**
  String get opsLiveTab;

  /// No description provided for @opsSettingsTab.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get opsSettingsTab;

  /// No description provided for @opsLast24h.
  ///
  /// In fr, this message translates to:
  /// **'Dernières 24 heures'**
  String get opsLast24h;

  /// No description provided for @opsDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Livré'**
  String get opsDelivered;

  /// No description provided for @opsCouriersOnline.
  ///
  /// In fr, this message translates to:
  /// **'Livreurs en ligne'**
  String get opsCouriersOnline;

  /// No description provided for @opsMissionsWaiting.
  ///
  /// In fr, this message translates to:
  /// **'Livraisons sans livreur'**
  String get opsMissionsWaiting;

  /// No description provided for @opsAlerts.
  ///
  /// In fr, this message translates to:
  /// **'Commandes en retard'**
  String get opsAlerts;

  /// No description provided for @opsNoAlert.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande en retard.'**
  String get opsNoAlert;

  /// No description provided for @opsNoCourier.
  ///
  /// In fr, this message translates to:
  /// **'sans livreur'**
  String get opsNoCourier;

  /// No description provided for @opsMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min'**
  String opsMinutes(int minutes);

  /// No description provided for @opsDelayHours.
  ///
  /// In fr, this message translates to:
  /// **'{hours} h {minutes} min'**
  String opsDelayHours(int hours, int minutes);

  /// No description provided for @opsDelayDays.
  ///
  /// In fr, this message translates to:
  /// **'{days} j {hours} h'**
  String opsDelayDays(int days, int hours);

  /// No description provided for @opsCourierCash.
  ///
  /// In fr, this message translates to:
  /// **'Cash des livreurs à recevoir'**
  String get opsCourierCash;

  /// No description provided for @opsNoCourierCash.
  ///
  /// In fr, this message translates to:
  /// **'Aucun cash à recevoir.'**
  String get opsNoCourierCash;

  /// No description provided for @opsCashReceived.
  ///
  /// In fr, this message translates to:
  /// **'Cash reçu'**
  String get opsCashReceived;

  /// No description provided for @opsThresholds.
  ///
  /// In fr, this message translates to:
  /// **'Seuils d\'alerte (minutes)'**
  String get opsThresholds;

  /// No description provided for @opsThresholdPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente de la vendeuse'**
  String get opsThresholdPending;

  /// No description provided for @opsThresholdReady.
  ///
  /// In fr, this message translates to:
  /// **'Prête, au-delà de la préparation'**
  String get opsThresholdReady;

  /// No description provided for @opsThresholdTransit.
  ///
  /// In fr, this message translates to:
  /// **'En route'**
  String get opsThresholdTransit;

  /// No description provided for @opsFeedWeights.
  ///
  /// In fr, this message translates to:
  /// **'Poids du fil des contenus'**
  String get opsFeedWeights;

  /// No description provided for @opsWeightRecency.
  ///
  /// In fr, this message translates to:
  /// **'Fraîcheur'**
  String get opsWeightRecency;

  /// No description provided for @opsWeightEngagement.
  ///
  /// In fr, this message translates to:
  /// **'Engagement'**
  String get opsWeightEngagement;

  /// No description provided for @opsWeightFollowed.
  ///
  /// In fr, this message translates to:
  /// **'Abonnements'**
  String get opsWeightFollowed;

  /// No description provided for @opsWeightLocal.
  ///
  /// In fr, this message translates to:
  /// **'Proximité'**
  String get opsWeightLocal;

  /// No description provided for @opsWeightAffinity.
  ///
  /// In fr, this message translates to:
  /// **'Affinité'**
  String get opsWeightAffinity;

  /// No description provided for @opsWeightShoppable.
  ///
  /// In fr, this message translates to:
  /// **'Achetable'**
  String get opsWeightShoppable;

  /// No description provided for @opsPlans.
  ///
  /// In fr, this message translates to:
  /// **'Formules (DYM+, Pro, À la une)'**
  String get opsPlans;

  /// No description provided for @opsPeriod.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =1{1 jour} other{{days} jours}}'**
  String opsPeriod(int days);

  /// No description provided for @opsPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get opsPrice;

  /// No description provided for @opsSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get opsSave;

  /// No description provided for @opsScopes.
  ///
  /// In fr, this message translates to:
  /// **'Admins limités à des pays'**
  String get opsScopes;

  /// No description provided for @opsScopesHint.
  ///
  /// In fr, this message translates to:
  /// **'Un admin limité ne pilote que ses pays. Sans limite, il pilote tous les pays.'**
  String get opsScopesHint;

  /// No description provided for @opsScopeEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail de l\'admin'**
  String get opsScopeEmail;

  /// No description provided for @opsScopeAdd.
  ///
  /// In fr, this message translates to:
  /// **'Limiter à {country}'**
  String opsScopeAdd(String country);

  /// No description provided for @opsScopeRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer {country}'**
  String opsScopeRemove(String country);

  /// No description provided for @opsInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Valeur invalide.'**
  String get opsInvalid;

  /// No description provided for @opsOutOfScope.
  ///
  /// In fr, this message translates to:
  /// **'Ce pays n\'est pas dans ton périmètre.'**
  String get opsOutOfScope;

  /// No description provided for @opsNothingOwed.
  ///
  /// In fr, this message translates to:
  /// **'Ce livreur ne doit plus rien.'**
  String get opsNothingOwed;

  /// No description provided for @opsNotAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Cette adresse n\'est pas celle d\'un admin.'**
  String get opsNotAdmin;

  /// No description provided for @adminSupportDraft.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon IA'**
  String get adminSupportDraft;

  /// No description provided for @moderationAi.
  ///
  /// In fr, this message translates to:
  /// **'Avis de l\'IA'**
  String get moderationAi;

  /// No description provided for @moderationAiRemove.
  ///
  /// In fr, this message translates to:
  /// **'à retirer'**
  String get moderationAiRemove;

  /// No description provided for @moderationAiKeep.
  ///
  /// In fr, this message translates to:
  /// **'à garder'**
  String get moderationAiKeep;

  /// No description provided for @moderationAiUnsure.
  ///
  /// In fr, this message translates to:
  /// **'incertain'**
  String get moderationAiUnsure;

  /// No description provided for @opsFraud.
  ///
  /// In fr, this message translates to:
  /// **'Signaux de fraude'**
  String get opsFraud;

  /// No description provided for @opsNoFraud.
  ///
  /// In fr, this message translates to:
  /// **'Aucun signal ouvert.'**
  String get opsNoFraud;

  /// No description provided for @opsFraudDismiss.
  ///
  /// In fr, this message translates to:
  /// **'Écarter'**
  String get opsFraudDismiss;

  /// No description provided for @opsFraudConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get opsFraudConfirm;

  /// No description provided for @fraudClientCancelBurst.
  ///
  /// In fr, this message translates to:
  /// **'Annulations répétées (cliente)'**
  String get fraudClientCancelBurst;

  /// No description provided for @fraudStoreRefusalBurst.
  ///
  /// In fr, this message translates to:
  /// **'Refus répétés (boutique)'**
  String get fraudStoreRefusalBurst;

  /// No description provided for @fraudSharedDevice.
  ///
  /// In fr, this message translates to:
  /// **'Appareil partagé par plusieurs comptes'**
  String get fraudSharedDevice;

  /// No description provided for @fraudHandoverFailures.
  ///
  /// In fr, this message translates to:
  /// **'Codes de remise faux (livreur)'**
  String get fraudHandoverFailures;

  /// No description provided for @fraudHaggleBurst.
  ///
  /// In fr, this message translates to:
  /// **'Marchandage en rafale sans achat'**
  String get fraudHaggleBurst;

  /// Séparateur de jour dans une conversation
  ///
  /// In fr, this message translates to:
  /// **'aujourd\'hui'**
  String get chatToday;

  /// Réponse rapide de la cliente
  ///
  /// In fr, this message translates to:
  /// **'C\'est disponible ?'**
  String get chatQuickIsAvailable;

  /// Réponse rapide de la cliente
  ///
  /// In fr, this message translates to:
  /// **'Quel est le prix ?'**
  String get chatQuickPrice;

  /// Réponse rapide de la cliente
  ///
  /// In fr, this message translates to:
  /// **'Vous livrez aujourd\'hui ?'**
  String get chatQuickDeliveryToday;

  /// Réponse rapide
  ///
  /// In fr, this message translates to:
  /// **'Merci !'**
  String get chatQuickThanks;

  /// Réponse rapide de la vendeuse
  ///
  /// In fr, this message translates to:
  /// **'Oui, c\'est disponible.'**
  String get chatQuickYesAvailable;

  /// Réponse rapide de la vendeuse
  ///
  /// In fr, this message translates to:
  /// **'Désolée, ce n\'est plus disponible.'**
  String get chatQuickSoldOut;

  /// Réponse rapide de la vendeuse
  ///
  /// In fr, this message translates to:
  /// **'Je prépare votre commande.'**
  String get chatQuickPreparing;

  /// Réponse rapide de la vendeuse
  ///
  /// In fr, this message translates to:
  /// **'Merci pour votre commande !'**
  String get chatQuickThanksOrder;

  /// Message en cours d'envoi
  ///
  /// In fr, this message translates to:
  /// **'Envoi…'**
  String get chatSending;

  /// Message en échec
  ///
  /// In fr, this message translates to:
  /// **'Non envoyé'**
  String get chatNotSent;

  /// Message reçu par le serveur
  ///
  /// In fr, this message translates to:
  /// **'Envoyé'**
  String get chatSent;

  /// Message ouvert par l'autre personne
  ///
  /// In fr, this message translates to:
  /// **'Vu'**
  String get chatSeen;

  /// Abandonner un message non envoyé
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get chatDiscard;

  /// Bandeau de la commande en cours dans une conversation
  ///
  /// In fr, this message translates to:
  /// **'Commande en cours'**
  String get chatActiveOrder;

  /// Ouvrir la commande depuis la conversation
  ///
  /// In fr, this message translates to:
  /// **'Voir la commande'**
  String get chatSeeOrder;

  /// Ouvrir la boutique depuis la conversation
  ///
  /// In fr, this message translates to:
  /// **'Voir la boutique'**
  String get chatSeeStore;

  /// Bouton joindre (photo, produit)
  ///
  /// In fr, this message translates to:
  /// **'Joindre'**
  String get chatAttach;

  /// Recherche dans les conversations
  ///
  /// In fr, this message translates to:
  /// **'Chercher une conversation'**
  String get chatSearchConversations;

  /// Aperçu de mon dernier message
  ///
  /// In fr, this message translates to:
  /// **'Toi : {text}'**
  String chatYou(String text);

  /// Aperçu d'un vocal
  ///
  /// In fr, this message translates to:
  /// **'Message vocal'**
  String get chatVoicePreview;

  /// Aperçu d'un appel
  ///
  /// In fr, this message translates to:
  /// **'Appel'**
  String get chatCallPreview;

  /// Conversation vide côté cliente
  ///
  /// In fr, this message translates to:
  /// **'Pose ta question à {name} : disponibilité, prix, livraison.'**
  String chatEmptyThreadStore(String name);

  /// Conversation vide côté vendeuse
  ///
  /// In fr, this message translates to:
  /// **'{name} t\'a ouvert une conversation. Réponds-lui ici.'**
  String chatEmptyThreadClient(String name);

  /// Envoi groupé de produits
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{Envoyer 1 produit} other{Envoyer {n} produits}}'**
  String chatShareSelected(int n);

  /// Recherche des produits de la boutique (cliente)
  ///
  /// In fr, this message translates to:
  /// **'Chercher dans la boutique'**
  String get chatSearchStoreProducts;

  /// Réglage : pas de messages ni d'offres la nuit
  ///
  /// In fr, this message translates to:
  /// **'Nuit calme'**
  String get prefQuietNightTitle;

  /// Explication de la nuit calme
  ///
  /// In fr, this message translates to:
  /// **'De 22 h à 7 h, pas de messages ni d\'offres sur le téléphone. Les commandes et les paiements passent toujours.'**
  String get prefQuietNightBody;

  /// Canal Android des commandes
  ///
  /// In fr, this message translates to:
  /// **'Commandes et paiements'**
  String get pushChannelOrders;

  /// Canal Android des messages
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get pushChannelMessages;

  /// Canal Android des courses du livreur
  ///
  /// In fr, this message translates to:
  /// **'Courses à livrer'**
  String get pushChannelMissions;

  /// Canal Android du reste
  ///
  /// In fr, this message translates to:
  /// **'Infos et offres'**
  String get pushChannelGeneral;

  /// Carte du tableau de bord admin : messages et notifications
  ///
  /// In fr, this message translates to:
  /// **'Échanges'**
  String get adminExchangesTitle;

  /// Statistique admin
  ///
  /// In fr, this message translates to:
  /// **'Messages envoyés'**
  String get adminMessagesSent;

  /// Statistique admin
  ///
  /// In fr, this message translates to:
  /// **'Sur commande'**
  String get adminMessagesWithOrder;

  /// Statistique admin
  ///
  /// In fr, this message translates to:
  /// **'Conversations actives'**
  String get adminConversationsActive;

  /// Statistique admin
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get adminPushSent;

  /// Statistique admin
  ///
  /// In fr, this message translates to:
  /// **'Retenues'**
  String get adminPushSkipped;

  /// Statistique admin
  ///
  /// In fr, this message translates to:
  /// **'Échecs d\'envoi'**
  String get adminPushFailed;

  /// Statistique admin
  ///
  /// In fr, this message translates to:
  /// **'Nuit calme activée'**
  String get adminQuietNightUsers;

  /// Statistique admin
  ///
  /// In fr, this message translates to:
  /// **'Boutiques actives par type'**
  String get adminStoresByOrigin;

  /// Pilotage : chiffre
  ///
  /// In fr, this message translates to:
  /// **'Ventes encaissées'**
  String get adminKpiSales;

  /// Pilotage : chiffre
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get adminKpiOrders;

  /// Pilotage : chiffre
  ///
  /// In fr, this message translates to:
  /// **'Panier moyen'**
  String get adminKpiBasket;

  /// Pilotage : chiffre
  ///
  /// In fr, this message translates to:
  /// **'Livraisons réussies'**
  String get adminKpiDeliveries;

  /// Pilotage : chiffre
  ///
  /// In fr, this message translates to:
  /// **'Paiements réussis'**
  String get adminKpiPayments;

  /// Pilotage : chiffre
  ///
  /// In fr, this message translates to:
  /// **'Nouvelles inscriptions'**
  String get adminKpiSignups;

  /// Pilotage : comparaison
  ///
  /// In fr, this message translates to:
  /// **'vs hier à la même heure'**
  String get adminVsDay;

  /// Pilotage : comparaison
  ///
  /// In fr, this message translates to:
  /// **'vs semaine dernière'**
  String get adminVsWeek;

  /// Pilotage : comparaison
  ///
  /// In fr, this message translates to:
  /// **'vs mois dernier'**
  String get adminVsMonth;

  /// Pilotage : rien sur la période précédente
  ///
  /// In fr, this message translates to:
  /// **'nouveau'**
  String get adminDeltaNew;

  /// Pilotage : titre de la courbe
  ///
  /// In fr, this message translates to:
  /// **'Évolution'**
  String get adminTrendTitle;

  /// Pilotage : série
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get adminTrendOrders;

  /// Pilotage : série
  ///
  /// In fr, this message translates to:
  /// **'Ventes'**
  String get adminTrendSales;

  /// Pilotage : série
  ///
  /// In fr, this message translates to:
  /// **'Livrées'**
  String get adminTrendDelivered;

  /// Pilotage : entonnoir
  ///
  /// In fr, this message translates to:
  /// **'Parcours d\'achat'**
  String get adminFunnelTitle;

  /// Pilotage : entonnoir
  ///
  /// In fr, this message translates to:
  /// **'Clientes actives'**
  String get adminFunnelActive;

  /// Pilotage : entonnoir
  ///
  /// In fr, this message translates to:
  /// **'Ont vu un produit'**
  String get adminFunnelViewed;

  /// Pilotage : entonnoir
  ///
  /// In fr, this message translates to:
  /// **'Ont rempli un panier'**
  String get adminFunnelAdded;

  /// Pilotage : entonnoir
  ///
  /// In fr, this message translates to:
  /// **'Ont commandé'**
  String get adminFunnelOrdered;

  /// Pilotage : entonnoir
  ///
  /// In fr, this message translates to:
  /// **'Ont été livrées'**
  String get adminFunnelDelivered;

  /// Pilotage : aide de l'entonnoir
  ///
  /// In fr, this message translates to:
  /// **'Personnes distinctes à chaque étape ; le pourcentage est le passage depuis l\'étape précédente.'**
  String get adminFunnelHelp;

  /// Pilotage : alertes
  ///
  /// In fr, this message translates to:
  /// **'À traiter'**
  String get adminTodoTitle;

  /// Pilotage : aucune alerte
  ///
  /// In fr, this message translates to:
  /// **'Rien à traiter pour l\'instant.'**
  String get adminTodoNone;

  /// Pilotage : anneau
  ///
  /// In fr, this message translates to:
  /// **'Issue des commandes'**
  String get adminOutcomesTitle;

  /// Pilotage : issue
  ///
  /// In fr, this message translates to:
  /// **'Livrées'**
  String get adminOutcomeDelivered;

  /// Pilotage : issue
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get adminOutcomeInProgress;

  /// Pilotage : issue
  ///
  /// In fr, this message translates to:
  /// **'Refusées'**
  String get adminOutcomeRefused;

  /// Pilotage : issue
  ///
  /// In fr, this message translates to:
  /// **'Annulées'**
  String get adminOutcomeCancelled;

  /// Pilotage : centre de l'anneau
  ///
  /// In fr, this message translates to:
  /// **'commandes'**
  String get adminOutcomesCenter;

  /// Pilotage : centre de l'anneau
  ///
  /// In fr, this message translates to:
  /// **'boutiques'**
  String get adminStoresCenter;

  /// Pilotage : lien
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get adminSeeAll;

  /// Pilotage : colonne
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get adminColOrders;

  /// Pilotage : colonne
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get adminColRating;

  /// Pilotage : livreurs
  ///
  /// In fr, this message translates to:
  /// **'En ligne'**
  String get adminStatOnline;

  /// Pilotage : livreurs
  ///
  /// In fr, this message translates to:
  /// **'Sans livreur'**
  String get adminStatWaiting;

  /// Pilotage : livreurs
  ///
  /// In fr, this message translates to:
  /// **'Prise médiane'**
  String get adminStatMedian;

  /// Pilotage : échanges
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get adminStatMessages;

  /// Pilotage : échanges
  ///
  /// In fr, this message translates to:
  /// **'Conversations'**
  String get adminStatConversations;

  /// Pilotage : notifications
  ///
  /// In fr, this message translates to:
  /// **'Envoyées'**
  String get adminPushLegendSent;

  /// Pilotage : notifications
  ///
  /// In fr, this message translates to:
  /// **'Retenues'**
  String get adminPushLegendHeld;

  /// Pilotage : notifications
  ///
  /// In fr, this message translates to:
  /// **'En échec'**
  String get adminPushLegendFailed;

  /// Pilotage : classement
  ///
  /// In fr, this message translates to:
  /// **'Produits les plus vendus'**
  String get adminTopProducts;

  /// Pilotage : utilisatrices
  ///
  /// In fr, this message translates to:
  /// **'Actives sur 7 jours'**
  String get adminActiveUsersShort;

  /// Pilotage : écart d'un taux en points
  ///
  /// In fr, this message translates to:
  /// **'{n} pt'**
  String adminPoints(int n);

  /// Suivi : phase
  ///
  /// In fr, this message translates to:
  /// **'En attente de la boutique'**
  String get trackPhaseWaiting;

  /// Suivi : explication
  ///
  /// In fr, this message translates to:
  /// **'{store} va confirmer ta commande.'**
  String trackPhaseWaitingHint(String store);

  /// Suivi : phase
  ///
  /// In fr, this message translates to:
  /// **'En préparation'**
  String get trackPhasePreparing;

  /// Suivi : explication
  ///
  /// In fr, this message translates to:
  /// **'{store} prépare ta commande.'**
  String trackPhasePreparingHint(String store);

  /// Suivi : phase
  ///
  /// In fr, this message translates to:
  /// **'Prête'**
  String get trackPhaseReady;

  /// Suivi : explication (livraison)
  ///
  /// In fr, this message translates to:
  /// **'Un livreur va la récupérer.'**
  String get trackPhaseReadyHint;

  /// Suivi : explication (retrait)
  ///
  /// In fr, this message translates to:
  /// **'Passe la récupérer chez {store}.'**
  String trackPhaseReadyPickupHint(String store);

  /// Suivi : phase
  ///
  /// In fr, this message translates to:
  /// **'En route'**
  String get trackPhaseOnTheWay;

  /// Suivi : explication
  ///
  /// In fr, this message translates to:
  /// **'Ta commande arrive, garde ton téléphone près de toi.'**
  String get trackPhaseOnTheWayHint;

  /// Suivi : phase
  ///
  /// In fr, this message translates to:
  /// **'Livrée'**
  String get trackPhaseDelivered;

  /// Suivi : explication
  ///
  /// In fr, this message translates to:
  /// **'Bon appétit ! Dis-nous si tout va bien.'**
  String get trackPhaseDeliveredHint;

  /// Suivi : phase (retrait)
  ///
  /// In fr, this message translates to:
  /// **'Récupérée'**
  String get trackPhaseCollected;

  /// Suivi : temps restant
  ///
  /// In fr, this message translates to:
  /// **'dans {minutes} min'**
  String trackInMinutes(int minutes);

  /// Suivi : première étape
  ///
  /// In fr, this message translates to:
  /// **'Envoyée'**
  String get trackSent;

  /// Suivi : appeler le livreur
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get trackCallCourier;

  /// Suivi : détail de la commande
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif'**
  String get trackSummary;

  /// Suivi : pas de frais de livraison
  ///
  /// In fr, this message translates to:
  /// **'Retrait en boutique'**
  String get trackPickupFee;

  /// Suivi : montant nul
  ///
  /// In fr, this message translates to:
  /// **'Gratuit'**
  String get trackFree;

  /// Suivi : mode de paiement
  ///
  /// In fr, this message translates to:
  /// **'Payée · {method}'**
  String trackPaidWith(String method);

  /// Suivi : mode de paiement (à régler)
  ///
  /// In fr, this message translates to:
  /// **'Paiement · {method}'**
  String trackPayWith(String method);

  /// Suivi : date de la commande
  ///
  /// In fr, this message translates to:
  /// **'Commandée le {date} à {time}'**
  String trackOrderedOn(String date, String time);

  /// Alerte plein écran d'une nouvelle commande
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle commande !'**
  String get vendorAlertTitle;

  /// Alerte : ouvrir la commande
  ///
  /// In fr, this message translates to:
  /// **'Voir la commande'**
  String get vendorAlertOpen;

  /// Alerte : fermer
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get vendorAlertLater;

  /// Alerte : autres commandes en attente
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 autre commande attend} other{{count} autres commandes attendent}}'**
  String vendorAlertMore(int count);

  /// Heure limite de réponse
  ///
  /// In fr, this message translates to:
  /// **'Réponds avant {time}'**
  String vendorRespondBefore(String time);

  /// Temps restant pour répondre
  ///
  /// In fr, this message translates to:
  /// **'{minutes, plural, =0{délai dépassé} =1{1 min restante} other{{minutes} min restantes}}'**
  String vendorMinutesLeft(int minutes);

  /// Explication du refus automatique
  ///
  /// In fr, this message translates to:
  /// **'Sans réponse, la commande sera refusée à {time}.'**
  String vendorAutoRefuseAt(String time);

  /// Accueil vendeuse : commandes en attente
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 commande attend ta réponse} other{{count} commandes attendent ta réponse}}'**
  String vendorUrgentTitle(int count);

  /// Accueil vendeuse : ouvrir les commandes
  ///
  /// In fr, this message translates to:
  /// **'Répondre'**
  String get vendorUrgentAction;

  /// Accueil vendeuse : comparaison
  ///
  /// In fr, this message translates to:
  /// **'vs hier à la même heure'**
  String get vendorVsDay;

  /// Accueil vendeuse : comparaison
  ///
  /// In fr, this message translates to:
  /// **'vs semaine dernière'**
  String get vendorVsWeek;

  /// Accueil vendeuse : comparaison
  ///
  /// In fr, this message translates to:
  /// **'vs mois dernier'**
  String get vendorVsMonth;

  /// Catalogue : interrupteur coupé
  ///
  /// In fr, this message translates to:
  /// **'Rupture'**
  String get productOutOfStockShort;

  /// Accueil vendeuse : raccourci de publication
  ///
  /// In fr, this message translates to:
  /// **'Publier un statut'**
  String get vendorPublishStatus;

  /// Livreur : appeler la boutique ou la cliente
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get missionCall;

  /// Livreur : ouvrir l'itinéraire dans l'app de cartes
  ///
  /// In fr, this message translates to:
  /// **'Itinéraire'**
  String get missionRoute;

  /// Recherche : résultats trouvés malgré une faute
  ///
  /// In fr, this message translates to:
  /// **'Résultats proches de « {query} »'**
  String searchFuzzy(String query);

  /// Notification : rappel de panier
  ///
  /// In fr, this message translates to:
  /// **'Ton panier t\'attend'**
  String get notifCartReminderTitle;

  /// Notification : rappel de panier
  ///
  /// In fr, this message translates to:
  /// **'{summary} : finalise ta commande en un geste.'**
  String notifCartReminderBody(String summary);

  /// Import en masse : titre
  ///
  /// In fr, this message translates to:
  /// **'Importer des produits'**
  String get importTitle;

  /// Catalogue : ouvrir l'import en masse
  ///
  /// In fr, this message translates to:
  /// **'Importer'**
  String get importAction;

  /// Import en masse : explication
  ///
  /// In fr, this message translates to:
  /// **'Colle tes lignes depuis un tableur : une ligne par produit, dans l\'ordre nom, prix, unité, rayon, stock. Les produits arrivent en brouillon : ajoute les photos, puis publie.'**
  String get importHelp;

  /// Import en masse : exemple
  ///
  /// In fr, this message translates to:
  /// **'Tomates ; 500 ; tas ; Légumes ; 40\nHuile rouge ; 1 200 ; ; Huiles et condiments ;'**
  String get importExample;

  /// Import en masse : champ
  ///
  /// In fr, this message translates to:
  /// **'Tes lignes'**
  String get importPasteLabel;

  /// Import en masse : aperçu
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get importCheck;

  /// Import en masse : résumé
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune ligne prête} =1{1 ligne prête} other{{count} lignes prêtes}} · {errors, plural, =0{aucune erreur} =1{1 erreur} other{{errors} erreurs}}'**
  String importSummary(int count, int errors);

  /// Import en masse : erreur d'une ligne
  ///
  /// In fr, this message translates to:
  /// **'Ligne {line} : {reason}'**
  String importLineError(int line, String reason);

  /// Import : raison
  ///
  /// In fr, this message translates to:
  /// **'nom manquant ou trop long'**
  String get importNameInvalid;

  /// Import : raison
  ///
  /// In fr, this message translates to:
  /// **'prix illisible'**
  String get importPriceInvalid;

  /// Import : raison
  ///
  /// In fr, this message translates to:
  /// **'rayon inconnu'**
  String get importCategoryUnknown;

  /// Import : raison
  ///
  /// In fr, this message translates to:
  /// **'unité inconnue'**
  String get importUnitUnknown;

  /// Import : raison
  ///
  /// In fr, this message translates to:
  /// **'stock illisible'**
  String get importStockInvalid;

  /// Import en masse : bouton
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Importer 1 produit} other{Importer {count} produits}}'**
  String importRun(int count);

  /// Import en masse : fin
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 brouillon créé} other{{count} brouillons créés}}'**
  String importDone(int count);

  /// Import en masse : suite
  ///
  /// In fr, this message translates to:
  /// **'Ajoute les photos, puis publie depuis le catalogue.'**
  String get importDoneHint;

  /// Import en masse : retour
  ///
  /// In fr, this message translates to:
  /// **'Voir le catalogue'**
  String get importBackToCatalog;

  /// Écran d'appel : bascule du micro (ouvert).
  ///
  /// In fr, this message translates to:
  /// **'Micro ouvert'**
  String get callMicrophoneOn;

  /// Écran d'appel : bascule du micro (coupé).
  ///
  /// In fr, this message translates to:
  /// **'Micro coupé'**
  String get callMicrophoneOff;

  /// Écran d'appel : son sur le haut-parleur.
  ///
  /// In fr, this message translates to:
  /// **'Haut-parleur'**
  String get callSpeakerOn;

  /// Écran d'appel : son dans l'écouteur du téléphone.
  ///
  /// In fr, this message translates to:
  /// **'Écouteur'**
  String get callSpeakerOff;

  /// Écran d'appel : le média (LiveKit) n'a pas pu se connecter.
  ///
  /// In fr, this message translates to:
  /// **'Son indisponible : vérifie ta connexion, puis rappelle.'**
  String get callMediaFailed;

  /// Admin : libellé du choix du rôle d'un admin.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get adminRoleLabel;

  /// Rôle admin : tous les droits, gère les admins.
  ///
  /// In fr, this message translates to:
  /// **'Super-admin'**
  String get adminRoleSuperAdmin;

  /// Rôle admin : commandes, litiges, boutiques, support.
  ///
  /// In fr, this message translates to:
  /// **'Opérations'**
  String get adminRoleOperations;

  /// Rôle admin : demandes, litiges, lecture des commandes.
  ///
  /// In fr, this message translates to:
  /// **'Support'**
  String get adminRoleSupport;

  /// Rôle admin : paiements, remboursements, risques.
  ///
  /// In fr, this message translates to:
  /// **'Finance'**
  String get adminRoleFinance;

  /// Rôle admin : catalogue, modération, recherche.
  ///
  /// In fr, this message translates to:
  /// **'Contenu'**
  String get adminRoleContent;

  /// Rôle admin : tout lire, ne rien modifier.
  ///
  /// In fr, this message translates to:
  /// **'Analyste'**
  String get adminRoleAnalyst;

  /// Admin, réglages : le rôle n'ouvre aucune section.
  ///
  /// In fr, this message translates to:
  /// **'Aucun réglage n\'est ouvert à ton rôle.'**
  String get adminSettingsNoneForRole;

  /// Admin, réglages : onglet des clés MCP.
  ///
  /// In fr, this message translates to:
  /// **'MCP'**
  String get adminTabMcp;

  /// Admin, clés MCP : explication.
  ///
  /// In fr, this message translates to:
  /// **'Une clé MCP permet à un assistant (Claude, par exemple) de piloter l\'admin et d\'interroger les analytics avec tes droits. Chaque action est journalisée.'**
  String get adminMcpHelp;

  /// Admin, clés MCP : champ du nom (ex. Claude du bureau).
  ///
  /// In fr, this message translates to:
  /// **'Nom de la clé'**
  String get adminMcpName;

  /// Admin, clés MCP : bouton.
  ///
  /// In fr, this message translates to:
  /// **'Créer une clé'**
  String get adminMcpCreate;

  /// Admin, clés MCP : clé tout juste créée.
  ///
  /// In fr, this message translates to:
  /// **'Copie ta clé maintenant : elle ne sera plus jamais montrée.'**
  String get adminMcpNewKeyTitle;

  /// Admin, clés MCP : libellé de la clé.
  ///
  /// In fr, this message translates to:
  /// **'Clé'**
  String get adminMcpKeyLabel;

  /// Admin, clés MCP : adresse à donner à l'assistant.
  ///
  /// In fr, this message translates to:
  /// **'Adresse du serveur MCP'**
  String get adminMcpEndpoint;

  /// Admin, clés MCP : copier une valeur.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get adminMcpCopy;

  /// Admin, clés MCP : confirmation de copie.
  ///
  /// In fr, this message translates to:
  /// **'Copié'**
  String get adminMcpCopied;

  /// Admin, clés MCP : fermer l'encadré de la nouvelle clé.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai copié la clé'**
  String get adminMcpDone;

  /// Admin, clés MCP : révoquer une clé.
  ///
  /// In fr, this message translates to:
  /// **'Révoquer'**
  String get adminMcpRevoke;

  /// Admin, clés MCP : clé révoquée.
  ///
  /// In fr, this message translates to:
  /// **'Révoquée'**
  String get adminMcpRevoked;

  /// Admin, clés MCP : date de dernière utilisation.
  ///
  /// In fr, this message translates to:
  /// **'Dernière utilisation : {date}'**
  String adminMcpLastUsed(String date);

  /// Admin, clés MCP : clé jamais utilisée.
  ///
  /// In fr, this message translates to:
  /// **'Jamais utilisée'**
  String get adminMcpNeverUsed;

  /// Vendeuse : écran et ligne de l'équipe de la boutique.
  ///
  /// In fr, this message translates to:
  /// **'Équipe'**
  String get staffTitle;

  /// Vendeuse, équipe : explication.
  ///
  /// In fr, this message translates to:
  /// **'Invite les personnes qui t\'aident. Chacune a son compte et ne voit que son travail ; l\'argent, les réglages et l\'équipe restent à toi.'**
  String get staffHelp;

  /// Vendeuse, équipe : choix du rôle.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get staffRoleLabel;

  /// Rôle de boutique : propriétaire.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get staffRoleOwner;

  /// Rôle de boutique : gère le quotidien.
  ///
  /// In fr, this message translates to:
  /// **'Gérante'**
  String get staffRoleManager;

  /// Rôle de boutique : prépare les commandes.
  ///
  /// In fr, this message translates to:
  /// **'Préparatrice'**
  String get staffRolePreparer;

  /// Rôle de boutique : tient la caisse.
  ///
  /// In fr, this message translates to:
  /// **'Caissière'**
  String get staffRoleCashier;

  /// Rôle gérante : ce qu'il permet.
  ///
  /// In fr, this message translates to:
  /// **'Commandes, catalogue, prix, messages, caisse et offres.'**
  String get staffRoleManagerHint;

  /// Rôle préparatrice : ce qu'il permet.
  ///
  /// In fr, this message translates to:
  /// **'Commandes et messages des clientes.'**
  String get staffRolePreparerHint;

  /// Rôle caissière : ce qu'il permet.
  ///
  /// In fr, this message translates to:
  /// **'Caisse, encaissements et commandes.'**
  String get staffRoleCashierHint;

  /// Vendeuse, équipe : bouton d'invitation.
  ///
  /// In fr, this message translates to:
  /// **'Inviter'**
  String get staffInvite;

  /// Vendeuse, équipe : compte pas encore créé.
  ///
  /// In fr, this message translates to:
  /// **'Invitation envoyée'**
  String get staffInvited;

  /// Vendeuse, équipe : retirer une personne.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de l\'équipe'**
  String get staffRemove;

  /// Vendeuse, équipe : liste vide.
  ///
  /// In fr, this message translates to:
  /// **'Personne dans l\'équipe'**
  String get staffEmpty;

  /// Vendeuse, équipe : liste vide, aide.
  ///
  /// In fr, this message translates to:
  /// **'Invite une personne par son email : elle se connecte à DYM Vendeuse avec ce compte.'**
  String get staffEmptyHint;

  /// Vendeuse, Ma boutique : groupe équipe et succursales.
  ///
  /// In fr, this message translates to:
  /// **'Équipe'**
  String get staffGroupTeam;

  /// Vendeuse : choisir la boutique active (succursales).
  ///
  /// In fr, this message translates to:
  /// **'Changer de boutique'**
  String get staffSwitchStore;

  /// Vendeuse, Ma boutique : rôle du personnel.
  ///
  /// In fr, this message translates to:
  /// **'Tu travailles ici comme {role}.'**
  String staffYouAre(String role);

  /// Exemple dans le champ email de la connexion.
  ///
  /// In fr, this message translates to:
  /// **'prenom@exemple.com'**
  String get authEmailHint;

  /// Bouton « ⋯ » de l'en-tête du panier : enregistrer, envoyer à un espace
  ///
  /// In fr, this message translates to:
  /// **'Plus d\'actions'**
  String get cartMoreActions;

  /// Groupe du menu de l'admin : tableau de bord, opérations
  ///
  /// In fr, this message translates to:
  /// **'Pilotage'**
  String get adminGroupPilot;

  /// Groupe du menu : commandes, boutiques, clientes
  ///
  /// In fr, this message translates to:
  /// **'Commerce'**
  String get adminGroupCommerce;

  /// Groupe du menu : finances
  ///
  /// In fr, this message translates to:
  /// **'Argent'**
  String get adminGroupMoney;

  /// Groupe du menu : litiges, modération, support
  ///
  /// In fr, this message translates to:
  /// **'Qualité'**
  String get adminGroupQuality;

  /// Groupe du menu : configuration, journal
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get adminGroupSettings;

  /// Sous-titre sous « DYM Admin » dans le menu
  ///
  /// In fr, this message translates to:
  /// **'Console de l\'équipe'**
  String get adminBrandSub;

  /// Premier élément du fil d'Ariane de l'admin
  ///
  /// In fr, this message translates to:
  /// **'DYM'**
  String get adminCrumbRoot;

  /// Bouton du menu de l'admin sur petit écran
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le menu'**
  String get adminOpenMenu;

  /// Sous-titre du tableau de bord
  ///
  /// In fr, this message translates to:
  /// **'Ventes, livraisons et incidents. Chaque chiffre vient des mêmes données que le reste de DYM.'**
  String get adminDashboardSubtitle;

  /// Carte du tableau de bord
  ///
  /// In fr, this message translates to:
  /// **'Ventes'**
  String get adminCardSales;

  /// Carte du tableau de bord
  ///
  /// In fr, this message translates to:
  /// **'Boutiques'**
  String get adminCardStores;

  /// Carte du tableau de bord
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get adminCardDelivery;

  /// Carte du tableau de bord : barres des commandes
  ///
  /// In fr, this message translates to:
  /// **'Commandes dans le temps'**
  String get adminCardDaily;

  /// Carte du tableau de bord : de la visite à la livraison
  ///
  /// In fr, this message translates to:
  /// **'Parcours des clientes'**
  String get adminCardJourney;

  /// Chiffre clé
  ///
  /// In fr, this message translates to:
  /// **'Ventes livrées'**
  String get adminMetricSales;

  /// Chiffre clé : commandes livrées
  ///
  /// In fr, this message translates to:
  /// **'Livrées'**
  String get adminMetricDelivered;

  /// Chiffre clé
  ///
  /// In fr, this message translates to:
  /// **'Panier moyen'**
  String get adminMetricBasket;

  /// Chiffre clé : boutiques actives
  ///
  /// In fr, this message translates to:
  /// **'Actives'**
  String get adminMetricActive;

  /// Chiffre clé : boutiques en brouillon
  ///
  /// In fr, this message translates to:
  /// **'À valider'**
  String get adminMetricToValidate;

  /// Chiffre clé
  ///
  /// In fr, this message translates to:
  /// **'Clientes actives'**
  String get adminMetricActiveClients;

  /// Chiffre clé : taux de livraison
  ///
  /// In fr, this message translates to:
  /// **'Livraisons réussies'**
  String get adminMetricDeliveryRate;

  /// Chiffre clé : en ligne sur actifs
  ///
  /// In fr, this message translates to:
  /// **'Livreurs en ligne'**
  String get adminMetricCouriers;

  /// Chiffre clé : délai médian d'acceptation d'une course
  ///
  /// In fr, this message translates to:
  /// **'Prise en charge'**
  String get adminMetricAccept;

  /// Chiffre clé
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get adminMetricOrders;

  /// Chiffre clé : plus forte valeur de la série
  ///
  /// In fr, this message translates to:
  /// **'Pic'**
  String get adminMetricPeak;

  /// Chiffre clé
  ///
  /// In fr, this message translates to:
  /// **'Litiges ouverts'**
  String get adminMetricDisputes;

  /// Chiffre clé : tickets de support
  ///
  /// In fr, this message translates to:
  /// **'Demandes ouvertes'**
  String get adminMetricTickets;

  /// Chiffre clé
  ///
  /// In fr, this message translates to:
  /// **'Bloquées'**
  String get adminMetricStuck;

  /// Chiffre clé : clientes actives du parcours
  ///
  /// In fr, this message translates to:
  /// **'Clientes venues'**
  String get adminMetricVisitors;

  /// Chiffre clé : commandes / visites
  ///
  /// In fr, this message translates to:
  /// **'Conversion'**
  String get adminMetricConversion;

  /// Intitulé au-dessus des barres
  ///
  /// In fr, this message translates to:
  /// **'Articles vendus par rayon'**
  String get adminSoldByAisle;

  /// Intitulé au-dessus des barres des boutiques
  ///
  /// In fr, this message translates to:
  /// **'Les plus actives'**
  String get adminMostActiveStores;

  /// Intitulé au-dessus des barres de livraison
  ///
  /// In fr, this message translates to:
  /// **'Issue des commandes'**
  String get adminOrdersOutcome;

  /// Note en bas de la carte Ventes
  ///
  /// In fr, this message translates to:
  /// **'Commandes livrées · comparées à la période précédente'**
  String get adminNoteSales;

  /// Note en bas de la carte Boutiques
  ///
  /// In fr, this message translates to:
  /// **'Ventes livrées par boutique sur la période'**
  String get adminNoteStores;

  /// Note en bas de la carte Livraison
  ///
  /// In fr, this message translates to:
  /// **'{relaunches} relances · {refused} refus automatiques'**
  String adminNoteDelivery(String relaunches, String refused);

  /// Note en bas de la carte À traiter
  ///
  /// In fr, this message translates to:
  /// **'Touchez une ligne pour ouvrir l\'écran où agir'**
  String get adminNoteTodo;

  /// Note en bas de la carte Commandes
  ///
  /// In fr, this message translates to:
  /// **'Toutes boutiques · une barre par point de la période'**
  String get adminNoteDaily;

  /// Pastille d'une ligne À traiter
  ///
  /// In fr, this message translates to:
  /// **'Litige'**
  String get adminPillDispute;

  /// Pastille d'une ligne À traiter
  ///
  /// In fr, this message translates to:
  /// **'Support'**
  String get adminPillTicket;

  /// Pastille d'une ligne À traiter
  ///
  /// In fr, this message translates to:
  /// **'Commande'**
  String get adminPillOrder;

  /// Pastille d'une ligne À traiter
  ///
  /// In fr, this message translates to:
  /// **'Boutique'**
  String get adminPillStore;

  /// Pastille d'une ligne À traiter
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get adminPillCourier;

  /// Phrase sur la photo de la page de connexion de l'admin
  ///
  /// In fr, this message translates to:
  /// **'Le marché du quartier, piloté en un coup d\'œil.'**
  String get adminSignInHeroTitle;

  /// Texte sous la phrase de la photo de connexion
  ///
  /// In fr, this message translates to:
  /// **'Commandes, boutiques, livreurs et paiements : toute l\'activité de DYM au même endroit.'**
  String get adminSignInHeroBody;

  /// Sous-titre de la page Boutiques
  ///
  /// In fr, this message translates to:
  /// **'{total} boutiques · {active} actives · {drafts} à valider'**
  String adminStoresSubtitle(int total, String active, String drafts);

  /// En-tête de colonne : type de boutique (marché, fait maison…)
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get adminColType;

  /// Unité après un nombre de minutes (chiffre clé)
  ///
  /// In fr, this message translates to:
  /// **'min'**
  String get adminUnitMinutes;

  /// Unité après un nombre d'heures (chiffre clé)
  ///
  /// In fr, this message translates to:
  /// **'h'**
  String get adminUnitHours;

  /// Unité après un nombre de jours (chiffre clé)
  ///
  /// In fr, this message translates to:
  /// **'j'**
  String get adminUnitDays;

  /// Distance en kilomètres, une décimale (ex. « 1,2 km »)
  ///
  /// In fr, this message translates to:
  /// **'{km} km'**
  String distanceKilometers(String km);

  /// Réglage de la boutique : rayon de livraison
  ///
  /// In fr, this message translates to:
  /// **'Je livre jusqu\'à'**
  String get storeDeliveryRadius;

  /// Explication sous le réglage du rayon de livraison
  ///
  /// In fr, this message translates to:
  /// **'Les clientes dans ce rayon autour de ta boutique voient tes produits et peuvent commander.'**
  String get storeDeliveryRadiusHint;

  /// Confirmation après changement du rayon
  ///
  /// In fr, this message translates to:
  /// **'Rayon de livraison enregistré.'**
  String get storeDeliveryRadiusSaved;

  /// Message d'un écran dont le chargement a échoué (pas une sauvegarde)
  ///
  /// In fr, this message translates to:
  /// **'La page n\'a pas pu se charger. Réessaie dans un instant.'**
  String get errorLoadMessage;

  /// Lien de la bienvenue cliente : parcourir l'app sans s'inscrire
  ///
  /// In fr, this message translates to:
  /// **'Découvrir sans compte'**
  String get authBrowse;

  /// Titre du choix du quartier en visiteuse
  ///
  /// In fr, this message translates to:
  /// **'Où veux-tu découvrir DYM ?'**
  String get authBrowseTitle;

  /// Sous-titre du choix du quartier en visiteuse
  ///
  /// In fr, this message translates to:
  /// **'Les boutiques qui livrent ce quartier s\'affichent. Tu crées ton compte seulement pour commander.'**
  String get authBrowseSubtitle;

  /// Bouton qui ouvre l'app en visiteuse
  ///
  /// In fr, this message translates to:
  /// **'Découvrir'**
  String get authBrowseAction;

  /// Titre de l'invitation à se connecter (visiteuse)
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi pour continuer'**
  String get visitorTitle;

  /// Texte de l'onglet Panier en visiteuse
  ///
  /// In fr, this message translates to:
  /// **'Crée ton compte en une minute pour remplir ton panier et commander.'**
  String get visitorCartBody;

  /// Texte de l'onglet Moi en visiteuse
  ///
  /// In fr, this message translates to:
  /// **'Ton compte garde tes commandes, tes adresses et ton wallet.'**
  String get visitorMeBody;

  /// Bouton de l'invitation à se connecter
  ///
  /// In fr, this message translates to:
  /// **'Se connecter ou créer un compte'**
  String get visitorSignIn;

  /// Lien pour choisir un autre quartier en visiteuse
  ///
  /// In fr, this message translates to:
  /// **'Changer de quartier'**
  String get visitorChangePlace;

  /// Marché : bascule vers la liste des boutiques (spec 095)
  ///
  /// In fr, this message translates to:
  /// **'Liste'**
  String get marketViewList;

  /// Marché : bascule vers la carte des boutiques (spec 095)
  ///
  /// In fr, this message translates to:
  /// **'Carte'**
  String get marketViewMap;

  /// Lecteur d'écran : la carte des boutiques
  ///
  /// In fr, this message translates to:
  /// **'Carte des boutiques'**
  String get mapSemantic;

  /// Filtre de la carte : boutiques ouvertes maintenant
  ///
  /// In fr, this message translates to:
  /// **'Ouvertes'**
  String get mapFilterOpen;

  /// Filtre de la carte : toutes les catégories
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get mapFilterAll;

  /// Carte : choisir un pays et une ville à afficher
  ///
  /// In fr, this message translates to:
  /// **'Explorer'**
  String get mapExplore;

  /// Titre de la feuille de choix du pays et de la ville
  ///
  /// In fr, this message translates to:
  /// **'Où regarder ?'**
  String get mapExploreTitle;

  /// Titre de la liste des pays dans l'explorateur
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get mapCountries;

  /// Carte : recentrer sur la position de l'appareil
  ///
  /// In fr, this message translates to:
  /// **'Ma position'**
  String get mapMyPosition;

  /// Carte : la position n'a pas pu être lue
  ///
  /// In fr, this message translates to:
  /// **'Position indisponible. Déplace la carte à la main.'**
  String get mapPositionUnavailable;

  /// Carte : aucune boutique dans le cadre
  ///
  /// In fr, this message translates to:
  /// **'Aucune boutique dans cette partie de la carte. Déplace-la ou retire un filtre.'**
  String get mapEmpty;

  /// Fiche de la carte : ouvrir la boutique
  ///
  /// In fr, this message translates to:
  /// **'Voir la boutique'**
  String get mapSeeStore;

  /// Fiche de la carte : rayon de livraison de la boutique
  ///
  /// In fr, this message translates to:
  /// **'Livre jusqu\'à {km} km'**
  String mapDeliversWithin(String km);

  /// Carte : nombre de boutiques visibles
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune boutique} =1{1 boutique} other{{count} boutiques}}'**
  String mapStoresCount(int count);

  /// Adresse : placer précisément la porte sur la carte (spec 095)
  ///
  /// In fr, this message translates to:
  /// **'Placer ma porte'**
  String get addressPlaceDoor;

  /// Consigne affichée sur la carte « Placer ma porte »
  ///
  /// In fr, this message translates to:
  /// **'Fais glisser la carte pour mettre l\'épingle sur ta porte.'**
  String get addressPlaceDoorHint;

  /// Bouton : valider la porte placée
  ///
  /// In fr, this message translates to:
  /// **'Valider cet emplacement'**
  String get addressPlaceDoorConfirm;

  /// Adresse : la porte a été placée sur la carte
  ///
  /// In fr, this message translates to:
  /// **'Porte placée sur la carte'**
  String get addressDoorPlaced;

  /// Vendeuse : légende de la carte du rayon de livraison
  ///
  /// In fr, this message translates to:
  /// **'Le cercle montre où tu livres.'**
  String get storeDeliveryMapHint;

  /// Suivi de commande : titre de la carte (spec 096)
  ///
  /// In fr, this message translates to:
  /// **'Suivi en direct'**
  String get trackLiveTitle;

  /// Suivi : position du livreur pas encore connue
  ///
  /// In fr, this message translates to:
  /// **'Le livreur apparaîtra ici'**
  String get trackLiveWaiting;

  /// Suivi : le livreur est en route
  ///
  /// In fr, this message translates to:
  /// **'{name} arrive'**
  String trackLiveCourier(String name);

  /// Suivi : minutes restantes estimées
  ///
  /// In fr, this message translates to:
  /// **'~{minutes} min'**
  String trackLiveEta(int minutes);

  /// Suivi : partager le lien avec un proche ou la personne qui réceptionne
  ///
  /// In fr, this message translates to:
  /// **'Partager le suivi'**
  String get trackShare;

  /// Message envoyé avec le lien de suivi
  ///
  /// In fr, this message translates to:
  /// **'Suis ma livraison DYM en direct : {url}'**
  String trackShareText(String url);

  /// Livreur : compte en attente de validation par l'équipe (spec 096)
  ///
  /// In fr, this message translates to:
  /// **'Compte en cours de validation'**
  String get courierPending;

  /// Livreur : explication de l'attente de validation
  ///
  /// In fr, this message translates to:
  /// **'L\'équipe DYM vérifie ton compte. Tu pourras passer en ligne dès qu\'il est validé.'**
  String get courierPendingHint;

  /// Livreur : compte refusé, le motif suit
  ///
  /// In fr, this message translates to:
  /// **'Compte à revoir'**
  String get courierRejected;

  /// Livreur : montrer le QR de récupération à la vendeuse
  ///
  /// In fr, this message translates to:
  /// **'Code de récupération'**
  String get pickupCodeShow;

  /// Titre de la feuille du code de récupération
  ///
  /// In fr, this message translates to:
  /// **'Montre ce code à la vendeuse'**
  String get pickupCodeTitle;

  /// Explication du code de récupération
  ///
  /// In fr, this message translates to:
  /// **'Elle le scanne pour te remettre la commande.'**
  String get pickupCodeHint;

  /// Livreur : la cliente ne répond pas devant la porte
  ///
  /// In fr, this message translates to:
  /// **'Cliente injoignable'**
  String get courierUnreachable;

  /// Livreur : confirmation du signalement injoignable
  ///
  /// In fr, this message translates to:
  /// **'La cliente est prévenue. Attends {minutes} min avant de repartir.'**
  String courierUnreachableSent(int minutes);

  /// Livreur : bouton d'alerte
  ///
  /// In fr, this message translates to:
  /// **'SOS'**
  String get courierSos;

  /// Livreur : confirmation de l'alerte SOS
  ///
  /// In fr, this message translates to:
  /// **'Alerter l\'équipe DYM ?'**
  String get courierSosTitle;

  /// Livreur : explication de l'alerte SOS
  ///
  /// In fr, this message translates to:
  /// **'L\'équipe reçoit ta position et te rappelle tout de suite. En cas de danger, appelle aussi les secours.'**
  String get courierSosBody;

  /// Livreur : envoyer l'alerte SOS
  ///
  /// In fr, this message translates to:
  /// **'Envoyer l\'alerte'**
  String get courierSosSend;

  /// Livreur : alerte SOS envoyée
  ///
  /// In fr, this message translates to:
  /// **'Alerte envoyée. L\'équipe te rappelle.'**
  String get courierSosSent;

  /// Vendeuse : livreurs de la boutique (spec 096)
  ///
  /// In fr, this message translates to:
  /// **'Mes livreurs'**
  String get storeCouriersTitle;

  /// Vendeuse : ajouter un livreur par son numéro
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un livreur'**
  String get storeCouriersAdd;

  /// Vendeuse : explication des livreurs de la boutique
  ///
  /// In fr, this message translates to:
  /// **'Ajoute les livreurs avec qui tu travailles : tu pourras leur confier tes commandes.'**
  String get storeCouriersHint;

  /// Vendeuse : aucun livreur ajouté
  ///
  /// In fr, this message translates to:
  /// **'Aucun livreur pour l\'instant'**
  String get storeCouriersEmpty;

  /// Champ : numéro du compte livreur DYM
  ///
  /// In fr, this message translates to:
  /// **'Numéro du livreur'**
  String get storeCourierPhone;

  /// Vendeuse : numéro inconnu
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte livreur DYM validé avec ce numéro.'**
  String get storeCourierNotFound;

  /// Vendeuse : retirer un livreur de la boutique
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get storeCourierRemove;

  /// Livreur occupé par une course
  ///
  /// In fr, this message translates to:
  /// **'En course'**
  String get storeCourierBusy;

  /// Vendeuse : confier la commande à son livreur
  ///
  /// In fr, this message translates to:
  /// **'Confier à un de mes livreurs'**
  String get storeCourierAssign;

  /// Vendeuse : scanner le QR de récupération
  ///
  /// In fr, this message translates to:
  /// **'Scanner le code du livreur'**
  String get pickupScan;

  /// Titre de l'écran de scan du code de récupération
  ///
  /// In fr, this message translates to:
  /// **'Code du livreur'**
  String get pickupScanTitle;

  /// Saisie du code de récupération à la main
  ///
  /// In fr, this message translates to:
  /// **'Code à 6 chiffres'**
  String get pickupCodeManual;

  /// Valider le code de récupération
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get pickupCodeValidate;

  /// Vendeuse : code bon, commande partie
  ///
  /// In fr, this message translates to:
  /// **'Commande remise au livreur.'**
  String get pickupConfirmed;

  /// Vendeuse : mauvais code de récupération
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect. Encore {count} essais.'**
  String pickupCodeWrong(int count);

  /// Vendeuse : boutique en validation (spec 096)
  ///
  /// In fr, this message translates to:
  /// **'L\'équipe DYM vérifie ta boutique. Tu pourras l\'ouvrir dès qu\'elle est validée.'**
  String get myStoreInReview;

  /// Vendeuse : boutique refusée
  ///
  /// In fr, this message translates to:
  /// **'Ta boutique est à revoir. Corrige ce qui est demandé puis publie-la de nouveau.'**
  String get myStoreRejected;

  /// Admin : boutiques et livreurs à valider (spec 096)
  ///
  /// In fr, this message translates to:
  /// **'Comptes à valider'**
  String get adminAccountsTitle;

  /// Admin : rien à valider
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte en attente'**
  String get adminAccountsEmpty;

  /// Admin : type de compte boutique
  ///
  /// In fr, this message translates to:
  /// **'Boutique'**
  String get adminAccountStore;

  /// Admin : type de compte livreur
  ///
  /// In fr, this message translates to:
  /// **'Livreur'**
  String get adminAccountCourier;

  /// Admin : valider un compte
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get adminAccountApprove;

  /// Admin : refuser un compte
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get adminAccountReject;

  /// Admin : motif du refus
  ///
  /// In fr, this message translates to:
  /// **'Motif (envoyé au compte)'**
  String get adminAccountReason;

  /// Admin : SOS et clientes injoignables (spec 096)
  ///
  /// In fr, this message translates to:
  /// **'Incidents de livraison'**
  String get adminIncidentsTitle;

  /// Admin : aucun incident
  ///
  /// In fr, this message translates to:
  /// **'Aucun incident ouvert'**
  String get adminIncidentsEmpty;

  /// Admin : incident SOS
  ///
  /// In fr, this message translates to:
  /// **'SOS'**
  String get adminIncidentSos;

  /// Admin : incident cliente injoignable
  ///
  /// In fr, this message translates to:
  /// **'Cliente injoignable'**
  String get adminIncidentUnreachable;

  /// Admin : clore un incident
  ///
  /// In fr, this message translates to:
  /// **'Clore'**
  String get adminIncidentResolve;

  /// Admin : tranches de frais de livraison (spec 096)
  ///
  /// In fr, this message translates to:
  /// **'Frais par distance'**
  String get adminFeeBandsTitle;

  /// Admin : explication des tranches
  ///
  /// In fr, this message translates to:
  /// **'Frais selon la distance de la boutique à la porte. Une boutique peut fixer ses propres frais.'**
  String get adminFeeBandsHint;

  /// Admin : distance maximale de la tranche
  ///
  /// In fr, this message translates to:
  /// **'Jusqu\'à (m)'**
  String get adminFeeBandUpTo;

  /// Admin : montant de la tranche
  ///
  /// In fr, this message translates to:
  /// **'Frais (unités mineures)'**
  String get adminFeeBandFee;

  /// Admin : ajouter une tranche
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une tranche'**
  String get adminFeeBandAdd;

  /// Boutique hors de son rayon : livraison possible, à confirmer par elle (spec 096)
  ///
  /// In fr, this message translates to:
  /// **'Longue distance · à confirmer'**
  String get storeLongDistance;

  /// Panier : boutique au-delà de son rayon de livraison
  ///
  /// In fr, this message translates to:
  /// **'Longue distance : frais plus élevés, la boutique confirme la livraison.'**
  String get cartLongDistance;

  /// Admin : réglages de livraison du pays (spec 096)
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get adminDeliveryTitle;

  /// Admin : mode de calcul des frais
  ///
  /// In fr, this message translates to:
  /// **'Calcul des frais'**
  String get adminDeliveryMode;

  /// Admin : mode au km
  ///
  /// In fr, this message translates to:
  /// **'Au kilomètre'**
  String get adminDeliveryPerKm;

  /// Admin : mode par tranches
  ///
  /// In fr, this message translates to:
  /// **'Par tranches'**
  String get adminDeliveryBands;

  /// Admin : frais fixes de départ
  ///
  /// In fr, this message translates to:
  /// **'Prise en charge'**
  String get adminDeliveryBase;

  /// Admin : distance comprise dans la prise en charge
  ///
  /// In fr, this message translates to:
  /// **'Distance incluse (m)'**
  String get adminDeliveryIncluded;

  /// Admin : prix par kilomètre au-delà de la distance incluse
  ///
  /// In fr, this message translates to:
  /// **'Prix par km'**
  String get adminDeliveryPerKmFee;

  /// Admin : frais minimum
  ///
  /// In fr, this message translates to:
  /// **'Minimum'**
  String get adminDeliveryMin;

  /// Admin : frais maximum
  ///
  /// In fr, this message translates to:
  /// **'Plafond (vide : aucun)'**
  String get adminDeliveryMaxFee;

  /// Admin : arrondi des frais
  ///
  /// In fr, this message translates to:
  /// **'Arrondi'**
  String get adminDeliveryRounding;

  /// Admin : supplément au-delà du rayon de la boutique
  ///
  /// In fr, this message translates to:
  /// **'Supplément longue distance'**
  String get adminDeliveryLongSurcharge;

  /// Admin : au-delà, retrait seulement
  ///
  /// In fr, this message translates to:
  /// **'Distance maximale de livraison (m)'**
  String get adminDeliveryMaxDistance;

  /// Admin : soir, week-end, heures de pointe
  ///
  /// In fr, this message translates to:
  /// **'Majorations horaires'**
  String get adminDeliverySurcharges;

  /// Admin : ajouter une majoration horaire
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une majoration'**
  String get adminDeliverySurchargeAdd;

  /// Admin : rayon par défaut par ville
  ///
  /// In fr, this message translates to:
  /// **'Rayon proposé aux nouvelles boutiques'**
  String get adminDeliveryCityRadius;

  /// Admin : calculer des frais pour tester le tarif
  ///
  /// In fr, this message translates to:
  /// **'Simulateur'**
  String get adminDeliverySimulator;

  /// Admin : lancer la simulation
  ///
  /// In fr, this message translates to:
  /// **'Calculer'**
  String get adminDeliverySimulate;

  /// Admin : distance simulée
  ///
  /// In fr, this message translates to:
  /// **'Distance (m)'**
  String get adminDeliverySimDistance;

  /// Admin : simuler la longue distance
  ///
  /// In fr, this message translates to:
  /// **'Hors du rayon de la boutique'**
  String get adminDeliverySimLong;

  /// Admin : résultat du simulateur
  ///
  /// In fr, this message translates to:
  /// **'Frais : {fee}'**
  String adminDeliverySimResult(String fee);

  /// Admin : réglage enregistré
  ///
  /// In fr, this message translates to:
  /// **'Enregistré'**
  String get adminSaved;

  /// Boîte de notifications vide (vendeuse, livreur, spec 097)
  ///
  /// In fr, this message translates to:
  /// **'Commandes, messages, appels et alertes de stock apparaîtront ici.'**
  String get inboxEmptyMessage;

  /// Canal Android des appels qui sonnent (spec 097)
  ///
  /// In fr, this message translates to:
  /// **'Appels'**
  String get pushChannelCalls;

  /// Bouton de notification : accepter la commande ou la course
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get pushActionAccept;

  /// Bouton de notification : ouvrir
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get pushActionView;

  /// Bouton de notification : répondre au message
  ///
  /// In fr, this message translates to:
  /// **'Répondre'**
  String get pushActionReply;

  /// Champ de réponse dans la notification
  ///
  /// In fr, this message translates to:
  /// **'Ton message'**
  String get pushActionReplyHint;

  /// Bouton de notification : décrocher l'appel
  ///
  /// In fr, this message translates to:
  /// **'Décrocher'**
  String get pushActionAnswer;

  /// Bouton de notification : refuser l'appel
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get pushActionDecline;

  /// Vendeuse : tendance des ventes (spec 098)
  ///
  /// In fr, this message translates to:
  /// **'Ventes jour par jour'**
  String get insightsTrend;

  /// Vendeuse : montant moyen d'une commande
  ///
  /// In fr, this message translates to:
  /// **'Panier moyen'**
  String get insightsAverageBasket;

  /// Vendeuse : clientes de la période, dont nouvelles
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{clientes} =1{clientes · 1 nouvelle} other{clientes · {count} nouvelles}}'**
  String insightsCustomers(int count);

  /// Vendeuse : produits sous le seuil d'alerte
  ///
  /// In fr, this message translates to:
  /// **'Bientôt en rupture'**
  String get insightsLowStock;

  /// Vendeuse : stock restant
  ///
  /// In fr, this message translates to:
  /// **'Reste {stock}'**
  String insightsStockLeft(String stock);

  /// Vendeuse : produits les plus vendus de la période
  ///
  /// In fr, this message translates to:
  /// **'Tes meilleurs produits'**
  String get insightsTopProducts;

  /// Vendeuse : quantité et montant vendus
  ///
  /// In fr, this message translates to:
  /// **'{quantity} vendus · {amount}'**
  String insightsSold(String quantity, String amount);

  /// Vendeuse : clientes qui reviennent (prénom seulement)
  ///
  /// In fr, this message translates to:
  /// **'Tes clientes fidèles'**
  String get insightsLoyal;

  /// Vendeuse : cliente fidèle et nombre de commandes
  ///
  /// In fr, this message translates to:
  /// **'{name} · {count, plural, =1{1 commande} other{{count} commandes}}'**
  String insightsLoyalChip(String name, int count);

  /// Chat : message vidéo (spec 099)
  ///
  /// In fr, this message translates to:
  /// **'Vidéo'**
  String get chatVideo;

  /// Chat : lire une vidéo
  ///
  /// In fr, this message translates to:
  /// **'Lire la vidéo'**
  String get chatVideoPlay;

  /// Chat : durée d'une vidéo
  ///
  /// In fr, this message translates to:
  /// **'Vidéo · {seconds} s'**
  String chatVideoDuration(int seconds);

  /// Chat : enregistrer une vidéo (1 min au plus)
  ///
  /// In fr, this message translates to:
  /// **'Filmer une vidéo'**
  String get chatVideoRecord;

  /// Chat : choisir une vidéo
  ///
  /// In fr, this message translates to:
  /// **'Partager une vidéo'**
  String get chatVideoShare;

  /// Chat : position partagée
  ///
  /// In fr, this message translates to:
  /// **'Position'**
  String get chatLocation;

  /// Chat : position en direct
  ///
  /// In fr, this message translates to:
  /// **'Position en direct jusqu\'à {time}'**
  String chatLocationLive(String time);

  /// Chat : ouvrir la position dans une carte
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir la carte'**
  String get chatLocationOpen;

  /// Chat : arrêter la position en direct
  ///
  /// In fr, this message translates to:
  /// **'Arrêter le partage'**
  String get chatLocationStop;

  /// Chat : position ponctuelle
  ///
  /// In fr, this message translates to:
  /// **'Envoyer ma position'**
  String get chatLocationSend;

  /// Chat : partager sa position en direct
  ///
  /// In fr, this message translates to:
  /// **'Position en direct (15 min)'**
  String get chatLocationLiveSend;

  /// Chat : devis de la boutique
  ///
  /// In fr, this message translates to:
  /// **'Devis'**
  String get chatQuote;

  /// Chat : total du devis
  ///
  /// In fr, this message translates to:
  /// **'Total : {amount}'**
  String chatQuoteTotal(String amount);

  /// Chat : accepter le devis en un geste
  ///
  /// In fr, this message translates to:
  /// **'Accepter et mettre au panier'**
  String get chatQuoteAccept;

  /// Chat : devis accepté
  ///
  /// In fr, this message translates to:
  /// **'Devis accepté'**
  String get chatQuoteAccepted;

  /// Chat : devis pas encore accepté
  ///
  /// In fr, this message translates to:
  /// **'En attente de la cliente'**
  String get chatQuotePending;

  /// Chat : devis accepté, panier mis à jour
  ///
  /// In fr, this message translates to:
  /// **'Articles ajoutés au panier aux prix du devis.'**
  String get chatQuoteInCart;

  /// Chat : la boutique propose un devis
  ///
  /// In fr, this message translates to:
  /// **'Faire un devis'**
  String get chatQuoteSend;

  /// Chat : aucun produit pour un devis
  ///
  /// In fr, this message translates to:
  /// **'Ajoute d\'abord des produits à ton catalogue.'**
  String get chatQuoteEmpty;

  /// Chat : prix du devis, ne dépasse pas le prix affiché
  ///
  /// In fr, this message translates to:
  /// **'Prix unitaire (affiché : {price})'**
  String chatQuoteUnitPrice(String price);

  /// Chat : retirer une unité du devis
  ///
  /// In fr, this message translates to:
  /// **'Moins'**
  String get chatQuoteLess;

  /// Chat : ajouter une unité au devis
  ///
  /// In fr, this message translates to:
  /// **'Plus'**
  String get chatQuoteMore;

  /// Chat : devis, paiement ou coupon expiré
  ///
  /// In fr, this message translates to:
  /// **'Expiré'**
  String get chatExpired;

  /// Chat : demande de paiement de la boutique
  ///
  /// In fr, this message translates to:
  /// **'Demande de paiement'**
  String get chatPaymentRequest;

  /// Chat : la boutique demande un paiement
  ///
  /// In fr, this message translates to:
  /// **'Demander un paiement'**
  String get chatPaymentRequestSend;

  /// Chat : payer la demande avec le wallet
  ///
  /// In fr, this message translates to:
  /// **'Payer {amount}'**
  String chatPay(String amount);

  /// Chat : demande payée
  ///
  /// In fr, this message translates to:
  /// **'Payé'**
  String get chatPaid;

  /// Chat : demande pas encore payée
  ///
  /// In fr, this message translates to:
  /// **'En attente du paiement'**
  String get chatPaymentWaiting;

  /// Chat : champ montant
  ///
  /// In fr, this message translates to:
  /// **'Montant ({symbol})'**
  String chatAmount(String symbol);

  /// Chat : motif de la demande de paiement
  ///
  /// In fr, this message translates to:
  /// **'Pour quoi ? (facultatif)'**
  String get chatPaymentLabel;

  /// Chat : coupon de la boutique
  ///
  /// In fr, this message translates to:
  /// **'−{percent} % sur ta prochaine commande'**
  String chatCoupon(int percent);

  /// Chat : fin de validité du coupon
  ///
  /// In fr, this message translates to:
  /// **'Valable jusqu\'au {date}'**
  String chatCouponUntil(String date);

  /// Chat : la cliente garde le coupon
  ///
  /// In fr, this message translates to:
  /// **'Garder le coupon'**
  String get chatCouponClaim;

  /// Chat : coupon gardé
  ///
  /// In fr, this message translates to:
  /// **'Coupon gardé : il s\'applique à ta prochaine commande ici.'**
  String get chatCouponClaimed;

  /// Chat : la boutique offre un coupon
  ///
  /// In fr, this message translates to:
  /// **'Offrir un coupon'**
  String get chatCouponSend;

  /// Chat : durée du coupon
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Valable 1 jour} other{Valable {count} jours}}'**
  String chatCouponDays(int count);

  /// Chat : afficher le texte d'un vocal
  ///
  /// In fr, this message translates to:
  /// **'Transcrire'**
  String get chatTranscribe;

  /// Chat : transcription indisponible, simulée (décision 0015)
  ///
  /// In fr, this message translates to:
  /// **'Transcription simulée : service à brancher.'**
  String get chatTranscriptSimulated;

  /// Wallet : avoir entre personnes (spec 100)
  ///
  /// In fr, this message translates to:
  /// **'Entre proches'**
  String get peopleTitle;

  /// Wallet entre personnes : rappel simulé, jamais de retrait
  ///
  /// In fr, this message translates to:
  /// **'Avoir DYM simulé : il se dépense chez les boutiques DYM, il ne se retire pas.'**
  String get peopleSimulatedNote;

  /// Wallet : code personnel à partager
  ///
  /// In fr, this message translates to:
  /// **'Mon code : montre ce QR pour recevoir'**
  String get peopleMyCodeHint;

  /// Wallet : envoyer de l'avoir
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get peopleSend;

  /// Wallet : demander de l'avoir (« paie ma commande »)
  ///
  /// In fr, this message translates to:
  /// **'Demander'**
  String get peopleRequest;

  /// Wallet : recharger le wallet d'une autre personne
  ///
  /// In fr, this message translates to:
  /// **'Recharger un proche'**
  String get peopleTopupFor;

  /// Wallet : demandes d'avoir
  ///
  /// In fr, this message translates to:
  /// **'Demandes en cours'**
  String get peopleRequests;

  /// Wallet : demande reçue
  ///
  /// In fr, this message translates to:
  /// **'{name} te demande {amount}'**
  String peopleAsksYou(String name, String amount);

  /// Wallet : demande envoyée
  ///
  /// In fr, this message translates to:
  /// **'Tu as demandé {amount} à {name}'**
  String peopleYouAsked(String amount, String name);

  /// Wallet : payer une demande
  ///
  /// In fr, this message translates to:
  /// **'Payer'**
  String get peoplePay;

  /// Wallet : historique des envois et réceptions
  ///
  /// In fr, this message translates to:
  /// **'Entre proches'**
  String get peopleHistory;

  /// Wallet : historique vide
  ///
  /// In fr, this message translates to:
  /// **'Rien pour l\'instant.'**
  String get peopleHistoryEmpty;

  /// Wallet : avoir reçu de
  ///
  /// In fr, this message translates to:
  /// **'De {name}'**
  String peopleFrom(String name);

  /// Wallet : avoir envoyé à
  ///
  /// In fr, this message translates to:
  /// **'À {name}'**
  String peopleTo(String name);

  /// Wallet : titre de l'envoi
  ///
  /// In fr, this message translates to:
  /// **'Envoyer à {name}'**
  String peopleSendTo(String name);

  /// Wallet : titre de la demande
  ///
  /// In fr, this message translates to:
  /// **'Demander à {name}'**
  String peopleRequestFrom(String name);

  /// Wallet : titre de la recharge pour un proche
  ///
  /// In fr, this message translates to:
  /// **'Recharger le wallet de {name}'**
  String peopleTopupForName(String name);

  /// Wallet : message joint
  ///
  /// In fr, this message translates to:
  /// **'Message (facultatif)'**
  String get peopleNote;

  /// Wallet : geste réussi
  ///
  /// In fr, this message translates to:
  /// **'C\'est fait.'**
  String get peopleDone;

  /// Wallet : saisir ou scanner un code
  ///
  /// In fr, this message translates to:
  /// **'Code de la personne'**
  String get peopleCodeTitle;

  /// Wallet : champ du code
  ///
  /// In fr, this message translates to:
  /// **'Code à 8 caractères'**
  String get peopleCodeLabel;

  /// Wallet : scanner le QR personnel
  ///
  /// In fr, this message translates to:
  /// **'Scanner son QR'**
  String get peopleScan;

  /// Wallet : valider le code
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get peopleContinue;

  /// Wallet : code introuvable
  ///
  /// In fr, this message translates to:
  /// **'Code inconnu.'**
  String get peopleUnknownCode;

  /// Wallet : plafond parental dépassé
  ///
  /// In fr, this message translates to:
  /// **'Plafond du jour atteint (réglé par un parent).'**
  String get peopleChildLimit;

  /// Wallet : devises différentes
  ///
  /// In fr, this message translates to:
  /// **'Cette personne utilise une autre devise.'**
  String get peopleCurrencyMismatch;

  /// Wallet : famille (spec 100)
  ///
  /// In fr, this message translates to:
  /// **'Famille et argent de poche'**
  String get familyTitle;

  /// Famille : explication
  ///
  /// In fr, this message translates to:
  /// **'Invite ton enfant avec son code : tu vois son solde, ses dépenses du jour, et tu règles son argent de poche et son plafond.'**
  String get familyHint;

  /// Famille : inviter par code
  ///
  /// In fr, this message translates to:
  /// **'Inviter mon enfant'**
  String get familyInvite;

  /// Famille : invitation reçue
  ///
  /// In fr, this message translates to:
  /// **'{name} t\'invite à suivre ton argent de poche'**
  String familyInvitedBy(String name);

  /// Famille : accepter l'invitation
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get familyAccept;

  /// Famille : en attente d'acceptation
  ///
  /// In fr, this message translates to:
  /// **'Invitation envoyée'**
  String get familyWaiting;

  /// Famille : solde de l'enfant
  ///
  /// In fr, this message translates to:
  /// **'Solde : {amount}'**
  String familyBalance(String amount);

  /// Famille : dépenses du jour et plafond
  ///
  /// In fr, this message translates to:
  /// **'Dépensé aujourd\'hui : {spent} (plafond : {limit})'**
  String familySpentToday(String spent, String limit);

  /// Famille : argent de poche
  ///
  /// In fr, this message translates to:
  /// **'Argent de poche : {amount} tous les {days} jours'**
  String familyAllowance(String amount, int days);

  /// Famille : régler les règles
  ///
  /// In fr, this message translates to:
  /// **'Argent de poche et plafond'**
  String get familyRules;

  /// Famille : montant de l'argent de poche
  ///
  /// In fr, this message translates to:
  /// **'Argent de poche (vide : aucun)'**
  String get familyAllowanceLabel;

  /// Famille : plafond journalier
  ///
  /// In fr, this message translates to:
  /// **'Plafond par jour (vide : aucun)'**
  String get familyLimitLabel;

  /// Wallet : bouton vers l'avoir entre personnes
  ///
  /// In fr, this message translates to:
  /// **'Entre proches'**
  String get walletPeople;

  /// Famille : argent de poche quotidien
  ///
  /// In fr, this message translates to:
  /// **'Chaque jour'**
  String get familyEveryDay;

  /// Famille : argent de poche hebdomadaire
  ///
  /// In fr, this message translates to:
  /// **'Chaque semaine'**
  String get familyEveryWeek;

  /// Famille : argent de poche mensuel
  ///
  /// In fr, this message translates to:
  /// **'Chaque mois'**
  String get familyEveryMonth;

  /// Cuisine : contenus des boutiques qui livrent ici (spec 101)
  ///
  /// In fr, this message translates to:
  /// **'Près de moi'**
  String get feedNear;

  /// Cuisine : enregistrer une recette
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer dans « Mes recettes »'**
  String get feedSave;

  /// Cuisine : signaler qu'on a fait la recette
  ///
  /// In fr, this message translates to:
  /// **'J\'ai fait la recette'**
  String get feedCooked;

  /// Cuisine : titre du « J'ai fait »
  ///
  /// In fr, this message translates to:
  /// **'Tu as fait cette recette ?'**
  String get feedCookedTitle;

  /// Cuisine : mot pour l'autrice
  ///
  /// In fr, this message translates to:
  /// **'Un petit mot (facultatif)'**
  String get feedCookedNote;

  /// Cuisine : confirmation du « J'ai fait »
  ///
  /// In fr, this message translates to:
  /// **'Merci ! L\'autrice est prévenue.'**
  String get feedCookedThanks;

  /// Cuisine : recettes enregistrées
  ///
  /// In fr, this message translates to:
  /// **'Mes recettes'**
  String get savedRecipesTitle;

  /// Profil public : abonnées
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune abonnée} =1{1 abonnée} other{{count} abonnées}}'**
  String profileFollowers(int count);

  /// Profil public : aucun contenu
  ///
  /// In fr, this message translates to:
  /// **'Rien de publié pour l\'instant.'**
  String get profileNoContent;

  /// Sous-titre de l'étape email en mode mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi avec ton email et ton mot de passe.'**
  String get authEmailSubtitlePassword;

  /// Menu Moi : réglage d'économie de données
  ///
  /// In fr, this message translates to:
  /// **'Économie de données'**
  String get accountDataSaver;

  /// Titre de la feuille d'économie de données
  ///
  /// In fr, this message translates to:
  /// **'Économie de données'**
  String get dataSaverTitle;

  /// Explication de l'économie de données
  ///
  /// In fr, this message translates to:
  /// **'Vidéos en version légère, gardées sur ton téléphone pour les revoir sans data. Rien n\'est préchargé.'**
  String get dataSaverBody;

  /// Interrupteur d'économie de données
  ///
  /// In fr, this message translates to:
  /// **'Économiser mes données'**
  String get dataSaverSwitch;

  /// Mes vidéos : temps moyen
  ///
  /// In fr, this message translates to:
  /// **'{seconds} s regardées en moyenne'**
  String contentStatsAvgWatch(int seconds);

  /// Mes vidéos : fin de lecture
  ///
  /// In fr, this message translates to:
  /// **'{percent} % jusqu\'au bout'**
  String contentStatsCompletion(int percent);

  /// Mes vidéos : ventes générées
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucune vente générée} =1{1 vente générée · {amount}} other{{n} ventes générées · {amount}}}'**
  String contentStatsSales(int n, String amount);

  /// Action : miniature d'une vidéo
  ///
  /// In fr, this message translates to:
  /// **'Choisir la miniature'**
  String get contentCoverChoose;

  /// Miniature par défaut
  ///
  /// In fr, this message translates to:
  /// **'Image par défaut'**
  String get contentCoverDefault;

  /// Miniature indisponible pendant la conversion
  ///
  /// In fr, this message translates to:
  /// **'La vidéo est en préparation : ses images arrivent bientôt.'**
  String get contentCoverPending;

  /// Confirmation
  ///
  /// In fr, this message translates to:
  /// **'Miniature enregistrée'**
  String get contentCoverSaved;

  /// Famille : rayons que l'enfant peut acheter
  ///
  /// In fr, this message translates to:
  /// **'Rayons autorisés'**
  String get familyCategoriesLabel;

  /// Famille : aucun filtre
  ///
  /// In fr, this message translates to:
  /// **'Tous les rayons'**
  String get familyCategoriesAll;

  /// Famille : nombre de rayons
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 rayon autorisé} other{{n} rayons autorisés}}'**
  String familyCategoriesSome(int n);

  /// Mouvement : abonnement
  ///
  /// In fr, this message translates to:
  /// **'Abonnement DYM+'**
  String get walletKindMembership;

  /// Mouvement : avantage membre
  ///
  /// In fr, this message translates to:
  /// **'Avantage DYM+'**
  String get walletKindMemberBenefit;

  /// Mouvement : paiement par QR
  ///
  /// In fr, this message translates to:
  /// **'Paiement en boutique'**
  String get walletKindQrPayment;

  /// Mouvement : envoyé à un proche
  ///
  /// In fr, this message translates to:
  /// **'À {name}'**
  String walletKindP2pSent(String name);

  /// Mouvement : reçu d'un proche
  ///
  /// In fr, this message translates to:
  /// **'De {name}'**
  String walletKindP2pReceived(String name);

  /// Mouvement entre proches sans prénom
  ///
  /// In fr, this message translates to:
  /// **'Entre proches'**
  String get walletKindP2pAnonymous;

  /// Erreur : rayon bloqué
  ///
  /// In fr, this message translates to:
  /// **'Ce rayon n\'est pas autorisé par ton parent.'**
  String get peopleChildCategory;

  /// Livreur : partager la course avec un proche
  ///
  /// In fr, this message translates to:
  /// **'Partager ma course'**
  String get courierShareRun;

  /// Message envoyé au proche
  ///
  /// In fr, this message translates to:
  /// **'Je suis en livraison avec DYM. Suis ma course en direct : {url}'**
  String courierShareRunText(String url);

  /// Bienvenue : connexion par WhatsApp
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec WhatsApp'**
  String get authContinueWhatsApp;

  /// Étape numéro
  ///
  /// In fr, this message translates to:
  /// **'Ton numéro WhatsApp'**
  String get authPhoneTitle;

  /// Étape numéro : explication
  ///
  /// In fr, this message translates to:
  /// **'On t\'envoie un code à 6 chiffres sur WhatsApp. Ton numéro n\'est montré à personne.'**
  String get authPhoneSubtitle;

  /// Champ numéro
  ///
  /// In fr, this message translates to:
  /// **'Numéro'**
  String get authPhoneLabel;

  /// Champ indicatif
  ///
  /// In fr, this message translates to:
  /// **'Indicatif'**
  String get authDialCode;

  /// Code : envoyé au numéro
  ///
  /// In fr, this message translates to:
  /// **'Code envoyé sur WhatsApp au {phone}'**
  String authCodeSentToPhone(String phone);

  /// Code : changer de numéro
  ///
  /// In fr, this message translates to:
  /// **'Changer de numéro'**
  String get authChangePhone;

  /// Mode simulé : code affiché
  ///
  /// In fr, this message translates to:
  /// **'Code simulé (WhatsApp pas encore branché) : {code}'**
  String authSimulatedCode(String code);

  /// Erreur : numéro
  ///
  /// In fr, this message translates to:
  /// **'Numéro incomplet : vérifie l\'indicatif et le numéro.'**
  String get authPhoneInvalid;

  /// Erreur : trop de codes
  ///
  /// In fr, this message translates to:
  /// **'Trop de codes demandés. Réessaie dans quelques minutes.'**
  String get authTooManyCodes;

  /// Catalogue : gestes en attente du réseau
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 geste gardé hors ligne : il partira au retour du réseau.} other{{n} gestes gardés hors ligne : ils partiront au retour du réseau.}}'**
  String catalogOfflinePending(int n);

  /// Accueil affiché depuis le cache
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne : affichage de ta dernière visite.'**
  String get homeFromCache;

  /// Code : astuce WhatsApp
  ///
  /// In fr, this message translates to:
  /// **'Astuce : le code arrive dans WhatsApp en moins d\'une minute.'**
  String get authCodeTipWhatsApp;

  /// Réponse rapide du livreur
  ///
  /// In fr, this message translates to:
  /// **'Je suis en route.'**
  String get chatQuickOnMyWay;

  /// Réponse rapide du livreur
  ///
  /// In fr, this message translates to:
  /// **'Je suis devant chez toi.'**
  String get chatQuickAtTheDoor;

  /// Réponse rapide du livreur
  ///
  /// In fr, this message translates to:
  /// **'Je ne trouve pas l\'adresse, peux-tu m\'aider ?'**
  String get chatQuickCantFind;

  /// Fil de commande fermé
  ///
  /// In fr, this message translates to:
  /// **'Livraison terminée : cette conversation est fermée.'**
  String get chatThreadClosed;

  /// Ouvrir le fil de commande (cliente)
  ///
  /// In fr, this message translates to:
  /// **'Discuter avec la boutique et le livreur'**
  String get orderLiveChat;

  /// Ouvrir le fil de commande (vendeuse)
  ///
  /// In fr, this message translates to:
  /// **'Discuter avec la cliente et le livreur'**
  String get orderLiveChatVendor;

  /// Ouvrir le fil de commande (livreur)
  ///
  /// In fr, this message translates to:
  /// **'Discuter avec la cliente et la boutique'**
  String get orderLiveChatCourier;

  /// Phase : le livreur va chercher la commande
  ///
  /// In fr, this message translates to:
  /// **'En route vers la boutique'**
  String get orderLiveToStore;

  /// Phase : le livreur livre
  ///
  /// In fr, this message translates to:
  /// **'En route vers la cliente'**
  String get orderLiveToDoor;

  /// Phase : remise confirmée
  ///
  /// In fr, this message translates to:
  /// **'Livrée et confirmée par le code'**
  String get orderLiveDelivered;

  /// Phase : pas encore de livreur
  ///
  /// In fr, this message translates to:
  /// **'En attente d\'un livreur'**
  String get orderLiveWaiting;

  /// Minutes restantes
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min'**
  String orderLiveEta(int minutes);

  /// Titre de la carte de suivi
  ///
  /// In fr, this message translates to:
  /// **'Suivi de la livraison'**
  String get orderLiveTitle;

  /// Fil de commande vide
  ///
  /// In fr, this message translates to:
  /// **'Pendant la livraison, la cliente, la boutique et le livreur s\'écrivent ici.'**
  String get chatEmptyOrderThread;

  /// Accueil : position dans une autre ville ou un autre pays
  ///
  /// In fr, this message translates to:
  /// **'Tu es à {city}'**
  String homeElsewhereTitle(String city);

  /// Accueil : passer à la ville de la position
  ///
  /// In fr, this message translates to:
  /// **'Voir les boutiques de {city}'**
  String homeElsewhereAction(String city);

  /// Panier d'un autre pays
  ///
  /// In fr, this message translates to:
  /// **'Ton panier contient des produits d\'un autre pays. Une commande ne mélange jamais deux pays.'**
  String get cartElsewhereText;

  /// Vider le panier de l'autre pays
  ///
  /// In fr, this message translates to:
  /// **'Vider le panier'**
  String get cartElsewhereClear;

  /// Garder le panier de l'autre pays
  ///
  /// In fr, this message translates to:
  /// **'Garder pour plus tard'**
  String get cartElsewhereKeep;

  /// Action : répondre à un message (spec 111)
  ///
  /// In fr, this message translates to:
  /// **'Répondre'**
  String get chatReply;

  /// Action : copier le texte d'un message
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get chatCopy;

  /// Confirmation après copie
  ///
  /// In fr, this message translates to:
  /// **'Message copié'**
  String get chatCopied;

  /// Action : transférer un message
  ///
  /// In fr, this message translates to:
  /// **'Transférer'**
  String get chatForward;

  /// Titre de la feuille de transfert
  ///
  /// In fr, this message translates to:
  /// **'Transférer à…'**
  String get chatForwardTo;

  /// Mention sur un message transféré
  ///
  /// In fr, this message translates to:
  /// **'Transféré'**
  String get chatForwarded;

  /// Confirmation de transfert
  ///
  /// In fr, this message translates to:
  /// **'Message transféré'**
  String get chatForwardDone;

  /// Transfert impossible : pas d'autre conversation
  ///
  /// In fr, this message translates to:
  /// **'Aucune autre conversation'**
  String get chatForwardNone;

  /// Action : supprimer un message pour soi
  ///
  /// In fr, this message translates to:
  /// **'Supprimer pour moi'**
  String get chatDeleteForMe;

  /// Action : supprimer pour tous (dans l'heure)
  ///
  /// In fr, this message translates to:
  /// **'Supprimer pour tout le monde'**
  String get chatDeleteForAll;

  /// Titre de la confirmation de suppression
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce message ?'**
  String get chatDeleteTitle;

  /// Bulle d'un message supprimé pour tous
  ///
  /// In fr, this message translates to:
  /// **'Ce message a été supprimé'**
  String get chatDeletedMessage;

  /// Suppression pour tous refusée (trop tard)
  ///
  /// In fr, this message translates to:
  /// **'Plus d\'une heure : supprime-le seulement pour toi'**
  String get chatDeleteTooLate;

  /// Bandeau au-dessus du champ pendant une réponse
  ///
  /// In fr, this message translates to:
  /// **'Réponse à {name}'**
  String chatReplyingTo(String name);

  /// Auteur d'un message cité quand c'est moi
  ///
  /// In fr, this message translates to:
  /// **'Toi'**
  String get chatYouName;

  /// Fermer le bandeau de réponse
  ///
  /// In fr, this message translates to:
  /// **'Annuler la réponse'**
  String get chatCancelReply;

  /// Séparateur avant les messages non lus
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 nouveau message} other{{count} nouveaux messages}}'**
  String chatNewMessages(int count);

  /// Indicateur de saisie de l'autre personne
  ///
  /// In fr, this message translates to:
  /// **'{name} écrit…'**
  String chatTyping(String name);

  /// Indicateur de saisie sans nom
  ///
  /// In fr, this message translates to:
  /// **'écrit…'**
  String get chatTypingSomeone;

  /// État d'un message reçu par l'autre app (✓✓ gris)
  ///
  /// In fr, this message translates to:
  /// **'Reçu'**
  String get chatDelivered;

  /// Bouton qui ouvre le panneau d'émojis
  ///
  /// In fr, this message translates to:
  /// **'Émojis'**
  String get chatEmoji;

  /// Bouton qui revient au clavier
  ///
  /// In fr, this message translates to:
  /// **'Clavier'**
  String get chatKeyboard;

  /// Ouvrir tous les émojis pour réagir
  ///
  /// In fr, this message translates to:
  /// **'Autres réactions'**
  String get chatMoreReactions;

  /// Libellé de la ligne des réactions
  ///
  /// In fr, this message translates to:
  /// **'Réactions'**
  String get chatReactions;

  /// Pièce jointe : document
  ///
  /// In fr, this message translates to:
  /// **'Document'**
  String get chatDocument;

  /// Ouvrir un document reçu
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le document'**
  String get chatDocumentOpen;

  /// Erreur d'envoi d'un document trop lourd
  ///
  /// In fr, this message translates to:
  /// **'Document trop lourd : 10 Mo au plus'**
  String get chatDocumentTooLarge;

  /// Erreur d'envoi : type refusé
  ///
  /// In fr, this message translates to:
  /// **'Ce type de document n\'est pas accepté'**
  String get chatDocumentUnsupported;

  /// Aide pendant l'enregistrement d'un vocal
  ///
  /// In fr, this message translates to:
  /// **'Glisse à gauche pour annuler'**
  String get chatVoiceSlideCancel;

  /// Garder le micro ouvert sans appuyer
  ///
  /// In fr, this message translates to:
  /// **'Verrouiller l\'enregistrement'**
  String get chatVoiceLock;

  /// Aide après un simple tap sur le micro
  ///
  /// In fr, this message translates to:
  /// **'Garde le doigt appuyé pour enregistrer'**
  String get chatVoiceHold;

  /// Mettre un vocal en pause
  ///
  /// In fr, this message translates to:
  /// **'Pause'**
  String get chatVoicePause;

  /// Changer la vitesse d'un vocal
  ///
  /// In fr, this message translates to:
  /// **'Vitesse de lecture'**
  String get chatVoiceSpeed;

  /// Vidéo : couper le son
  ///
  /// In fr, this message translates to:
  /// **'Couper le son'**
  String get chatVideoMute;

  /// Vidéo : remettre le son
  ///
  /// In fr, this message translates to:
  /// **'Remettre le son'**
  String get chatVideoUnmute;

  /// Vidéo : pause
  ///
  /// In fr, this message translates to:
  /// **'Pause'**
  String get chatVideoPause;

  /// Ouvrir une photo ou une vidéo en plein écran
  ///
  /// In fr, this message translates to:
  /// **'Plein écran'**
  String get chatFullScreen;

  /// Champ de recherche dans un fil
  ///
  /// In fr, this message translates to:
  /// **'Rechercher dans la conversation'**
  String get chatSearchInThread;

  /// Recherche sans résultat
  ///
  /// In fr, this message translates to:
  /// **'Aucun message trouvé'**
  String get chatSearchEmpty;

  /// Aide de la recherche dans un fil
  ///
  /// In fr, this message translates to:
  /// **'Tape au moins 2 lettres'**
  String get chatSearchHint;

  /// Titre de la galerie d'une conversation
  ///
  /// In fr, this message translates to:
  /// **'Médias et documents'**
  String get chatMediaTitle;

  /// Onglet photos et vidéos
  ///
  /// In fr, this message translates to:
  /// **'Médias'**
  String get chatMediaTab;

  /// Onglet documents
  ///
  /// In fr, this message translates to:
  /// **'Documents'**
  String get chatDocumentsTab;

  /// Galerie vide
  ///
  /// In fr, this message translates to:
  /// **'Aucune photo ni vidéo pour l\'instant'**
  String get chatMediaEmpty;

  /// Onglet documents vide
  ///
  /// In fr, this message translates to:
  /// **'Aucun document pour l\'instant'**
  String get chatDocumentsEmpty;

  /// Filtre : toutes les conversations
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get chatFilterAll;

  /// Filtre : conversations non lues
  ///
  /// In fr, this message translates to:
  /// **'Non lues'**
  String get chatFilterUnread;

  /// Filtre : fils de commande
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get chatFilterOrders;

  /// Liste filtrée vide
  ///
  /// In fr, this message translates to:
  /// **'Aucune conversation ici'**
  String get chatFilterEmpty;

  /// Mention d'un fil de commande épinglé
  ///
  /// In fr, this message translates to:
  /// **'Commande en cours'**
  String get chatPinnedOrder;

  /// Menu de l'en-tête d'une conversation
  ///
  /// In fr, this message translates to:
  /// **'Plus d\'options'**
  String get chatMoreOptions;

  /// Fermer une vue (recherche, plein écran)
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get chatClose;

  /// Bouton : créer un groupe famille (spec 112)
  ///
  /// In fr, this message translates to:
  /// **'Nouveau groupe'**
  String get chatNewGroup;

  /// Titre de la fenêtre de création
  ///
  /// In fr, this message translates to:
  /// **'Créer un groupe famille'**
  String get chatNewGroupTitle;

  /// Champ : nom du groupe
  ///
  /// In fr, this message translates to:
  /// **'Nom du groupe'**
  String get chatGroupNameLabel;

  /// Exemple de nom de groupe
  ///
  /// In fr, this message translates to:
  /// **'Ex. : La famille, Les courses du samedi'**
  String get chatGroupNameHint;

  /// Valider la création
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get chatCreate;

  /// Filtre : groupes
  ///
  /// In fr, this message translates to:
  /// **'Groupes'**
  String get chatFilterGroups;

  /// Nombre de membres d'un groupe
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 membre} other{{count} membres}}'**
  String chatMembers(int count);

  /// Menu : détail du groupe
  ///
  /// In fr, this message translates to:
  /// **'Infos du groupe'**
  String get chatGroupInfo;

  /// Ajouter une personne au groupe
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un proche'**
  String get chatAddMember;

  /// Où trouver le code d'une personne
  ///
  /// In fr, this message translates to:
  /// **'Son code est dans « Entre proches », sous son QR.'**
  String get chatMemberCodeHelp;

  /// Rôle de la créatrice du groupe
  ///
  /// In fr, this message translates to:
  /// **'Administratrice'**
  String get chatAdmin;

  /// Action : retirer un membre
  ///
  /// In fr, this message translates to:
  /// **'Retirer {name} du groupe'**
  String chatRemoveMember(String name);

  /// Action : quitter le groupe
  ///
  /// In fr, this message translates to:
  /// **'Quitter le groupe'**
  String get chatLeaveGroup;

  /// Confirmation avant de quitter
  ///
  /// In fr, this message translates to:
  /// **'Quitter « {name} » ?'**
  String chatLeaveConfirm(String name);

  /// Action : renommer
  ///
  /// In fr, this message translates to:
  /// **'Renommer le groupe'**
  String get chatRenameGroup;

  /// Ajout refusé : code inconnu
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte avec ce code'**
  String get chatMemberUnknown;

  /// Ajout refusé : groupe complet
  ///
  /// In fr, this message translates to:
  /// **'Le groupe est complet (20 personnes)'**
  String get chatGroupFull;

  /// Ouvrir le fil d'une offre groupée
  ///
  /// In fr, this message translates to:
  /// **'Discuter avec le groupe'**
  String get chatGroupDiscuss;

  /// Fil de groupe vide
  ///
  /// In fr, this message translates to:
  /// **'Écris le premier message du groupe.'**
  String get chatEmptyGroup;

  /// Mention d'un fil d'achat groupé
  ///
  /// In fr, this message translates to:
  /// **'Achat groupé'**
  String get chatGroupBuyLabel;

  /// Mention d'un groupe famille
  ///
  /// In fr, this message translates to:
  /// **'Groupe famille'**
  String get chatFamilyLabel;

  /// Notification : message dans un groupe
  ///
  /// In fr, this message translates to:
  /// **'{name} a écrit dans le groupe.'**
  String notifGroupMessageBody(String name);

  /// Notification : ajoutée à un groupe (titre)
  ///
  /// In fr, this message translates to:
  /// **'Nouveau groupe'**
  String get notifGroupAddedTitle;

  /// Notification : ajoutée à un groupe
  ///
  /// In fr, this message translates to:
  /// **'{name} t\'a ajoutée au groupe « {group} ».'**
  String notifGroupAddedBody(String name, String group);
}

class _DymLocalizationsDelegate
    extends LocalizationsDelegate<DymLocalizations> {
  const _DymLocalizationsDelegate();

  @override
  Future<DymLocalizations> load(Locale locale) {
    return SynchronousFuture<DymLocalizations>(lookupDymLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_DymLocalizationsDelegate old) => false;
}

DymLocalizations lookupDymLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return DymLocalizationsEn();
    case 'fr':
      return DymLocalizationsFr();
  }

  throw FlutterError(
    'DymLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
