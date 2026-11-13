@Tags(['golden'])
library;

import 'package:dym_client/features/cart/addresses/address_form_view.dart';
import 'package:dym_client/features/cart/payment/payment_view.dart';
import 'package:dym_client/features/group_buy/group_buy_view.dart';
import 'package:dym_client/features/orders/orders_views.dart';
import 'package:dym_client/features/orders/testing.dart';
import 'package:dym_client/features/reviews/review_views.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/cart_fixtures.dart';
import '../support/discovery_fixtures.dart';
import 'capture.dart';

/// Captures des dernières pages de la cliente (spec 058).
class _Groups implements GroupBuyService {
  @override
  Future<Result<CountryConfig>> countryConfig() async => Ok(togoConfig());

  @override
  Future<Result<List<GroupOffer>>> near() async => Ok([
    GroupOffer(
      id: 'g1',
      storeId: 's1',
      storeName: 'Chez Fatou',
      productId: 'p1',
      productName: 'Riz parfumé',
      variantId: 'v1',
      groupPriceMinor: 1600,
      priceMinor: 1950,
      minQuantity: 5,
      closesAt: DateTime(2026, 11, 13),
      status: 'open',
      memberDeliveryFeeMinor: 200,
      committed: 3,
      members: 2,
    ),
  ]);

  @override
  Future<Result<GroupOffer>> join(GroupOffer offer, int quantity) async =>
      Ok(offer);

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('achats groupés', (t) async {
    await capture(
      t,
      'achats_groupes',
      GroupBuysView(service: _Groups(), onBack: () {}),
    );
  });
  testWidgets('adresse', (t) async {
    await capture(
      t,
      'adresse',
      AddressFormView(service: memoryCart(), onDone: (_) {}),
    );
  });
  testWidgets('reglages notifications', (t) async {
    await capture(
      t,
      'reglages_notifications',
      NotificationSettingsView(
        service: MemoryOrdersService(config: togoConfig()),
        onBack: () {},
      ),
    );
  });
  testWidgets('avis', (t) async {
    await capture(
      t,
      'avis',
      ReviewFormView(
        service: MemoryOrdersService(config: togoConfig()),
        orderId: 'o1',
        storeName: "Étal d'Akossiwa",
        onBack: () {},
        onSent: (_) {},
      ),
    );
  });
  testWidgets('paiement', (t) async {
    final service = memoryCart(online: true);
    await service.select(paymentMethodId: 'sim');
    final purchase = (await service.placeOrder()).valueOrNull!;
    await capture(
      t,
      'paiement',
      PaymentView(
        service: service,
        purchase: purchase,
        onSettled: (_) {},
        onBack: () {},
        openAtStart: false,
      ),
    );
  });
}
