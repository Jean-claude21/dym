import 'package:intl/intl.dart';

/// Compteur court selon la langue : 382 · 12,4 k · 1,2 M (j'aime, vues).
String compactCount(int value, String locale) =>
    NumberFormat.compact(locale: locale).format(value);
