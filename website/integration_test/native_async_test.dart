// Verifies the NATIVE Oniguruma engine (ShikiHighlighterNativeEngine, dart:ffi)
// works INSIDE shiki_flutter's async worker isolate on IO, which is the one
// combination benchmarked only in pieces before:
//
//   1. Correctness: tokens produced through the worker must equal the same
//      engine run synchronously on the main isolate. This proves native assets
//      load and run in a spawned (Isolate.spawn) worker.
//   2. No freeze: driving ShikiCodeListView(async: true) with a native-engine
//      highlighter must keep the UI thread responsive while the worker does the
//      cold grammar/regex compile off-thread.
//
// Run on macOS profile (from website/):
//   flutter drive --driver=test_driver/perf_driver.dart \
//     --target=integration_test/native_async_test.dart -d macos --profile

import 'dart:convert';
import 'dart:ui' show FrameTiming, TimingsCallback;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter_native_engine/shiki_flutter_native_engine.dart';

import 'support/corpus.dart';
import 'support/local_writer.dart';

const _lang = 'dart';
const double _budget60 = 1000 / 60;
const double _budget120 = 1000 / 120;
const _base = TextStyle(fontFamily: 'monospace', fontSize: 14, height: 1.4);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final theme = ShikiThemes.githubDark.id;

  testWidgets('native engine via async worker: parity + no freeze', (
    tester,
  ) async {
    await loadWasm(); // no-op on IO; keeps startup portable

    final opts = TokenizeOptions(lang: _lang, theme: theme);
    final src = corpusFor(CorpusSize.l); // 2,000 lines - the freeze case

    // Reference tokens: the default (dart-port) engine, synchronous.
    final refH = createHighlighter(
      langs: [CodeLanguages.dart],
      themes: [ShikiThemes.githubDark],
    );
    final refFp = _fp(refH.codeToTokens(src, opts));

    // Native engine. codeToTokensAsync routes through the worker isolate with
    // the native (FFI) engine forwarded to it.
    final nativeH = createHighlighter(
      langs: [CodeLanguages.dart],
      themes: [ShikiThemes.githubDark],
      engine: const ShikiHighlighterNativeEngine(),
    );
    final asyncTokens = await nativeH.codeToTokensAsync(src, opts);
    final asyncFp = _fp(asyncTokens);
    final asyncCount = _count(asyncTokens);
    // Same engine run synchronously on the main isolate, as the correctness
    // oracle: the worker must match this exactly.
    final nativeSyncFp = _fp(nativeH.codeToTokens(src, opts));

    final report = <String, dynamic>{
      'platform': 'io (macos, profile)',
      'native_async_token_count': asyncCount,
      'parity_workerNative_vs_mainNative': asyncFp == nativeSyncFp,
      'parity_native_vs_dartPort': asyncFp == refFp,
    };

    // --- Jank: fresh native highlighter so its worker pays a COLD compile
    // off-thread while we watch the UI thread. If the FFI work leaked onto the
    // main isolate (e.g. silent inline fallback), the ~cold compile would show
    // up as one big frame here.
    final jankH = createHighlighter(
      langs: [CodeLanguages.dart],
      themes: [ShikiThemes.githubDark],
      engine: const ShikiHighlighterNativeEngine(),
    );
    final reg = jankH.getThemeRegistration(theme);
    final fg = parseColor(reg.fg);
    final bg = parseColor(reg.bg);

    final timings = <FrameTiming>[];
    final TimingsCallback cb = timings.addAll;
    binding.addTimingsCallback(cb);

    final firstFrame = Stopwatch()..start();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: ShikiCodeListView(
              key: const Key('scroller'),
              highlighter: jankH,
              code: src,
              lang: CodeLanguages.dart,
              theme: ShikiThemes.githubDark,
              textStyle: _base.copyWith(color: fg),
              async: true,
            ),
          ),
        ),
      ),
    );
    firstFrame.stop();
    await tester.pumpAndSettle();
    // Let the worker's cold compile + tokenize land and the highlight swap in
    // before measuring scroll.
    await Future<void>.delayed(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    final scroller = find.byKey(const Key('scroller'));
    for (var i = 0; i < 6; i++) {
      await tester.fling(scroller, const Offset(0, -600), 3000);
      await tester.pumpAndSettle();
      await tester.fling(scroller, const Offset(0, 600), 3000);
      await tester.pumpAndSettle();
    }
    await Future<void>.delayed(const Duration(seconds: 1));
    await tester.pump();
    binding.removeTimingsCallback(cb);

    final totals =
        timings.map((t) => t.totalSpan.inMicroseconds / 1000).toList()..sort();
    report['jank'] = {
      'frame_count': totals.length,
      'first_frame_ms': _r(firstFrame.elapsedMicroseconds / 1000),
      'worst_ms': totals.isEmpty ? 0 : _r(totals.last),
      'p99_ms': totals.isEmpty
          ? 0
          : _r(
              totals[(0.99 * totals.length).ceil().clamp(1, totals.length) - 1],
            ),
      'missed_60fps': totals.where((v) => v > _budget60).length,
      'missed_120fps': totals.where((v) => v > _budget120).length,
    };

    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['native_async'] = report;
    writeLocalJson(
      '../benchmark/results/native_async_io.json',
      const JsonEncoder.withIndent('  ').convert(report),
    );
    // ignore: avoid_print
    print('[native-async] ${jsonEncode(report)}');

    // Hard proof it actually ran on the worker and produced real tokens.
    expect(
      asyncCount,
      greaterThan(5000),
      reason: 'native async should tokenize the l corpus (~11k tokens)',
    );
    expect(
      report['parity_workerNative_vs_mainNative'],
      isTrue,
      reason: 'worker-native tokens must equal main-isolate-native tokens',
    );
  });
}

double _r(double v) => double.parse(v.toStringAsFixed(3));

int _count(List<List<ThemedToken>> lines) {
  var n = 0;
  for (final l in lines) {
    n += l.length;
  }
  return n;
}

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
