import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/group_buy/group_offers_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CountryConfig _togo() => CountryConfig(
  country: Country.fromJson(const {
    'code': 'TG',
    'name': {'fr': 'Togo'},
    'currency_code': 'XOF',
    'dial_code': '+228',
    'default_locale': 'fr',
    'timezone': 'Africa/Lome',
  }),
  currency: Currency.xof,
  cities: const [],
  zones: const [],
  categories: const [],
  storeOrigins: const [],
  units: const [],
  paymentMethods: const [],
  deliveryFees: const [],
  featureFlags: const [],
);

GroupOffer _offer({int committed = 0, int? mine, bool reached = false}) =>
    GroupOffer(
      id: 'g1',
      storeId: 's1',
      storeName: 'Étal de Kodjo',
      productId: 'p1',
      productName: 'Igname',
      variantId: 'v1',
      groupPriceMinor: 800,
      priceMinor: 1000,
      minQuantity: 5,
      closesAt: DateTime(2026, 11, 13),
      status: 'open',
      memberDeliveryFeeMinor: 200,
      committed: committed,
      members: committed == 0 ? 0 : 1,
      myQuantity: mine,
      reached: reached,
    );

class _Offers implements GroupOffersService {
  List<GroupOffer> state = [];
  final calls = <String>[];

  @override
  Future<Result<CountryConfig>> countryConfig() async => Ok(_togo());

  @override
  Future<Result<List<GroupOffer>>> mine() async => Ok(state);

  @override
  Future<Result<List<Product>>> products() async => const Ok([]);

  @override
  Future<Result<GroupOffer>> create({
    required String productId,
    required int groupPriceMinor,
    required int minQuantity,
    int days = 3,
    int? memberDeliveryFeeMinor,
  }) async {
    calls.add('create:$groupPriceMinor:$minQuantity:$memberDeliveryFeeMinor');
    state = [_offer()];
    return Ok(state.single);
  }

  @override
  Future<Result<GroupOffer>> cancel(GroupOffer offer) async {
    calls.add('cancel');
    return Ok(offer);
  }
}

void main() {
  group('offres groupées de la vendeuse (spec 051)', () {
    test('créer : contrôles puis offre', () async {
      final service = _Offers();
      final vm = GroupOffersViewModel(service: service);
      await vm.load();
      const product = Product(
        id: 'p1',
        name: 'Igname',
        currencyCode: 'XOF',
        status: ProductStatus.published,
      );
      expect(
        await vm.create(
          product: product,
          priceText: '800',
          minText: '1',
          days: 3,
        ),
        isFalse,
      );
      expect(vm.problem, 'invalid_amount');
      expect(
        await vm.create(
          product: product,
          priceText: '800',
          minText: '5',
          days: 3,
          feeText: '200',
        ),
        isTrue,
      );
      expect(service.calls, ['create:800:5:200']);
      expect(vm.offers, hasLength(1));
    });

    testWidgets('écran : offre et annulation', (tester) async {
      final service = _Offers()..state = [_offer(committed: 2)];
      await tester.pumpWidget(
        MaterialApp(
          theme: DymTheme.light(),
          locale: const Locale('fr'),
          localizationsDelegates: DymLocalizations.localizationsDelegates,
          supportedLocales: DymLocalizations.supportedLocales,
          home: GroupOffersView(service: service, onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Igname'), findsOneWidget);
      await tester.tap(find.text("Annuler l'offre"));
      await tester.pumpAndSettle();
      expect(service.calls, ['cancel']);
    });
  });
}
