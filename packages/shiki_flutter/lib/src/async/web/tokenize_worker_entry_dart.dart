// The pure-Dart-port Web Worker entry point: compiled on its own with
// `dart compile js` (see `tool/build_web_worker.dart`) into
// `shiki_tokenize_worker_dart.js`. The web transport loads this instead of the
// default worker when the configured engine is `ShikiHighlighterDartEngine`
// (the `oniguruma_dart` port). Install it with
// `dart run shiki_flutter:install --dart`.
//
// Kept a separate artifact from the embedded worker so the default worker isn't
// bloated by the port's regex engine: each worker tree-shakes to exactly the one
// engine it runs. Output is golden-identical to embedded; embedded is faster on
// web, so this is only for callers who want Oniguruma-port semantics everywhere.
//
// Flutter-free (no `dart:ui`).

import 'package:shiki_flutter_dart_engine/shiki_flutter_dart_engine.dart';

import 'worker_runtime.dart';

void main() => runTokenizeWorker(const ShikiHighlighterDartEngine());
