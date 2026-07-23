// The pluggable regex-engine seam the TextMate tokenizer runs on, mirroring
// `vscode-textmate`'s `onigLib.ts` / `IOnigLib` and Shiki's JavaScript
// `scanner.ts`.
//
// The contract types ([ShikiHighlighterEngine], [OnigScanner], [OnigString],
// [OnigMatch], [OnigCaptureIndex] and [kUnmatchedOffset]) live in
// `package:shiki_flutter_engine_interface` so every engine backend shares them.
// This file re-exports them and adds shiki_flutter's bundled implementation:
// [ShikiHighlighterEmbeddedEngine], the pure-Dart engine backed by [OnigRegex].

import 'package:shiki_flutter_engine_interface/shiki_flutter_engine_interface.dart';

import 'regex_engine.dart';

export 'package:shiki_flutter_engine_interface/shiki_flutter_engine_interface.dart';

/// The pure-Dart [OnigScanner], backed by [OnigRegex]. Works on every platform.
///
/// Replicates Shiki's JavaScript engine: patterns are tried in order; a pattern
/// matching exactly at the start position wins immediately, otherwise the
/// pattern with the left-most match wins (ties broken by pattern order).
class DartOnigScanner implements OnigScanner {
  /// Compiles [sources] as Oniguruma patterns. When [forgiving] (the
  /// default), a pattern that fails to compile or match is skipped instead of
  /// throwing, matching Shiki's tolerance of malformed grammar regexes.
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

  /// Whether a pattern that fails to compile or match is skipped rather than
  /// thrown, as passed to the constructor.
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
        captures.add(
          const OnigCaptureIndex(kUnmatchedOffset, kUnmatchedOffset, 0),
        );
      } else {
        captures.add(OnigCaptureIndex(s, e, e - s));
      }
    }
    return OnigMatch(index, captures);
  }
}

/// The default engine: the pure-Dart [DartOnigScanner] backed by [OnigRegex].
///
/// Ships with the package and runs on every Flutter platform. It is the fastest
/// option on web (its RegExp fast path routes to V8's native regex).
class ShikiHighlighterEmbeddedEngine implements ShikiHighlighterEngine {
  /// Creates the embedded engine. Stateless, so this is a `const` singleton.
  const ShikiHighlighterEmbeddedEngine();

  @override
  String get id => 'embedded';

  @override
  OnigScanner createScanner(List<String> sources) => DartOnigScanner(sources);

  @override
  OnigString createString(String str) => OnigString(str);
}
