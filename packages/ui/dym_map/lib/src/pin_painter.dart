import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dym_map/src/map_models.dart';
import 'package:flutter/painting.dart';

/// Taille logique d'une épingle (carré de 34 + pointe de 8).
const dymPinSize = Size(34, 42);

/// Dessine une épingle carrée à pointe, l'icône au centre, en PNG à
/// [pixelRatio] (une image nette par densité d'écran).
Future<Uint8List> paintPin(DymPinStyle style, {double pixelRatio = 3}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(pixelRatio);
  const w = 34.0;
  const body = 34.0;
  const tip = 8.0;
  const stroke = 2.5;
  final square = RRect.fromRectAndRadius(
    const Rect.fromLTWH(stroke / 2, stroke / 2, w - stroke, body - stroke),
    const Radius.circular(8),
  );
  final path = Path()
    ..addRRect(square)
    ..moveTo(w / 2 - 6, body - stroke)
    ..lineTo(w / 2, body + tip - stroke / 2)
    ..lineTo(w / 2 + 6, body - stroke)
    ..close();
  canvas
    ..drawShadow(path, const Color(0x55000000), 2, false)
    ..drawPath(path, Paint()..color = style.background)
    ..drawPath(
      path,
      Paint()
        ..color = style.foreground
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.round,
    );
  final icon = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(style.icon.codePoint),
      style: TextStyle(
        fontSize: 20,
        fontFamily: style.icon.fontFamily,
        package: style.icon.fontPackage,
        color: style.foreground,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  icon.paint(canvas, Offset((w - icon.width) / 2, (body - icon.height) / 2));
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (dymPinSize.width * pixelRatio).ceil(),
    (dymPinSize.height * pixelRatio).ceil(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}
