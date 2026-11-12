import 'package:dym_ui/src/theme/dym_colors.dart';
import 'package:dym_ui/src/theme/dym_text_styles.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Thème DYM « Épuré, formes tenues » (décision 0016). Clair uniquement ; le
/// mode vidéo plein écran est la seule surface sombre.
///
/// Les thèmes de composants Material sont réglés ici pour que chaque page, y
/// compris celles qui utilisent des widgets Material directement, suive le
/// design : filets plutôt qu'ombres, rayons 10–12 px, Inter, un seul vert.
abstract final class DymTheme {
  /// Thème clair.
  static ThemeData light() {
    const c = DymColors.light;
    final t = DymTextStyles.light;
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: DymTokenColors.brandPrimary,
      onPrimary: DymTokenColors.textOnBrand,
      primaryContainer: DymTokenColors.tintVertTendre,
      onPrimaryContainer: DymTokenColors.brandPrimaryDeep,
      secondary: DymTokenColors.brandPrimaryDeep,
      onSecondary: DymTokenColors.textOnBrand,
      secondaryContainer: DymTokenColors.tintVertTendre,
      onSecondaryContainer: DymTokenColors.brandPrimaryDeep,
      tertiary: DymTokenColors.accentPlantain,
      onTertiary: DymTokenColors.textPrimary,
      error: DymTokenColors.accentPimentStrong,
      onError: DymTokenColors.textOnBrand,
      errorContainer: DymTokenColors.tintPimentClair,
      onErrorContainer: DymTokenColors.accentPimentStrong,
      surface: DymTokenColors.surfaceCard,
      onSurface: DymTokenColors.textPrimary,
      onSurfaceVariant: DymTokenColors.textSecondary,
      surfaceContainerLowest: DymTokenColors.surfaceCard,
      surfaceContainerLow: DymTokenColors.surfaceBackground,
      surfaceContainer: DymTokenColors.surfaceCard,
      surfaceContainerHigh: DymTokenColors.surfaceCard,
      surfaceContainerHighest: DymTokenColors.surfaceMuted,
      outline: DymTokenColors.lineStrong,
      outlineVariant: DymTokenColors.lineHairline,
      surfaceTint: Colors.transparent,
      shadow: Color(0x1F16201B),
      inverseSurface: DymTokenColors.textPrimary,
      onInverseSurface: DymTokenColors.surfaceCard,
    );
    const radius = BorderRadius.all(Radius.circular(DymTokenRadius.button));
    const fieldRadius = BorderRadius.all(Radius.circular(DymTokenRadius.field));
    const buttonShape = RoundedRectangleBorder(borderRadius: radius);
    final buttonText = t.body.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );
    const buttonSize = Size(48, DymTokenSize.buttonHeight);
    OutlineInputBorder field(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      fontFamily: DymTokenFonts.body,
      package: DymTokenFonts.package,
      // Ondulation simple : légère sur un Android d'entrée de gamme.
      splashFactory: InkRipple.splashFactory,
      dividerColor: c.hairline,
      textTheme: TextTheme(
        displaySmall: t.display,
        headlineMedium: t.display,
        headlineSmall: t.display.copyWith(fontSize: 24),
        titleLarge: t.title,
        titleMedium: t.title.copyWith(fontSize: 16),
        titleSmall: t.body.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: t.body,
        bodyMedium: t.body,
        bodySmall: t.label.copyWith(
          fontWeight: FontWeight.w400,
          color: c.textSecondary,
        ),
        labelLarge: t.label,
        labelMedium: t.label,
        labelSmall: t.label.copyWith(fontSize: 12),
      ),
      iconTheme: IconThemeData(color: c.textPrimary, size: 24),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        titleTextStyle: t.title,
        iconTheme: IconThemeData(color: c.textPrimary),
        shape: Border(bottom: BorderSide(color: c.background)),
      ),
      cardTheme: CardThemeData(
        color: c.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(DymTokenRadius.card),
          ),
          side: BorderSide(color: c.hairline),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.hairline, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
        titleTextStyle: t.body.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: t.label.copyWith(
          fontWeight: FontWeight.w400,
          color: c.textSecondary,
        ),
        minVerticalPadding: 12,
        shape: const RoundedRectangleBorder(borderRadius: radius),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.brand,
          foregroundColor: c.onBrand,
          disabledBackgroundColor: c.muted,
          disabledForegroundColor: c.textSecondary,
          minimumSize: buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: buttonShape,
          textStyle: buttonText,
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.brand,
          foregroundColor: c.onBrand,
          minimumSize: buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: buttonShape,
          textStyle: buttonText,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          minimumSize: buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: buttonShape,
          side: BorderSide(color: c.lineStrong),
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.brand,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: buttonShape,
          textStyle: buttonText.copyWith(fontSize: 15),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: c.textPrimary,
          minimumSize: const Size(48, 48),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.brand,
        foregroundColor: c.onBrand,
        elevation: 0,
        highlightElevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: radius),
        extendedTextStyle: buttonText,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.card,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: t.body.copyWith(color: c.textSecondary),
        floatingLabelStyle: t.label.copyWith(color: c.brandDeep),
        hintStyle: t.body.copyWith(color: c.textSecondary),
        helperStyle: t.label.copyWith(
          fontWeight: FontWeight.w400,
          color: c.textSecondary,
        ),
        errorStyle: t.label.copyWith(color: c.pimentStrong),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: field(c.lineStrong),
        enabledBorder: field(c.lineStrong),
        focusedBorder: field(c.brand, 2),
        errorBorder: field(c.pimentStrong),
        focusedErrorBorder: field(c.pimentStrong, 2),
        disabledBorder: field(c.hairline),
        prefixIconColor: c.textSecondary,
        suffixIconColor: c.textSecondary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.card,
        selectedColor: c.brand,
        disabledColor: c.muted,
        checkmarkColor: c.onBrand,
        labelStyle: t.label.copyWith(color: c.textPrimary),
        secondaryLabelStyle: t.label.copyWith(color: c.onBrand),
        side: BorderSide(color: c.lineStrong),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(DymTokenRadius.chip)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        showCheckmark: false,
        elevation: 0,
        pressElevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: c.lineStrong,
        dragHandleSize: const Size(36, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DymTokenRadius.card + 4),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: t.title,
        contentTextStyle: t.body,
        shape: const RoundedRectangleBorder(borderRadius: radius),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.textPrimary,
        contentTextStyle: t.body.copyWith(color: c.card),
        actionTextColor: c.plantain,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: fieldRadius),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(c.card),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.brand : c.lineStrong,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? c.brand : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(c.onBrand),
        side: BorderSide(color: c.lineStrong, width: 1.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.brand : c.lineStrong,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.brand,
        linearTrackColor: c.muted,
        circularTrackColor: Colors.transparent,
        linearMinHeight: 6,
        borderRadius: const BorderRadius.all(Radius.circular(3)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: c.textPrimary,
        unselectedLabelColor: c.textSecondary,
        labelStyle: t.body.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: t.body,
        indicatorColor: c.brand,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: c.hairline,
        overlayColor: WidgetStateProperty.all(c.tintVertTendre),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: c.card,
          foregroundColor: c.textPrimary,
          selectedBackgroundColor: c.brand,
          selectedForegroundColor: c.onBrand,
          side: BorderSide(color: c.lineStrong),
          shape: const RoundedRectangleBorder(borderRadius: fieldRadius),
          textStyle: t.label,
          minimumSize: const Size(48, 44),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: c.tintVertTendre,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => t.label.copyWith(
            fontSize: 12,
            color: s.contains(WidgetState.selected) ? c.brand : c.textSecondary,
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.textPrimary,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        textStyle: t.label.copyWith(color: c.card),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.card,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: c.hairline),
        ),
        textStyle: t.body,
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: c.pimentStrong,
        textColor: c.onBrand,
        textStyle: t.label.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.brand,
        selectionColor: c.tintVertTendre,
        selectionHandleColor: c.brand,
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
