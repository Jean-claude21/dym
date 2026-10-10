import 'package:dym_account/dym_account.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
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

MemorySupportService _service({String app = 'client'}) => MemorySupportService(
  app: app,
  orders: const [(id: 'o1', label: "7K2Q4F1A · Étal d'Akossiwa")],
  tickets: [
    SupportTicket(
      id: 't0',
      app: app,
      subject: TicketSubject.account,
      status: TicketStatus.closed,
      createdAt: DateTime.utc(2026, 10, 3),
      lastActivityAt: DateTime.utc(2026, 10, 3),
      messages: [
        TicketMessage(
          id: 'm0',
          authorRole: 'user',
          body: 'Changer mon adresse',
          createdAt: DateTime.utc(2026, 10, 3),
        ),
        TicketMessage(
          id: 'm1',
          authorRole: 'team',
          body: "C'est fait !",
          createdAt: DateTime.utc(2026, 10, 3, 1),
        ),
      ],
    ),
  ],
);

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
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  test('demande : texte exigé, envoi, réponse', () async {
    final vm = SupportViewModel(service: _service());
    await vm.load();
    expect(vm.orders, hasLength(1));
    expect(vm.subjects, isNot(contains(TicketSubject.store)));
    expect(await vm.send(), isFalse);
    vm
      ..setOrder('o1')
      ..setBody('Je n’ai pas reçu ma monnaie');
    expect(await vm.send(), isTrue);
    expect(vm.tickets!.first.orderId, 'o1');
    expect(vm.sent, isTrue);
    expect(await vm.reply(vm.tickets!.first.id, 'Merci'), isTrue);
    expect(vm.tickets!.first.messages, hasLength(2));
  });

  test('vendeuse : sujet « Ma boutique » proposé', () {
    expect(
      SupportViewModel(service: _service(app: 'vendor')).subjects,
      contains(TicketSubject.store),
    );
  });

  test('échec réseau : erreur gardée', () async {
    final service = _service()..failNext = const NetworkFailure('3G');
    final vm = SupportViewModel(service: service);
    await vm.load();
    expect(vm.failure, isA<NetworkFailure>());
  });

  group('écran 66 aux 7 tailles, texte 130 %', () {
    for (final size in _sizes) {
      for (final locale in const [Locale('fr'), Locale('en')]) {
        testWidgets('66 · ${size.width.toInt()}×${size.height.toInt()} · '
            '${locale.languageCode}', (tester) async {
          await _pump(
            tester,
            SupportView(
              service: _service(),
              onBack: () {},
              clock: () => DateTime.utc(2026, 10, 5, 11),
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

  testWidgets('66 : écrire et envoyer', (tester) async {
    await _pump(
      tester,
      SupportView(
        service: _service(),
        onBack: () {},
        clock: () => DateTime.utc(2026, 10, 5, 11),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Décris ton problème'),
      'Paiement débité deux fois',
    );
    await tester.pump();
    await tester.tap(find.text('Envoyer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Paiement débité deux fois'), findsOneWidget);
  });
}
