## 1.0.0

Initial release: a native Oniguruma engine backend for `shiki_flutter` over
`dart:ffi`, via the `oniguruma_native` package.

* Ships `ShikiHighlighterNativeEngine`, which tokenizes with the real Oniguruma C
  library on IO platforms. Not available on web (no `dart:ffi`).
* Experimental — not yet at parity with the pure-Dart engines. Because
  `oniguruma_native` drives Oniguruma in UTF-16LE, the 2-digit `\xHH` byte escape
  (e.g. CSS's `[^\x00-\x7F]`) fails to compile and is skipped. See the README's
  "Known limitation" and `test/parity_test.dart`.
