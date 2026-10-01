import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _items = [
  DymNavItem(icon: Icons.home_rounded, label: 'Accueil'),
  DymNavItem(icon: Icons.grid_view_rounded, label: 'Rayons'),
  DymNavItem(icon: Icons.receipt_long_rounded, label: 'Commandes'),
  DymNavItem(icon: Icons.person_outline_rounded, label: 'Moi'),
];

class _Counter extends StatefulWidget {
  const new();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int n = 0;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => setState(() => n++),
    child: Text('compteur $n'),
  );
}

class _Host extends StatefulWidget {
  const new();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int index = 0;

  @override
  Widget build(BuildContext context) => DymAdaptiveScaffold(
    destinations: _items,
    currentIndex: index,
    onDestinationSelected: (i) => setState(() => index = i),
    body: const Center(child: _Counter()),
  );
}

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(theme: DymTheme.light(), home: const _Host()),
  );
}

void main() {
  testWidgets('compacte (400) : barre basse', (tester) async {
    await _pump(tester, const Size(400, 800));
    expect(find.byType(DymBottomNav), findsOneWidget);
    expect(find.byType(DymNavRail), findsNothing);
  });

  for (final width in [700.0, 1000.0]) {
    testWidgets('moyenne/étendue ($width) : rail compact', (tester) async {
      await _pump(tester, Size(width, 800));
      expect(find.byType(DymBottomNav), findsNothing);
      final rail = tester.widget<DymNavRail>(find.byType(DymNavRail));
      expect(rail.extended, isFalse);
      expect(
        tester.getSize(find.byType(DymNavRail)).width,
        DymTokenLayout.railWidth,
      );
    });
  }

  testWidgets('large (1300) : rail étendu, toute la hauteur', (tester) async {
    await _pump(tester, const Size(1300, 800));
    final rail = tester.widget<DymNavRail>(find.byType(DymNavRail));
    expect(rail.extended, isTrue);
    expect(tester.getRect(find.byType(DymNavRail)).height, 800);
    expect(tester.getRect(find.byType(DymNavRail)).top, 0);
    expect(find.text('Commandes'), findsOneWidget);
  });

  testWidgets('sélection et sémantique dans le rail, cibles ≥ 48', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, const Size(1000, 800));
    await tester.tap(find.text('Rayons'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Rayons')),
      isSemantics(label: 'Rayons', isButton: true, isSelected: true),
    );
    for (final label in ['Accueil', 'Rayons', 'Commandes', 'Moi']) {
      final size = tester.getSize(
        find.ancestor(of: find.text(label), matching: find.byType(InkWell)),
      );
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    }
    handle.dispose();
  });

  testWidgets('le corps garde son état au changement de classe', (
    tester,
  ) async {
    await _pump(tester, const Size(400, 800));
    await tester.tap(find.text('compteur 0'));
    await tester.pump();
    expect(find.text('compteur 1'), findsOneWidget);

    tester.view.physicalSize = const Size(1300, 800);
    await tester.pumpAndSettle();
    expect(find.byType(DymNavRail), findsOneWidget);
    expect(find.text('compteur 1'), findsOneWidget);
  });
}
