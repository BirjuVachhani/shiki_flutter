// Value type describing a theme that ships with the package.
//
// Like [BundledLanguage], each theme lives in its own library under
// `lib/themes/` and is referenced by symbol, so unused themes are tree-shaken.
class ShikiTheme {
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
}
