import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('lecteur d’écran : le champ annonce son libellé (spec 068)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: DymTheme.light(),
        home: const Scaffold(
          body: DymTextField(label: 'Ton email', hint: 'prenom@exemple.com'),
        ),
      ),
    );
    final node = tester.getSemantics(
      find.bySemanticsLabel(RegExp('Ton email')),
    );
    expect(node.getSemanticsData().flagsCollection.isTextField, isTrue);
    handle.dispose();
  });
}
