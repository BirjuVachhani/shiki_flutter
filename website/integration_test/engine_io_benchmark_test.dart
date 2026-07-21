// IO engine benchmark + parity: the native Oniguruma engine
// (ShikiHighlighterNativeEngine, dart:ffi, now UTF-8) vs the pure-Dart port
// (ShikiHighlighterDartEngine, shiki_flutter's IO default) - the two engines the
// async worker can run on IO.
//
//   * Parity: after the UTF-8 fix, does the native engine match the golden
//     embedded engine on every language, including CSS/HTML (which diverged
//     under the old UTF-16LE build)?
//   * Throughput: cold (compile + tokenize) and warm (steady-state) tokenize
//     for native vs the dart-port, which decides which is the better engine to
//     run inside the async worker.
//
// Compute only (no widgets), so it needs no window/vsync. Run on macOS profile:
//   flutter drive --driver=test_driver/perf_driver.dart \
//     --target=integration_test/engine_io_benchmark_test.dart -d macos --profile

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter_native_engine/shiki_flutter_native_engine.dart';

import 'support/corpus.dart';
import 'support/local_writer.dart';

// Small but rule-exercising samples. CSS/HTML hit the class-selector rules that
// use `[^\x00-\x7F]` byte escapes - the ones the old UTF-16LE build skipped.
const _samples = {
  'dart': "class A<T> { final int x = 0x1F; String s = 'hi \$x'; // c\n}",
  'javascript': "const f = (a) => `t\${a}`; // c\nlet x = 0x1F, s = 'y';",
  'json': '{"a":1,"b":[true,null,"x"],"c":1.5e3}',
  'python': "def f(x):\n    return f'{x}'  # c\nclass A: pass",
  'css':
      ".foo,#bar>.baz:hover{color:#fff;margin:0 auto}\n.qux::before{content:'x'}",
  'html':
      '<!DOCTYPE html><div class="a"><style>.x{color:red}</style><p>hi</p></div>',
};

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final theme = ShikiThemes.githubDark.id;
  final langs = [
    CodeLanguages.dart,
    CodeLanguages.javascript,
    CodeLanguages.json,
    CodeLanguages.python,
    CodeLanguages.css,
    CodeLanguages.html,
  ];

  testWidgets('native (UTF-8) vs dart-port: parity + throughput (IO)', (
    tester,
  ) async {
    await loadWasm(); // no-op on IO

    // Golden oracle: the pure-Dart embedded engine (golden-proven).
    final embedded = createHighlighter(
      langs: langs,
      themes: [ShikiThemes.githubDark],
      engine: const ShikiHighlighterEmbeddedEngine(),
    );
    // The two async-worker candidates.
    final port = createHighlighter(
      langs: langs,
      themes: [ShikiThemes.githubDark],
    ); // default = dart-port
    final native = createHighlighter(
      langs: langs,
      themes: [ShikiThemes.githubDark],
      engine: const ShikiHighlighterNativeEngine(),
    );

    // --- Parity vs the golden embedded engine, per language.
    final parity = <String, dynamic>{};
    _samples.forEach((lang, src) {
      final opts = TokenizeOptions(lang: lang, theme: theme);
      final g = _fp(embedded.codeToTokens(src, opts));
      final n = _fp(native.codeToTokens(src, opts));
      final p = _fp(port.codeToTokens(src, opts));
      parity[lang] = {
        'native_matches_golden': n == g,
        'port_matches_golden': p == g,
      };
    });

    // --- Throughput: native vs dart-port, cold + warm, on the Dart corpus.
    final throughput = <String, dynamic>{};
    for (final name in const ['dart_port', 'native']) {
      final byShape = <String, dynamic>{};
      for (final size in const [CorpusSize.m, CorpusSize.l, CorpusSize.xl]) {
        final code = corpusFor(size);
        final opts = TokenizeOptions(lang: 'dart', theme: theme);
        // Fresh highlighter so the first call pays the full compile.
        final h = name == 'native'
            ? createHighlighter(
                langs: [CodeLanguages.dart],
                themes: [ShikiThemes.githubDark],
                engine: const ShikiHighlighterNativeEngine(),
              )
            : createHighlighter(
                langs: [CodeLanguages.dart],
                themes: [ShikiThemes.githubDark],
              );

        final cold = Stopwatch()..start();
        h.codeToTokens(code, opts);
        cold.stop();

        const k = 8;
        final times = <double>[];
        for (var i = 0; i < k; i++) {
          final sw = Stopwatch()..start();
          h.codeToTokens(code, opts);
          sw.stop();
          times.add(sw.elapsedMicroseconds / 1000);
        }
        times.sort();
        byShape[size.label] = {
          'cold_ms': _r(cold.elapsedMicroseconds / 1000),
          'warm_median_ms': _r(times[times.length ~/ 2]),
          'warm_min_ms': _r(times.first),
        };
      }
      throughput[name] = byShape;
    }

    // Speed ratios (dart_port / native): > 1 means native is faster.
    final ratios = <String, dynamic>{};
    for (final size in const ['m', 'l', 'xl']) {
      final p = throughput['dart_port'][size];
      final n = throughput['native'][size];
      ratios[size] = {
        'cold': _r(p['cold_ms'] / n['cold_ms']),
        'warm': _r(p['warm_median_ms'] / n['warm_median_ms']),
      };
    }

    final report = {
      'platform': 'io (macos, profile)',
      'parity_vs_golden': parity,
      'throughput': throughput,
      'native_speedup_over_port': ratios,
    };

    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['engine_io_benchmark'] = report;
    writeLocalJson(
      '../benchmark/results/engine_io_benchmark.json',
      const JsonEncoder.withIndent('  ').convert(report),
    );
    // ignore: avoid_print
    print('[engine-io] ${jsonEncode(report)}');

    // The point of the exercise: native must now match golden on CSS/HTML.
    expect(
      parity['css']['native_matches_golden'],
      isTrue,
      reason: 'native engine must match golden on CSS after the UTF-8 fix',
    );
    expect(
      parity['html']['native_matches_golden'],
      isTrue,
      reason: 'native engine must match golden on HTML after the UTF-8 fix',
    );
  });
}

double _r(double v) => double.parse(v.toStringAsFixed(3));

int _fp(List<List<ThemedToken>> lines) {
  var h = 0x811c9dc5;
  void mix(String s) {
    for (var i = 0; i < s.length; i++) {
      h = (h * 31 + s.codeUnitAt(i)) & 0xFFFFFFFF;
    }
  }

  for (final line in lines) {
    for (final t in line) {
      mix(t.content);
      mix('|${t.offset}|${t.color ?? ''}|${t.fontStyle}|');
    }
    mix('\n');
  }
  return h;
}
