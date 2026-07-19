/// Flutter-free toolkit for building a custom tokenize **Web Worker** entry
/// point against `shiki_flutter`'s async protocol.
///
/// The built-in worker (installed by `dart run shiki_flutter:install`)
/// tokenizes with the embedded or pure-Dart port engine. A backend that can't
/// live in the core package — e.g. `shiki_flutter_native_engine`, which pulls in
/// a native build hook — ships its own separately-compiled worker instead. Such
/// an entry compiles against this library (plus the Flutter-free `engine.dart`)
/// so it never has to reach into `shiki_flutter`'s `src/`.
///
/// It exposes exactly what a `DedicatedWorkerGlobalScope` message handler needs:
/// the JSON codec for the values that cross the `postMessage` structured-clone
/// boundary, the engine tag the main isolate selected, and the language
/// descriptor round-trip used to rehydrate grammars sent as JSON.
///
/// Holds no `dart:isolate` / `dart:js_interop` / `dart:ui` import: callers do
/// their own `jsonEncode`/`jsonDecode` and JS interop.
library;

export 'src/async/lang_descriptor.dart'
    show LangDescriptor, rebuildBundledLanguage;
export 'src/async/protocol_codec.dart'
    show
        langDescriptorFromJson,
        tokenizeOptionsFromJson,
        tokensToJson,
        workerConfigFromJson;
