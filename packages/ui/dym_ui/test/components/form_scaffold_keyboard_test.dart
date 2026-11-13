import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _form({required double keyboard}) => MaterialApp(
  theme: DymTheme.light(),
  home: MediaQuery(
    data: MediaQueryData(
      size: const Size(412, 915),
      viewInsets: EdgeInsets.only(bottom: keyboard),
    ),
    child: DymFormScaffold(
      title: 'Bienvenue',
      backLabel: 'Retour',
      action: FilledButton(onPressed: () {}, child: const Text('Continuer')),
      children: const [TextField()],
    ),
  ),
);

void main() {
  testWidgets('clavier fermé : action en bas de l’écran', (tester) async {
    await tester.pumpWidget(_form(keyboard: 0));
    expect(
      find.descendant(
        of: find.byType(ListView),
        matching: find.text('Continuer'),
      ),
      findsNothing,
    );
    expect(find.text('Continuer'), findsOneWidget);
  });

  testWidgets('clavier ouvert : action à la suite du contenu (spec 068)', (
    tester,
  ) async {
    await tester.pumpWidget(_form(keyboard: 300));
    expect(
      find.descendant(
        of: find.byType(ListView),
        matching: find.text('Continuer'),
      ),
      findsOneWidget,
    );
  });
}
