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
  String get authZoneLabel => 'Your address';

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

  @override
  String get navStore => 'Shop';

  @override
  String storeStepLabel(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get storeContinue => 'Continue';

  @override
  String get storeSave => 'Save';

  @override
  String get storeSaveError =>
      'Could not save. Check your connection and try again.';

  @override
  String get storeIncomplete => 'Some information is still missing.';

  @override
  String get storeNameTitle => 'What is your shop called?';

  @override
  String get storeNameSubtitle =>
      'Customers will see this name. You can change it later.';

  @override
  String get storeNameLabel => 'Shop name';

  @override
  String get storeNameInvalid => '2 to 60 characters.';

  @override
  String get storeDescriptionLabel => 'Describe your shop (optional)';

  @override
  String get storeDescriptionHint => 'What you sell, what makes you special';

  @override
  String storeCharCount(int count, int max) {
    return '$count/$max';
  }

  @override
  String get storePreviewTitle => 'What customers see';

  @override
  String storePreviewPlace(String zone) {
    return '$zone · open';
  }

  @override
  String get storeOriginTitle => 'Where do you sell?';

  @override
  String get storeOriginSubtitle =>
      'Every shop has its place on DYM. You can change this later.';

  @override
  String get storeOriginPrivacy =>
      'Your address stays private: customers only see your neighbourhood.';

  @override
  String get storeAddressTitle => 'Where are orders picked up?';

  @override
  String get storeAddressSubtitle => 'The rider collects orders here.';

  @override
  String get storeZoneLabel => 'Your neighbourhood';

  @override
  String get storeZoneVisible => '(visible to customers)';

  @override
  String get storeAddressLabel => 'Pickup address';

  @override
  String get storeAddressHint => 'Street, house, gate…';

  @override
  String get storeLandmarkLabel => 'Landmark';

  @override
  String get storeLandmarkHint => 'E.g. behind the pharmacy';

  @override
  String get storeAddressPrivacy =>
      'Your address stays private: customers only see your neighbourhood. Only the rider of each order receives it.';

  @override
  String get storeCategoryTitle => 'What do you mostly sell?';

  @override
  String get storeCategorySubtitle => 'Your shop will appear in this aisle.';

  @override
  String get storeDeliveryTitle => 'Where do you deliver?';

  @override
  String get storeDeliverySubtitle =>
      'The neighbourhoods you take orders from. DYM handles the moto-taxi.';

  @override
  String get storeSelectAll => 'Select all';

  @override
  String get storePrepTitle => 'Preparation time';

  @override
  String storePrepMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String storePrepHours(int hours) {
    return '$hours h';
  }

  @override
  String get storePickupTitle => 'Customers can pick up';

  @override
  String get storePickupSubtitle => 'Pickup on site, no delivery fee';

  @override
  String get storePaymentTitle => 'How do you want to be paid?';

  @override
  String get storePaymentSubtitle => 'Customers choose from these methods.';

  @override
  String get storePaymentCashHint => 'The rider hands you the money.';

  @override
  String get storePaymentSoon => 'Soon';

  @override
  String get storePaymentSoonHint => 'Coming soon.';

  @override
  String get storePaymentMomoNote =>
      'Mobile Money arrives as soon as DYM enables it in your country.';

  @override
  String get storeHoursTitle => 'When are you open?';

  @override
  String get storeHoursSubtitle =>
      'Orders only arrive during your opening hours.';

  @override
  String get storeHoursClosed => 'Closed';

  @override
  String get storeHoursOpens => 'Opens';

  @override
  String get storeHoursCloses => 'Closes';

  @override
  String get storeHoursSameEveryDay => 'Same hours every open day';

  @override
  String get storeHoursInvalid => 'Opening time must be before closing time.';

  @override
  String get weekday1 => 'Monday';

  @override
  String get weekday2 => 'Tuesday';

  @override
  String get weekday3 => 'Wednesday';

  @override
  String get weekday4 => 'Thursday';

  @override
  String get weekday5 => 'Friday';

  @override
  String get weekday6 => 'Saturday';

  @override
  String get weekday7 => 'Sunday';

  @override
  String get storeOpenAction => 'Open my shop';

  @override
  String get storeOpenedTitle => 'Your shop is open!';

  @override
  String storeNamePlace(String name, String zone) {
    return '$name · $zone';
  }

  @override
  String get storeSummaryName => 'Name and description';

  @override
  String storeSummaryOrigin(String origin) {
    return '$origin · private address';
  }

  @override
  String storeSummaryDelivery(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delivery to $count neighbourhoods',
      one: 'Delivery to 1 neighbourhood',
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
      '1': 'Monday',
      '2': 'Tuesday',
      '3': 'Wednesday',
      '4': 'Thursday',
      '5': 'Friday',
      '6': 'Saturday',
      'other': 'Sunday',
    });
    return '$first to $_temp0, $opens – $closes';
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
      other: '$count days a week',
      one: '1 day a week',
    );
    return '$_temp0';
  }

  @override
  String get storeAddFirstProduct => 'Add my first product';

  @override
  String get storeSeeMine => 'See my shop';

  @override
  String get myStoreTitle => 'My shop';

  @override
  String get myStoreOpen => 'Open';

  @override
  String get myStoreOpenHint => 'Customers can order';

  @override
  String get myStoreClosed => 'Closed';

  @override
  String get myStoreClosedHint => 'Customers can\'t order';

  @override
  String get myStoreSuspended =>
      'Your shop has been suspended by the DYM team. Contact us to reopen it.';

  @override
  String get myStoreRowOrigin => 'Where you sell';

  @override
  String get myStoreAddressPrivate => 'private';

  @override
  String get myStoreRowDelivery => 'Delivery';

  @override
  String myStoreDeliveryValue(int count, String prep) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neighbourhoods',
      one: '1 neighbourhood',
    );
    return '$_temp0 · $prep';
  }

  @override
  String get myStoreRowPayment => 'Payment';

  @override
  String get myStoreRowHours => 'Opening hours';

  @override
  String get myStoreRowCategory => 'Aisle';

  @override
  String get navProducts => 'Products';

  @override
  String get productsTitle => 'My products';

  @override
  String get productsAll => 'All';

  @override
  String get productsArchived => 'Archived';

  @override
  String get productsEmpty => 'No products yet.';

  @override
  String get productsEmptyHint =>
      'Add your first product: a photo is enough to start.';

  @override
  String get productsAdd => 'Add a product';

  @override
  String get productInStock => 'In stock';

  @override
  String get productOutOfStock => 'Out of stock';

  @override
  String get productDraft => 'Draft';

  @override
  String productStockCount(int count) {
    return '$count in stock';
  }

  @override
  String productVariantCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count variants',
      one: '1 variant',
    );
    return '$_temp0';
  }

  @override
  String get productRestore => 'Restore';

  @override
  String get productArchive => 'Archive';

  @override
  String get productDeleteDraft => 'Delete draft';

  @override
  String get productEdit => 'Edit';

  @override
  String productActions(String name) {
    return 'Actions for $name';
  }

  @override
  String get productNewTitle => 'New product';

  @override
  String get productEditTitle => 'Edit product';

  @override
  String get productPhotoSubtitle => 'Take a photo, DYM fills in the details.';

  @override
  String get productTakePhoto => 'Take a photo';

  @override
  String get productChoosePhoto => 'Choose from gallery';

  @override
  String get productAddPhoto => 'Photo';

  @override
  String productPhotoCount(int count, int max) {
    return '$count/$max photos';
  }

  @override
  String get productRemovePhoto => 'Remove photo';

  @override
  String get productPhotoUploading => 'Uploading photo…';

  @override
  String get productPhotoFailed =>
      'The photo could not be uploaded. Try again.';

  @override
  String get productSuggesting => 'DYM is preparing the details…';

  @override
  String get productSuggestedBy => 'Suggested by DYM';

  @override
  String get productSuggestionCheck => 'Check and correct if needed.';

  @override
  String get productSuggestionUnavailable => 'Fill in the details yourself.';

  @override
  String get productNameLabel => 'Name';

  @override
  String get productNameHint => 'E.g. Bissap juice 50 cl';

  @override
  String get productNameInvalid => '2 to 80 characters.';

  @override
  String get productAisleLabel => 'Aisle';

  @override
  String get productDescriptionLabel => 'Description (optional)';

  @override
  String get productPriceTitle => 'Price and stock';

  @override
  String get productPriceLabel => 'Price';

  @override
  String get productPriceInvalid => 'Enter a price above zero.';

  @override
  String get productUnitLabel => 'Unit';

  @override
  String get productVariantsTitle => 'Variants';

  @override
  String get productTrackStock => 'I track my stock';

  @override
  String get productTrackStockHint =>
      'Otherwise the product stays available until you mark it out of stock.';

  @override
  String get productStockLabel => 'Stock';

  @override
  String get productVariantLabel => 'Variant (e.g. 1 L)';

  @override
  String get productVariantPrice => 'Price (optional)';

  @override
  String get productVariantAdd => 'Add a variant';

  @override
  String get productVariantRemove => 'Remove variant';

  @override
  String productVariantNamed(String label) {
    return 'Variant $label';
  }

  @override
  String get productStockDecrease => 'One less';

  @override
  String get productStockIncrease => 'One more';

  @override
  String get productStoreCategoryTitle => 'My shop category';

  @override
  String get productStoreCategoryNew => 'New';

  @override
  String get productPublish => 'Publish product';

  @override
  String get productMissingPhoto => 'Add at least one photo to publish.';

  @override
  String get productVariantLabelsRequired => 'Name each variant.';

  @override
  String get categoriesTitle => 'My categories';

  @override
  String get categoriesSubtitle => 'Organise your products for customers.';

  @override
  String get categoriesNewHint => 'New category';

  @override
  String get categoriesAdd => 'Add';

  @override
  String categoriesProductCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products',
      one: '1 product',
      zero: 'No products',
    );
    return '$_temp0';
  }

  @override
  String get categoriesArchived => 'archived';

  @override
  String get categoriesRestore => 'Restore';

  @override
  String get categoriesRename => 'Rename';

  @override
  String get categoriesArchive => 'Archive';

  @override
  String get categoriesDuplicate => 'This category already exists.';

  @override
  String categoriesMove(String name) {
    return 'Move $name';
  }

  @override
  String get categoriesEmpty => 'No categories yet: create the first one.';

  @override
  String get navAisles => 'Aisles';

  @override
  String homeDeliveredIn(int minutes) {
    return 'Delivered in $minutes min';
  }

  @override
  String get homeSearchHint => 'Search tomatoes, gari, homemade juice…';

  @override
  String get homeOpenStores => 'Shops open near you';

  @override
  String get homeOtherStores => 'Other shops in your area';

  @override
  String get homeNoOpenStore =>
      'No shop is open in your neighbourhood right now.';

  @override
  String get homeAisles => 'Aisles';

  @override
  String homeChangeZone(String zone) {
    return 'Change neighbourhood: $zone';
  }

  @override
  String storeOpenUntil(String time) {
    return 'Open until $time';
  }

  @override
  String get storeOpenNow => 'Open';

  @override
  String get storeClosedNow => 'Closed';

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
  String get zonePickerTitle => 'Where should we deliver?';

  @override
  String get zoneUseLocation => 'Use my location';

  @override
  String get zoneLocating => 'Finding your location…';

  @override
  String get zoneLocationUnavailable =>
      'Location unavailable: search for your neighbourhood.';

  @override
  String zoneSuggestion(String zone) {
    return 'Are you in $zone?';
  }

  @override
  String get zoneConfirm => 'Yes, that\'s right';

  @override
  String get zoneSearchLabel => 'Search your neighbourhood';

  @override
  String get zoneSearchHint => 'Neighbourhood or city';

  @override
  String get zoneNoResult =>
      'No neighbourhood found. Try another name or use your location.';

  @override
  String get zoneOutsideArea =>
      'Your location is outside the areas we serve: search for your neighbourhood.';

  @override
  String get aisleAll => 'All';

  @override
  String get aisleEmpty => 'Nothing in this aisle for your neighbourhood yet.';

  @override
  String get searchHint => 'Search a product or a shop';

  @override
  String get searchClear => 'Clear search';

  @override
  String get searchTabAll => 'All';

  @override
  String get searchTabProducts => 'Products';

  @override
  String get searchTabStores => 'Shops';

  @override
  String get searchFilters => 'Filters';

  @override
  String searchFiltersActive(int count) {
    return 'Filters, $count active';
  }

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
      zero: 'No results',
    );
    return '$_temp0';
  }

  @override
  String get searchEmpty => 'Nothing found. Try another word.';

  @override
  String get searchPrompt => 'Type at least 2 letters.';

  @override
  String get searchLoadMore => 'Show more';

  @override
  String get sortRelevance => 'Relevance';

  @override
  String get sortPriceAsc => 'Price: low to high';

  @override
  String get sortPriceDesc => 'Price: high to low';

  @override
  String get filtersTitle => 'Filters';

  @override
  String get filtersClear => 'Clear';

  @override
  String get filtersSort => 'Sort by';

  @override
  String get filtersOrigin => 'Origin';

  @override
  String get filtersPrice => 'Price';

  @override
  String get filtersMin => 'Min';

  @override
  String get filtersMax => 'Max';

  @override
  String get filtersAisle => 'Aisle';

  @override
  String get filtersAvailable => 'Available only';

  @override
  String get filtersApply => 'Show results';

  @override
  String get filtersPriceInvalid => 'The minimum is above the maximum.';

  @override
  String productFrom(String price) {
    return 'from $price';
  }

  @override
  String get productChoose => 'Choose';

  @override
  String productDeliveryEstimate(int minutes, String zone) {
    return 'Delivered in about $minutes min to $zone';
  }

  @override
  String productDeliveryEstimateShort(int minutes) {
    return 'Delivered in about $minutes min';
  }

  @override
  String productNotServed(String zone) {
    return 'This shop doesn\'t deliver to $zone.';
  }

  @override
  String productPhotoPosition(int index, int count) {
    return 'Photo $index of $count';
  }

  @override
  String get productUnavailableTitle => 'This product is no longer available.';

  @override
  String storePagePickupNote(String zone) {
    return 'Pickup available in $zone · address shared with the rider only';
  }

  @override
  String get storePageProducts => 'Its products';

  @override
  String get storePageEmpty => 'No products published yet.';

  @override
  String get storePageUnavailable => 'This shop is no longer available.';

  @override
  String get shareLabel => 'Share';

  @override
  String get cartTitle => 'Your basket';

  @override
  String cartSummary(int stores, int items) {
    String _temp0 = intl.Intl.pluralLogic(
      stores,
      locale: localeName,
      other: '$stores shops',
      one: '1 shop',
    );
    String _temp1 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items items',
      one: '1 item',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String cartMiniSummary(int stores, int items) {
    String _temp0 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items items',
      one: '1 item',
    );
    String _temp1 = intl.Intl.pluralLogic(
      stores,
      locale: localeName,
      other: '$stores shops',
      one: '1 shop',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get cartView => 'View basket';

  @override
  String get cartAdd => 'Add to basket';

  @override
  String get cartAdded => 'Added to basket';

  @override
  String get cartFreeLead => 'Only';

  @override
  String get cartFreeTrail => 'more for free delivery';

  @override
  String get cartFreeReached => 'Free delivery!';

  @override
  String get cartSubstitutionTitle => 'If a product is missing';

  @override
  String get cartSubstitutionSubtitle =>
      'The shop offers an equivalent at the same price';

  @override
  String get cartDelivery => 'Delivery';

  @override
  String cartDeliveryMeta(int pickups, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      pickups,
      locale: localeName,
      other: '$pickups pickups',
      one: '1 pickup',
      zero: 'Pickup in store',
    );
    return '$_temp0 · $minutes min';
  }

  @override
  String get cartChange => 'Change';

  @override
  String get cartPayment => 'Payment';

  @override
  String get cartSubtotal => 'Subtotal';

  @override
  String get cartTotal => 'Total';

  @override
  String cartOrder(String total) {
    return 'Order · $total';
  }

  @override
  String get cartEmptyTitle => 'Your basket is empty';

  @override
  String get cartEmptyMessage => 'Add products from the shops open near you.';

  @override
  String get cartBrowse => 'See the shops';

  @override
  String get cartRemove => 'Remove';

  @override
  String get cartIssueUnavailable => 'Out of stock';

  @override
  String cartIssueStock(int count) {
    return 'Only $count left';
  }

  @override
  String get cartIssuePriceChanged => 'Price changed';

  @override
  String get cartIssueClosed => 'Closed now';

  @override
  String get cartIssueSuspended => 'Shop unavailable';

  @override
  String get cartIssueNotDelivered =>
      'Doesn\'t deliver to your address: choose pickup or another address';

  @override
  String get cartIssuePickupUnavailable => 'This shop doesn\'t offer pickup';

  @override
  String get cartIssuePaymentNotAccepted => 'Payment not accepted by this shop';

  @override
  String get cartBlocked => 'Fix the flagged items to order.';

  @override
  String get cartUnavailable => 'This product is no longer available.';

  @override
  String get cartOtherCountry =>
      'This product is from another country than your basket.';

  @override
  String get orderErrorAddressRequired => 'Choose a delivery address.';

  @override
  String get orderErrorTotalChanged =>
      'Your basket changed: check the new total.';

  @override
  String get orderErrorPaymentUnavailable =>
      'This payment method isn\'t available yet.';

  @override
  String get orderErrorEmpty => 'Your basket is empty.';

  @override
  String get deliveryTitle => 'Delivery';

  @override
  String get deliveryWhere => 'Where should we deliver?';

  @override
  String get deliveryAddAddress => 'Add an address';

  @override
  String get deliveryModes => 'Mode per shop';

  @override
  String get deliveryModeDelivery => 'Delivery';

  @override
  String get deliveryModePickup => 'I\'ll pick up';

  @override
  String get deliveryConfirm => 'Confirm delivery';

  @override
  String get deliveryNoAddress => 'Add an address to get delivered.';

  @override
  String get addressesTitle => 'My addresses';

  @override
  String get addressDefault => 'Default';

  @override
  String get addressPositionSaved => 'Location saved';

  @override
  String get addressSetDefault => 'Make default';

  @override
  String get addressEdit => 'Edit';

  @override
  String get addressDelete => 'Delete';

  @override
  String get addressMenu => 'Address options';

  @override
  String get addressesEmptyTitle => 'No address yet';

  @override
  String get addressesEmptyMessage =>
      'Add your address to get delivered faster.';

  @override
  String get addressKindHome => 'Home';

  @override
  String get addressKindWork => 'Work';

  @override
  String get addressKindOther => 'Other';

  @override
  String get addressNewTitle => 'New address';

  @override
  String get addressEditTitle => 'Edit address';

  @override
  String get addressWhere => 'Where?';

  @override
  String get addressLabel => 'Address name (optional)';

  @override
  String get addressLandmark => 'Landmark';

  @override
  String get addressLandmarkHint => 'E.g. blue gate after the pharmacy';

  @override
  String get addressLandmarkInvalid =>
      'Describe a landmark (3 to 200 characters)';

  @override
  String get addressPhone => 'Phone for delivery';

  @override
  String get addressPhoneInvalid => 'Invalid phone number';

  @override
  String get addressMakeDefault => 'Default address';

  @override
  String get addressSave => 'Save address';

  @override
  String get orderSentTitle => 'Order sent!';

  @override
  String get orderSentSubtitle =>
      'The sellers will accept it. We\'ll let you know.';

  @override
  String get orderPending => 'Waiting for acceptance';

  @override
  String orderItems(int items) {
    String _temp0 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String orderDeliveryTo(String place) {
    return 'Delivery: $place';
  }

  @override
  String get orderBackHome => 'Back to home';

  @override
  String get cartAddShort => 'Add';
}
