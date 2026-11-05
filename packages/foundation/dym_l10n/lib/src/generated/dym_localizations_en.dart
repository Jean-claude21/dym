// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'dym_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class DymLocalizationsEn extends DymLocalizations {
  DymLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appNameClient => 'DYM';

  @override
  String get appNameVendor => 'DYM Seller';

  @override
  String get appNameAdmin => 'DYM Admin';

  @override
  String get tagline => 'The market near you, delivered to your door';

  @override
  String get vendorTagline => 'Your shop, your orders, your cash';

  @override
  String get adminTagline => 'Resolve every incident in under an hour';

  @override
  String get startupPreparing => 'Getting ready…';

  @override
  String environmentLabel(String name) {
    return 'Environment: $name';
  }

  @override
  String get configErrorTitle => 'Missing configuration';

  @override
  String get configErrorMessage =>
      'This version of the app is not configured. Install the official version.';

  @override
  String get navHome => 'Home';

  @override
  String get navOrders => 'Orders';

  @override
  String get navStores => 'Shops';

  @override
  String get navSettings => 'Settings';
}
