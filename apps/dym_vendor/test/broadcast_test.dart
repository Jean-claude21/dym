import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/broadcast/broadcast_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _sizes = [
  Size(360, 640),
  Size(412, 915),
  Size(915, 412),
  Size(640, 360),
  Size(800, 1280),
  Size(1280, 800),
  Size(1440, 900),
];

const _catalog = [
  Product(
    id: 'p1',
    name: 'Gombo frais',
    currencyCode: 'XOF',
    status: ProductStatus.published,
    priceMinor: 300,
  ),
];

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(412, 915),
  Locale locale = const Locale('fr'),
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DymTheme.light(),
      locale: locale,
      localizationsDelegates: DymLocalizations.localizationsDelegates,
      supportedLocales: DymLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          disableAnimations: true,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('viewmodel', () {
    test('relance : segment, message, envoi unique', () async {
      final service = MemoryVendorBroadcastService(catalog: _catalog);
      final vm = BroadcastViewModel(service: service);
      await vm.load();
      expect(vm.recipients, 12);
      expect(vm.canSend, isFalse, reason: 'sans message');
      vm
        ..selectSegment(BroadcastSegment.month)
        ..setMessage('Gombo frais arrivé ce matin !')
        ..attach('p1');
      expect(vm.recipients, 31);
      expect(await vm.send(), isTrue);
      expect(vm.sent, 31);
      expect(vm.canSend, isFalse, reason: 'une seule relance');
      expect(service.gestures, ['send:month:p1']);
    });

    test("relance déjà faite aujourd'hui : message", () async {
      final vm = BroadcastViewModel(
        service: MemoryVendorBroadcastService(
          failure: const ValidationFailure('broadcast_daily_limit'),
        ),
      );
      await vm.load();
      vm.setMessage('Encore');
      expect(await vm.send(), isFalse);
      expect(vm.sendFailure, const ValidationFailure('broadcast_daily_limit'));
    });

    test('stock bas : seuil, coupure', () async {
      final service = MemoryVendorBroadcastService();
      final vm = BroadcastViewModel(service: service);
      await vm.load();
      await vm.setThreshold(10);
      await vm.setThreshold(null);
      expect(vm.audience!.lowStockThreshold, isNull);
      expect(service.gestures, ['threshold:10', 'threshold:off']);
    });
  });

  group('écran 78 aux 7 tailles, texte 130 %', () {
    for (final size in _sizes) {
      for (final locale in const [Locale('fr'), Locale('en')]) {
        testWidgets('78 · ${size.width.toInt()}×${size.height.toInt()} · '
            '${locale.languageCode}', (tester) async {
          await _pump(
            tester,
            BroadcastView(
              service: MemoryVendorBroadcastService(catalog: _catalog),
              onBack: () {},
            ),
            size: size,
            locale: locale,
            textScale: 1.3,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  testWidgets('78 : écrire et envoyer', (tester) async {
    final l10n = await DymLocalizations.delegate.load(const Locale('fr'));
    final service = MemoryVendorBroadcastService(catalog: _catalog);
    await _pump(tester, BroadcastView(service: service, onBack: () {}));
    await tester.enterText(find.byType(TextField).first, 'Gombo frais !');
    await tester.pump();
    await tester.ensureVisible(find.text(l10n.broadcastSend(12)));
    await tester.tap(find.text(l10n.broadcastSend(12)));
    await tester.pumpAndSettle();
    expect(find.text(l10n.broadcastSent(12)), findsOneWidget);
    expect(service.gestures, ['send:regular:-']);
  });
}
