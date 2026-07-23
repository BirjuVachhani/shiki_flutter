// Value type describing a language grammar that ships with the package.
//
// Each bundled grammar lives in its own library under `lib/langs/` and is
// referenced by symbol, so the Dart compiler tree-shakes away any grammar the
// consuming app never imports. The heavy grammar JSON is stored as a `const`
// string; `embeddedLanguages` is a lazy thunk so grammars can reference each
// other (e.g. HTML -> CSS/JS) without forming a `const` initialization cycle.
/// A bundled TextMate grammar and its metadata (id, aliases, display name,
/// classification, and the embedded grammars it depends on).
class CodeLanguage {
  /// Creates a language description. Bundled grammars are constructed once as
  /// `const` values in their own `lib/langs/*.dart` file.
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
  /// Web technologies, e.g. HTML, CSS, JavaScript, JSON, GraphQL.
  web,

  /// Markup and documentation languages, e.g. Markdown, LaTeX, AsciiDoc.
  markup,

  /// General-purpose programming languages, e.g. Python, Kotlin, C, Haskell.
  general,

  /// Scripting languages, e.g. Bat, ActionScript.
  scripting,

  /// Data-interchange and serialization formats, e.g. YAML, TSV, RON.
  data,

  /// Domain-specific languages, e.g. SQL, QML, ShaderLab, regex.
  dsl,

  /// Small utility file formats, e.g. PO, git-rebase todo lists.
  utility,

  /// Configuration file formats, e.g. Dockerfile, Nginx, desktop entries.
  config,

  /// Lisp-family languages, e.g. Racket, Common Lisp, Emacs Lisp.
  lisp,
}

List<CodeLanguage> _noEmbedded() => const [];
