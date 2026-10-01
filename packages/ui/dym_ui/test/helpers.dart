import 'dart:typed_data';

import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monte [child] dans le thème DYM.
Future<void> pumpDym(
  WidgetTester tester,
  Widget child, {
  bool disableAnimations = false,
  double textScale = 1,
  Size size = const Size(412, 915),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DymTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          disableAnimations: disableAnimations,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

/// Petite image PNG valide (4 × 1, crème), générée avec un CRC correct.
final testImage = MemoryImage(
  Uint8List.fromList(const [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x04,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0xF9,
    0x3C,
    0x0F,
    0xCD,
    0x00,
    0x00,
    0x00,
    0x0F,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0xF8,
    0xFD,
    0xED,
    0xCD,
    0x7F,
    0x64,
    0x0C,
    0x00,
    0x83,
    0x45,
    0x0F,
    0x71,
    0x54,
    0x18,
    0x27,
    0xC5,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]),
);

/// Image introuvable : doit déclencher le repli des composants.
const missingImage = AssetImage('assets/introuvable.webp');
