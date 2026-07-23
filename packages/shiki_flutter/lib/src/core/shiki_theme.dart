/// A theme, or a light/dark pair of themes, that a [ShikiTheme] highlighter
/// can be configured with. Implemented by [ShikiTheme] (a single theme) and
/// [ShikiDualTheme] (a light/dark pair resolved at highlight time).
sealed class ShikiThemeBase {
  const ShikiThemeBase();

  /// Creates a [ShikiDualTheme] that resolves to [light] or [dark] depending
  /// on the ambient brightness.
  const factory ShikiThemeBase.dual({
    required ShikiTheme light,
    required ShikiTheme dark,
  }) = ShikiDualTheme;

  /// Returns the concrete [ShikiTheme] to use, choosing [ShikiDualTheme.dark]
  /// or [ShikiDualTheme.light] when [isDark] applies; a plain [ShikiTheme]
  /// ignores [isDark] and always returns itself.
  ShikiTheme resolve({required bool isDark});

  /// Every concrete [ShikiTheme] this references, for eager loading (see
  /// `ShikiHighlighter.preload`): a single theme yields itself; a
  /// [ShikiDualTheme] yields both its light and dark themes.
  List<ShikiTheme> get themes;
}

// Value type describing a theme that ships with the package.
//
// Like [BundledLanguage], each theme lives in its own library under
// `lib/themes/` and is referenced by symbol, so unused themes are tree-shaken.
/// A single bundled theme description.
class ShikiTheme extends ShikiThemeBase {
  /// Creates a theme description. Bundled themes are constructed once as
  /// `const` values in their own `lib/themes/*.dart` file.
  const ShikiTheme({
    required this.id,
    required this.type,
    required this.json,
  });

  /// The theme id / name (e.g. `github-dark`).
  final String id;

  /// `'light'` or `'dark'`.
  final String type;

  /// The raw theme JSON, parsed on load.
  final String json;

  @override
  ShikiTheme resolve({required bool isDark}) => this;

  @override
  List<ShikiTheme> get themes => [this];
}

/// A pair of themes that [resolve] switches between based on brightness,
/// letting a highlighter track light/dark mode without being rebuilt.
class ShikiDualTheme extends ShikiThemeBase {
  /// The theme used when [resolve] is called with `isDark: false`.
  final ShikiTheme light;

  /// The theme used when [resolve] is called with `isDark: true`.
  final ShikiTheme dark;

  /// Creates a dual theme from its [light] and [dark] variants.
  const ShikiDualTheme({required this.light, required this.dark});

  @override
  ShikiTheme resolve({required bool isDark}) => isDark ? dark : light;

  @override
  List<ShikiTheme> get themes => [light, dark];
}
