/// A native [ShikiHighlighterEngine] backed by the real Oniguruma C library
/// (via the standalone `oniguruma` FFI package). On IO platforms this tokenizes
/// with Oniguruma instead of shiki_flutter's pure-Dart engine.
///
/// Enable it once — guarded for web, where `dart:ffi` isn't available:
///
/// ```dart
/// import 'package:flutter/foundation.dart' show kIsWeb;
/// import 'package:shiki_flutter/shiki_flutter.dart';
/// import 'package:shiki_flutter_ffi_engine/shiki_flutter_ffi_engine.dart';
///
/// void main() {
///   if (!kIsWeb) ShikiHighlighter.engine = ShikiHighlighterFFIEngine();
///   runApp(const MyApp());
/// }
/// ```
///
/// A per-highlighter override is also possible:
/// `createHighlighter(engine: ShikiHighlighterFFIEngine())`.
///
/// Status: experimental. The pure-Dart [ShikiHighlighterDartEngine] is the
/// golden-tested, trustworthy default. This backend is not yet at parity —
/// because the underlying `oniguruma` package runs Oniguruma in UTF-16LE, the
/// 2-digit `\xHH` byte escape (e.g. CSS's `[^\x00-\x7F]`) fails to compile and
/// is skipped. See this package's README (Known limitations) and
/// `test/parity_test.dart`.
library;

import 'package:oniguruma/oniguruma.dart' as ffi;
import 'package:shiki_flutter/engine.dart';

/// Re-exported so callers can branch without importing `oniguruma` directly:
/// `true` on IO (native Oniguruma present), `false` on web.
export 'package:oniguruma/oniguruma.dart' show isOnigurumaSupported;

// The tokenizer never disposes scanners/strings explicitly (the pure-Dart
// engine relies on GC), so we free the native buffers when the Dart wrappers
// are collected. Best-effort, which is the right trade-off here: steady-state
// tokenization reclaims memory, and process exit frees the rest.
final Finalizer<ffi.OnigString> _stringFinalizer =
    Finalizer<ffi.OnigString>((s) => s.dispose());
final Finalizer<ffi.OnigScanner> _scannerFinalizer =
    Finalizer<ffi.OnigScanner>((s) => s.dispose());

/// A [ShikiHighlighterEngine] that runs the Oniguruma C library over `dart:ffi`.
///
/// Only usable where [isOnigurumaSupported] is true (all IO platforms). On web,
/// guard construction with `kIsWeb` and keep the default
/// [ShikiHighlighterDartEngine].
class ShikiHighlighterFFIEngine implements ShikiHighlighterEngine {
  const ShikiHighlighterFFIEngine();

  @override
  OnigScanner createScanner(List<String> sources) => _FfiScanner(sources);

  @override
  OnigString createString(String str) => _FfiOnigString(str);
}

/// A shiki [OnigString] that also holds the input encoded once in native memory
/// (UTF-16LE by the `oniguruma` backend), reused across every `findNextMatch`
/// for the line.
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
    // Fallback: a plain String or a non-FFI OnigString — encode a throwaway
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
  /// become the [kUnmatchedOffset] sentinel — byte-identical to
  /// `DartOnigScanner`'s conversion.
  static OnigMatch _convert(ffi.OnigMatch m) {
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
