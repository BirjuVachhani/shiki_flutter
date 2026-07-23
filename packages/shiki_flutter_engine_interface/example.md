`shiki_flutter`'s regex engine is pluggable through the `ShikiHighlighterEngine`
seam. Implement it to back `shiki_flutter` with your own regex engine instead of
`shiki_flutter_dart_engine` or `shiki_flutter_native_engine`.

The whole contract is two methods: build an `OnigScanner` that finds the
earliest match among a set of patterns, and wrap a `String` in an `OnigString`.

This example backs the scanner with `dart:core`'s `RegExp`, simplified to report
only the whole match's offsets (a real engine, like `shiki_flutter_dart_engine`,
also resolves each capture group):

```dart
import 'package:shiki_flutter_engine_interface/shiki_flutter_engine_interface.dart';

class MyEngine implements ShikiHighlighterEngine {
  const MyEngine();

  // A stable literal, not derived from runtimeType (which minifies on web).
  @override
  String get id => 'my-engine';

  @override
  OnigScanner createScanner(List<String> sources) => MyScanner(sources);

  @override
  OnigString createString(String str) => OnigString(str);
}

class MyScanner implements OnigScanner {
  MyScanner(List<String> sources)
      : _patterns = sources.map(RegExp.new).toList(growable: false);

  final List<RegExp> _patterns;

  @override
  OnigMatch? findNextMatch(Object string, int startPosition) {
    final content = string is OnigString ? string.content : string as String;

    Match? bestMatch;
    var bestIndex = -1;
    for (var i = 0; i < _patterns.length; i++) {
      final match = _firstMatchFrom(_patterns[i], content, startPosition);
      if (match != null &&
          (bestMatch == null || match.start < bestMatch.start)) {
        bestMatch = match;
        bestIndex = i;
      }
    }
    if (bestMatch == null) return null;

    return OnigMatch(bestIndex, [
      OnigCaptureIndex(
        bestMatch.start,
        bestMatch.end,
        bestMatch.end - bestMatch.start,
      ),
    ]);
  }

  Match? _firstMatchFrom(RegExp pattern, String content, int start) {
    for (final match in pattern.allMatches(content, start)) {
      return match;
    }
    return null;
  }
}

void main() {
  const engine = MyEngine();
  final scanner = engine.createScanner([r'\bvoid\b', r'\bmain\b']);

  final match = scanner.findNextMatch('void main() {}', 0);
  print('Pattern ${match!.index} matched at ${match.captureIndices.first.start}.');
}
```

Point `shiki_flutter` at it once, e.g. on IO:

```dart
ShikiHighlighter.config =
    ShikiHighlighter.config.copyWith(ioEngine: const MyEngine());
```
