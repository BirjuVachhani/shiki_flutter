// Grammar decode / parse benchmark for shiki_flutter.
//
// Answers one question with real numbers: how long does turning a bundled
// grammar's `const` JSON string into usable data cost on the main isolate?
//
// It isolates the two synchronous costs a `loadBundledLanguage` call pays:
//
//   1. decode : jsonDecode(lang.json)           -> Map
//   2. build  : RawGrammar.fromJson(decodedMap) -> grammar model
//
// Oniguruma regex compilation is deliberately NOT measured: it is lazy
// (compiled per-rule at tokenize time and memoized), so it is not part of the
// load-time cost this benchmark is about.
//
// Pure Dart (no Flutter), so it exercises the VM's eager-decode path -- the
// same one mobile/desktop AOT uses. (The dart2js web path is lazier, and thus
// cheaper, because it wraps the native `JSON.parse` result.)
//
//   dart run benchmark/decode_benchmark.dart                 # JIT
//
// For the numbers a release Flutter app actually pays, run it AOT-compiled:
//
//   dart compile exe benchmark/decode_benchmark.dart -o /tmp/decode_bench
//   /tmp/decode_bench AOT
//
// The optional first argument is just a label for the report header / JSON.
// A machine-readable copy is written to benchmark/results/decode_latest.json.

import 'dart:convert';
import 'dart:io';

import 'package:shiki_flutter/langs.dart';
import 'package:shiki_flutter/src/textmate/raw_grammar.dart';

import 'src/stats.dart';

/// One grammar's measured costs.
class _Row {
  _Row(this.id, this.bytes, this.decodeMs, this.buildMs);

  final String id;
  final int bytes;
  final double decodeMs;
  final double buildMs;

  double get totalMs => decodeMs + buildMs;
  double get kb => bytes / 1024;
}

/// Fewer iterations for the giant grammars so total wall-clock stays sane.
({int warmup, int iters}) _budget(int bytes) {
  if (bytes > 200 * 1024) return (warmup: 2, iters: 6);
  if (bytes > 50 * 1024) return (warmup: 2, iters: 12);
  return (warmup: 3, iters: 25);
}

void main(List<String> args) {
  final mode = args.isNotEmpty ? args.first : 'VM / JIT';
  final rows = <_Row>[];

  for (final lang in CodeLanguages.all) {
    final json = lang.json;
    final bytes = utf8.encode(json).length;
    final b = _budget(bytes);

    final decode = measure(
      lang.id,
      warmup: b.warmup,
      iters: b.iters,
      body: () => jsonDecode(json),
    );

    // Decode once up front so `build` times only model construction, not the
    // decode we already measured. RawGrammar.fromJson does not mutate its input.
    final map = jsonDecode(json) as Map<String, dynamic>;
    final build = measure(
      lang.id,
      warmup: b.warmup,
      iters: b.iters,
      body: () => RawGrammar.fromJson(map),
    );

    rows.add(_Row(lang.id, bytes, decode.medianMs, build.medianMs));
  }

  _report(rows, mode);
}

void _report(List<_Row> rows, String mode) {
  final totalBytes = rows.fold<int>(0, (s, r) => s + r.bytes);
  final sumDecode = rows.fold<double>(0, (s, r) => s + r.decodeMs);
  final sumBuild = rows.fold<double>(0, (s, r) => s + r.buildMs);
  final sumTotal = sumDecode + sumBuild;

  final byTotal = [...rows]..sort((a, b) => a.totalMs.compareTo(b.totalMs));
  final worst = byTotal.last;
  final medianGrammar = byTotal[byTotal.length ~/ 2];

  // Distribution of per-grammar total load cost.
  int lt1 = 0, lt4 = 0, lt8 = 0, lt16 = 0, ge16 = 0;
  for (final r in rows) {
    final t = r.totalMs;
    if (t < 1) {
      lt1++;
    } else if (t < 4) {
      lt4++;
    } else if (t < 8) {
      lt8++;
    } else if (t < 16) {
      lt16++;
    } else {
      ge16++;
    }
  }

  final out = StringBuffer()
    ..writeln('\n==== grammar decode / parse ($mode, eager decode) ====')
    ..writeln(
      '${Platform.operatingSystem} · ${Platform.numberOfProcessors} cores · '
      'Dart ${Platform.version.split(' ').first}',
    )
    ..writeln(
      'languages: ${rows.length}   total JSON: ${ms(totalBytes / 1024 / 1024)} MB',
    )
    ..writeln()
    ..writeln(
      'Per-grammar cost = decode (jsonDecode) + build '
      '(RawGrammar.fromJson).',
    )
    ..writeln('Lazy regex compilation is NOT included.')
    ..writeln();

  final agg = ConsoleTable(['aggregate', 'decode', 'build', 'total'])
    ..addRow(['sum (all langs)', ms(sumDecode), ms(sumBuild), ms(sumTotal)])
    ..addRow([
      'mean / grammar',
      ms(sumDecode / rows.length),
      ms(sumBuild / rows.length),
      ms(sumTotal / rows.length),
    ])
    ..addRow([
      'median grammar',
      ms(medianGrammar.decodeMs),
      ms(medianGrammar.buildMs),
      ms(medianGrammar.totalMs),
    ])
    ..addRow([
      'worst (${worst.id})',
      ms(worst.decodeMs),
      ms(worst.buildMs),
      ms(worst.totalMs),
    ]);
  out
    ..writeln(agg.render())
    ..writeln('-- per-grammar total load cost --')
    ..writeln('  < 1 ms  : $lt1')
    ..writeln('  1-4 ms  : $lt4')
    ..writeln('  4-8 ms  : $lt8')
    ..writeln('  8-16 ms : $lt16')
    ..writeln(
      '  >=16 ms : $ge16   (dropped-frame risk @60fps if loaded '
      'synchronously on the main isolate)',
    )
    ..writeln();

  final biggest = [...rows]..sort((a, b) => b.bytes.compareTo(a.bytes));
  final table = ConsoleTable([
    'id',
    'size KB',
    'decode ms',
    'build ms',
    'total ms',
  ]);
  for (final r in biggest.take(15)) {
    table.addRow([
      r.id,
      ms(r.kb),
      ms(r.decodeMs),
      ms(r.buildMs),
      ms(r.totalMs),
    ]);
  }
  out
    ..writeln('-- 15 biggest grammars --')
    ..writeln(table.render());

  stdout.write(out.toString());

  final path = writeJsonResult('decode', {
    'mode': mode,
    'platform': Platform.operatingSystem,
    'cores': Platform.numberOfProcessors,
    'dart': Platform.version,
    'language_count': rows.length,
    'total_bytes': totalBytes,
    'sum_decode_ms': _r(sumDecode),
    'sum_build_ms': _r(sumBuild),
    'sum_total_ms': _r(sumTotal),
    'languages': [
      for (final r in biggest)
        {
          'id': r.id,
          'bytes': r.bytes,
          'decode_ms': _r(r.decodeMs),
          'build_ms': _r(r.buildMs),
          'total_ms': _r(r.totalMs),
        },
    ],
  });
  stdout.writeln('\nwrote $path');
}

double _r(double v) => double.parse(v.toStringAsFixed(4));
