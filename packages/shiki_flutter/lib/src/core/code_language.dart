// Value type describing a language grammar that ships with the package.
//
// Each bundled grammar lives in its own library under `lib/langs/` and is
// referenced by symbol, so the Dart compiler tree-shakes away any grammar the
// consuming app never imports. The heavy grammar JSON is stored as a `const`
// string; `embeddedLanguages` is a lazy thunk so grammars can reference each
// other (e.g. HTML -> CSS/JS) without forming a `const` initialization cycle.
class CodeLanguage {
  const CodeLanguage({
    required this.id,
    required this.scopeName,
    required this.displayName,
    required this.json,
    this.embeddedLanguages = _noEmbedded,
    this.aliases = const [],
    this.categories = const [],
  });

  /// The language id (e.g. `dart`, `javascript`).
  final String id;

  /// The grammar's TextMate scope name (e.g. `source.dart`).
  final String scopeName;

  /// The human-readable name (e.g. `Dart`, `Angular HTML`), suitable for use as
  /// a label in a language picker. Falls back to [id] when the grammar source
  /// provides no display name.
  final String displayName;

  /// The raw `.tmLanguage.json` grammar as a JSON string, parsed on load.
  final String json;

  /// Grammars this language embeds (loaded automatically alongside it).
  final List<CodeLanguage> Function() embeddedLanguages;

  /// Alternative names that resolve to this language (e.g. `js` -> `javascript`).
  final List<String> aliases;

  /// The grammar's classification (from `tm-grammars`, e.g. `web`, `scripting`).
  /// May be empty: not every grammar declares a category.
  final List<GrammarCategory> categories;
}

/// The classification tags a [CodeLanguage] can carry, mirroring the
/// `GrammarCategory` union from `tm-grammars`.
enum GrammarCategory {
  web,
  markup,
  general,
  scripting,
  data,
  dsl,
  utility,
  config,
  lisp,
}

List<CodeLanguage> _noEmbedded() => const [];
