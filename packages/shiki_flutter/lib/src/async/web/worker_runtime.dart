// The shared Web Worker runtime: the `DedicatedWorkerGlobalScope` message loop
// that every prebuilt tokenize-worker entry runs. Each entry is a three-line
// `main()` that hands [runTokenizeWorker] the engine to tokenize with; the loop,
// the JSON protocol, and the warm-highlighter lifecycle live here once so the
// per-engine workers can't drift from each other.
//
// Exposed publicly via `package:shiki_flutter/worker_runtime.dart` so a backend
// that ships its own worker (e.g. `shiki_flutter_native_engine`) reuses this
// exact loop instead of copying it. Web-only: it imports `dart:js_interop`, so
// it is only ever reached from a `dart compile js` worker entry.
library;

import 'dart:convert';
import 'dart:js_interop';

import 'package:shiki_flutter_engine_interface/shiki_flutter_engine_interface.dart';

import '../../core/highlighter.dart';
import '../lang_descriptor.dart';
import '../protocol_codec.dart';

// The dedicated worker global scope (`self`). Kept as a tiny local interop
// surface so this file depends only on `dart:js_interop`.
@JS('self')
external _WorkerScope get _self;

extension type _WorkerScope._(JSObject _) implements JSObject {
  external set onmessage(JSFunction value);
  external void postMessage(JSAny? message);
}

extension type _MessageEvent._(JSObject _) implements JSObject {
  external JSAny? get data;
}

void _post(Map<String, dynamic> message) =>
    _self.postMessage(jsonEncode(message).toJS);

/// Runs the tokenize-worker message loop, tokenizing every request with
/// [engine]. Call it from a Flutter-free worker entry's `main()`.
///
/// [prepare], if given, is awaited **once** before the first `config` builds the
/// warm highlighter, the seam the native engine uses to `await loadWasm()`
/// before it can tokenize. On failure the `ready` handshake never fires and the
/// main thread falls back to inline tokenization.
///
/// Grammars and themes are not compiled in; they arrive as JSON in the messages,
/// so one prebuilt worker serves every app.
void runTokenizeWorker(
  ShikiHighlighterEngine engine, {
  Future<void> Function()? prepare,
}) {
  ShikiHighlighter? highlighter;

  Future<void> handle(String raw) async {
    final msg = (jsonDecode(raw) as Map).cast<String, dynamic>();
    switch (msg['type']) {
      case 'config':
        if (prepare != null) await prepare();
        // Build the warm highlighter from the shipped grammars/themes.
        final cfg =
            workerConfigFromJson((msg['config'] as Map).cast<String, dynamic>());
        final h = ShikiHighlighter(engine: engine);
        for (final themeJson in cfg.themeJsons) {
          h.loadThemeFromJson(themeJson);
        }
        for (final lang in cfg.langs) {
          h.loadBundledLanguage(rebuildBundledLanguage(lang));
        }
        for (final json in cfg.rawLangJsons) {
          h.loadLanguageFromJson(json);
        }
        highlighter = h;
        _post({'type': 'ready'});
      case 'tokenize':
        final id = msg['id'] as int;
        final h = highlighter;
        if (h == null) {
          _post({'type': 'error', 'id': id, 'message': 'worker not configured'});
          return;
        }
        try {
          final tokens = h.codeToTokens(
            msg['code'] as String,
            tokenizeOptionsFromJson(
                (msg['options'] as Map).cast<String, dynamic>()),
          );
          _post({'type': 'result', 'id': id, 'tokens': tokensToJson(tokens)});
        } catch (e, st) {
          _post({
            'type': 'error',
            'id': id,
            'message': e.toString(),
            'stack': st.toString(),
          });
        }
      case 'loadLang':
        highlighter?.loadBundledLanguage(rebuildBundledLanguage(
            langDescriptorFromJson(
                (msg['lang'] as Map).cast<String, dynamic>())));
      case 'loadRawLang':
        highlighter?.loadLanguageFromJson(msg['json'] as String);
      case 'loadTheme':
        highlighter?.loadThemeFromJson(msg['themeJson'] as String);
    }
  }

  _self.onmessage = ((_MessageEvent event) {
    final data = event.data;
    if (data == null || !data.isA<JSString>()) return;
    handle((data as JSString).toDart);
  }).toJS;
}
