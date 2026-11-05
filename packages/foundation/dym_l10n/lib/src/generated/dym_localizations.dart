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
  /// **'Environnement : {name}'**
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
