![shiki_flutter](https://raw.githubusercontent.com/BirjuVachhani/shiki_flutter/main/website/assets/banner.webp)

# shiki_flutter_native_engine

A native [Oniguruma](https://github.com/kkos/oniguruma) engine backend for
[`shiki_flutter`](../shiki_flutter), wired through the standalone
[`oniguruma_native`](https://pub.dev/packages/oniguruma_native) package. It
tokenizes with the real Oniguruma C library instead of shiki_flutter's pure-Dart
engine: `dart:ffi` on IO and WebAssembly on web.

It exists because `shiki_flutter`'s engine is pluggable: `ShikiHighlighterEngine`
is the seam; `shiki_flutter` picks a pure-Dart default per platform
(`ShikiHighlighterDartEngine` on native/VM, `ShikiHighlighterEmbeddedEngine` on
web), and this package provides `ShikiHighlighterNativeEngine`.

## Usage

Set it once at startup. On web the wasm module loads asynchronously, so
`await loadWasm()` before the first highlight; it is a no-op on IO, so the same
startup code is portable across every platform:

```dart
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter_native_engine/shiki_flutter_native_engine.dart';

Future<void> main() async {
  await loadWasm(); // no-op on IO; loads the Oniguruma wasm module on web
  ShikiHighlighter.config = ShikiHighlighter.config.copyWith(
    ioEngine: const ShikiHighlighterNativeEngine(),
    // Optionally on web too, but the embedded engine is faster on web:
    // webEngine: const ShikiHighlighterNativeEngine(),
  );
  runApp(const MyApp());
}
```

Or per highlighter: `createHighlighter(engine: ShikiHighlighterNativeEngine())`.

On IO the native library builds automatically on first run (via
`oniguruma_native`'s build hook), no `flutter config` flag needed. On web, run
`dart run oniguruma_native:setup` once to self-host the WebAssembly module (else
`loadWasm()` fetches it from the version-matched GitHub Release at runtime).

## Parity

At parity with the pure-Dart engines. `oniguruma_native` drives Oniguruma in
**UTF-8**, the encoding TextMate/VS Code grammars are authored against, so
2-digit `\xHH` byte escapes (e.g. CSS's `[^\x00-\x7F]`) compile as intended, and
maps the reported byte offsets back to UTF-16 code units that line up with Dart
`String` indices.

`test/parity_test.dart` tokenizes the core package's golden fixtures (proven
byte-identical to real Shiki) with both this engine and the built-in pure-Dart
engine and asserts the token streams are identical, across all sampled languages
(json, javascript, css, python, html) and themes.

## Off-main-thread on web (optional)

With `asyncWeb: true`, web highlighting runs in a browser Web Worker. Because this
engine needs its WebAssembly module inside the worker, it ships its own worker.
Install it (and the wasm) into your app's `web/` once, via shiki_flutter's install
command with the `--native` flag:

```sh
dart run shiki_flutter:install --native
```

Then set `webEngine: const ShikiHighlighterNativeEngine()` and `asyncWeb: true`,
and `await loadWasm()` at startup. Without the worker installed, web async falls
back to inline tokenization on the current isolate, so nothing breaks.

## When to use

**Fastest on IO** (~2.4x the pure-Dart port) with full parity: best for large
files or heavy re-highlighting on native/desktop. On web it runs as WebAssembly
but is ~2x slower than the embedded engine, so prefer the embedded engine there
unless you specifically want the real Oniguruma engine everywhere.
