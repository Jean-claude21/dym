import 'package:dym_client/features/orders/adjustments_view.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _pending = OrderAdjustment(
  id: 'a1',
  kind: AdjustmentKind.substitution,
  variantId: 'v1',
  itemName: 'Tomates',
  proposedName: 'Piment',
  photoKey: 'orders/o1/p.jpg',
  status: AdjustmentStatus.pending,
);

class _Fake implements AdjustmentsService {
  final answers = <bool>[];
  Failure? claimFailure;

  @override
  Future<Result<Map<String, String>>> photoUrls(String orderId) async =>
      const Ok({});

  @override
  Future<Result<List<OrderAdjustment>>> answer(
    String adjustmentId, {
    required bool accept,
  }) async {
    answers.add(accept);
    return Ok([
      OrderAdjustment(
        id: 'a1',
        kind: AdjustmentKind.substitution,
        variantId: 'v1',
        itemName: 'Tomates',
        proposedName: 'Piment',
        photoKey: 'orders/o1/p.jpg',
        status: accept ? AdjustmentStatus.accepted : AdjustmentStatus.refused,
        creditedMinor: accept ? 0 : 1000,
      ),
    ]);
  }

  @override
  Future<Result<List<OrderAdjustment>?>> claimFreshness({
    required String orderId,
    required String variantId,
    required PhotoSource source,
    String? note,
  }) async {
    if (claimFailure case final f?) return Err(f);
    return const Ok([
      OrderAdjustment(
        id: 'a2',
        kind: AdjustmentKind.freshness,
        variantId: 'v2',
        itemName: 'Gombo',
        photoKey: 'orders/o1/q.jpg',
        status: AdjustmentStatus.credited,
        creditedMinor: 300,
      ),
    ]);
  }
}

CustomerOrder _order({
  OrderStatus status = OrderStatus.accepted,
  List<OrderAdjustment> adjustments = const [_pending],
}) => CustomerOrder.fromJson({
  'id': 'o1',
  'purchase_id': 'pu1',
  'status': status.name == 'outForDelivery' ? 'out_for_delivery' : status.name,
  'fulfillment': 'pickup',
  'created_at': '2026-11-10T10:00:00Z',
  'currency_code': 'XOF',
  'total_minor': 1300,
  'store': const {'id': 's1', 'name': 'Étal de Kodjo', 'origin': 'marche'},
  'items': const [
    {
      'product_id': 'p1',
      'variant_id': 'v1',
      'name': 'Tomates',
      'unit_price_minor': 500,
      'quantity': 2,
      'amount_minor': 1000,
    },
    {
      'product_id': 'p2',
      'variant_id': 'v2',
      'name': 'Gombo',
      'unit_price_minor': 300,
      'quantity': 1,
      'amount_minor': 300,
    },
  ],
  'adjustments': [
    for (final a in adjustments)
      {
        'id': a.id,
        'kind': a.kind.name,
        'variant_id': a.variantId,
        'item_name': a.itemName,
        'proposed_name': a.proposedName,
        'photo_key': a.photoKey,
        'status': a.status.name,
        'credited_minor': a.creditedMinor,
      },
  ],
});

void main() {
  group('remplacement et fraîcheur (spec 034)', () {
    test('refus : montant rendu annoncé', () async {
      final service = _Fake();
      final vm = AdjustmentsViewModel(service: service, order: _order());
      expect(vm.adjustments.single.awaitingAnswer, isTrue);
      await vm.answer(vm.adjustments.single, accept: false);
      expect(service.answers, [false]);
      expect(vm.lastCredited, 1000);
      expect(vm.credited('v1'), isTrue);
    });

    test('fraîcheur : crédit, ou limite atteinte expliquée', () async {
      final service = _Fake();
      final vm = AdjustmentsViewModel(
        service: service,
        order: _order(status: OrderStatus.delivered, adjustments: const []),
      );
      await vm.claim('v2', PhotoSource.camera);
      expect(vm.lastCredited, 300);
      service.claimFailure = const ValidationFailure('claim_limit_reached');
      await vm.claim('v1', PhotoSource.gallery);
      expect(vm.problem, AdjustmentError.limitReached);
    });

    testWidgets('écran : proposition à valider', (tester) async {
      final service = _Fake();
      await tester.pumpWidget(
        MaterialApp(
          theme: DymTheme.light(),
          locale: const Locale('fr'),
          localizationsDelegates: DymLocalizations.localizationsDelegates,
          supportedLocales: DymLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: OrderAdjustmentsPanel(
                service: service,
                order: _order(),
                money: (m) => '$m F',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('la vendeuse propose Piment'), findsOneWidget);
      await tester.tap(find.text('Accepter'));
      await tester.pumpAndSettle();
      expect(service.answers, [true]);
      expect(find.text('Tomates remplacé par Piment.'), findsOneWidget);
    });
  });
}
