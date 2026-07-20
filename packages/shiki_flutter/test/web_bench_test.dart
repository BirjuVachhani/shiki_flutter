// Web tokenization benchmark. Runs our engine compiled to JavaScript
// (dart2js -> native JS RegExp for the fast path) in headless Chrome, so we can
// see real web throughput and how much the RegExp fast path helps on web.
//
//   flutter test test/web_bench_test.dart --platform chrome
//
// (Also runs on the VM with `flutter test test/web_bench_test.dart`, which is
// handy for a VM-vs-web comparison.)

import 'package:flutter_test/flutter_test.dart';
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter/langs/dart.dart';
import 'package:shiki_flutter/themes/github_dark.dart';
import 'package:shiki_flutter/src/onig/regex_engine.dart' show OnigRegex;

import '../benchmark/src/corpus.dart';

void main() {
  test(
    'web tokenization throughput (Dart / GitHub Dark)',
    () {
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
          final t = hl.codeToTokens(src, opts);
          sw.stop();
          samples.add(sw.elapsedMicroseconds);
          if (t.isEmpty) fail('empty');
        }
        samples.sort();
        return samples[samples.length ~/ 2] / 1000.0;
      }

      final buf = StringBuffer('\n==== web tokenize (codeToTokens) ====\n');
      buf.writeln(
        'size   lines   fast-path ms   interpreter ms   speedup   lines/s(fast)',
      );
      for (final size in CorpusSize.values) {
        final fast = median(size, fastPath: true);
        // Interpreter-only is much slower; skip it for the largest size on web.
        final doInterp = size != CorpusSize.xl;
        final interp = doInterp ? median(size, fastPath: false) : 0.0;
        final lps = (size.lines / (fast / 1000)).round();
        buf.writeln(
          '${size.label.padRight(5)}  '
          '${size.lines.toString().padLeft(5)}  '
          '${fast.toStringAsFixed(1).padLeft(11)}  '
          '${(doInterp ? interp.toStringAsFixed(1) : "-").padLeft(13)}  '
          '${(doInterp && fast > 0 ? "${(interp / fast).toStringAsFixed(1)}x" : "-").padLeft(7)}  '
          '${lps.toString().padLeft(12)}',
        );
      }
      OnigRegex.fastPathEnabled = true;
      // ignore: avoid_print
      print(buf.toString());
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
