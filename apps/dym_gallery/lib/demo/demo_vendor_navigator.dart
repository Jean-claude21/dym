import 'package:dym_models/dym_models.dart';
import 'package:dym_vendor/features/store/onboarding/store_onboarding_viewmodel.dart';
import 'package:dym_vendor/ui/navigation.dart';

/// Navigation inerte de la galerie : les écrans restent affichés.
class DemoVendorNavigator implements AppNavigator {
  @override
  void toSignIn({bool startWithProfile = false}) {}

  @override
  void toStartup() {}

  @override
  void toHome() {}

  @override
  void toStoreOnboarding() {}

  @override
  void toStoreOpened(MyStore store, CountryConfig config) {}

  @override
  Future<void> toStoreSetting(StoreStep step) async {}

  @override
  void toAddProduct() {}

  @override
  Future<void> toProductEditor({Product? product}) async {}

  @override
  Future<void> toStoreCategories() async {}

  @override
  void toOrder(String orderId) {}

  @override
  void toChat(String conversationId) {}

  @override
  void toReviews() {}

  @override
  void toCourierCash() {}

  @override
  void toTill() {}

  @override
  void toCredit() {}

  @override
  void toStudio() {}

  @override
  void toWholesale() {}

  @override
  void toHaggling() {}

  @override
  void toGroupOffers() {}

  @override
  void toContents() {}

  @override
  void toBroadcast() {}

  @override
  void toHelp() {}
}
