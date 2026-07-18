// Inline (same-isolate) worker: the web implementation, and the fallback when
// spawning a real isolate fails on native/VM.
//
// It must NOT import `dart:isolate` (unavailable on web). Tokenization runs on
// the current isolate, so it does not remove UI-thread work; it exists so the
// async API works uniformly everywhere. Each request is deferred one event-loop
// turn so a placeholder frame can paint before the (blocking) tokenize runs.
library;

import '../core/highlighter.dart';
import '../core/themed_token.dart';
import 'lang_descriptor.dart';
import 'protocol.dart';
import 'tokenize_worker.dart';

class InlineTokenizeWorker implements TokenizeWorker {
  InlineTokenizeWorker(this._highlighter);

  final ShikiHighlighter _highlighter;

  @override
  bool get isRemote => false;

  @override
  Future<void> get ready => Future.value();

  @override
  Future<List<List<ThemedToken>>> tokenize(
    String code,
    TokenizeOptions options,
  ) {
    // Defer to the event queue (not a microtask) so the caller can render its
    // placeholder frame before this blocking tokenize runs.
    return Future(() => _highlighter.codeToTokens(code, options));
  }

  @override
  void loadLanguage(LangDescriptor lang) =>
      _highlighter.loadBundledLanguage(rebuildBundledLanguage(lang));

  @override
  void loadRawLanguage(String json) =>
      _highlighter.loadLanguageFromJson(json);

  @override
  void loadTheme(String themeJson) =>
      _highlighter.loadThemeFromJson(themeJson);

  @override
  Future<void> dispose() => Future.value();
}

/// Builds a warm inline worker from [config]. Warm-up specs are ignored: warming
/// up inline would only front-load the same UI-thread cost, so grammars compile
/// lazily on the first real request instead.
Future<TokenizeWorker> spawnTokenizeWorker(WorkerConfig config) async {
  final highlighter = ShikiHighlighter(engine: config.engine);
  for (final themeJson in config.themeJsons) {
    highlighter.loadThemeFromJson(themeJson);
  }
  for (final lang in config.langs) {
    highlighter.loadBundledLanguage(rebuildBundledLanguage(lang));
  }
  for (final json in config.rawLangJsons) {
    highlighter.loadLanguageFromJson(json);
  }
  return InlineTokenizeWorker(highlighter);
}
