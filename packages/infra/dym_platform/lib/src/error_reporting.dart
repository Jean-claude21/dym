import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry/sentry.dart';

/// Lance l'app avec le suivi des erreurs (constitution IX) : erreurs non
/// gérées de Flutter et de la plateforme envoyées à Sentry ou GlitchTip.
///
/// Sans `DYM_ERROR_DSN`, l'app démarre normalement et rien n'est envoyé.
/// Client Dart pur (`sentry`) : aucun code natif, aucune contrainte de
/// version Android. Aucune donnée personnelle : `sendDefaultPii` est coupé et
/// l'app n'attache jamais d'utilisateur ; pas de trace de performance.
Future<void> runWithErrorReporting({
  required DymEnvironment environment,
  required String app,
  required FutureOr<void> Function() body,
}) async {
  final dsn = environment.errorReportingDsn;
  if (dsn == null) {
    await body();
    return;
  }
  await Sentry.init(
    (options) => options
      ..dsn = dsn.toString()
      ..environment = environment.name.name
      ..release = 'dym-$app'
      ..sendDefaultPii = false
      ..tracesSampleRate = 0,
  );
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    previous?.call(details);
    unawaited(
      Sentry.captureException(details.exception, stackTrace: details.stack),
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(Sentry.captureException(error, stackTrace: stack));
    // Laisse aussi l'erreur suivre son chemin habituel (journal).
    return false;
  };
  await body();
}
