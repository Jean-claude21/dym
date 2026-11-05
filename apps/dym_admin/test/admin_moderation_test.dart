import 'package:dym_admin/features/moderation/moderation_view.dart';
import 'package:dym_admin/features/ops/testing.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
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

final _now = DateTime.utc(2026, 10, 5, 11);
DateTime _clock() => _now;

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(1440, 900),
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
        child: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  test('modération : garder, retirer, raison obligatoire', () async {
    final service = MemoryAdminService();
    final vm = AdminModerationViewModel(service: service);
    await vm.load();
    expect(vm.items, hasLength(4));
    final video = vm.items!.first;
    expect(await vm.decide(video, remove: true, reason: ' '), isFalse);
    expect(vm.actionFailure, const ValidationFailure('reason_required'));
    expect(
      await vm.decide(video, remove: true, reason: 'Contenu trompeur'),
      isTrue,
    );
    expect(vm.items, hasLength(3));
    await vm.selectDecided(value: true);
    expect(vm.items!.single.status, 'removed');
    expect(service.gestures, ['r-video:removed']);
  });

  group('écran 76 aux 7 tailles, texte 130 %', () {
    for (final size in _sizes) {
      for (final locale in const [Locale('fr'), Locale('en')]) {
        testWidgets('76 · ${size.width.toInt()}×${size.height.toInt()} · '
            '${locale.languageCode}', (tester) async {
          await _pump(
            tester,
            AdminModerationView(service: MemoryAdminService(), clock: _clock),
            size: size,
            locale: locale,
            textScale: 1.3,
          );
          expect(tester.takeException(), isNull);
          await tester.tap(find.textContaining("Étal d'Akossiwa").first);
          await _settle(tester);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  testWidgets('76 : retirer avec une raison', (tester) async {
    final l10n = await DymLocalizations.delegate.load(const Locale('fr'));
    final service = MemoryAdminService();
    await _pump(tester, AdminModerationView(service: service, clock: _clock));
    await tester.tap(find.textContaining('Les jus').first);
    await _settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Spam répété');
    await tester.pump();
    await tester.tap(find.text(l10n.moderationRemove));
    await _settle(tester);
    expect(service.gestures, ['r-story:removed']);
  });
}
