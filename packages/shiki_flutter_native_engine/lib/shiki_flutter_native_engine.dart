/// A [ShikiHighlighterEngine] backed by the real Oniguruma C library (via the
/// standalone `oniguruma_native` package): `dart:ffi` on IO and WebAssembly on
/// web, tokenizing with Oniguruma instead of shiki_flutter's pure-Dart engine.
///
/// Enable it once in `main()`. On web the wasm module loads asynchronously, so
/// `await loadWasm()` before the first highlight; it is a no-op on IO, so the
/// same startup code is portable:
///
/// ```dart
/// import 'package:shiki_flutter/shiki_flutter.dart';
/// import 'package:shiki_flutter_native_engine/shiki_flutter_native_engine.dart';
///
/// Future<void> main() async {
///   await loadWasm(); // no-op on IO; loads the embedded wasm on web
///   ShikiHighlighter.config = ShikiHighlighter.config.copyWith(
///     ioEngine: const ShikiHighlighterNativeEngine());
///   runApp(const MyApp());
/// }
/// ```
///
/// A per-highlighter override is also possible:
/// `createHighlighter(engine: ShikiHighlighterNativeEngine())`.
///
/// At parity with the pure-Dart engines: `oniguruma_native` drives Oniguruma in
/// UTF-8 (mapping match offsets back to UTF-16 code units for Dart `String`
/// indices), so 2-digit `\xHH` byte escapes (e.g. CSS's `[^\x00-\x7F]`) compile
/// correctly. `test/parity_test.dart` asserts byte-identical output against the
/// golden-tested pure-Dart engine across the sampled languages (json, javascript,
/// css, python, html) and themes.
library;

import 'package:oniguruma_native/oniguruma_native.dart' as ffi;
import 'package:shiki_flutter_engine_interface/shiki_flutter_engine_interface.dart';

/// Re-exported so callers can initialize without importing `oniguruma_native`
/// directly. On web the wasm module loads asynchronously, so `await loadWasm()`
/// once at startup before tokenizing; it is a no-op on IO, so the call is
/// portable across platforms.
export 'package:oniguruma_native/oniguruma_native.dart' show loadWasm;

// The tokenizer never disposes scanners/strings explicitly (the pure-Dart
// engine relies on GC), so we free the native buffers when the Dart wrappers
// are collected. Best-effort, which is the right trade-off here: steady-state
// tokenization reclaims memory, and process exit frees the rest.
final Finalizer<ffi.OnigString> _stringFinalizer = Finalizer<ffi.OnigString>(
  (s) => s.dispose(),
);
final Finalizer<ffi.OnigScanner> _scannerFinalizer = Finalizer<ffi.OnigScanner>(
  (s) => s.dispose(),
);

/// A [ShikiHighlighterEngine] that runs the real Oniguruma C engine through
/// `oniguruma_native`: `dart:ffi` on IO and WebAssembly on web.
///
/// Works on every platform `oniguruma_native` supports. On web the wasm module
/// loads asynchronously, so `await loadWasm()` once at startup before the first
/// highlight (it is a no-op on IO), as shown in the library doc above.
class ShikiHighlighterNativeEngine implements ShikiHighlighterEngine {
  const ShikiHighlighterNativeEngine();

  @override
  String get id => 'native';

  @override
  OnigScanner createScanner(List<String> sources) => _FfiScanner(sources);

  @override
  OnigString createString(String str) => _FfiOnigString(str);
}

/// A shiki [OnigString] that also holds the input encoded once in native memory
/// (UTF-8 by the `oniguruma_native` backend, with a byte↔UTF-16 offset map),
/// reused across every `findNextMatch` for the line.
class _FfiOnigString extends OnigString {
  _FfiOnigString(super.content) : native = ffi.OnigString(content) {
    _stringFinalizer.attach(this, native, detach: this);
  }

  final ffi.OnigString native;
}

class _FfiScanner implements OnigScanner {
  _FfiScanner(List<String> sources) : _sc = ffi.OnigScanner(sources) {
    _scannerFinalizer.attach(this, _sc, detach: this);
  }

  final ffi.OnigScanner _sc;

  @override
  OnigMatch? findNextMatch(Object string, int startPosition) {
    // Fast path: reuse the native buffer cached on the line's OnigString.
    if (string is _FfiOnigString) {
      final m = _sc.findNextMatch(string.native, startPosition);
      return m == null ? null : _convert(m);
    }
    // Fallback: a plain String or a non-FFI OnigString. Encode a throwaway
    // native buffer for this single call.
    final content = string is OnigString ? string.content : string as String;
    final tmp = ffi.OnigString(content);
    try {
      final m = _sc.findNextMatch(tmp, startPosition);
      return m == null ? null : _convert(m);
    } finally {
      tmp.dispose();
    }
  }

  /// Maps a native match to shiki's contract. Unmatched groups (native `-1`)
  /// become the [kUnmatchedOffset] sentinel, byte-identical to
  /// `DartOnigScanner`'s conversion.
  static OnigMatch _convert(ffi.OnigScannerMatch m) {
    final caps = List<OnigCaptureIndex>.generate(m.captureIndices.length, (i) {
      final c = m.captureIndices[i];
      if (c.start < 0 || c.end < 0) {
        return const OnigCaptureIndex(kUnmatchedOffset, kUnmatchedOffset, 0);
      }
      return OnigCaptureIndex(c.start, c.end, c.end - c.start);
    });
    return OnigMatch(m.index, caps);
  }
}
