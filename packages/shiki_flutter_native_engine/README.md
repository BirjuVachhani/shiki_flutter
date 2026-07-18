# shiki_flutter_native_engine

A native [Oniguruma](https://github.com/kkos/oniguruma) engine backend for
[`shiki_flutter`](../shiki_flutter), wired through the standalone
[`oniguruma_native`](https://github.com/BirjuVachhani/oniguruma-dart/tree/main/packages/oniguruma_native)
FFI package. On IO platforms it tokenizes with the real Oniguruma C library
instead of shiki_flutter's pure-Dart engine.

It exists because `shiki_flutter`'s engine is pluggable: `ShikiHighlighterEngine`
is the seam; `shiki_flutter` picks a pure-Dart default per platform
(`ShikiHighlighterDartEngine` on native/VM, `ShikiHighlighterEmbeddedEngine` on
web), and this package provides `ShikiHighlighterNativeEngine`.

## Usage

Set it once at startup, guarded for web (where `dart:ffi` isn't available):

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter_native_engine/shiki_flutter_native_engine.dart';

void main() {
  if (!kIsWeb) {
    ShikiHighlighter.config = ShikiHighlighter.config.copyWith(
      ioEngine: const ShikiHighlighterNativeEngine(),
    );
  }
  runApp(const MyApp());
}
```

Or per highlighter: `createHighlighter(engine: ShikiHighlighterNativeEngine())`.

Flutter apps must enable native assets: `flutter config --enable-native-assets`.

## Status: experimental — not yet at parity

The pure-Dart engines are the trustworthy defaults on every platform:
`shiki_flutter`'s built-in `ShikiHighlighterEmbeddedEngine` is golden-tested
byte-for-byte against real Shiki, and `ShikiHighlighterDartEngine` (the
native/VM default) is checked byte-for-byte against it. This FFI backend is
**not yet a drop-in equal** — prefer the default unless you have measured a need
for the native speedup on IO and have verified the grammars you use aren't
affected by the limitation below.

The `test/parity_test.dart` differential gate tokenizes the core package's
golden corpus with both engines and asserts byte-identical output. It passes for
`json` / `javascript` / `python` and **skips** `css` / `html` for the reason
below.

### Known limitation: `\xHH` escapes under UTF-16LE

The `oniguruma_native` package drives Oniguruma in **UTF-16LE** so match offsets line
up 1:1 with Dart `String` indices (no UTF-8↔UTF-16 conversion). A consequence:
the 2-digit `\xHH` byte escape — common in TextMate grammars for ASCII ranges,
e.g. `[^\x00-\x7F]` — is interpreted as a raw **byte**, not a codepoint. Such
patterns fail to compile and are silently skipped, so tokens they'd produce are
missed.

Shiki drives Oniguruma in **UTF-8**, where `\xHH` for `0x00`–`0x7F` equals the
ASCII codepoint, so it never hits this. Among the golden fixtures the gap shows
up in CSS class selectors (`[-a-z[^\x00-\x7F]]`) and HTML's embedded CSS.

The brace form `\x{HH}` works correctly under UTF-16LE. A full fix means either
switching the shim to UTF-8 with an offset map (as vscode-oniguruma does) or
rewriting `\xHH` → `\x{HH}` inside the shim before compiling. Until then, treat
this backend as an opt-in accelerator, not a correctness-equal replacement.
