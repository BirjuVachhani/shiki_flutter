/// A [ShikiHighlighterEngine] backed by `oniguruma_dart` — a faithful pure-Dart
/// port of the Oniguruma regex engine.
///
/// No FFI and no native build, so it runs on every platform (web included)
/// while matching real Oniguruma semantics: it drives the engine in UTF-8 (so
/// 2-digit `\xHH` escapes behave like the C library) yet reports offsets in
/// UTF-16 code units that line up with Dart `String` indices.
///
/// `shiki_flutter` depends on this package and already uses
/// [ShikiHighlighterDartEngine] as its default engine on native/VM. (On web it
/// falls back to the built-in `ShikiHighlighterEmbeddedEngine`, whose `RegExp`
/// fast path is faster under dart2js.) So on native platforms you get this
/// engine without writing any setup code.
///
/// To force the port on every platform (web included), set it explicitly:
/// `ShikiHighlighter.config = const ShikiHighlighterConfig(`
/// `    ioEngine: ShikiHighlighterDartEngine(),`
/// `    webEngine: ShikiHighlighterDartEngine());`
/// Or per-highlighter:
/// `createHighlighter(engine: const ShikiHighlighterDartEngine())`.
library;

import 'package:oniguruma_dart/oniguruma_dart.dart' as onig;
import 'package:shiki_flutter_engine_interface/shiki_flutter_engine_interface.dart';

/// A [ShikiHighlighterEngine] that tokenizes with the pure-Dart Oniguruma port.
///
/// Unlike `ShikiHighlighterNativeEngine`, it needs no native library and works on
/// web. Unlike shiki_flutter's built-in `ShikiHighlighterEmbeddedEngine`, the
/// regex work is delegated to a 1:1 Oniguruma port rather than shiki's own
/// engine, so grammars that lean on Oniguruma-specific syntax tokenize more
/// faithfully.
class ShikiHighlighterDartEngine implements ShikiHighlighterEngine {
  const ShikiHighlighterDartEngine();

  @override
  OnigScanner createScanner(List<String> sources) => _OnigDartScanner(sources);

  @override
  OnigString createString(String str) => OnigString(str);
}

/// Scans a line for the earliest match among [sources], backed by
/// [onig.OnigRegex]. Mirrors `DartOnigScanner`'s contract exactly: a match at
/// the start position wins immediately, otherwise the left-most match wins
/// (ties broken by pattern order). Patterns the port can't compile are skipped
/// (never match), matching the tokenizer's forgiving behavior.
class _OnigDartScanner implements OnigScanner {
  _OnigDartScanner(List<String> sources)
      : _regexes = List<onig.OnigRegex?>.filled(sources.length, null) {
    for (var i = 0; i < sources.length; i++) {
      try {
        _regexes[i] = onig.OnigRegex.compile(sources[i]);
      } on Object {
        // Forgiving: a pattern the port rejects simply never matches, exactly
        // as an uncompilable pattern is dropped by DartOnigScanner.
        _regexes[i] = null;
      }
    }
  }

  final List<onig.OnigRegex?> _regexes;

  @override
  OnigMatch? findNextMatch(Object string, int startPosition) {
    final str = string is OnigString ? string.content : string as String;

    int? bestIndex;
    onig.OnigMatch? best;

    for (var i = 0; i < _regexes.length; i++) {
      final re = _regexes[i];
      if (re == null) continue;

      onig.OnigMatch? m;
      try {
        // `start` also fixes the `\G` anchor (Oniguruma's gpos), so anchored
        // grammar rules behave as the tokenizer expects.
        m = re.firstMatch(str, start: startPosition);
      } on Object {
        continue;
      }
      if (m == null) continue;

      // A match exactly at the start position wins immediately.
      if (m.start == startPosition) return _convert(i, m);
      if (best == null || m.start < best.start) {
        best = m;
        bestIndex = i;
      }
    }

    return best == null ? null : _convert(bestIndex!, best);
  }

  /// Maps a port match to shiki's contract. Unmatched groups (port `-1`) become
  /// the [kUnmatchedOffset] sentinel — identical to `DartOnigScanner`'s
  /// conversion, so downstream tokenization is byte-for-byte comparable.
  static OnigMatch _convert(int index, onig.OnigMatch m) {
    final caps = List<OnigCaptureIndex>.generate(m.numRegs, (g) {
      final s = m.startOf(g);
      final e = m.endOf(g);
      if (s < 0 || e < 0) {
        return const OnigCaptureIndex(kUnmatchedOffset, kUnmatchedOffset, 0);
      }
      return OnigCaptureIndex(s, e, e - s);
    });
    return OnigMatch(index, caps);
  }
}
