// Adapter that presents [OnigRegex] through the interface the TextMate
// tokenizer expects (mirroring `vscode-textmate`'s `onigLib.ts` and Shiki's
// JavaScript `scanner.ts`).
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
/// offset conversion is required.
class OnigString {
  OnigString(this.content);

  final String content;
}

/// Sentinel used for capture groups that did not participate in a match.
const int _kMaxOffset = 0xFFFFFFFF;

/// Scans a line for the earliest match among a set of patterns.
///
/// This replicates the behaviour of Shiki's JavaScript engine: patterns are
/// tried in order; a pattern matching exactly at the start position wins
/// immediately, otherwise the pattern with the left-most match wins (ties
/// broken by pattern order).
class OnigScanner {
  OnigScanner(List<String> sources, {this.forgiving = true})
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
        captures.add(const OnigCaptureIndex(_kMaxOffset, _kMaxOffset, 0));
      } else {
        captures.add(OnigCaptureIndex(s, e, e - s));
      }
    }
    return OnigMatch(index, captures);
  }
}

/// Factory for scanners and strings. Mirrors `IOnigLib`.
class OnigLib {
  const OnigLib();

  OnigScanner createScanner(List<String> sources) => OnigScanner(sources);

  OnigString createString(String str) => OnigString(str);
}
