// Demonstrates implementing the `ShikiHighlighterEngine` seam using nothing
// but `dart:core`'s RegExp. It is not production quality (a real engine,
// like `shiki_flutter_dart_engine`, resolves full Oniguruma regex syntax and
// exposes per-group capture offsets; `dart:core`'s Match only exposes
// offsets for the whole match); it exists purely to show what the contract
// requires: an `OnigScanner` that finds the earliest match among a set of
// patterns, and a way to wrap a `String` as an `OnigString`.

import 'package:shiki_flutter_engine_interface/shiki_flutter_engine_interface.dart';

void main() {
  final engine = _RegExpEngine();
  final scanner = engine.createScanner([
    r'\bvoid\b',
    r'\bmain\b',
    r'\(\)',
  ]);

  const source = 'void main() {}';
  final string = engine.createString(source);

  var position = 0;
  while (true) {
    final match = scanner.findNextMatch(string, position);
    if (match == null) break;

    final whole = match.captureIndices.first;
    print(
      'Pattern ${match.index} matched '
      '"${source.substring(whole.start, whole.end)}" '
      'at [${whole.start}, ${whole.end}).',
    );
    position = whole.end;
  }
}

/// Scans for the earliest match among a set of [RegExp] patterns, compiled
/// once up front from the constructor's `sources`.
class _RegExpScanner implements OnigScanner {
  _RegExpScanner(List<String> sources)
    : _patterns = sources.map(RegExp.new).toList(growable: false);

  final List<RegExp> _patterns;

  @override
  OnigMatch? findNextMatch(Object string, int startPosition) {
    final content = string is OnigString ? string.content : string as String;
    if (startPosition > content.length) return null;

    Match? bestMatch;
    var bestPatternIndex = -1;
    for (var i = 0; i < _patterns.length; i++) {
      final match = _firstMatchFrom(_patterns[i], content, startPosition);
      if (match != null &&
          (bestMatch == null || match.start < bestMatch.start)) {
        bestMatch = match;
        bestPatternIndex = i;
      }
    }
    if (bestMatch == null) return null;

    // dart:core's Match interface only exposes offsets for the whole match
    // (group 0); individual capture groups only expose their matched
    // substring via `group(i)`, not offsets. A real engine resolves true
    // per-group Oniguruma capture offsets instead.
    return OnigMatch(bestPatternIndex, [
      OnigCaptureIndex(
        bestMatch.start,
        bestMatch.end,
        bestMatch.end - bestMatch.start,
      ),
    ]);
  }

  /// Returns the first match of [pattern] in [content] at or after [start],
  /// or null if there isn't one.
  Match? _firstMatchFrom(RegExp pattern, String content, int start) {
    for (final match in pattern.allMatches(content, start)) {
      return match;
    }
    return null;
  }
}

/// Builds [_RegExpScanner]s and wraps strings for scanning. A real engine
/// (see `shiki_flutter_dart_engine` / `shiki_flutter_native_engine`) would
/// wire up a full Oniguruma-compatible regex engine here instead of
/// `dart:core`'s RegExp.
class _RegExpEngine implements ShikiHighlighterEngine {
  @override
  String get id => 'example-regexp';

  @override
  OnigScanner createScanner(List<String> sources) => _RegExpScanner(sources);

  @override
  OnigString createString(String str) => OnigString(str);
}
