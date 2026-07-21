// The default Web Worker entry point: compiled on its own with `dart compile js`
// (see `tool/build_web_worker.dart`) into `shiki_tokenize_worker.js`, which runs
// inside a browser Web Worker. The main thread drives it through
// `tokenize_worker_web.dart`; `dart run shiki_flutter:install` copies
// it into the app's `web/`.
//
// It tokenizes with the pure-Dart embedded engine: golden-identical tokens to
// every other engine, the fastest engine on web, and no WebAssembly, keeping
// this bundle small. Selecting the `oniguruma_dart` port instead loads the sibling
// `shiki_tokenize_worker_dart.js`; the `native` engine loads the one shipped by
// `shiki_flutter_native_engine`. All three share `runTokenizeWorker`.
//
// Flutter-free (no `dart:ui`): it compiles only against the tokenizer core.

import '../../onig/onig.dart' show ShikiHighlighterEmbeddedEngine;
import 'worker_runtime.dart';

void main() => runTokenizeWorker(const ShikiHighlighterEmbeddedEngine());
