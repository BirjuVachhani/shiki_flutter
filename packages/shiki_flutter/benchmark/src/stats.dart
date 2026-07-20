// Timing, statistics and reporting helpers for the benchmark suite.
//
// Dependency-free (only `dart:io` + `dart:convert`) so it can be imported from a
// `flutter test` file without pulling in Flutter. Timings are collected in
// microseconds via [Stopwatch] and summarized as min / mean / median / p90 /
// p99 / max. Percentiles matter here because layout cost is spiky.
library;

import 'dart:convert';
import 'dart:io';

/// A collection of timing samples, in microseconds.
class Sample {
  Sample(this.label);

  final String label;
  final List<int> _micros = [];

  void add(int micros) => _micros.add(micros);

  int get count => _micros.length;
  bool get isEmpty => _micros.isEmpty;

  List<int> get _sorted => [..._micros]..sort();

  double get meanMicros =>
      isEmpty ? 0 : _micros.reduce((a, b) => a + b) / _micros.length;

  int get minMicros => isEmpty ? 0 : _sorted.first;
  int get maxMicros => isEmpty ? 0 : _sorted.last;
  int get medianMicros => percentileMicros(50);

  /// Nearest-rank percentile (p in 0..100).
  int percentileMicros(double p) {
    if (isEmpty) return 0;
    final sorted = _sorted;
    final rank = (p / 100 * sorted.length).ceil().clamp(1, sorted.length);
    return sorted[rank - 1];
  }

  double get medianMs => medianMicros / 1000;
  double get p90Ms => percentileMicros(90) / 1000;
  double get p99Ms => percentileMicros(99) / 1000;
  double get minMs => minMicros / 1000;
  double get maxMs => maxMicros / 1000;
  double get meanMs => meanMicros / 1000;

  Map<String, dynamic> toJson() => {
    'label': label,
    'count': count,
    'min_ms': _round(minMs),
    'mean_ms': _round(meanMs),
    'median_ms': _round(medianMs),
    'p90_ms': _round(p90Ms),
    'p99_ms': _round(p99Ms),
    'max_ms': _round(maxMs),
  };
}

/// Runs [body] [warmup] times untimed, then [iters] times timed, returning a
/// [Sample] labeled [label]. Each iteration is measured independently so
/// percentiles reflect per-run variance rather than an averaged-away total.
Sample measure(
  String label, {
  required int warmup,
  required int iters,
  required void Function() body,
}) {
  for (var i = 0; i < warmup; i++) {
    body();
  }
  final sample = Sample(label);
  final sw = Stopwatch();
  for (var i = 0; i < iters; i++) {
    sw
      ..reset()
      ..start();
    body();
    sw.stop();
    sample.add(sw.elapsedMicroseconds);
  }
  return sample;
}

/// Times a single execution of [body] in microseconds (for cold/first-run
/// measurements that must not be repeated).
int measureOnce(void Function() body) {
  final sw = Stopwatch()..start();
  body();
  sw.stop();
  return sw.elapsedMicroseconds;
}

double _round(double v) => double.parse(v.toStringAsFixed(4));

/// A simple fixed-width text table for console output.
class ConsoleTable {
  ConsoleTable(this.headers);

  final List<String> headers;
  final List<List<String>> _rows = [];

  void addRow(List<String> cells) => _rows.add(cells);

  String render() {
    final widths = List<int>.generate(headers.length, (i) => headers[i].length);
    for (final row in _rows) {
      for (var i = 0; i < row.length; i++) {
        if (row[i].length > widths[i]) widths[i] = row[i].length;
      }
    }
    String fmtRow(List<String> cells) {
      final parts = <String>[];
      for (var i = 0; i < cells.length; i++) {
        // First column left-aligned, the rest right-aligned (numbers).
        parts.add(
          i == 0 ? cells[i].padRight(widths[i]) : cells[i].padLeft(widths[i]),
        );
      }
      return parts.join('  ');
    }

    final sep = List<int>.generate(
      headers.length,
      (i) => widths[i],
    ).map((w) => '-' * w).join('  ');
    final buffer = StringBuffer()
      ..writeln(fmtRow(headers))
      ..writeln(sep);
    for (final row in _rows) {
      buffer.writeln(fmtRow(row));
    }
    return buffer.toString();
  }
}

/// Formats a millisecond value with adaptive precision.
String ms(double v) {
  if (v >= 100) return v.toStringAsFixed(0);
  if (v >= 10) return v.toStringAsFixed(1);
  return v.toStringAsFixed(2);
}

/// Formats a throughput count with thousands separators.
String count(num v) {
  final s = v.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Writes [data] as pretty JSON to `<dir>/<name>_<timestamp>.json` and also
/// updates `<dir>/<name>_latest.json`. Returns the timestamped path. Creates
/// [dir] if needed.
String writeJsonResult(
  String name,
  Map<String, dynamic> data, {
  String dir = 'benchmark/results',
}) {
  Directory(dir).createSync(recursive: true);
  final stamp = DateTime.now()
      .toIso8601String()
      .replaceAll(':', '-')
      .split('.')
      .first;
  final encoder = const JsonEncoder.withIndent('  ');
  final json = encoder.convert(data);
  final path = '$dir/${name}_$stamp.json';
  File(path).writeAsStringSync(json);
  File('$dir/${name}_latest.json').writeAsStringSync(json);
  return path;
}
