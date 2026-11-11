import 'dart:io';
import 'dart:typed_data';

import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/cart_fixtures.dart';

/// Rend [child] en téléphone portrait (412 × 915, ×2) et l'enregistre dans
/// `goldens/[name].png` : captures de contrôle du design « Épuré ».
/// [scroll] fait défiler la première liste pour voir le bas de la page ;
/// [before] joue des gestes (feuille ouverte…) avant la capture.
Future<void> capture(
  WidgetTester tester,
  String name,
  Widget child, {
  double scroll = 0,
  Future<void> Function(WidgetTester tester)? before,
}) async {
  const size = Size(412, 915);
  tester.view
    ..physicalSize = size * 2
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: DymTheme.light(),
      locale: const Locale('fr'),
      localizationsDelegates: DymLocalizations.localizationsDelegates,
      supportedLocales: DymLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(
          size: size,
          devicePixelRatio: 2,
          disableAnimations: true,
          padding: EdgeInsets.only(top: 24, bottom: 16),
        ),
        child: CartScope(
          service: memoryCart(),
          onOpenCart: () {},
          child: child,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage(
        (element.widget as Image).image,
        element,
        onError: (_, _) {},
      );
    }
  });
  if (before != null) {
    await before(tester);
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage(
          (element.widget as Image).image,
          element,
          onError: (_, _) {},
        );
      }
    });
  }
  if (scroll > 0) {
    final list = find.byType(Scrollable).first;
    await tester.drag(list, Offset(0, -scroll));
  }
  await tester.pump(const Duration(milliseconds: 600));
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );
}

/// Photos de contrôle (générées, sans texte) pour juger les pages avec de
/// vraies images : couverture de boutique, bissap, tomates, gombo.
ImageProvider capturePhoto(String key) {
  final name = switch (key) {
    _ when key.contains('cover') => 'cover',
    _ when key.contains('tomate') => 'tomates',
    _ when key.contains('bissap') || key.contains('sirop') => 'bissap',
    _ => 'gombo',
  };
  return MemoryImage(
    _photos[name] ??= File('test/capture/photos/$name.webp').readAsBytesSync(),
  );
}

final _photos = <String, Uint8List>{};
