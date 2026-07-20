import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds the [ThemeData] for a given [brightness], wiring in the [AppColors]
/// extension, the Inter UI font, and a neutral, low-chrome Material baseline.
ThemeData buildTheme(Brightness brightness) {
  final colors = brightness == Brightness.dark ? AppColors.dark : AppColors.light;

  final scheme = ColorScheme.fromSeed(
    seedColor: colors.foreground,
    brightness: brightness,
  ).copyWith(
    surface: colors.background,
    onSurface: colors.foreground,
    primary: colors.primary,
    onPrimary: colors.onPrimary,
  );

  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.background,
    fontFamily: AppFonts.sans,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: colors.foreground.withValues(alpha: 0.04),
  );

  return base.copyWith(
    extensions: [colors],
    textTheme: _textTheme(base.textTheme, colors.foreground),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.foreground,
      selectionColor: colors.link.withValues(alpha: 0.28),
      selectionHandleColor: colors.link,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        final hovered = states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.dragged);
        return colors.foreground.withValues(alpha: hovered ? 0.45 : 0.28);
      }),
      thickness: const WidgetStatePropertyAll(6),
      radius: const Radius.circular(8),
      crossAxisMargin: 3,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: colors.surfaceInset,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: colors.border),
      ),
      textStyle: TextStyle(
        color: colors.foreground,
        fontFamily: AppFonts.sans,
        fontSize: 12,
      ),
    ),
  );
}

TextTheme _textTheme(TextTheme base, Color fg) {
  TextStyle apply(TextStyle? s) =>
      (s ?? const TextStyle()).copyWith(color: fg, fontFamily: AppFonts.sans);
  return base.apply(fontFamily: AppFonts.sans).copyWith(
        displayLarge: apply(base.displayLarge),
        displayMedium: apply(base.displayMedium),
        headlineLarge: apply(base.headlineLarge),
        headlineMedium: apply(base.headlineMedium),
        titleLarge: apply(base.titleLarge),
        bodyLarge: apply(base.bodyLarge),
        bodyMedium: apply(base.bodyMedium),
      );
}
