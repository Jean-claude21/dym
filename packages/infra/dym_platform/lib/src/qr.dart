import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// QR affiché à l'écran (paiement par QR, spec 046) : noir sur blanc pour
/// rester lisible en plein soleil.
class DymQrImage extends StatelessWidget {
  const new({required this.data, this.size = 220, super.key});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) => QrImageView(
    data: data,
    size: size,
    backgroundColor: Colors.white,
    errorCorrectionLevel: QrErrorCorrectLevel.M,
  );
}

/// Lecture d'un QR par la caméra ; [onCode] reçoit le premier contenu lu.
/// Caméra refusée ou absente : [fallback] (saisie du code à la main).
class QrScanView extends StatefulWidget {
  const new({required this.onCode, required this.fallback, super.key});

  final ValueChanged<String> onCode;
  final Widget fallback;

  @override
  State<QrScanView> createState() => _QrScanViewState();
}

class _QrScanViewState extends State<QrScanView> {
  bool _done = false;

  @override
  Widget build(BuildContext context) => MobileScanner(
    onDetect: (capture) {
      final value = capture.barcodes
          .map((b) => b.rawValue)
          .whereType<String>()
          .firstOrNull;
      if (value == null || _done) return;
      _done = true;
      widget.onCode(value);
    },
    errorBuilder: (context, error) => widget.fallback,
  );
}
