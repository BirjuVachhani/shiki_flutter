// Web engine comparison: bundled (shiki_flutter's built-in Dart engine, whose
// RegExp fast path routes to V8's native regex) vs oniguruma_dart (pure-Dart
// backtracking port). The FFI engine has no web backend, so it is excluded.
//
// Same corpus, grammar, and theme as the VM benchmark; only the engine differs.
//
// Run (from packages/shiki_flutter_dart_engine):
//   dart compile js -O2 benchmark/web_engine_compare.dart -o /tmp/web_bench.js
//   node /tmp/web_bench.js

import 'package:shiki_flutter/engine.dart';
import 'package:shiki_flutter/langs/dart.dart';
import 'package:shiki_flutter/themes/github_dark.dart';
import 'package:shiki_flutter_dart_engine/shiki_flutter_dart_engine.dart';

import '../../shiki_flutter/benchmark/src/corpus.dart';

const _opts = TokenizeOptions(lang: 'dart', theme: 'github-dark');
const _sizes = [CorpusSize.m, CorpusSize.l, CorpusSize.xl];

double _medianMs(List<int> micros) {
  micros.sort();
  return micros[micros.length ~/ 2] / 1000.0;
}

double _bench(ShikiHighlighterEngine engine, String src,
    {required int warmup, required int iters}) {
  final hl =
      createHighlighter(langs: [dart], themes: [githubDark], engine: engine);
  for (var i = 0; i < warmup; i++) {
    hl.codeToTokens(src, _opts);
  }
  final micros = <int>[];
  for (var i = 0; i < iters; i++) {
    final sw = Stopwatch()..start();
    hl.codeToTokens(src, _opts);
    sw.stop();
    micros.add(sw.elapsedMicroseconds);
  }
  return _medianMs(micros);
}

void main() {
  final engines = <String, ShikiHighlighterEngine>{
    'bundled (built-in Dart, RegExp fast path)':
        const ShikiHighlighterEmbeddedEngine(),
    'oniguruma_dart (port)': const ShikiHighlighterDartEngine(),
  };

  print('Web engine comparison — codeToTokens (dart2js + node)');
  print('lang=dart, theme=github-dark · median of iters');
  print('x bundled = median / bundled median (lower is faster)');

  for (final size in _sizes) {
    final src = corpusFor(size);
    final iters = size == CorpusSize.xl ? 5 : 10;
    print('\n${size.label} (${size.lines} lines):');
    double? base;
    engines.forEach((label, engine) {
      final med = _bench(engine, src, warmup: 2, iters: iters);
      base ??= med;
      final rel = med / base!;
      print('  ${label.padRight(44)}'
          ' ${med.toStringAsFixed(1).padLeft(9)} ms'
          '   ${rel.toStringAsFixed(2)}x bundled');
    });
  }
}
