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
  String get adminSignInBody =>
      'DYM team only: get a code on your admin email.';

  @override
  String get adminContinueGoogle => 'Continue with Google';

  @override
  String get adminSecurityNote =>
      'Team access only · Signed out after 30 min of inactivity';

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
  String get myStoreClosedByHours => 'Closed for now';

  @override
  String get myStoreClosedByHoursHint =>
      'Outside your hours: customers can order when you reopen';

  @override
  String get productStoreClosed =>
      'This store is closed for now. You can order when it reopens.';

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
  String get orderErrorOwnStore => 'You can\'t order from your own store.';

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

  @override
  String get paymentTitle => 'Payment';

  @override
  String get paymentWaitingTitle => 'Waiting for payment';

  @override
  String get paymentWaitingBody =>
      'Confirm the payment on the page that just opened, then come back here.';

  @override
  String get paymentAmount => 'Amount';

  @override
  String get paymentReference => 'Reference';

  @override
  String get paymentChecking => 'Checking automatically…';

  @override
  String get paymentOpenPage => 'Open the payment page';

  @override
  String get paymentPayOnDeliveryInstead => 'Pay on delivery instead';

  @override
  String get paymentFailedTitle => 'The payment didn\'t go through';

  @override
  String get paymentFailedBody =>
      'Nothing was charged. Your order is kept: try again or pay on delivery.';

  @override
  String get paymentRetry => 'Try the payment again';

  @override
  String get paymentPayOnDelivery => 'Pay on delivery';

  @override
  String get paymentConfirmed => 'Payment confirmed';

  @override
  String get paymentCashOnDelivery => 'Cash on delivery';

  @override
  String get paymentCashNotAccepted =>
      'A shop doesn\'t accept payment on delivery.';

  @override
  String get paymentOpenFailed => 'Couldn\'t open the payment page.';

  @override
  String get ordersEmptyTitle => 'No orders yet';

  @override
  String get ordersEmptyMessage => 'Paid and cash orders show up here.';

  @override
  String vendorOrderOf(String name) {
    return 'Order from $name';
  }

  @override
  String vendorOrderReceivedAt(String time) {
    return 'Received at $time';
  }

  @override
  String get vendorPaidTitle => 'Payment confirmed';

  @override
  String get vendorPaidBody => 'You can prepare the order.';

  @override
  String get vendorCashTitle => 'Cash on delivery';

  @override
  String vendorCashBody(String amount) {
    return 'Collect $amount when handing over the order.';
  }

  @override
  String get vendorItems => 'Items';

  @override
  String get vendorPayment => 'Payment';

  @override
  String get vendorPaymentMethod => 'Method';

  @override
  String get vendorPaymentDate => 'Date';

  @override
  String get vendorDelivery => 'Delivery';

  @override
  String get vendorPickup => 'Pickup in store';

  @override
  String vendorLandmark(String landmark) {
    return 'Landmark: $landmark';
  }

  @override
  String get vendorCall => 'Call';

  @override
  String vendorQuantity(int count) {
    return '× $count';
  }

  @override
  String get orderStatusPending => 'Waiting';

  @override
  String get orderStatusAccepted => 'Accepted';

  @override
  String get orderStatusPreparing => 'Being prepared';

  @override
  String get orderStatusReady => 'Ready';

  @override
  String get orderStatusOutForDelivery => 'On the way';

  @override
  String get orderStatusDelivered => 'Delivered';

  @override
  String get orderStatusCollected => 'Picked up';

  @override
  String get orderStatusRefused => 'Declined';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String get ordersMineTitle => 'My orders';

  @override
  String get ordersActive => 'In progress';

  @override
  String get ordersDone => 'Completed';

  @override
  String get ordersMineEmptyMessage => 'Your orders show up here.';

  @override
  String orderEtaAt(String time) {
    return 'Delivered around $time';
  }

  @override
  String orderPickupAt(String time) {
    return 'Ready around $time';
  }

  @override
  String orderOn(String date) {
    return 'On $date';
  }

  @override
  String get trackTitle => 'Order tracking';

  @override
  String get trackConfirmed => 'Confirmed';

  @override
  String get trackPrepared => 'Prepared';

  @override
  String trackArrives(String time) {
    return 'Arrives around $time';
  }

  @override
  String trackReadyAt(String time) {
    return 'Ready around $time';
  }

  @override
  String get trackPayOnDelivery => 'To pay on delivery';

  @override
  String trackCashAmount(String amount) {
    return '$amount in cash';
  }

  @override
  String get trackCancel => 'Cancel the order';

  @override
  String get trackCancelTitle => 'Cancel the order?';

  @override
  String get trackCancelBody =>
      'The shop will be told. The order can\'t be restored.';

  @override
  String get trackCancelKeep => 'Keep the order';

  @override
  String trackRefused(String reason) {
    return 'Declined by the shop: $reason';
  }

  @override
  String get trackCancelledByYou => 'You cancelled this order.';

  @override
  String get trackRefundDue => 'A refund is on its way.';

  @override
  String get orderStatusChanged =>
      'The order changed: it has just been updated.';

  @override
  String get reasonOutOfStock => 'Out of stock';

  @override
  String get reasonTooBusy => 'Shop too busy';

  @override
  String get reasonAreaNotServed => 'Can\'t deliver to this area';

  @override
  String get reasonOther => 'Other reason';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsReadAll => 'Mark all read';

  @override
  String get notificationsEmptyTitle => 'No notifications';

  @override
  String get notificationsEmptyMessage =>
      'You\'ll be told at every step of your orders.';

  @override
  String notificationsUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread',
      one: '1 unread',
    );
    return '$_temp0';
  }

  @override
  String get notifNewOrderTitle => 'New order!';

  @override
  String notifNewOrderBody(String name) {
    return '$name placed an order.';
  }

  @override
  String get notifCancelledByClientTitle => 'Order cancelled';

  @override
  String get notifCancelledByClientBody => 'The customer cancelled the order.';

  @override
  String get notifAcceptedTitle => 'Order accepted';

  @override
  String notifAcceptedBody(String store) {
    return '$store accepted your order.';
  }

  @override
  String get notifRefusedTitle => 'Order declined';

  @override
  String notifRefusedBody(String store) {
    return '$store can\'t fulfil your order.';
  }

  @override
  String notifPreparingBody(String store) {
    return '$store is preparing your order.';
  }

  @override
  String get notifReadyTitle => 'Order ready';

  @override
  String notifReadyBody(String store) {
    return 'Your order at $store is ready.';
  }

  @override
  String get notifOnTheWayBody => 'Your order is on its way.';

  @override
  String get notifDeliveredBody => 'Enjoy! Tell us if everything is fine.';

  @override
  String get notifPaidBody => 'Your order is paid.';

  @override
  String get notifPaymentFailedTitle => 'Payment failed';

  @override
  String get notifPaymentFailedBody =>
      'Your payment didn\'t go through: try again or pay on delivery.';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String get timeYesterday => 'yesterday';

  @override
  String timeDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get notifSettingsTitle => 'Notification settings';

  @override
  String get notifSettingsIntro => 'Choose what DYM can send to this phone.';

  @override
  String get prefOrdersTitle => 'My order updates';

  @override
  String get prefOrdersBody =>
      'Accepted, being prepared, on the way, delivered';

  @override
  String get prefPaymentsTitle => 'Payments';

  @override
  String get prefPaymentsBody => 'Payment confirmed or failed';

  @override
  String get prefMessagesTitle => 'Messages from shops';

  @override
  String get prefMessagesBody => 'Replies from sellers';

  @override
  String get prefPromotionsTitle => 'Deals';

  @override
  String get prefPromotionsBody => 'Promotions from my shops';

  @override
  String get notifSettingsNote =>
      'Important notifications stay visible in the app.';

  @override
  String get vendorScopeNew => 'New';

  @override
  String get vendorScopeActive => 'In progress';

  @override
  String get vendorScopeDone => 'Completed';

  @override
  String get vendorReplyQuickly => 'Reply quickly: the customer is waiting.';

  @override
  String get vendorYouCollect => 'You collect';

  @override
  String get vendorAccept => 'Accept';

  @override
  String get vendorRefuse => 'Decline';

  @override
  String get vendorRefuseTitle => 'Decline the order?';

  @override
  String get vendorRefuseBody => 'The customer will be told. Choose a reason.';

  @override
  String get vendorRefuseNote => 'Add details (optional)';

  @override
  String get vendorRefuseConfirm => 'Decline the order';

  @override
  String get vendorStartPreparing => 'Start preparing';

  @override
  String get vendorMarkReady => 'Mark ready';

  @override
  String get vendorOutForDelivery => 'Out for delivery';

  @override
  String get vendorMarkDelivered => 'Mark delivered';

  @override
  String get vendorMarkCollected => 'Mark picked up';

  @override
  String vendorConfirmCash(String amount) {
    return 'I collected $amount';
  }

  @override
  String get vendorCashCollected => 'Cash collected';

  @override
  String get vendorNewOrderAlert => 'New order received';

  @override
  String get vendorRefundDue => 'Refund to be made by the DYM team.';

  @override
  String vendorOrderRefusedReason(String reason) {
    return 'Declined: $reason';
  }

  @override
  String get disputeReport => 'Report a problem';

  @override
  String get disputeWhatHappened => 'What happened?';

  @override
  String get disputeTellUs => 'Tell us more';

  @override
  String get disputeDescriptionInvalid =>
      'Describe the problem (3 to 500 characters)';

  @override
  String get disputeWhoAnswers => 'The shop and the DYM team will reply.';

  @override
  String get disputeSend => 'Send the report';

  @override
  String get disputeReasonMissingItem => 'An item is missing';

  @override
  String get disputeReasonWrongItem => 'Wrong item';

  @override
  String get disputeReasonDamaged => 'Damaged item';

  @override
  String get disputeReasonQuality => 'Disappointing quality';

  @override
  String get disputeReasonNotDelivered => 'Order never received';

  @override
  String get disputeReasonOther => 'Other';

  @override
  String get disputeMine => 'My report';

  @override
  String get disputeOpenStatus => 'Being handled';

  @override
  String get disputeResolvedStatus => 'Handled';

  @override
  String get disputeYou => 'You';

  @override
  String get disputeTeam => 'DYM team';

  @override
  String get disputeCustomer => 'Customer';

  @override
  String get disputeWriteMessage => 'Write a message…';

  @override
  String get disputeSendMessage => 'Send';

  @override
  String disputeRefunded(String amount) {
    return 'Refund of $amount decided.';
  }

  @override
  String get disputeNoAction => 'Report closed without a refund.';

  @override
  String get disputeAlreadyOpen => 'A report is already open for this order.';

  @override
  String get disputeNotAllowed => 'This order can no longer be reported.';

  @override
  String disputeVendorBanner(String reason) {
    return 'Problem reported: $reason';
  }

  @override
  String get disputeReply => 'Reply';

  @override
  String get disputeReplyHint => 'Your reply to the customer';

  @override
  String get disputeSeeThread => 'See the report';

  @override
  String disputeMessageLine(String author, String body) {
    return '$author: $body';
  }

  @override
  String get notifDisputeRepliedTitle => 'Reply to your report';

  @override
  String notifDisputeRepliedBody(String author) {
    return '$author replied to you.';
  }

  @override
  String get notifDisputeResolvedTitle => 'Report handled';

  @override
  String get notifDisputeResolvedBody => 'The DYM team handled your report.';

  @override
  String get adminActive => 'Active';

  @override
  String get adminAddCategory => 'Add a category';

  @override
  String get adminAddCity => 'Add a city';

  @override
  String get adminAddPaymentMethod => 'Add a payment method';

  @override
  String get adminAddZone => 'Add an area';

  @override
  String get adminAfter => 'After';

  @override
  String get adminAll => 'All';

  @override
  String get adminAuditAction => 'Action';

  @override
  String get adminAuditEntity => 'Entity';

  @override
  String get adminAuditSearch => 'Search (action, entity, reason)';

  @override
  String get adminAuditSubtitle => 'Every team action, append-only.';

  @override
  String get adminAuditTitle => 'Audit log';

  @override
  String adminAuthorClient(String name) {
    return '$name (customer)';
  }

  @override
  String adminAuthorVendor(String name) {
    return '$name (seller)';
  }

  @override
  String adminBaseFee(String symbol) {
    return 'Base fee $symbol';
  }

  @override
  String get adminBefore => 'Before';

  @override
  String get adminBeforeAfter => 'Before / after';

  @override
  String get adminCancellation => 'Cancellation';

  @override
  String get adminCash => 'Cash';

  @override
  String get adminCityName => 'City name';

  @override
  String get adminClose => 'Close';

  @override
  String get adminCloseNoAction => 'Close without action';

  @override
  String get adminCountryChecklist =>
      'Before activating a country: at least one city with areas, a payment method and delivery fees.';

  @override
  String get adminDecision => 'Decision';

  @override
  String get adminDeliveryMinutes => 'Delivery time (minutes)';

  @override
  String adminDeliveryMinutesValue(int n) {
    return 'Delivery in about $n min';
  }

  @override
  String get adminEditCategory => 'Edit the category';

  @override
  String get adminEditCity => 'Edit the city';

  @override
  String get adminEditCommission => 'Change the commission';

  @override
  String get adminEditFees => 'Change delivery fees';

  @override
  String get adminEditStore => 'Correct the details';

  @override
  String get adminEditZone => 'Edit the area';

  @override
  String get adminExecute => 'Execute';

  @override
  String adminExtraPickupFee(String symbol) {
    return 'Extra pickup $symbol';
  }

  @override
  String adminFreeThreshold(String symbol) {
    return 'Free from $symbol';
  }

  @override
  String get adminGeographyHelp =>
      'Enter the country\'s cities and areas: customers and sellers find them by search or location.';

  @override
  String get adminInternalNote => 'Internal note (team only)';

  @override
  String get adminLabelEn => 'English label';

  @override
  String get adminLabelFr => 'French label';

  @override
  String get adminLatitude => 'Latitude (optional)';

  @override
  String get adminLongitude => 'Longitude (optional)';

  @override
  String get adminMarkCashRefunded => 'Mark as handed over';

  @override
  String get adminNavAudit => 'Log';

  @override
  String get adminNavDisputes => 'Disputes';

  @override
  String get adminNavFinance => 'Finance';

  @override
  String get adminNoAudit => 'No actions.';

  @override
  String get adminNoCities => 'No cities: add the first one.';

  @override
  String get adminNoCommission => 'No commission: 0%.';

  @override
  String get adminNoDisputes => 'No open disputes.';

  @override
  String get adminNoFees => 'No delivery fees.';

  @override
  String get adminNoHistory => 'No team actions.';

  @override
  String get adminNoParent => 'None (main category)';

  @override
  String get adminNoPaymentMethods => 'No payment methods.';

  @override
  String get adminNoPendingPayments => 'No pending payments.';

  @override
  String get adminNoRefunds => 'No refunds.';

  @override
  String get adminNoStores => 'No shops.';

  @override
  String get adminOffersPickup => 'In-store pickup';

  @override
  String get adminOnlinePayment => 'Online payment';

  @override
  String get adminOpenDisputes => 'Open disputes';

  @override
  String get adminOpenDisputesCount => 'Open disputes';

  @override
  String get adminOpenedOn => 'Open since';

  @override
  String get adminOperator => 'Operator (optional)';

  @override
  String get adminOrders7d => 'Orders · 7 d';

  @override
  String get adminOver24h => '> 24 h';

  @override
  String adminPaidWith(String amount, String method) {
    return '$amount by $method';
  }

  @override
  String get adminParentCategory => 'Parent category';

  @override
  String get adminPendingPayments => 'Pending payments';

  @override
  String get adminPrepMinutes => 'Preparation (minutes)';

  @override
  String get adminProvider => 'Provider';

  @override
  String get adminPublishedProducts => 'Published products';

  @override
  String get adminRatePercent => 'Rate (%)';

  @override
  String adminRateValue(String rate) {
    return '$rate%';
  }

  @override
  String get adminReactivateStore => 'Reactivate the shop';

  @override
  String adminRefundAll(String amount) {
    return 'Refund everything ($amount)';
  }

  @override
  String get adminRefundAmount => 'Amount';

  @override
  String adminRefundMax(String amount) {
    return '$amount at most';
  }

  @override
  String get adminRefundMethod => 'Method';

  @override
  String get adminRefundPart => 'Refund part';

  @override
  String get adminRefundReason => 'Reason';

  @override
  String get adminRefunds => 'Refunds';

  @override
  String get adminRefundsDone => 'Done';

  @override
  String get adminRefundsFailed => 'Failed';

  @override
  String get adminReplyHint => 'Write to the customer and seller';

  @override
  String get adminRequested => 'Requested';

  @override
  String get adminResolve => 'Resolve the dispute';

  @override
  String get adminRetry => 'Retry';

  @override
  String get adminSales7d => 'Sales · 7 d';

  @override
  String get adminSave => 'Save';

  @override
  String get adminSettingsSubtitle =>
      'Opening a country is a configuration task.';

  @override
  String get adminStoreActive => 'Active';

  @override
  String get adminStoreDescription => 'Description';

  @override
  String get adminStoreDraft => 'Draft';

  @override
  String get adminStoreName => 'Shop name';

  @override
  String get adminStoreSearch => 'Shop or seller name';

  @override
  String get adminStoreSuspended => 'Suspended';

  @override
  String adminStoresActive(int n) {
    return 'Active · $n';
  }

  @override
  String adminStoresDraft(int n) {
    return 'Drafts · $n';
  }

  @override
  String adminStoresSuspended(int n) {
    return 'Suspended · $n';
  }

  @override
  String get adminSuspendHelp =>
      'Suspending closes the shop and needs a reason.';

  @override
  String get adminSuspendStore => 'Suspend the shop';

  @override
  String get adminTabCategories => 'Categories';

  @override
  String get adminTabCommission => 'Commission';

  @override
  String get adminTabCountries => 'Countries';

  @override
  String get adminTabFees => 'Delivery fees';

  @override
  String get adminTabGeography => 'Cities and areas';

  @override
  String get adminTeamHistory => 'Team action history';

  @override
  String get adminWarnVendor => 'Warn the seller';

  @override
  String get adminWholeCountry => 'Whole country';

  @override
  String get adminZoneName => 'Area name';

  @override
  String adminZoneStores(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n shops',
      one: '1 shop',
      zero: 'No shops',
    );
    return '$_temp0';
  }

  @override
  String get adminPaid => 'Paid';

  @override
  String get adminAwaitingPayment => 'Awaiting payment';

  @override
  String get adminActorClient => 'Customer';

  @override
  String get adminActorVendor => 'Seller';

  @override
  String get adminActorTeam => 'Team';

  @override
  String get adminActorSystem => 'System';

  @override
  String get adminAuditSignedIn => 'Sign-in';

  @override
  String get adminAuditStatusForced => 'Status forced';

  @override
  String get adminAuditOrderCancelled => 'Order cancelled';

  @override
  String get adminAuditCourierAssigned => 'Courier assigned';

  @override
  String get adminAuditDisputeResolved => 'Dispute resolved';

  @override
  String get adminAuditRefundSucceeded => 'Refund done';

  @override
  String get adminAuditRefundFailed => 'Refund failed';

  @override
  String get adminAuditStoreSuspended => 'Shop suspended';

  @override
  String get adminAuditStoreReactivated => 'Shop reactivated';

  @override
  String get adminAuditStoreUpdated => 'Details corrected';

  @override
  String get adminAuditCountryActivated => 'Country activated';

  @override
  String get adminAuditCountryDeactivated => 'Country deactivated';

  @override
  String get adminAuditCity => 'City changed';

  @override
  String get adminAuditZone => 'Area changed';

  @override
  String get adminAuditPaymentMethod => 'Payment method changed';

  @override
  String get adminAuditCommission => 'Commission changed';

  @override
  String get adminAuditDeliveryFee => 'Delivery fees changed';

  @override
  String get adminAuditCategory => 'Category changed';

  @override
  String get adminAuditRole => 'Role changed';

  @override
  String get adminEntityOrder => 'Order';

  @override
  String get adminEntityDispute => 'Dispute';

  @override
  String get adminEntityRefund => 'Refund';

  @override
  String get adminEntityStore => 'Shop';

  @override
  String get adminEntityCountry => 'Country';

  @override
  String get adminEntityCity => 'City';

  @override
  String get adminEntityZone => 'Area';

  @override
  String get adminEntityPaymentMethod => 'Payment method';

  @override
  String get adminEntityCategory => 'Category';

  @override
  String get adminEntityUser => 'Team';

  @override
  String get adminOrderClosed => 'This order is closed: use a dispute.';

  @override
  String get adminPaymentPendingRefusal =>
      'This order\'s payment isn\'t confirmed yet.';

  @override
  String get adminReasonRequired => 'Give a reason (at least 3 characters).';

  @override
  String get adminCourierNotAllowed =>
      'A courier can only be assigned to an active delivery.';

  @override
  String get adminDisputeClosed => 'This dispute is already resolved.';

  @override
  String get adminRefundAmountInvalid =>
      'Invalid amount: between 1 and the order total.';

  @override
  String get adminRefundNotPending =>
      'This refund is already in progress or done.';

  @override
  String get adminCountryNotReady =>
      'This country isn\'t ready: complete what\'s missing.';

  @override
  String get adminProviderInactive => 'This payment provider is inactive.';

  @override
  String get adminStoreStatusUnchanged => 'The shop already has this status.';

  @override
  String adminMinutes(int n) {
    return '$n min';
  }

  @override
  String adminHoursMinutes(int h, String m) {
    return '$h h $m';
  }

  @override
  String get adminSelectItem => 'Pick an item in the list.';

  @override
  String get adminReasonLabel => 'Reason (required)';

  @override
  String get adminOrderSearch => 'Order no., customer or shop';

  @override
  String get adminFilterAll => 'All';

  @override
  String get adminFilterActive => 'In progress';

  @override
  String adminFilterStuck(int n) {
    return 'Stuck · $n';
  }

  @override
  String get adminFilterDelivered => 'Delivered';

  @override
  String get adminFilterClosed => 'Cancelled or declined';

  @override
  String get adminNoOrders => 'No orders.';

  @override
  String get adminColNumber => 'No.';

  @override
  String get adminColStore => 'Shop';

  @override
  String get adminColCustomer => 'Customer';

  @override
  String get adminColStatus => 'Status';

  @override
  String get adminColPayment => 'Payment';

  @override
  String get adminColAmount => 'Amount';

  @override
  String get adminColSince => 'Since';

  @override
  String get adminStuck => 'Stuck';

  @override
  String adminPageRange(int from, int to, int total) {
    return '$from to $to of $total';
  }

  @override
  String get adminPrevious => 'Previous page';

  @override
  String get adminNext => 'Next page';

  @override
  String get adminFirstName => 'First name';

  @override
  String get adminPhone => 'Phone';

  @override
  String get adminAddress => 'Address';

  @override
  String adminOrderTitle(String reference) {
    return 'Order $reference';
  }

  @override
  String adminStuckSince(String duration) {
    return 'Stuck for $duration';
  }

  @override
  String get adminOpenDispute => 'Open dispute';

  @override
  String get adminActorPayment => 'Payment';

  @override
  String adminPaymentLine(String status, String method, String reference) {
    return '$status ($method, $reference)';
  }

  @override
  String adminCourierLine(String name, String phone) {
    return 'Courier: $name · $phone';
  }

  @override
  String adminRefundLine(String amount, String status) {
    return 'Refund of $amount · $status';
  }

  @override
  String get adminTimeline => 'Timeline';

  @override
  String adminNoStepSince(String duration) {
    return 'No step for $duration';
  }

  @override
  String adminCancelledNote(String reason) {
    return 'Cancelled by the team: $reason';
  }

  @override
  String get adminRefundPending => 'To execute';

  @override
  String get adminRefundProcessing => 'In progress';

  @override
  String get adminRefundSucceeded => 'Done';

  @override
  String get adminRefundFailed => 'Failed';

  @override
  String get adminTotal => 'Total';

  @override
  String adminCancelTitle(String reference) {
    return 'Cancel order $reference?';
  }

  @override
  String get adminCancelRefund => 'Cancel and refund';

  @override
  String get adminCancelOrder => 'Cancel the order';

  @override
  String get adminActions => 'Actions';

  @override
  String get adminForceStatus => 'Force a status';

  @override
  String get adminChooseStatus => 'Choose a status';

  @override
  String get adminApply => 'Apply';

  @override
  String get adminExternalDelivery => 'External delivery';

  @override
  String get adminCourierName => 'Courier name';

  @override
  String get adminAssign => 'Assign';

  @override
  String get adminOrderPlaced => 'Order placed';

  @override
  String get dashboardTitle => 'My day';

  @override
  String get dashboardDay => 'Today';

  @override
  String get dashboardWeek => 'Week';

  @override
  String get dashboardMonth => 'Month';

  @override
  String get dashboardRevenue => 'Collected sales';

  @override
  String get dashboardRevenueExplanation =>
      'Delivered and paid items, excluding delivery, before commission. Refunds are deducted.';

  @override
  String get dashboardToDo => 'To do';

  @override
  String get dashboardEmpty => 'No orders in this period.';

  @override
  String get dashboardOffline => 'Offline: showing the latest figures.';

  @override
  String get dashboardRefreshFailed =>
      'Figures could not be refreshed. Pull down to retry.';

  @override
  String get dashboardRecapHint => 'Your daily recap arrives from 7 pm.';

  @override
  String dashboardOrderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'orders',
      one: 'order',
    );
    return '$_temp0';
  }

  @override
  String dashboardPendingPayments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'payments awaited',
      one: 'payment awaited',
    );
    return '$_temp0';
  }

  @override
  String dashboardNewOrders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new orders',
      one: '1 new order',
      zero: 'No new orders',
    );
    return '$_temp0';
  }

  @override
  String dashboardActiveOrders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders in progress',
      one: '1 order in progress',
      zero: 'No orders in progress',
    );
    return '$_temp0';
  }

  @override
  String dashboardStock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products out of stock',
      one: '1 product out of stock',
      zero: 'No products out of stock',
    );
    return '$_temp0';
  }

  @override
  String dashboardCritical(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count important messages are waiting',
      one: 'A customer is waiting for your reply',
    );
    return '$_temp0';
  }

  @override
  String get dashboardCriticalAction => 'See notifications';

  @override
  String get dashboardNewOrdersHint => 'Customers placed orders';

  @override
  String get dashboardActiveOrdersHint => 'To prepare and deliver';

  @override
  String get dashboardStockHint => 'Restock to keep selling';

  @override
  String get chatMessagesTitle => 'Messages';

  @override
  String chatUnread(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n unread',
      one: '1 unread',
      zero: 'All read',
    );
    return '$_temp0';
  }

  @override
  String get chatEmptyList => 'No conversations yet.';

  @override
  String get chatEmptyThread => 'Write your first message.';

  @override
  String get chatPhoto => 'Photo';

  @override
  String chatProductPreview(String name) {
    return 'Product: $name';
  }

  @override
  String get chatWriteHint => 'Write your message…';

  @override
  String get chatSend => 'Send';

  @override
  String get chatSendPhoto => 'Send a photo';

  @override
  String get chatCamera => 'Take a photo';

  @override
  String get chatGallery => 'Choose from gallery';

  @override
  String get chatShareProduct => 'Share a product';

  @override
  String get chatSearchProducts => 'Search my products';

  @override
  String get chatNoProducts => 'No published products.';

  @override
  String get chatShare => 'Share';

  @override
  String get chatAddToCart => 'Add to cart';

  @override
  String get chatProductUnavailable => 'This product is no longer for sale.';

  @override
  String get chatAttachProduct => 'Attach this product';

  @override
  String get chatDismiss => 'Remove';

  @override
  String get chatSendFailed => 'Message not sent. Try again.';

  @override
  String get chatOffline => 'Offline: showing the latest messages.';

  @override
  String get chatWriteToStore => 'Message the shop';

  @override
  String get chatAskProduct => 'Ask a question';

  @override
  String get chatMyMessages => 'My messages';

  @override
  String get chatStoreUnavailable =>
      'This shop isn\'t accepting messages right now.';

  @override
  String dashboardUnreadMessages(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n unread messages',
      one: '1 unread message',
      zero: 'No unread messages',
    );
    return '$_temp0';
  }

  @override
  String get dashboardUnreadMessagesHint => 'Reply to your customers';

  @override
  String get notifNewMessageTitle => 'New message';

  @override
  String notifNewMessageBody(String sender) {
    return '$sender sent you a message.';
  }

  @override
  String get reorder => 'Order again';

  @override
  String get reorderNothing => 'None of these items are for sale anymore.';

  @override
  String reorderSkipped(String items) {
    return 'No longer for sale: $items';
  }

  @override
  String reviewAverage(String rating) {
    return '$rating/5';
  }

  @override
  String get reviewCommentLabel => 'Tell us in a few words (optional)';

  @override
  String reviewCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n reviews',
      one: '1 review',
      zero: 'No reviews',
    );
    return '$_temp0';
  }

  @override
  String get reviewEditReply => 'Edit my reply';

  @override
  String get reviewExists => 'You already reviewed this order.';

  @override
  String get reviewGive => 'Leave a review';

  @override
  String get reviewLater => 'Later';

  @override
  String get reviewMine => 'My reviews';

  @override
  String reviewMyReply(String reply) {
    return 'Your reply: $reply';
  }

  @override
  String get reviewNone => 'No reviews yet.';

  @override
  String get reviewNoneYet => 'New shop';

  @override
  String get reviewNotAllowed => 'You can leave a review after delivery.';

  @override
  String get reviewPublish => 'Post my review';

  @override
  String get reviewPublishReply => 'Post the reply';

  @override
  String get reviewQuestion => 'How was your order?';

  @override
  String get reviewReplyHint => 'Your reply';

  @override
  String reviewReplyTo(String name) {
    return 'Your reply to $name';
  }

  @override
  String reviewStarsLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String reviewStoreReply(String store, String reply) {
    return 'Reply from $store: $reply';
  }

  @override
  String get reviewStoreTitle => 'Reviews';

  @override
  String get reviewTagFast => 'Fast delivery';

  @override
  String get reviewTagFresh => 'Fresh produce';

  @override
  String get reviewTagFriendly => 'Friendly';

  @override
  String get reviewTagWellPacked => 'Well packed';

  @override
  String reviewThanks(int rating) {
    return 'Thanks for your review ($rating/5)!';
  }

  @override
  String get reviewTitle => 'Your review';

  @override
  String get supportClosed => 'Closed';

  @override
  String get supportInProgress => 'In progress';

  @override
  String get supportMine => 'My requests';

  @override
  String get supportNew => 'New request';

  @override
  String get supportNoOrder => 'None';

  @override
  String get supportNone => 'No requests yet.';

  @override
  String get supportOrder => 'Related order';

  @override
  String get supportPromise => 'The DYM team replies within an hour.';

  @override
  String get supportSend => 'Send';

  @override
  String get supportSent => 'Request sent: we\'ll reply soon.';

  @override
  String get supportSubject => 'Subject';

  @override
  String get supportSubjectAccount => 'My account';

  @override
  String get supportSubjectOrder => 'My order';

  @override
  String get supportSubjectOther => 'Other';

  @override
  String get supportSubjectPayment => 'A payment';

  @override
  String get supportSubjectStore => 'My shop';

  @override
  String get supportDescribe => 'Describe your problem';

  @override
  String reviewSummary(String rating, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n reviews',
      one: '1 review',
    );
    return '$rating/5 · $_temp0';
  }

  @override
  String get adminNavDashboard => 'Dashboard';

  @override
  String get adminNavClients => 'Customers';

  @override
  String get adminNavSupport => 'Support';

  @override
  String get navMore => 'More';

  @override
  String adminPercent(int value) {
    return '$value%';
  }

  @override
  String get adminActiveOrders => 'Active orders';

  @override
  String get adminRevenueLabel => 'Revenue';

  @override
  String get adminPaymentsSucceeded => 'Successful payments · 24 h';

  @override
  String adminPaymentsLastHour(String value) {
    return 'Last hour: $value';
  }

  @override
  String get adminDeliveriesSucceeded => 'Successful deliveries';

  @override
  String get adminStuckOrders => 'Stuck orders';

  @override
  String get adminPendingDisputes => 'Pending disputes';

  @override
  String adminLateDisputes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n overdue > 48 h',
      one: '1 overdue > 48 h',
    );
    return '$_temp0';
  }

  @override
  String get adminOpenTickets => 'Open tickets';

  @override
  String adminLateTickets(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n unanswered > 1 h',
      one: '1 unanswered > 1 h',
    );
    return '$_temp0';
  }

  @override
  String get adminDraftStores => 'Draft shops';

  @override
  String get adminOrders30d => 'Orders · 30 days';

  @override
  String get adminActiveUsers7d => 'Active users · 7 days';

  @override
  String get adminNewSignups => 'New sign-ups';

  @override
  String get adminTopStores => 'Top shops';

  @override
  String get adminTopCategories => 'Top categories';

  @override
  String get adminNoData => 'Nothing for this period.';

  @override
  String adminOrdersCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n orders',
      one: '1 order',
      zero: 'No orders',
    );
    return '$_temp0';
  }

  @override
  String get adminClientSearch => 'First name or email';

  @override
  String get adminNoClients => 'No customers found.';

  @override
  String adminSince(String date) {
    return 'since $date';
  }

  @override
  String get adminSpent => 'Spent';

  @override
  String get adminTickets => 'Help requests';

  @override
  String get adminLastOrders => 'Latest orders';

  @override
  String get adminAddresses => 'Addresses';

  @override
  String get adminReviewsLeft => 'Reviews left';

  @override
  String get adminReadOnlyAudited => 'Read-only view, recorded in the log.';

  @override
  String get adminTicketsOpen => 'Open';

  @override
  String get adminTicketsPending => 'Pending';

  @override
  String get adminTicketsClosed => 'Closed';

  @override
  String get adminNoTickets => 'No requests here.';

  @override
  String get adminOver1h => '> 1 h';

  @override
  String get adminWriteReply => 'Write a reply…';

  @override
  String get adminCloseTicket => 'Close ticket';

  @override
  String get adminTicketInvalid => 'The reply is empty or too long.';

  @override
  String get adminTabFlags => 'Features';

  @override
  String get adminFlagsHelp =>
      'Disabled features stay hidden in the apps. Every change is logged.';

  @override
  String get adminFlagEverywhere => 'All countries';

  @override
  String get adminViewAsVendor => 'View as seller';

  @override
  String get adminDeleteVendor => 'Delete account';

  @override
  String get adminVendorHasOrders =>
      'This shop has orders: suspend it instead.';

  @override
  String get adminOutOfStock => 'Sold out';

  @override
  String adminStock(int n) {
    return 'Stock: $n';
  }

  @override
  String get adminRevenue => 'Revenue';

  @override
  String get adminThisMonth => 'This month';

  @override
  String get adminLastMonth => 'Last month';

  @override
  String get admin30Days => '30 days';

  @override
  String get adminSalesCollected => 'Sales collected';

  @override
  String get adminCommission => 'DYM commission';

  @override
  String get adminVendorNet => 'Seller net';

  @override
  String get adminByStore => 'By shop';

  @override
  String get adminCommissionNote =>
      'Commission computed by the database when the order was placed.';

  @override
  String get adminColSales => 'Sales';

  @override
  String get adminVendors => 'Sellers';

  @override
  String get voiceListening => 'I\'m listening…';

  @override
  String get voiceTranscribing => 'Working on it…';

  @override
  String get voiceDone => 'Got it.';

  @override
  String get voiceNothing =>
      'I didn\'t hear anything. Try again or type your search.';

  @override
  String get voiceStop => 'I\'m done';

  @override
  String get voiceRestart => 'Try again';

  @override
  String get voiceHint =>
      'Speak naturally, for example: “tomatoes and okra for tonight”';

  @override
  String get voiceYouSaid => 'You said: ';

  @override
  String get voiceSearch => 'Search';

  @override
  String get voiceMicDenied =>
      'Microphone access is denied. Allow it in settings or type your search.';

  @override
  String get aiSearchFailed => 'That didn\'t work this time. Type your search.';

  @override
  String get searchHistory => 'History';

  @override
  String get searchHistoryClear => 'Clear';

  @override
  String get searchSuggestions => 'Suggestions';

  @override
  String get photoSearchAnalyzing => 'Looking at your photo…';

  @override
  String get photoSearchNothing =>
      'I couldn\'t recognise a product. Try another photo or type your search.';

  @override
  String get photoTake => 'Take a photo';

  @override
  String get photoFromGallery => 'Choose from gallery';

  @override
  String get photoSearchYourPhoto => 'Your photo';

  @override
  String get photoSearchFrom => 'From your photo:';

  @override
  String get photoSearchEdit => 'Edit';

  @override
  String get photoSearchNew => 'New photo';

  @override
  String get voiceSearchAction => 'Search by voice';

  @override
  String get photoSearchAction => 'Search by photo';

  @override
  String get copilotTitle => 'Tell me what you want to cook';

  @override
  String get copilotEntry =>
      'Tell me what you want to cook, I\'ll build your basket.';

  @override
  String get copilotExample => 'For example: “Okra stew for 4 people tonight”';

  @override
  String get copilotHint => 'Type or speak…';

  @override
  String get copilotSend => 'Send';

  @override
  String get copilotThinking => 'Building your basket…';

  @override
  String get copilotProposal => 'Here\'s the basket I suggest';

  @override
  String copilotMissing(String items) {
    return 'I couldn\'t find: $items';
  }

  @override
  String get copilotNothing => 'I didn\'t find anything for that.';

  @override
  String get copilotUnavailable =>
      'The assistant isn\'t answering right now. Search yourself, it\'s quick.';

  @override
  String get copilotPlusDelivery => '+ delivery';

  @override
  String get copilotAddAll => 'Add all to basket';

  @override
  String get copilotSearchMyself => 'Search myself';

  @override
  String copilotRemove(String name) {
    return 'Remove $name';
  }

  @override
  String copilotRefused(String items) {
    return 'No longer available, not added: $items';
  }

  @override
  String get actionClose => 'Close';

  @override
  String get adminNavModeration => 'Moderation';

  @override
  String get navVideos => 'Videos';

  @override
  String get feedForYou => 'For you';

  @override
  String get feedFollowing => 'Followed shops';

  @override
  String get feedEmpty => 'No videos in your area yet.';

  @override
  String get feedEmptyFollowing =>
      'Videos from shops you\'ve ordered from will show up here.';

  @override
  String get feedAdd => 'Add';

  @override
  String feedAdded(String name) {
    return '$name is in your basket.';
  }

  @override
  String get feedLike => 'Like';

  @override
  String get storiesTitle => 'Shop stories';

  @override
  String storyAddProduct(String name) {
    return 'Add $name';
  }

  @override
  String productVideos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Watch videos ($n)',
      one: 'Watch video',
    );
    return '$_temp0';
  }

  @override
  String get reportAction => 'Report';

  @override
  String get reportTitle => 'Why are you reporting this?';

  @override
  String get reportMisleading => 'Misleading';

  @override
  String get reportOffensive => 'Offensive';

  @override
  String get reportForbidden => 'Prohibited item';

  @override
  String get reportSpam => 'Spam';

  @override
  String get reportOther => 'Other';

  @override
  String get contentMine => 'My stories and videos';

  @override
  String get contentPublishTitle => 'Post';

  @override
  String get contentStory => '24 h story';

  @override
  String get contentVideo => 'Video';

  @override
  String get contentPickStory => 'Film or pick a photo or a short video.';

  @override
  String get contentPickVideo => 'Film or pick a video of up to 60 seconds.';

  @override
  String get contentVideoReady => 'Video ready';

  @override
  String get contentFilm => 'Film';

  @override
  String get contentGallery => 'Gallery';

  @override
  String get contentTagged => 'Tagged products';

  @override
  String get contentNoProducts => 'Publish a product first to tag it.';

  @override
  String get contentTagLimit => 'Up to 5 products.';

  @override
  String get contentCaption => 'Caption (optional)';

  @override
  String get contentPublishStory => 'Post story';

  @override
  String get contentPublishVideo => 'Post video';

  @override
  String get contentStoryHint => 'Visible for 24 h to customers in your area.';

  @override
  String get contentVideoHint => 'Shown in the feed of customers in your area.';

  @override
  String get contentNone => 'No stories or videos yet.';

  @override
  String get contentArchived => 'Archived';

  @override
  String contentStats(int views, int clicks, int likes) {
    return '$views views · $clicks taps · $likes likes';
  }

  @override
  String get contentActions => 'Actions';

  @override
  String get contentArchive => 'Archive';

  @override
  String get contentDelete => 'Delete';

  @override
  String get moderationOpen => 'Reported';

  @override
  String get moderationDecided => 'Handled';

  @override
  String get moderationEmpty => 'No reports.';

  @override
  String moderationReports(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n reports',
      one: '1 report',
    );
    return '$_temp0';
  }

  @override
  String get moderationKept => 'Kept';

  @override
  String get moderationRemoved => 'Removed';

  @override
  String get moderationVideo => 'Video';

  @override
  String get moderationStory => 'Story';

  @override
  String get moderationProduct => 'Product';

  @override
  String get moderationReview => 'Review';

  @override
  String get moderationPreview => 'Report preview';

  @override
  String get moderationCaption => 'Caption';

  @override
  String get moderationTagged => 'Tagged products';

  @override
  String get moderationReason => 'Reason';

  @override
  String get moderationDecision => 'Decision';

  @override
  String get moderationReasonRequired => 'Reason (required)';

  @override
  String get moderationKeep => 'Keep';

  @override
  String get moderationRemove => 'Remove';

  @override
  String get adminDashboardOverview => 'Overview';

  @override
  String get adminDashboardAi => 'AI and payments';

  @override
  String get aiUnderstood => 'Understood requests';

  @override
  String get aiLatency => 'Average latency';

  @override
  String aiSeconds(double value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String valueString = valueNumberFormat.format(value);

    return '$valueString s';
  }

  @override
  String get aiFallback => 'Fallbacks to classic search';

  @override
  String get adminPaymentsSucceeded1h => 'Successful payments';

  @override
  String get ai24h => '24 h';

  @override
  String get ai1h => '1 h';

  @override
  String get aiSeries => 'Understanding · 7 days';

  @override
  String get aiMisses => 'Latest misunderstood requests';

  @override
  String get aiOutcomeNoResult => 'No result';

  @override
  String get aiOutcomeFailure => 'Failure';

  @override
  String get aiUsageVoice => 'Voice';

  @override
  String get aiUsagePhoto => 'Photo';

  @override
  String get aiUsageText => 'Text';

  @override
  String get aiNoPersonalData =>
      'No personal data is shown or linked to these requests.';

  @override
  String aiPaymentsAlert(String value) {
    return 'Alert: only $value successful payments in the last hour.';
  }

  @override
  String get broadcastTitle => 'Reach my customers';

  @override
  String get broadcastEntry => 'Reach my customers';

  @override
  String get broadcastAudience => 'Choose recipients';

  @override
  String get broadcastRegular => 'Regular customers';

  @override
  String get broadcastRegularHint => '2 or more orders';

  @override
  String get broadcastMonth => 'This month\'s customers';

  @override
  String get broadcastAll => 'All my customers';

  @override
  String get broadcastMessage => 'My message';

  @override
  String get broadcastMessageHint => 'Fresh okra arrived this morning…';

  @override
  String get broadcastAttach => 'Attach a product (optional)';

  @override
  String get broadcastNoProduct => 'No product';

  @override
  String get broadcastRules =>
      'At most one message a day. Customers can turn these messages off.';

  @override
  String broadcastSend(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Send to $n customers',
      one: 'Send to 1 customer',
      zero: 'No customers to reach',
    );
    return '$_temp0';
  }

  @override
  String broadcastSent(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Message sent to $n customers.',
      one: 'Message sent to 1 customer.',
    );
    return '$_temp0';
  }

  @override
  String get broadcastDailyLimit =>
      'You\'ve already messaged your customers today. Try again tomorrow.';

  @override
  String get lowStockTitle => 'Low stock alert';

  @override
  String get lowStockEnabled => 'Notify me when a product runs low';

  @override
  String get lowStockThreshold => 'Threshold';

  @override
  String lowStockUnder(int n) {
    return 'Notify me under $n units';
  }

  @override
  String get accountEditName => 'Edit my first name';

  @override
  String get accountSave => 'Save';

  @override
  String get adminTabAdmins => 'Admins';

  @override
  String get adminAdminsHelp =>
      'Default admins come from the ADMIN_EMAILS variable. An invited email becomes admin on its first DYM Admin sign-in.';

  @override
  String get adminAdminsInvite => 'Invite';

  @override
  String get adminAdminsDefault => 'Default';

  @override
  String get adminAdminsActive => 'Active';

  @override
  String get adminAdminsPending => 'Invitation pending';

  @override
  String get adminAdminsRemove => 'Remove admin access';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authSignInPassword => 'Sign in';

  @override
  String get authUsePassword => 'I have a password';

  @override
  String get authUseCode => 'Get a code instead';

  @override
  String get authPasswordWrong => 'Wrong email or password.';

  @override
  String get contentMediaMode => 'Photo or video';

  @override
  String get contentTextMode => 'Write a status';

  @override
  String get contentTextLabel => 'Your message';

  @override
  String get contentTextHint => 'Write your status…';

  @override
  String get accountWallet => 'My wallet';

  @override
  String get walletTitle => 'My wallet';

  @override
  String get walletAvailable => 'Available';

  @override
  String walletTotal(String amount) {
    return 'Total with pockets: $amount';
  }

  @override
  String get walletTopup => 'Top up';

  @override
  String get walletTopupSimulated =>
      'Simulated top-up: no real money is charged.';

  @override
  String get walletMove => 'Move';

  @override
  String get walletPockets => 'My pockets';

  @override
  String get walletNewPocket => 'New pocket';

  @override
  String get walletPocketsEmpty =>
      'Create a pocket to set money aside: monthly shopping, celebrations, pre-orders.';

  @override
  String walletPocketGoal(String amount) {
    return 'Goal $amount';
  }

  @override
  String walletPocketRoundUp(String amount) {
    return 'Round up to $amount';
  }

  @override
  String get walletPocketArchive => 'Close pocket';

  @override
  String get walletMovements => 'Activity';

  @override
  String get walletMovementsEmpty => 'No activity yet.';

  @override
  String get walletKindTopup => 'Top-up';

  @override
  String get walletKindTransfer => 'Pocket transfer';

  @override
  String get walletKindPayment => 'Order payment';

  @override
  String get walletKindRefund => 'Refund';

  @override
  String get walletKindCashback => 'Cashback';

  @override
  String get walletKindOther => 'Movement';

  @override
  String get walletAmount => 'Amount';

  @override
  String get walletPocketName => 'Pocket name';

  @override
  String get walletPocketGoalField => 'Goal (optional)';

  @override
  String get walletPocketRoundUpField => 'Round up each payment to (optional)';

  @override
  String get walletFrom => 'From';

  @override
  String get walletTo => 'To';

  @override
  String get walletMain => 'Wallet';

  @override
  String get walletConfirm => 'Confirm';

  @override
  String get walletErrorInsufficient => 'Insufficient balance.';

  @override
  String get walletErrorAmount => 'Invalid amount.';

  @override
  String get walletErrorTopupDisabled => 'Top-up isn\'t available here.';

  @override
  String get walletErrorPocketLimit =>
      'You\'ve reached the maximum number of pockets.';

  @override
  String get orderErrorWalletInsufficient =>
      'Not enough in your wallet: top it up or choose another method.';

  @override
  String walletToPocket(String name) {
    return 'To $name';
  }

  @override
  String walletFromPocket(String name) {
    return 'From $name';
  }

  @override
  String cartDeliveryTo(String zone, String landmark) {
    return '$zone · $landmark';
  }

  @override
  String get cartAddAddress => 'Add a delivery address';

  @override
  String get homeWhatToEat => 'What are we eating?';

  @override
  String get homePopular => 'Most ordered near you';

  @override
  String get homeFresh => 'New in';

  @override
  String get homeReorderTitle => 'Reorder your groceries';

  @override
  String homeReorderMeta(String store, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$store · $_temp0';
  }

  @override
  String get homeReorderAction => 'Reorder';

  @override
  String get copilotReasonSameStore => 'Same store: one pickup';

  @override
  String get copilotReasonOpenNow => 'Store open now';

  @override
  String get copilotReasonTopRated => 'Best rated store';

  @override
  String get copilotReasonBestPrice => 'Best price';

  @override
  String get copilotReasonNearby => 'Store in your neighbourhood';

  @override
  String get copilotReasonBestMatch => 'Best match for your request';

  @override
  String get adminTabSearch => 'Search';

  @override
  String get adminRankingHelp =>
      'Weights from 0 to 100 used to pick the products suggested by the assistant. The higher the weight, the more the criterion counts.';

  @override
  String get adminEditRanking => 'Edit weights';

  @override
  String get adminWeightText => 'Text match';

  @override
  String get adminWeightSameStore => 'Same store (fewer pickups)';

  @override
  String get adminWeightOpen => 'Store open';

  @override
  String get adminWeightRating => 'Store rating';

  @override
  String get adminWeightPrice => 'Low price';

  @override
  String get adminWeightSameZone => 'Store in the neighbourhood';

  @override
  String get adminSynonymsTitle => 'Local names';

  @override
  String get adminAddSynonym => 'Add a local name';

  @override
  String get adminSynonymTerm => 'Local name (e.g. gboma)';

  @override
  String get adminSynonymList => 'Equivalents, comma separated';

  @override
  String adminRemoveSynonym(String term) {
    return 'Remove $term';
  }

  @override
  String get shoppingTitle => 'My shopping';

  @override
  String get shoppingHomeTile => 'My shopping lists';

  @override
  String get shoppingHomeTileHint => 'Redo your shopping in one tap';

  @override
  String get shoppingIntro =>
      'Nothing is ordered without you: the assistant builds the basket, you check it and add it to your cart.';

  @override
  String get shoppingEmpty =>
      'No list yet. Create “Saturday shopping”, “Breakfast”… and the assistant will build your basket.';

  @override
  String get shoppingNew => 'New list';

  @override
  String get shoppingFromHabits => 'My usual list';

  @override
  String get shoppingFromHabitsHint => 'What you often buy';

  @override
  String get shoppingNoHabits =>
      'No habits yet: you need to have ordered the same product at least twice.';

  @override
  String get shoppingDescribe => 'Describe my shopping';

  @override
  String get shoppingDescribeHint => 'E.g. the week for 4 people';

  @override
  String get shoppingDescribeAction => 'Suggest a list';

  @override
  String get shoppingAiUnavailable =>
      'The assistant is not answering. You can create your list by hand.';

  @override
  String get shoppingAiNothing =>
      'I found nothing to suggest. Try other words.';

  @override
  String shoppingItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get shoppingNoRepeat => 'No reminder';

  @override
  String get shoppingEvery7 => 'Every week';

  @override
  String get shoppingEvery14 => 'Every 2 weeks';

  @override
  String get shoppingEvery30 => 'Every month';

  @override
  String shoppingNextOn(String date) {
    return 'Next reminder: $date';
  }

  @override
  String get shoppingOpen => 'Build my basket';

  @override
  String shoppingMore(String name) {
    return 'More actions for $name';
  }

  @override
  String get shoppingEdit => 'Edit';

  @override
  String get shoppingDelete => 'Delete';

  @override
  String shoppingDeleteConfirm(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get shoppingDeleted => 'List deleted';

  @override
  String get shoppingEditTitle => 'My list';

  @override
  String get shoppingName => 'List name';

  @override
  String get shoppingNameHint => 'E.g. Saturday shopping';

  @override
  String get shoppingItemsTitle => 'Items';

  @override
  String get shoppingItemHint => 'Add an item (tomatoes, rice…)';

  @override
  String get shoppingAddItem => 'Add';

  @override
  String shoppingRemoveItem(String name) {
    return 'Remove $name';
  }

  @override
  String shoppingLess(String name) {
    return 'One less: $name';
  }

  @override
  String shoppingMoreQty(String name) {
    return 'One more: $name';
  }

  @override
  String get shoppingRepeatTitle => 'Remind me';

  @override
  String shoppingStartsOn(String date) {
    return 'First reminder on $date';
  }

  @override
  String get shoppingPickDate => 'Change the date';

  @override
  String get shoppingRepeatNote =>
      'On the day, at 8 am, we let you know: you check and confirm.';

  @override
  String get shoppingSave => 'Save the list';

  @override
  String get shoppingSaved => 'List saved';

  @override
  String get shoppingErrorName => 'Give your list a name.';

  @override
  String get shoppingErrorItems => 'Add at least one item.';

  @override
  String get shoppingErrorTooMany => '20 lists at most: delete one.';

  @override
  String get shoppingErrorTooManyItems => '20 items at most per list.';

  @override
  String get notifShoppingDueTitle => 'Your shopping is ready';

  @override
  String notifShoppingDueBody(String name) {
    return '“$name”: check and confirm your basket.';
  }

  @override
  String get favoriteAdd => 'Add to favourites';

  @override
  String get favoriteRemove => 'Remove from favourites';

  @override
  String get favoritesTitle => 'My favourites';

  @override
  String get favoritesStores => 'Shops';

  @override
  String get favoritesProducts => 'Products';

  @override
  String get favoritesEmpty =>
      'Tap the heart on a shop or a product to find it here.';

  @override
  String get basketsTitle => 'My baskets';

  @override
  String get basketsEmpty =>
      'Save your basket (breakfast, lunch, the month…) from the cart to redo it in one tap.';

  @override
  String get basketSave => 'Save this basket';

  @override
  String get basketSaveAction => 'Save';

  @override
  String get basketName => 'Basket name';

  @override
  String get basketNameHint => 'E.g. Breakfast';

  @override
  String get basketSaved => 'Basket saved: find it in “My baskets”.';

  @override
  String get basketToCart => 'Add back to cart';

  @override
  String basketMeta(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0 · $total today';
  }

  @override
  String basketUnavailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items unavailable',
      one: '1 item unavailable',
    );
    return '$_temp0';
  }

  @override
  String basketSkipped(String items) {
    return 'Not added (no longer available): $items';
  }

  @override
  String basketMore(String name) {
    return 'More actions for $name';
  }

  @override
  String get basketRename => 'Rename';

  @override
  String get basketDelete => 'Delete';

  @override
  String basketDeleteConfirm(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get basketErrorEmpty => 'Your cart is empty.';

  @override
  String get basketErrorTooMany =>
      '20 baskets of 50 items at most: delete one.';

  @override
  String get basketErrorName => 'Give your basket a name.';

  @override
  String get accountFavorites => 'My favourites';

  @override
  String get accountBaskets => 'My baskets';

  @override
  String get spacesTitle => 'My spaces';

  @override
  String get spacesIntro =>
      'A space brings together those who fill the basket and those who confirm and pay: home, family back home, a savings group…';

  @override
  String get spacesEmpty =>
      'No space yet. Create one or join a relative\'s with their code.';

  @override
  String get spacesEmptyShort => 'First create or join a space in “Me”.';

  @override
  String get spaceCreate => 'Create a space';

  @override
  String get spaceCreateAction => 'Create';

  @override
  String get spaceJoin => 'Join';

  @override
  String get spaceJoinAction => 'Join';

  @override
  String get spaceCodeHint => 'Code you received (8 characters)';

  @override
  String get spaceName => 'Space name';

  @override
  String get spaceNameHint => 'E.g. Home, Family in Kpalimé';

  @override
  String get spaceBudget => 'Monthly budget (optional)';

  @override
  String get spaceBudgetHint => 'E.g. 50,000';

  @override
  String spaceMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get spaceRolePayer => 'Confirms and pays';

  @override
  String get spaceRoleMember => 'Fills the basket';

  @override
  String get spaceOwner => 'Owner · confirms and pays';

  @override
  String spaceMe(String name) {
    return '$name (me)';
  }

  @override
  String spaceManage(String name) {
    return 'Manage $name';
  }

  @override
  String get spaceMakePayer => 'Can confirm and pay';

  @override
  String get spaceMakeMember => 'Fills only';

  @override
  String get spaceRemoveMember => 'Remove from the space';

  @override
  String get spaceMembers => 'Members';

  @override
  String get spaceBasket => 'Shared basket';

  @override
  String get spaceSendCart => 'Send my cart';

  @override
  String get spaceBasketEmpty =>
      'Empty for now: everyone fills their cart as usual, then sends it here.';

  @override
  String spaceTotal(String total) {
    return 'Total: $total + delivery';
  }

  @override
  String get spaceValidate => 'Confirm and move to cart';

  @override
  String get spaceWaitPayer => 'Someone who confirms will place the order.';

  @override
  String get spaceDelete => 'Delete the space';

  @override
  String get spaceLeave => 'Leave the space';

  @override
  String spaceDeleteConfirm(String name) {
    return 'Delete “$name” for everyone?';
  }

  @override
  String spaceLeaveConfirm(String name) {
    return 'Leave “$name”?';
  }

  @override
  String get spaceBudgetTitle => 'Monthly budget';

  @override
  String spaceBudgetMeta(String spent, String budget, String left) {
    return '$spent spent of $budget · $left left';
  }

  @override
  String get spaceInvite => 'Invite code';

  @override
  String get spaceCopyCode => 'Copy the code';

  @override
  String get spaceCodeCopied => 'Code copied: send it to your relatives.';

  @override
  String spaceAddedBy(String name) {
    return 'added by $name';
  }

  @override
  String get spaceUnavailable => 'unavailable';

  @override
  String get spaceSendCartTitle => 'Send my cart to…';

  @override
  String get spaceSendToSpace => 'Send to a space';

  @override
  String spaceCartSent(String name) {
    return 'Cart sent to “$name”.';
  }

  @override
  String get spaceErrorName => 'Give the space a name.';

  @override
  String get spaceErrorBudget => 'Invalid budget.';

  @override
  String get spaceErrorUnknownCode => 'Unknown code: check it.';

  @override
  String get spaceErrorOtherCountry => 'This space is in another country.';

  @override
  String get spaceErrorFull => 'This space already has 20 members.';

  @override
  String get spaceErrorTooMany => '20 spaces at most.';

  @override
  String get spaceErrorCartEmpty => 'Nothing to send or confirm.';

  @override
  String get spaceErrorBudgetExceeded =>
      'This basket exceeds the monthly budget.';

  @override
  String get spaceErrorNotPayer => 'Only someone who confirms can do this.';

  @override
  String get accountSpaces => 'My spaces';

  @override
  String get notifSpaceValidatedTitle => 'Shared basket confirmed';

  @override
  String notifSpaceValidatedBody(String name, String space) {
    return '$name confirmed the “$space” basket.';
  }

  @override
  String get spacePocket => 'Shared pot';

  @override
  String get spaceContribute => 'Add money';

  @override
  String get spaceContributeTitle => 'Add from my wallet';

  @override
  String spaceContributedMonth(String amount) {
    return 'added $amount this month';
  }

  @override
  String get spaceUsePocket => 'Pay with the shared pot';

  @override
  String get spaceUsePocketHint =>
      'The items amount moves to your wallet: choose “DYM Wallet” to pay.';

  @override
  String get spaceErrorPocketInsufficient =>
      'The shared pot doesn\'t cover this basket.';

  @override
  String get spaceErrorSpaceBalance =>
      'The shared pot is not empty: use it first.';

  @override
  String get walletKindSpaceContribution => 'Added to a space';

  @override
  String get walletKindSpacePayout => 'Received from a space';

  @override
  String get slotTitle => 'When?';

  @override
  String get slotAsap => 'As soon as possible';

  @override
  String get slotToday => 'Today';

  @override
  String get slotTomorrow => 'Tomorrow';

  @override
  String slotWindow(String start, String end) {
    return '$start–$end';
  }

  @override
  String slotRequiredFrom(String date) {
    return 'Your cart has an upcoming arrival: delivery from $date.';
  }

  @override
  String get orderErrorSlotRequired => 'Choose a delivery slot.';

  @override
  String get orderErrorSlotInvalid =>
      'This slot is no longer available: choose another one.';

  @override
  String get orderErrorSlotClosed =>
      'A shop is closed at this slot: choose another one.';

  @override
  String orderScheduled(String day, String start, String end) {
    return 'Planned $day, $start–$end';
  }

  @override
  String productArrivalBadge(String date) {
    return 'Arriving $date · price locked';
  }

  @override
  String productArrivalOn(String date) {
    return 'Arrives $date · pre-orders open';
  }

  @override
  String get productArrivalSet => 'Set an arrival date';

  @override
  String get productArrivalClear => 'Remove the arrival date';

  @override
  String get productArrivalHint =>
      'Arrival date: customers pre-order at a locked price';

  @override
  String vendorOrderScheduled(String day, String start, String end) {
    return 'Deliver $day, $start–$end';
  }

  @override
  String get adjustTitle => 'Replacements and freshness';

  @override
  String adjustProposed(String item, String proposed) {
    return '$item is missing: the seller suggests $proposed, same price.';
  }

  @override
  String adjustAccepted(String item, String proposed) {
    return '$item replaced by $proposed.';
  }

  @override
  String adjustRefused(String item, String amount) {
    return '$item removed: $amount back to your wallet.';
  }

  @override
  String adjustFreshness(String item, String amount) {
    return '$item not fresh: $amount back to your wallet.';
  }

  @override
  String get adjustAccept => 'Accept';

  @override
  String get adjustRefuse => 'Refuse and get refunded';

  @override
  String adjustCreditedNow(String amount) {
    return '$amount is already in your wallet.';
  }

  @override
  String get freshnessClaim => 'An item is not fresh?';

  @override
  String get freshnessHint =>
      'Freshness guarantee: send a photo and get refunded right away to your wallet.';

  @override
  String get freshnessWhich => 'Which item?';

  @override
  String get freshnessWindowClosed =>
      'The guarantee period is over: use “Report a problem”.';

  @override
  String get freshnessLimitReached =>
      'Monthly limit reached: use “Report a problem”, the team will check.';

  @override
  String get freshnessAlreadyCredited => 'This item was already refunded.';

  @override
  String get notifSubstitutionTitle => 'A replacement is proposed';

  @override
  String notifSubstitutionBody(String item, String proposed) {
    return '$item is missing: the seller suggests $proposed.';
  }

  @override
  String get vendorSubstituteTitle => 'An item is missing?';

  @override
  String get vendorSubstituteHint =>
      'Suggest another product with a photo: same quantity, same price. The customer confirms.';

  @override
  String vendorSubstitute(String item) {
    return 'Replace $item';
  }

  @override
  String vendorSubstituteLine(String item, String proposed) {
    return '$item → $proposed';
  }

  @override
  String get vendorSubstituteWaiting => 'Waiting for the customer';

  @override
  String get vendorSubstituteAccepted => 'Accepted';

  @override
  String get vendorSubstituteRefunded => 'Refunded to the customer';

  @override
  String vendorFreshnessClaimed(String item) {
    return '$item reported not fresh';
  }

  @override
  String get vendorSubstituteNone => 'No other product available in your shop.';

  @override
  String get vendorSubstituteNote => 'A note for the customer (optional)';

  @override
  String get chatVoiceRecord => 'Record a voice message';

  @override
  String get chatVoiceRecording => 'Recording… (60 s max)';

  @override
  String get chatVoiceSend => 'Send the voice message';

  @override
  String get chatVoiceCancel => 'Cancel the voice message';

  @override
  String get chatVoicePlay => 'Play';

  @override
  String get chatVoiceStop => 'Stop';

  @override
  String chatVoiceDuration(int seconds) {
    return '$seconds s';
  }

  @override
  String get callAudio => 'Call';

  @override
  String get callVideo => 'Video call “Show me”';

  @override
  String get callRinging => 'Ringing…';

  @override
  String get callIncoming => 'Incoming call';

  @override
  String get callOngoing => 'In call';

  @override
  String get callDeclined => 'Call declined';

  @override
  String get callMissed => 'Missed call';

  @override
  String get callEnded => 'Call ended';

  @override
  String get callUnavailable => 'Calling is not possible right now.';

  @override
  String get callSimulated =>
      'Simulated call: voice and video will use the real service before going live.';

  @override
  String get callAnswer => 'Answer';

  @override
  String get callDecline => 'Decline';

  @override
  String get callHangUp => 'Hang up';

  @override
  String get callClose => 'Close';

  @override
  String get callOpen => 'Open';

  @override
  String callIncomingFrom(String name) {
    return '$name is calling you';
  }

  @override
  String callSummaryEnded(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '1 min',
    );
    return 'Call · $_temp0';
  }

  @override
  String get accountCreator => 'Create and share';

  @override
  String get creatorTitle => 'Creator studio';

  @override
  String get creatorIntro =>
      'Share your recipes, tips and market finds. Tag the products: people buy them in one tap.';

  @override
  String get creatorName => 'Creator name';

  @override
  String get creatorNameHint => 'E.g. Awa cooks';

  @override
  String get creatorBio => 'Short bio (optional)';

  @override
  String get creatorBecome => 'Open my studio';

  @override
  String get creatorErrorName => 'Your creator name: 2 to 40 characters.';

  @override
  String get creatorErrorMedia =>
      'This media cannot be published: choose another one.';

  @override
  String get creatorNewPost => 'New post';

  @override
  String get creatorMyPosts => 'My posts';

  @override
  String get creatorNoPost => 'No post yet: share your first recipe!';

  @override
  String creatorPostStats(int views, int clicks, int tags) {
    return '$views views · $clicks clicks · $tags products';
  }

  @override
  String get creatorArchive => 'Archive';

  @override
  String get creatorPickVideo => 'Video (60 s)';

  @override
  String get creatorCaption => 'Caption';

  @override
  String get creatorCaptionHint => 'E.g. My Sunday okra stew';

  @override
  String get creatorCategory => 'Category';

  @override
  String get creatorSuggestCategory => 'Let AI choose';

  @override
  String get creatorCategoryHint =>
      'Without a choice, your post goes to “Other”.';

  @override
  String creatorTagProducts(int count, int max) {
    return 'Tagged products ($count/$max)';
  }

  @override
  String get creatorSearchProducts => 'Search a product to tag';

  @override
  String get creatorPublish => 'Publish';

  @override
  String get feedGrid => 'Grid view';

  @override
  String get feedFullScreen => 'Full screen';

  @override
  String get feedAllCategories => 'All';

  @override
  String get feedFollow => 'Follow';

  @override
  String get feedFollowingOne => 'Following';

  @override
  String get feedComments => 'Comments';

  @override
  String get feedNoComment => 'No comment yet: start the conversation!';

  @override
  String get feedCommentHint => 'Add a comment';

  @override
  String get feedDeleteComment => 'Delete my comment';

  @override
  String get moderationComment => 'Comment';
}
