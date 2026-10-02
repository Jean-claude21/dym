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
  /// **'Ton quartier'**
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
