// A theme selection: either a single theme or a light/dark pair.
//
// Kept Flutter-free (no `dart:ui`/`Brightness`) so it can live in core and be
// re-exported from the Flutter-free `engine.dart`. The Flutter layer maps
// `Theme.of(context).brightness` to the [isDark] flag that [resolve] takes.

import 'shiki_theme.dart';

/// Selects the theme(s) a highlighter renders with: either a single [ShikiTheme]
/// or a light/dark pair chosen automatically from the ambient brightness.
///
/// Construct it with one of the two factories and either set it as the global
/// default on [ShikiHighlighterConfig.defaultTheme] or pass it to a widget's
/// `theme:` argument:
///
/// ```dart
/// // One theme everywhere.
/// ShikiThemeConfig.single(ShikiThemes.githubDark);
///
/// // Light in light mode, dark in dark mode (picked from Theme.of(context)).
/// ShikiThemeConfig.dual(
///   light: ShikiThemes.githubLight,
///   dark: ShikiThemes.githubDark,
/// );
/// ```
sealed class ShikiThemeConfig {
  const ShikiThemeConfig();

  /// A single theme used regardless of brightness.
  const factory ShikiThemeConfig.single(ShikiTheme theme) = SingleThemeConfig;

  /// A light/dark pair; [resolve] returns [dark] when `isDark`, else [light].
  const factory ShikiThemeConfig.dual({
    required ShikiTheme light,
    required ShikiTheme dark,
  }) = DualThemeConfig;

  /// The concrete theme for the given brightness. A [ShikiThemeConfig.dual]
  /// picks by [isDark]; a [ShikiThemeConfig.single] ignores it.
  ShikiTheme resolve({required bool isDark});

  /// Every theme this config references, for eager or on-demand loading.
  List<ShikiTheme> get themes;
}

/// A [ShikiThemeConfig] holding one theme; see [ShikiThemeConfig.single].
final class SingleThemeConfig extends ShikiThemeConfig {
  const SingleThemeConfig(this.theme);

  final ShikiTheme theme;

  @override
  ShikiTheme resolve({required bool isDark}) => theme;

  @override
  List<ShikiTheme> get themes => [theme];
}

/// A [ShikiThemeConfig] holding a light/dark pair; see [ShikiThemeConfig.dual].
final class DualThemeConfig extends ShikiThemeConfig {
  const DualThemeConfig({required this.light, required this.dark});

  final ShikiTheme light;
  final ShikiTheme dark;

  @override
  ShikiTheme resolve({required bool isDark}) => isDark ? dark : light;

  @override
  List<ShikiTheme> get themes => [light, dark];
}
