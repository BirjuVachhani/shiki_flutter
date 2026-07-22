// Engine tokenization benchmark: the built-in pure-Dart engine
// (ShikiHighlighterEmbeddedEngine, the web default) vs the real Oniguruma engine
// from `oniguruma_native` (WebAssembly on web, dart:ffi on IO), wrapped by
// ShikiHighlighterNativeEngine.
//
// This measures TOKENIZATION only (codeToTokens is pure data, no dart:ui), so it
// runs standalone in the integration binding without pumping any widgets. It
// reports the one-time grammar/regex compile cost and steady-state tokenize
// throughput at two document sizes, plus a parity fingerprint proving the two
// engines produce the same tokens.
//
// Run on web in profile mode (from website/, with chromedriver on :4444):
//
//   flutter drive \
//     --driver=test_driver/perf_driver.dart \
//     --target=integration_test/engine_web_benchmark_test.dart \
//     -d chrome --profile
//
// Web prints go to the browser console, so results are read from the driver's
// build/integration_response_data.json (reportData), not the terminal.

import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter_native_engine/shiki_flutter_native_engine.dart';

import 'support/corpus.dart';
import 'support/local_writer.dart';

const _langId = 'dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final theme = ShikiThemes.githubDark.id;

  testWidgets('engine benchmark: embedded (pure-Dart) vs oniguruma_native', (
    tester,
  ) async {
    // Web instantiates the Oniguruma wasm module asynchronously; it must be
    // loaded before the native engine tokenizes. No-op on IO.
    await loadWasm();

    final report = <String, dynamic>{
      'platform': kIsWeb ? 'web (dart2js + CanvasKit)' : 'io',
      'lang': _langId,
      'theme': theme,
    };

    for (final name in const ['embedded', 'oniguruma_native']) {
      final engineResult = <String, dynamic>{};

      for (final size in const [CorpusSize.m, CorpusSize.l]) {
        final src = corpusFor(size);
        final opts = TokenizeOptions(lang: _langId, theme: theme);

        // A fresh highlighter per (engine, size) so the FIRST call pays the
        // full one-time cost: build the rule tree + compile every regex the
        // corpus hits (Oniguruma-in-wasm, or pure-Dart), then tokenize. On
        // single-threaded web this cold call is the UI-blocking cost that
        // matters, since there is no isolate to hide it behind.
        final h = name == 'oniguruma_native'
            ? (ShikiHighlighter(engine: const ShikiHighlighterNativeEngine())
                ..preload(
                  langs: [CodeLanguages.dart],
                  themes: [ShikiThemes.githubDark],
                ))
            : (ShikiHighlighter()..preload(
                langs: [CodeLanguages.dart],
                themes: [ShikiThemes.githubDark],
              ));

        final cold = Stopwatch()..start();
        final first = h.codeToTokens(src, opts);
        cold.stop();

        // Fingerprint the tokens for the cross-engine parity check.
        report['_fp_${name}_${size.label}'] = _fingerprint(first);
        report['_tok_${name}_${size.label}'] = _tokenCount(first);

        // Warm steady-state: grammar already compiled, so this is pure
        // tokenize throughput (no per-input result caching in codeToTokens).
        const k = 8;
        final times = <double>[];
        for (var i = 0; i < k; i++) {
          final sw = Stopwatch()..start();
          h.codeToTokens(src, opts);
          sw.stop();
          times.add(sw.elapsedMicroseconds / 1000);
        }
        times.sort();
        engineResult[size.label] = {
          'cold_ms': _r(cold.elapsedMicroseconds / 1000),
          'warm_median_ms': _r(times[times.length ~/ 2]),
          'warm_min_ms': _r(times.first),
          'warm_max_ms': _r(times.last),
          'warm_avg_ms': _r(times.reduce((a, b) => a + b) / times.length),
          'warm_runs': k,
        };
      }
      report[name] = engineResult;
    }

    // Parity: do the two engines produce the same tokens for this Dart corpus?
    final parity = <String, dynamic>{};
    for (final size in const [CorpusSize.m, CorpusSize.l]) {
      parity[size.label] = {
        'identical':
            report['_fp_embedded_${size.label}'] ==
            report['_fp_oniguruma_native_${size.label}'],
        'tokens_embedded': report['_tok_embedded_${size.label}'],
        'tokens_native': report['_tok_oniguruma_native_${size.label}'],
      };
    }
    report['parity'] = parity;
    report.removeWhere((k, _) => k.startsWith('_'));

    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['engine_web_benchmark'] = report;
    // Best-effort local copy (no-op on web, which has no filesystem).
    final json = const JsonEncoder.withIndent('  ').convert(report);
    writeLocalJson('build/engine_web_benchmark.json', json);
    writeLocalJson('../benchmark/results/engine_web_benchmark.json', json);
    // ignore: avoid_print
    print('[engine-bench] ${jsonEncode(report)}');
  });
}

double _r(double v) => double.parse(v.toStringAsFixed(3));

int _tokenCount(List<List<ThemedToken>> lines) {
  var n = 0;
  for (final line in lines) {
    n += line.length;
  }
  return n;
}

/// A 32-bit FNV-ish fingerprint over token content + offset + color + style.
/// Kept inside 32 bits (mask each step) so it is exact under dart2js, which
/// loses precision on integer math above 2^53. Equal fingerprints + equal token
/// counts means the two engines tokenized identically.
int _fingerprint(List<List<ThemedToken>> lines) {
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
