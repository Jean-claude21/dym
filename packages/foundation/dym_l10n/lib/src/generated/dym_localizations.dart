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
  /// **'Les boutiques de ton quartier, un seul panier, livré en zem.'**
  String get welcomeSlide1Body;

  /// Bienvenue, écran 2
  ///
  /// In fr, this message translates to:
  /// **'Plusieurs boutiques, un seul panier'**
  String get welcomeSlide2Title;

  /// Bienvenue, écran 2
  ///
  /// In fr, this message translates to:
  /// **'Les tomates du marché, le bissap fait maison : tu commandes tout en une fois.'**
  String get welcomeSlide2Body;

  /// Bienvenue, écran 3
  ///
  /// In fr, this message translates to:
  /// **'Cash ou Mobile Money'**
  String get welcomeSlide3Title;

  /// Bienvenue, écran 3
  ///
  /// In fr, this message translates to:
  /// **'Tu paies à la livraison ou par Mobile Money, et tu suis ton zem.'**
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
  /// **'Ton email reste privé : les vendeuses ne le voient pas.'**
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
  /// **'Ton quartier sert à te montrer les boutiques proches et le délai de livraison.'**
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
  /// **'Accès réservé aux comptes Google Workspace de DYM.'**
  String get adminSignInBody;

  /// Bouton admin
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google Workspace'**
  String get adminContinueGoogle;

  /// Note sécurité admin
  ///
  /// In fr, this message translates to:
  /// **'Double authentification obligatoire · Déconnexion après 30 min d\'inactivité'**
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

  /// Étape 5
  ///
  /// In fr, this message translates to:
  /// **'Les quartiers où tu acceptes les commandes. DYM s\'occupe du zem.'**
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
  /// **'Boutiques ouvertes près de toi'**
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

  /// Distance en mètres
  ///
  /// In fr, this message translates to:
  /// **'{meters} m'**
  String distanceMeters(int meters);

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
  /// **'Ta position est hors des zones desservies : cherche ton quartier.'**
  String get zoneOutsideArea;

  /// Filtre de rayon
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get aisleAll;

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
  /// **'{pickups, plural, =0{Retrait sur place} =1{1 ramassage} other{{pickups} ramassages}} · {minutes} min'**
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
  /// **'Livrée vers {time}'**
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

  /// Colonne : boutique
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
