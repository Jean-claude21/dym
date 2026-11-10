import 'package:dym_client/ui/navigation.dart';
import 'package:dym_models/dym_models.dart';

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
  void toSearch({String text = ''}) {}

  @override
  void toCopilot() {}

  @override
  void toProductVideos(String productId) {}

  @override
  void toStories(List<StoryGroup> groups, int index) {}

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

  @override
  void toWallet() {}

  @override
  void toShoppingLists() {}

  @override
  void toFavorites() {}

  @override
  void toBaskets() {}

  @override
  Future<void> toShoppingList(String listId) async {}
}
