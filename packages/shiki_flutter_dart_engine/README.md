![shiki_flutter](https://raw.githubusercontent.com/BirjuVachhani/shiki_flutter/main/website/assets/banner.webp)

# shiki_flutter_dart_engine

A pure-Dart [Oniguruma](https://github.com/kkos/oniguruma) engine backend for
[`shiki_flutter`](../shiki_flutter), wired through the
[`oniguruma_dart`](https://github.com/BirjuVachhani/oniguruma-dart/tree/main/packages/oniguruma_dart)
port: a 1:1 Dart implementation of the Oniguruma regex engine. No FFI, no
native build: it runs on **every platform, web included**.

It exists because `shiki_flutter`'s engine is pluggable: `ShikiHighlighterEngine`
is a seam the TextMate tokenizer runs on, and this package provides an
implementation backed by a faithful Oniguruma port.

## It's already the default on native/VM

`shiki_flutter` depends on this package and uses `ShikiHighlighterDartEngine` as
its default engine on native and the Dart VM (faithful semantics, and it edges
out the bundled engine there). On web it falls back to the built-in
`ShikiHighlighterEmbeddedEngine`, whose `RegExp` fast path is several times
faster than the port under dart2js. So for that recommended per-platform setup
you don't have to write anything: importing `shiki_flutter` is enough.

To force the port on **every** platform (web included), set it explicitly:

```dart
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter_dart_engine/shiki_flutter_dart_engine.dart';

void main() {
  ShikiHighlighter.config = const ShikiHighlighterConfig(
    ioEngine: ShikiHighlighterDartEngine(),
    webEngine: ShikiHighlighterDartEngine(),
  );
  runApp(const MyApp());
}
```

Or per-highlighter:
`createHighlighter(engine: const ShikiHighlighterDartEngine())`.

## Which engine should I use?

| Engine | Package | Platforms | Regex backend |
|--------|---------|-----------|---------------|
| `ShikiHighlighterEmbeddedEngine` | built into `shiki_flutter` (default on web) | all | shiki_flutter's own engine |
| `ShikiHighlighterDartEngine` | this package (default on native/VM) | all (web included) | `oniguruma_dart` port |
| `ShikiHighlighterNativeEngine` | `shiki_flutter_native_engine` | IO only | native Oniguruma C (FFI) |

Reach for this engine when you want Oniguruma semantics without the native
build/FFI constraints of `shiki_flutter_native_engine`, including on web, where
FFI isn't available. Unlike that engine, the port drives Oniguruma in **UTF-8**,
so 2-digit `\xHH` escapes (e.g. CSS's `[^\x00-\x7F]`) compile correctly; offsets
are still reported in UTF-16 code units, matching Dart `String` indices.

## Correctness

`test/parity_test.dart` tokenizes the core package's golden fixtures (proven
byte-identical to real Shiki) with both this engine and the built-in pure-Dart
engine and asserts the token streams are identical, across all sampled
languages and themes.

## Performance note

The scanner compiles each grammar pattern to its own `OnigRegex` and searches
them one by one, picking the left-most match. The input line is encoded once per
pattern (cached by the port on the line's `String` identity) rather than once
per scanner. A future optimization can switch to the port's `OnigRegSet` to
encode once and search all patterns together. On web the built-in
`ShikiHighlighterEmbeddedEngine` (the default there) is faster than the port, so
there's usually no reason to force this engine on web.
