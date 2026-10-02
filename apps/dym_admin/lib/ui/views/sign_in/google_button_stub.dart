import 'package:flutter/widgets.dart';

/// Hors web : pas de bouton rendu par le SDK Google.
Widget? googleWebButton({
  required String clientId,
  required void Function(String idToken) onIdToken,
}) => null;
