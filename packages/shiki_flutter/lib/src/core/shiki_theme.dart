sealed class ShikiThemeBase {
  const ShikiThemeBase();

  const factory ShikiThemeBase.dual({
    required ShikiTheme light,
    required ShikiTheme dark,
  }) = ShikiDualTheme;

  ShikiTheme resolve({required bool isDark});
}

// Value type describing a theme that ships with the package.
//
// Like [BundledLanguage], each theme lives in its own library under
// `lib/themes/` and is referenced by symbol, so unused themes are tree-shaken.
class ShikiTheme extends ShikiThemeBase {
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
}

class ShikiDualTheme extends ShikiThemeBase {
  final ShikiTheme light;
  final ShikiTheme dark;

  const ShikiDualTheme({required this.light, required this.dark});

  @override
  ShikiTheme resolve({required bool isDark}) => isDark ? dark : light;
}
