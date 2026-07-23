// A sendable mirror of [BundledLanguage] for shipping grammars into a worker
// isolate.
//
// [BundledLanguage.embeddedLanguages] is a `Function()` thunk, which cannot be
// sent across a `SendPort`. We flatten it on the main isolate (where calling
// the thunk is fine) into a plain, sendable tree of [LangDescriptor]s, then
// rebuild an equivalent [BundledLanguage] inside the worker.

import '../core/code_language.dart';

/// A plain, isolate-sendable description of a [CodeLanguage] and the
/// grammars it embeds.
///
/// Every field is a `String`, `List<String>`, `List<GrammarCategory>` (enums are
/// sendable), or `List<LangDescriptor>`: no closures, so an instance copies
/// cleanly across an isolate boundary.
class LangDescriptor {
  /// Creates a [LangDescriptor]; [id], [scopeName], [displayName], and
  /// [json] are required, mirroring the required fields of [CodeLanguage].
  const LangDescriptor({
    required this.id,
    required this.scopeName,
    required this.displayName,
    required this.json,
    this.aliases = const [],
    this.categories = const [],
    this.embedded = const [],
  });

  /// The language id (e.g. `dart`, `javascript`).
  final String id;

  /// The grammar's TextMate scope name (e.g. `source.dart`).
  final String scopeName;

  /// A human-readable name for the language, e.g. for use as a label in a
  /// language picker.
  final String displayName;

  /// The raw `.tmLanguage.json` grammar as a JSON string, parsed on load.
  final String json;

  /// Alternative names that resolve to this language (e.g. `js` -> `javascript`).
  final List<String> aliases;

  /// The grammar's classification (from `tm-grammars`, e.g. `web`, `scripting`).
  /// May be empty: not every grammar declares a category.
  final List<GrammarCategory> categories;

  /// The flattened grammars this language embeds, already expanded by
  /// [flattenBundledLanguage] (in place of [CodeLanguage]'s lazy thunk,
  /// which can't cross an isolate boundary).
  final List<LangDescriptor> embedded;
}

/// Flattens [lang] (and, transitively, the grammars it embeds) into a sendable
/// [LangDescriptor] tree by invoking the `embeddedLanguages()` thunk on the
/// current (main) isolate.
///
/// [seen] guards against embedding cycles (e.g. two grammars that reference each
/// other): a scope already expanded higher in the tree is included as a leaf, so
/// every grammar still appears at least once while recursion stays finite. The
/// worker's [CodeLanguage] loader is idempotent by scope, so the duplicate is
/// skipped there.
LangDescriptor flattenBundledLanguage(
  CodeLanguage lang, [
  Set<String>? seen,
]) {
  seen ??= <String>{};
  final embedded = <LangDescriptor>[];
  if (seen.add(lang.scopeName)) {
    for (final child in lang.embeddedLanguages()) {
      embedded.add(flattenBundledLanguage(child, seen));
    }
  }
  return LangDescriptor(
    id: lang.id,
    scopeName: lang.scopeName,
    displayName: lang.displayName,
    json: lang.json,
    aliases: lang.aliases,
    categories: lang.categories,
    embedded: embedded,
  );
}

/// Rebuilds a [CodeLanguage] from a [LangDescriptor] inside the worker, with
/// an `embeddedLanguages` thunk that closes over the descriptor's children.
CodeLanguage rebuildBundledLanguage(LangDescriptor d) => CodeLanguage(
  id: d.id,
  scopeName: d.scopeName,
  displayName: d.displayName,
  json: d.json,
  aliases: d.aliases,
  categories: d.categories,
  embeddedLanguages: () => d.embedded.map(rebuildBundledLanguage).toList(),
);
