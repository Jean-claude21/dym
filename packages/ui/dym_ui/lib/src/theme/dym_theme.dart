import 'package:dym_ui/src/theme/dym_colors.dart';
import 'package:dym_ui/src/theme/dym_text_styles.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Thème DYM « Le marché de Lomé, livré chez toi ». Clair uniquement (0009).
abstract final class DymTheme {
  /// Thème clair validé.
  static ThemeData light() {
    const c = DymColors.light;
    final t = DymTextStyles.light;
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: DymTokenColors.brandPrimary,
      onPrimary: DymTokenColors.textOnBrand,
      secondary: DymTokenColors.accentPlantain,
      onSecondary: DymTokenColors.textPrimary,
      error: DymTokenColors.accentPimentStrong,
      onError: DymTokenColors.textOnBrand,
      surface: DymTokenColors.surfaceCard,
      onSurface: DymTokenColors.textPrimary,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      fontFamily: DymTokenFonts.body,
      package: DymTokenFonts.package,
      splashFactory: InkSparkle.splashFactory,
      textTheme: TextTheme(
        headlineMedium: t.display,
        titleLarge: t.title,
        titleMedium: t.title.copyWith(fontSize: 16),
        bodyLarge: t.body,
        bodyMedium: t.body,
        labelLarge: t.label,
        labelMedium: t.label,
      ),
      extensions: [c, t],
    );
  }
}

/// Accès court aux valeurs DYM : `context.dym.colors`, `context.dym.text`.
extension DymThemeContext on BuildContext {
  /// Palette et styles DYM du thème courant.
  DymThemeValues get dym {
    final theme = Theme.of(this);
    return DymThemeValues(
      colors: theme.extension<DymColors>() ?? DymColors.light,
      text: theme.extension<DymTextStyles>() ?? DymTextStyles.light,
    );
  }
}

/// Valeurs DYM résolues depuis le thème.
@immutable
class DymThemeValues {
  /// Regroupe palette et styles.
  const new({required this.colors, required this.text});

  /// Palette.
  final DymColors colors;

  /// Styles de texte.
  final DymTextStyles text;
}
