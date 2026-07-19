// JSON codec for the worker protocol values.
//
// The `dart:isolate` worker sends the protocol classes (`WorkerConfig`,
// `TokenizeRequest`, `ThemedToken`, …) as live Dart objects — an isolate copies
// them for free. A browser Web Worker cannot: `postMessage` only carries
// structured-clone-safe values, so everything that crosses that boundary is
// encoded to plain JSON-able maps/lists here (and back on the other side).
//
// This file is Flutter-free and holds no `dart:isolate` / `dart:js_interop`
// import: it is shared by the main-isolate web transport (`tokenize_worker_web`)
// and the compiled worker entry (`web/tokenize_worker_entry`), and it is unit
// tested on the VM. Callers do the `jsonEncode`/`jsonDecode`; this layer only
// converts between the protocol objects and JSON-able structures.
library;

import 'package:shiki_flutter_engine_interface/shiki_flutter_engine_interface.dart';

import '../core/highlighter.dart';
import '../core/themed_token.dart';
import 'lang_descriptor.dart';
import 'protocol.dart';

// --- LangDescriptor ---------------------------------------------------------

Map<String, dynamic> langDescriptorToJson(LangDescriptor d) => {
      'id': d.id,
      'scopeName': d.scopeName,
      'json': d.json,
      'aliases': d.aliases,
      'embedded': d.embedded.map(langDescriptorToJson).toList(),
    };

LangDescriptor langDescriptorFromJson(Map<String, dynamic> j) => LangDescriptor(
      id: j['id'] as String,
      scopeName: j['scopeName'] as String,
      json: j['json'] as String,
      aliases: (j['aliases'] as List).cast<String>(),
      embedded: (j['embedded'] as List)
          .map((e) => langDescriptorFromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );

// --- TokenizeOptions --------------------------------------------------------

Map<String, dynamic> tokenizeOptionsToJson(TokenizeOptions o) => {
      'lang': o.lang,
      'theme': o.theme,
      'includeExplanation': o.includeExplanation,
      'tokenizeMaxLineLength': o.tokenizeMaxLineLength,
      'tokenizeTimeLimit': o.tokenizeTimeLimit,
      'colorReplacements': o.colorReplacements,
    };

TokenizeOptions tokenizeOptionsFromJson(Map<String, dynamic> j) => TokenizeOptions(
      lang: j['lang'] as String?,
      theme: j['theme'] as String?,
      includeExplanation: (j['includeExplanation'] as bool?) ?? false,
      tokenizeMaxLineLength: (j['tokenizeMaxLineLength'] as int?) ?? 0,
      tokenizeTimeLimit: (j['tokenizeTimeLimit'] as int?) ?? 500,
      colorReplacements:
          (j['colorReplacements'] as Map?)?.cast<String, dynamic>(),
    );

// --- ThemedToken ------------------------------------------------------------

// Short keys keep the (potentially large) token payload compact on the wire.
// Optional fields are omitted when at their default to shrink it further.
Map<String, dynamic> themedTokenToJson(ThemedToken t) {
  final m = <String, dynamic>{'c': t.content, 'o': t.offset};
  if (t.color != null) m['fg'] = t.color;
  if (t.bgColor != null) m['bg'] = t.bgColor;
  if (t.fontStyle != 0) m['fs'] = t.fontStyle;
  if (t.scopes != null) m['s'] = t.scopes;
  return m;
}

ThemedToken themedTokenFromJson(Map<String, dynamic> j) => ThemedToken(
      content: j['c'] as String,
      offset: j['o'] as int,
      color: j['fg'] as String?,
      bgColor: j['bg'] as String?,
      fontStyle: (j['fs'] as int?) ?? 0,
      scopes: (j['s'] as List?)?.cast<String>(),
    );

List<dynamic> tokensToJson(List<List<ThemedToken>> lines) =>
    lines.map((line) => line.map(themedTokenToJson).toList()).toList();

List<List<ThemedToken>> tokensFromJson(List<dynamic> j) => j
    .map((line) => (line as List)
        .map((t) => themedTokenFromJson((t as Map).cast<String, dynamic>()))
        .toList())
    .toList();

// --- WorkerConfig -----------------------------------------------------------

/// The stable [ShikiHighlighterEngine.id] tag for [engine], or null when none is
/// set. The web transport uses it to pick the matching prebuilt worker, and it
/// travels in the config JSON for diagnostics. Reads the engine's own `id`
/// literal — deliberately NOT `runtimeType`, whose name minifies in release web
/// builds — so this file needn't depend on any engine backend package.
String? engineTag(ShikiHighlighterEngine? engine) => engine?.id;

Map<String, dynamic> workerConfigToJson(WorkerConfig c) => {
      'engine': engineTag(c.engine),
      'langs': c.langs.map(langDescriptorToJson).toList(),
      'rawLangJsons': c.rawLangJsons,
      'themeJsons': c.themeJsons,
    };

/// Rebuilds a [WorkerConfig] from JSON. [engine] is intentionally left null: each
/// prebuilt worker is compiled for one engine (the main isolate picks which
/// worker script to load from [engineTag]), so no engine backend needs to be
/// reconstructed (or depended on) here.
WorkerConfig workerConfigFromJson(Map<String, dynamic> j) => WorkerConfig(
      langs: (j['langs'] as List)
          .map((e) => langDescriptorFromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      rawLangJsons: (j['rawLangJsons'] as List).cast<String>(),
      themeJsons: (j['themeJsons'] as List).cast<String>(),
    );
