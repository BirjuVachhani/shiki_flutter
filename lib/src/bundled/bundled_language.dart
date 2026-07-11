// Value type describing a language grammar that ships with the package.
//
// Each bundled grammar lives in its own library under `lib/langs/` and is
// referenced by symbol, so the Dart compiler tree-shakes away any grammar the
// consuming app never imports. The heavy grammar JSON is stored as a `const`
// string; `embeddedLanguages` is a lazy thunk so grammars can reference each
// other (e.g. HTML -> CSS/JS) without forming a `const` initialization cycle.
library;

class BundledLanguage {
  const BundledLanguage({
    required this.id,
    required this.scopeName,
    required this.json,
    this.embeddedLanguages = _noEmbedded,
    this.aliases = const [],
  });

  /// The language id (e.g. `dart`, `javascript`).
  final String id;

  /// The grammar's TextMate scope name (e.g. `source.dart`).
  final String scopeName;

  /// The raw `.tmLanguage.json` grammar as a JSON string, parsed on load.
  final String json;

  /// Grammars this language embeds (loaded automatically alongside it).
  final List<BundledLanguage> Function() embeddedLanguages;

  /// Alternative names that resolve to this language (e.g. `js` -> `javascript`).
  final List<String> aliases;
}

List<BundledLanguage> _noEmbedded() => const [];
