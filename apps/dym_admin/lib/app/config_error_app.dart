import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Affichée quand l'app est compilée sans configuration valide (production
/// sans URLs) : aucune requête n'est tentée.
class ConfigErrorApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: DymTheme.light(),
    debugShowCheckedModeBanner: false,
    localizationsDelegates: DymLocalizations.localizationsDelegates,
    supportedLocales: DymLocalizations.supportedLocales,
    home: Builder(
      builder: (context) {
        final l10n = DymLocalizations.of(context);
        return Scaffold(
          body: SafeArea(
            child: DymStateView(
              kind: DymStateKind.error,
              title: l10n.configErrorTitle,
              message: l10n.configErrorMessage,
            ),
          ),
        );
      },
    ),
  );
}
