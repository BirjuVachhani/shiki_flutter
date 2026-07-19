## 1.0.0

Initial release: a native Oniguruma engine backend for `shiki_flutter`, via the
`oniguruma_native` package — `dart:ffi` on IO and WebAssembly on web.

* Ships `ShikiHighlighterNativeEngine`, which tokenizes with the real Oniguruma C
  library. Works on every platform `oniguruma_native` supports; on web, call
  `await loadWasm()` once at startup before highlighting.
* At parity with the pure-Dart engines. `oniguruma_native` drives Oniguruma in
  UTF-8 (mapping offsets back to UTF-16 code units), so 2-digit `\xHH` byte
  escapes (e.g. CSS's `[^\x00-\x7F]`) compile correctly. `test/parity_test.dart`
  asserts byte-identical output against the pure-Dart engine across json,
  javascript, css, python, and html.
* Off-main-thread highlighting on web: ships a prebuilt Web Worker installed with
  `dart run shiki_flutter:install --native` (loads the Oniguruma WebAssembly
  module inside the worker). Enable with `asyncWeb: true`.
