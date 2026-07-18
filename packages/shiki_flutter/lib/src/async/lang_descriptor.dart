// A sendable mirror of [BundledLanguage] for shipping grammars into a worker
// isolate.
//
// [BundledLanguage.embeddedLanguages] is a `Function()` thunk, which cannot be
// sent across a `SendPort`. We flatten it on the main isolate (where calling
// the thunk is fine) into a plain, sendable tree of [LangDescriptor]s, then
// rebuild an equivalent [BundledLanguage] inside the worker.
library;

import '../bundled/bundled_language.dart';

/// A plain, isolate-sendable description of a [BundledLanguage] and the
/// grammars it embeds.
///
/// Every field is a `String`, `List<String>`, or `List<LangDescriptor>` — no
/// closures, so an instance copies cleanly across an isolate boundary.
class LangDescriptor {
  const LangDescriptor({
    required this.id,
    required this.scopeName,
    required this.json,
    this.aliases = const [],
    this.embedded = const [],
  });

  final String id;
  final String scopeName;
  final String json;
  final List<String> aliases;
  final List<LangDescriptor> embedded;
}

/// Flattens [lang] (and, transitively, the grammars it embeds) into a sendable
/// [LangDescriptor] tree by invoking the `embeddedLanguages()` thunk on the
/// current (main) isolate.
///
/// [seen] guards against embedding cycles (e.g. two grammars that reference each
/// other): a scope already expanded higher in the tree is included as a leaf, so
/// every grammar still appears at least once while recursion stays finite. The
/// worker's [BundledLanguage] loader is idempotent by scope, so the duplicate is
/// skipped there.
LangDescriptor flattenBundledLanguage(BundledLanguage lang, [Set<String>? seen]) {
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
    json: lang.json,
    aliases: lang.aliases,
    embedded: embedded,
  );
}

/// Rebuilds a [BundledLanguage] from a [LangDescriptor] inside the worker, with
/// an `embeddedLanguages` thunk that closes over the descriptor's children.
BundledLanguage rebuildBundledLanguage(LangDescriptor d) => BundledLanguage(
      id: d.id,
      scopeName: d.scopeName,
      json: d.json,
      aliases: d.aliases,
      embeddedLanguages: () => d.embedded.map(rebuildBundledLanguage).toList(),
    );
