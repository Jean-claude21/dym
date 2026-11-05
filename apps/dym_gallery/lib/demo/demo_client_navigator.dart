import 'package:dym_client/ui/navigation.dart';

/// Navigation inerte de la galerie (app cliente) : les écrans restent
/// affichés.
class DemoClientNavigator implements AppNavigator {
  @override
  void toSignIn({bool startWithProfile = false}) {}

  @override
  void toHome() {}

  @override
  void toAisle(String categoryId) {}

  @override
  void toStore(String storeId) {}

  @override
  void toProduct(String productId) {}

  @override
  void toSearch() {}

  @override
  void toCart() {}

  @override
  void toAddresses() {}

  @override
  void toOrders() {}

  @override
  void toOrder(String orderId) {}

  @override
  void toNotifications() {}

  @override
  void toNotificationSettings() {}

  @override
  void toMessages() {}

  @override
  Future<void> toStoreChat(String storeId, {String? productId}) async {}

  @override
  void toChat(String conversationId) {}

  @override
  void toHelp() {}
}
