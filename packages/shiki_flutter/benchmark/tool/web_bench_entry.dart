// Web tokenization benchmark entry: pure-Dart core only (no Flutter, no
// dart:io), compiled with dart2js and run on V8 (the same JS engine as Chrome),
// so the numbers reflect real web execution incl. native JS RegExp for the
// fast path.
//
//   dart compile js -O2 benchmark/tool/web_bench_entry.dart -o /tmp/webbench.js
//   node /tmp/webbench.js
// ignore_for_file: avoid_print

import 'package:shiki_flutter/src/core/highlighter.dart';
import 'package:shiki_flutter/src/onig/regex_engine.dart' show OnigRegex;
import 'package:shiki_flutter/langs/dart.dart';
import 'package:shiki_flutter/themes/github_dark.dart';

import '../src/corpus.dart';

void main() {
  final hl = createHighlighter(langs: [dart], themes: [githubDark]);
  const opts = TokenizeOptions(lang: 'dart', theme: 'github-dark');

  double median(CorpusSize size, {required bool fastPath}) {
    OnigRegex.fastPathEnabled = fastPath;
    final src = corpusFor(size);
    hl.codeToTokens(src, opts); // warmup
    final iters = size.lines >= 2000 ? 3 : 9;
    final samples = <int>[];
    for (var i = 0; i < iters; i++) {
      final sw = Stopwatch()..start();
      hl.codeToTokens(src, opts);
      sw.stop();
      samples.add(sw.elapsedMicroseconds);
    }
    samples.sort();
    return samples[samples.length ~/ 2] / 1000.0;
  }

  print('\n==== WEB (dart2js / V8) tokenize: Dart / GitHub Dark ====');
  print('size   lines   fast-path ms   interpreter ms   speedup   lines/s(fast)');
  for (final size in CorpusSize.values) {
    final fast = median(size, fastPath: true);
    final doInterp = size != CorpusSize.xl;
    final interp = doInterp ? median(size, fastPath: false) : 0.0;
    final lps = (size.lines / (fast / 1000)).round();
    print('${size.label.padRight(5)}  '
        '${size.lines.toString().padLeft(5)}  '
        '${fast.toStringAsFixed(1).padLeft(11)}  '
        '${(doInterp ? interp.toStringAsFixed(1) : "-").padLeft(13)}  '
        '${(doInterp ? "${(interp / fast).toStringAsFixed(1)}x" : "-").padLeft(7)}  '
        '${lps.toString().padLeft(12)}');
  }
  OnigRegex.fastPathEnabled = true;
}
