// The pluggable regex-engine seam the TextMate tokenizer runs on, mirroring
// `vscode-textmate`'s `onigLib.ts` / `IOnigLib` and Shiki's JavaScript
// `scanner.ts`. The bundled engine is pure Dart ([ShikiHighlighterDartEngine],
// backed by [OnigRegex]); a native backend (e.g. FFI Oniguruma) plugs in by
// implementing [ShikiHighlighterEngine] + [OnigScanner].
library;

import 'regex_engine.dart';

/// A captured range within a match. Mirrors `IOnigCaptureIndex`.
class OnigCaptureIndex {
  const OnigCaptureIndex(this.start, this.end, this.length);

  final int start;
  final int end;
  final int length;
}

/// The result of [OnigScanner.findNextMatch]. Mirrors `IOnigMatch`.
class OnigMatch {
  const OnigMatch(this.index, this.captureIndices);

  /// Index of the pattern (within the scanner) that matched.
  final int index;
  final List<OnigCaptureIndex> captureIndices;
}

/// Wraps a string being scanned. Mirrors `OnigString`.
///
/// Because both this engine and Dart strings work in UTF-16 code units, no
/// offset conversion is required. A native engine may subclass this to cache an
/// encoded copy of [content] (see `shiki_flutter_ffi_engine`).
class OnigString {
  OnigString(this.content);

  final String content;
}

/// Sentinel used for capture groups that did not participate in a match.
const int kUnmatchedOffset = 0xFFFFFFFF;

/// Scans a line for the earliest match among a set of patterns.
///
/// This is the contract the TextMate tokenizer depends on. The bundled
/// implementation is [DartOnigScanner]; a native engine provides its own
/// implementation through a [ShikiHighlighterEngine].
abstract interface class OnigScanner {
  /// Finds the earliest match at or after [startPosition]; a match exactly at
  /// [startPosition] wins immediately. Returns null when nothing matches.
  ///
  /// [string] is an [OnigString] (or a plain [String]); offsets are UTF-16
  /// code units.
  OnigMatch? findNextMatch(Object string, int startPosition);
}

/// The pure-Dart [OnigScanner], backed by [OnigRegex]. Works on every platform.
///
/// Replicates Shiki's JavaScript engine: patterns are tried in order; a pattern
/// matching exactly at the start position wins immediately, otherwise the
/// pattern with the left-most match wins (ties broken by pattern order).
class DartOnigScanner implements OnigScanner {
  DartOnigScanner(List<String> sources, {this.forgiving = true})
      : _regexes = List<OnigRegex?>.filled(sources.length, null) {
    for (var i = 0; i < sources.length; i++) {
      try {
        _regexes[i] = OnigRegex(sources[i]);
      } on RegexSyntaxException {
        if (!forgiving) rethrow;
        _regexes[i] = null;
      } on Object {
        if (!forgiving) rethrow;
        _regexes[i] = null;
      }
    }
  }

  final List<OnigRegex?> _regexes;
  final bool forgiving;

  @override
  OnigMatch? findNextMatch(Object string, int startPosition) {
    final str = string is OnigString ? string.content : string as String;

    int? bestIndex;
    OnigEngineMatch? bestMatch;

    for (var i = 0; i < _regexes.length; i++) {
      final re = _regexes[i];
      if (re == null) continue;
      OnigEngineMatch? m;
      try {
        m = re.search(str, startPosition, gAnchor: startPosition);
      } on Object {
        if (!forgiving) rethrow;
        continue;
      }
      if (m == null) continue;

      // A match exactly at the start position wins immediately.
      if (m.index == startPosition) {
        return _toMatch(i, m);
      }
      if (bestMatch == null || m.index < bestMatch.index) {
        bestMatch = m;
        bestIndex = i;
      }
    }

    if (bestMatch != null) {
      return _toMatch(bestIndex!, bestMatch);
    }
    return null;
  }

  OnigMatch _toMatch(int index, OnigEngineMatch m) {
    final captures = <OnigCaptureIndex>[];
    for (var g = 0; g < m.start.length; g++) {
      final s = m.start[g];
      final e = m.end[g];
      if (s < 0 || e < 0) {
        captures
            .add(const OnigCaptureIndex(kUnmatchedOffset, kUnmatchedOffset, 0));
      } else {
        captures.add(OnigCaptureIndex(s, e, e - s));
      }
    }
    return OnigMatch(index, captures);
  }
}

/// Factory for scanners and strings — the pluggable engine seam. Mirrors
/// `vscode-textmate`'s `IOnigLib`.
///
/// The default is [ShikiHighlighterDartEngine] (pure Dart, every platform). To
/// use a native backend on IO, set the global `ShikiHighlighter.engine` once
/// (e.g. in `main`), or pass one per call via `createHighlighter(engine: …)`.
abstract interface class ShikiHighlighterEngine {
  OnigScanner createScanner(List<String> sources);
  OnigString createString(String str);
}

/// The default engine: the pure-Dart [DartOnigScanner] backed by [OnigRegex].
///
/// Ships with the package and runs on every Flutter platform. It is the fastest
/// option on web (its RegExp fast path routes to V8's native regex).
class ShikiHighlighterDartEngine implements ShikiHighlighterEngine {
  const ShikiHighlighterDartEngine();

  @override
  OnigScanner createScanner(List<String> sources) => DartOnigScanner(sources);

  @override
  OnigString createString(String str) => OnigString(str);
}
