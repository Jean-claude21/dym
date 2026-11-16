import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_notifications/dym_notifications.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AppNotification _n(String id, String kind, {bool read = false}) =>
    AppNotification(
      id: id,
      kind: kind,
      category: NotificationCategory.orders,
      createdAt: DateTime.now(),
      readAt: read ? DateTime.now() : null,
      orderId: 'o-$id',
      text: {'title': 'Titre $id', 'body': 'Texte $id'},
    );

void main() {
  testWidgets('boîte : texte rendu, lecture, ouverture', (tester) async {
    final service = MemoryNotificationInboxService([
      _n('1', 'new_order'),
      _n('2', 'call_missed_vendor', read: true),
    ]);
    AppNotification? opened;
    await tester.pumpWidget(
      MaterialApp(
        theme: DymTheme.light(),
        locale: const Locale('fr'),
        localizationsDelegates: DymLocalizations.localizationsDelegates,
        supportedLocales: DymLocalizations.supportedLocales,
        home: NotificationInboxView(
          service: service,
          onOpen: (n) => opened = n,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Titre 1'), findsOneWidget);
    expect(find.text('Texte 2'), findsOneWidget);
    expect(service.read, ['1'], reason: 'ouvrir la boîte vaut lecture');
    await tester.tap(find.text('Titre 1'));
    expect(opened?.orderId, 'o-1');
  });

  testWidgets('vide : message clair', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DymTheme.light(),
        localizationsDelegates: DymLocalizations.localizationsDelegates,
        supportedLocales: DymLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: NotificationInboxView(
          service: MemoryNotificationInboxService(),
          onOpen: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aucune notification'), findsOneWidget);
  });
}
