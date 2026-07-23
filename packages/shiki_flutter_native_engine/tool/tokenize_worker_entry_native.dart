// The native (WebAssembly) Web Worker entry point: compiled on its own with
// `dart compile js` (see `tool/build_web_worker_native.dart`) into
// `lib/src/prebuilt/shiki_tokenize_worker_native.js`. shiki_flutter's web
// transport (`tokenize_worker_web.dart`) loads that script (instead of the
// default one) whenever the configured engine is the native engine.
//
// This source lives in `tool/`, not `lib/`, on purpose: it is only ever a
// compile input for the maintainer build tool, never a library apps import. The
// committed `.js` output under `lib/src/prebuilt/` is what ships. Keeping the
// entry out of `lib/` is what lets `shiki_flutter` stay a dev_dependency (it is
// imported only here, to reuse the shared loop), so depending on this package
// pulls in neither the core package nor Flutter.
//
// It reuses shiki_flutter's shared `runTokenizeWorker` loop, tokenizing with the
// real Oniguruma engine (`ShikiHighlighterNativeEngine`), which on web is a
// WebAssembly module. That module instantiates asynchronously, so `prepare:
// loadWasm` runs before the first `config` builds the highlighter. `loadWasm()`
// fetches `oniguruma_native.wasm` relative to this worker's own URL (installed
// next to it by `dart run shiki_flutter:install --native`),
// falling back to the version-matched GitHub Release if the local copy is absent.
//
// Flutter-free (no `dart:ui`): compiled against shiki_flutter's Flutter-free
// `worker_runtime.dart` plus `oniguruma_native`. Compiling to JS targets the web,
// so oniguruma_native's native (C) build hook does not run and no wasm is bundled.
library;

import 'package:shiki_flutter/worker_runtime.dart';
import 'package:shiki_flutter_native_engine/shiki_flutter_native_engine.dart';

void main() =>
    runTokenizeWorker(const ShikiHighlighterNativeEngine(), prepare: loadWasm);
