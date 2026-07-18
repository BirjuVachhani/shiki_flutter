// The Web Worker entry point: this file is compiled on its own with
// `dart compile js` (see `tool/build_web_worker.dart`) into
// `shiki_tokenize_worker.js`, which runs inside a browser Web Worker. The main
// thread drives it through `tokenize_worker_web.dart`.
//
// It must stay Flutter-free (no `dart:ui`): it imports only the Flutter-free
// tokenizer core. Grammars and themes are NOT compiled in — they arrive as JSON
// in the `config` message, so this one prebuilt worker serves every app
// regardless of which languages/themes the app imports.
//
// It always tokenizes with the pure-Dart embedded engine: it produces tokens
// identical to every other engine (golden-verified), is the fastest engine on
// web, and needs no WebAssembly, keeping this bundle small.
library;

import 'dart:convert';
import 'dart:js_interop';

import '../../core/highlighter.dart';
import '../../onig/onig.dart';
import '../lang_descriptor.dart';
import '../protocol_codec.dart';

// The dedicated worker global scope (`self`). Kept as a tiny local interop
// surface so the entry depends only on `dart:js_interop`.
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

void main() {
  ShikiHighlighter? highlighter;

  void handle(String raw) {
    final msg = (jsonDecode(raw) as Map).cast<String, dynamic>();
    switch (msg['type']) {
      case 'config':
        // Build the warm highlighter from the shipped grammars/themes.
        final cfg =
            workerConfigFromJson((msg['config'] as Map).cast<String, dynamic>());
        final h =
            ShikiHighlighter(engine: const ShikiHighlighterEmbeddedEngine());
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
