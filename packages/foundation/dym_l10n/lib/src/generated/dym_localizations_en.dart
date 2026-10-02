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

  @override
  String get welcomeSkip => 'Skip';

  @override
  String get welcomeSlide1Title =>
      'Your neighbourhood market, delivered to you';

  @override
  String get welcomeSlide1Body =>
      'Your neighbourhood shops, one basket, delivered by zem.';

  @override
  String get welcomeSlide2Title => 'Many shops, one basket';

  @override
  String get welcomeSlide2Body =>
      'Market tomatoes, homemade bissap: order everything at once.';

  @override
  String get welcomeSlide3Title => 'Cash or Mobile Money';

  @override
  String get welcomeSlide3Body =>
      'Pay on delivery or by Mobile Money, and follow your zem.';

  @override
  String welcomePage(int current, int total) {
    return 'Screen $current of $total';
  }

  @override
  String get authContinueGoogle => 'Continue with Google';

  @override
  String get authContinueEmail => 'Continue with my email';

  @override
  String get authLegal =>
      'By continuing, you accept the terms of use and the privacy policy.';

  @override
  String get authBack => 'Back';

  @override
  String get authEmailTitle => 'Your email';

  @override
  String get authEmailSubtitle =>
      'We\'ll send you a 6-digit code. No password to remember.';

  @override
  String get authEmailLabel => 'Email address';

  @override
  String get authEmailValid => 'Valid address';

  @override
  String get authEmailInvalid => 'Check your email address';

  @override
  String get authEmailPrivacy =>
      'Your email stays private: sellers never see it.';

  @override
  String get authSendCode => 'Get my code';

  @override
  String get authCodeTitle => 'Enter the code';

  @override
  String authCodeSentTo(String email) {
    return 'Sent to $email';
  }

  @override
  String get authChangeEmail => 'Change';

  @override
  String get authCodeLabel => '6-digit code';

  @override
  String authResendIn(int seconds) {
    return 'Resend the code in $seconds s';
  }

  @override
  String get authResend => 'Resend the code';

  @override
  String get authCodeTip =>
      'Tip: the code arrives in under a minute. Check your spam folder too.';

  @override
  String get authCodeWrong =>
      'This code doesn\'t work. Check it or ask for a new one.';

  @override
  String get authProfileTitle => 'Welcome to DYM!';

  @override
  String get authProfileSubtitle => 'Two questions and you\'re in.';

  @override
  String get authFirstNameLabel => 'Your first name';

  @override
  String get authFirstNameInvalid =>
      'Enter your first name (40 characters max)';

  @override
  String get authPhotoOptional => 'Photo (optional)';

  @override
  String get authZoneLabel => 'Your neighbourhood';

  @override
  String get authZoneHint =>
      'Your neighbourhood lets us show nearby shops and the delivery time.';

  @override
  String get authZoneRequired => 'Choose your neighbourhood';

  @override
  String get authStart => 'Let\'s go';

  @override
  String get errorOffline => 'No connection. Check your network and try again.';

  @override
  String get errorGeneric => 'Something went wrong. Try again in a moment.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get retry => 'Try again';

  @override
  String get accountTitle => 'Me';

  @override
  String get accountAddresses => 'My addresses';

  @override
  String get accountNotifications => 'Notifications';

  @override
  String accountLanguage(String language) {
    return 'Language · $language';
  }

  @override
  String get languageName => 'English';

  @override
  String get accountHelp => 'Help and contact';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountDelete => 'Delete my account';

  @override
  String get accountDeleteTitle => 'Delete your account?';

  @override
  String get accountDeleteBody =>
      'Your profile, addresses and history will be erased. Ongoing orders must be delivered or cancelled first. This cannot be undone.';

  @override
  String get accountDeleteConfirm => 'Delete permanently';

  @override
  String get cancel => 'Cancel';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get vendorWelcomeBody =>
      'Your shop, your orders, your cash. At the market, at home or in your shop.';

  @override
  String get vendorPoint1 => 'Publish a product in under a minute';

  @override
  String get vendorPoint2 => 'Get clear orders, no DMs';

  @override
  String get vendorPoint3 => 'Get paid in cash or Mobile Money';

  @override
  String get vendorNextStep => 'Your account is ready. Next step: your shop.';

  @override
  String homeHello(String name) {
    return 'Hello $name!';
  }

  @override
  String get adminSignInTitle => 'Team sign-in';

  @override
  String get adminSignInBody => 'Restricted to DYM Google Workspace accounts.';

  @override
  String get adminContinueGoogle => 'Continue with Google Workspace';

  @override
  String get adminSecurityNote =>
      'Two-factor authentication required · Signed out after 30 min of inactivity';

  @override
  String get adminAuditNote => 'Every action is recorded in the audit log.';

  @override
  String get adminAccessDenied =>
      'Restricted to the DYM team. This account has no admin rights.';

  @override
  String get adminGoogleUnavailable =>
      'Google sign-in is not configured for this environment.';

  @override
  String get adminSignedOutInactive =>
      'You were signed out after 30 minutes of inactivity.';
}
