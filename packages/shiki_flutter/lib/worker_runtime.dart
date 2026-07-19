/// Web-only runtime for building a custom tokenize **Web Worker** entry point.
///
/// A backend that ships its own prebuilt worker (because it can't live in the
/// core package — e.g. `shiki_flutter_native_engine`, which pulls a native build
/// hook) writes a Flutter-free entry whose `main()` is a single call to
/// [runTokenizeWorker], passing the engine to tokenize with. That reuses the one
/// shared message loop, so per-engine workers can't drift.
///
/// Pair it with `package:shiki_flutter/engine.dart` (the Flutter-free tokenizer)
/// and, if the entry needs the JSON codec directly, `worker_protocol.dart`.
///
/// Web-only: imports `dart:js_interop`, so only ever reached from a
/// `dart compile js` worker entry.
library;

export 'src/async/web/worker_runtime.dart' show runTokenizeWorker;
