// The worker abstraction that runs tokenization off the current isolate.
//
// The concrete implementation is chosen at compile time: a real `dart:isolate`
// worker on native/VM, a browser Web Worker on web, and an inline (same-isolate)
// worker as the fallback. All three expose the same `spawnTokenizeWorker` entry
// point. `dart.library.io` matches only on the VM and `dart.library.js_interop`
// only on web, so each platform resolves to exactly one implementation.
library;

import '../core/highlighter.dart';
import '../core/themed_token.dart';
import 'lang_descriptor.dart';
import 'protocol.dart';
import 'tokenize_worker_inline.dart'
    if (dart.library.io) 'tokenize_worker_io.dart'
    if (dart.library.js_interop) 'tokenize_worker_web.dart' as impl;

/// Runs `codeToTokens` for a warm highlighter, ideally on a background isolate.
///
/// A worker owns one highlighter seeded from a [WorkerConfig]; call [tokenize]
/// repeatedly and it stays warm (compiled grammars/regexes are retained), so
/// only the first request per grammar pays the compile cost.
abstract interface class TokenizeWorker {
  /// Completes once the worker is spawned and warmed and ready for requests.
  Future<void> get ready;

  /// True if tokenization runs on a separate isolate; false when it runs inline
  /// on the current isolate (web, or an isolate-spawn fallback).
  bool get isRemote;

  /// Tokenizes [code] with [options] and returns the themed tokens.
  Future<List<List<ThemedToken>>> tokenize(String code, TokenizeOptions options);

  /// Adds a bundled language to the running worker (mirrors a later
  /// `loadBundledLanguage` on the main highlighter).
  void loadLanguage(LangDescriptor lang);

  /// Adds a raw-JSON language to the running worker (mirrors a later
  /// `loadLanguageFromJson`).
  void loadRawLanguage(String json);

  /// Adds a theme to the running worker.
  void loadTheme(String themeJson);

  /// Tears the worker down (kills the isolate, if any). Idempotent.
  Future<void> dispose();
}

/// Spawns a [TokenizeWorker] for [config]. On native/VM this spawns an isolate
/// (falling back to inline if the spawn fails); on web it runs inline.
Future<TokenizeWorker> spawnTokenizeWorker(WorkerConfig config) =>
    impl.spawnTokenizeWorker(config);
