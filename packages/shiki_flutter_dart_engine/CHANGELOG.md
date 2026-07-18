## 1.0.0

Initial release: a pure-Dart Oniguruma engine backend for `shiki_flutter`,
backed by the `oniguruma_dart` port (a 1:1 Dart implementation of the Oniguruma
regex engine).

* Ships `ShikiHighlighterDartEngine`. No FFI and no native build, so it runs on
  every platform, web included.
* `shiki_flutter` depends on this package and uses it as the default engine on
  native/VM (falling back to its built-in engine on web).
* Drives Oniguruma in UTF-8 (so 2-digit `\xHH` escapes behave like the C
  library) while reporting offsets in UTF-16 code units that match Dart `String`
  indices.
* `test/parity_test.dart` asserts token output is byte-identical to
  `shiki_flutter`'s built-in engine across the golden fixtures.
