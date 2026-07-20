// Deterministic Dart source generator for the benchmark suite.
//
// The generator tiles a fixed, token-dense Dart snippet up to a target line
// count. It contains no randomness so every run - and both benchmark layers
// (headless `flutter test` and the device `integration_test`) - sees the exact
// same input for a given [CorpusSize]. Each tile is lightly renumbered so the
// document isn't a byte-for-byte repeat (which would be unrealistically kind to
// caches), while staying fully reproducible.
//
// This file is intentionally dependency-free and duplicated into
// `website/integration_test/support/corpus.dart` so each layer runs standalone.
library;

/// Named workload sizes, measured in lines of Dart.
enum CorpusSize {
  xs(20),
  s(100),
  m(500),
  l(2000),
  xl(5000);

  const CorpusSize(this.lines);

  /// Target number of source lines this size produces.
  final int lines;

  /// Short label used in report tables and filenames.
  String get label => name;
}

/// Returns deterministic Dart source with exactly [size].lines lines.
String corpusFor(CorpusSize size) => generateDartSource(size.lines);

/// Returns deterministic Dart source with exactly [lineCount] lines.
///
/// The output is a sequence of self-similar but distinctly-numbered units, then
/// truncated (or padded with blank lines) to hit [lineCount] precisely.
String generateDartSource(int lineCount) {
  final unitLines = _unitTemplate.split('\n').length;
  final tiles = (lineCount / unitLines).ceil() + 1;

  final buffer = StringBuffer();
  for (var i = 0; i < tiles; i++) {
    buffer.writeln(_renderUnit(i));
  }

  final all = buffer.toString().split('\n');
  if (all.length >= lineCount) {
    return all.sublist(0, lineCount).join('\n');
  }
  // Pad (only hit for tiny targets) with blank lines.
  return [...all, ...List.filled(lineCount - all.length, '')].join('\n');
}

/// Renders one unit, substituting the tile index [i] into identifiers, numbers
/// and strings so tokens vary across the document while remaining deterministic.
String _renderUnit(int i) {
  return _unitTemplate
      .replaceAll(r'$I', '$i')
      .replaceAll(r'$HEX', '0x${(i * 0x1F + 0xA).toRadixString(16)}')
      .replaceAll(r'$NUM', '${i * 3 + 1}')
      .replaceAll(r'$FLOAT', '${i + 1}.${(i * 7) % 100}');
}

// A ~40-line unit exercising many grammar rules: doc comments, annotations,
// generics, keywords, storage modifiers, numeric literals (int/hex/double),
// interpolated + raw strings, operators and control flow. `$I` etc. are
// substituted per tile by [_renderUnit].
const _unitTemplate = r'''
/// A widget model for section [$I], used to benchmark the highlighter.
///
/// See also [Repository$I] and the `render()` method below. Contains a mix of
/// numbers ($NUM, $FLOAT, $HEX) and interpolated strings for token density.
@immutable
class Repository$I<T extends Comparable<T>> implements Disposable {
  const Repository$I({
    required this.id,
    this.label = 'repo-$I',
    this.threshold = $FLOAT,
    this.mask = $HEX,
  });

  final int id;
  final String label;
  final double threshold;
  final int mask;

  static const int maxItems = $NUM;
  late final List<T> _cache = <T>[];

  /// Loads up to [maxItems] entries, retrying on transient failure.
  Future<Result<T>> load(Uri endpoint, {bool force = false}) async {
    var attempt = 0;
    while (attempt < 3) {
      try {
        final response = await _fetch('$endpoint?page=$I&limit=$NUM');
        if (response.ok && response.body.isNotEmpty) {
          return Result.success(response.decode<T>());
        }
      } on TimeoutException catch (e, stack) {
        print('retry #$attempt for $I failed: ${e.message}\n$stack');
      }
      attempt += 1;
    }
    return const Result.failure('exhausted retries');
  }

  @override
  void dispose() => _cache.clear();
}
''';

/// Basic structural facts about a corpus string - reported alongside timings so
/// numbers can be normalized (per-line, per-char) by whoever reads them.
class WorkloadStats {
  WorkloadStats(String source)
    : lines = '\n'.allMatches(source).length + 1,
      chars = source.length,
      bytes = _utf8Length(source);

  final int lines;
  final int chars;
  final int bytes;

  static int _utf8Length(String s) {
    var count = 0;
    for (final rune in s.runes) {
      if (rune <= 0x7F) {
        count += 1;
      } else if (rune <= 0x7FF) {
        count += 2;
      } else if (rune <= 0xFFFF) {
        count += 3;
      } else {
        count += 4;
      }
    }
    return count;
  }

  @override
  String toString() => '$lines lines, $chars chars, $bytes bytes';
}
