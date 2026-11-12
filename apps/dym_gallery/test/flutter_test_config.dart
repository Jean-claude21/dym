import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Charge les vraies polices (Inter, icônes Material) pour que
/// les captures golden soient comparables aux écrans validés.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> load(String family, String asset) async {
    final loader = FontLoader(family)..addFont(rootBundle.load(asset));
    await loader.load();
  }

  await load(
    'packages/dym_ui/Inter',
    'packages/dym_ui/fonts/Inter[opsz,wght].ttf',
  );
  await load('MaterialIcons', 'fonts/MaterialIcons-Regular.otf');
  await testMain();
}
