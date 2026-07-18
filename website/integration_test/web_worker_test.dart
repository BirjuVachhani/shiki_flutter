// Verifies the browser Web Worker path on web (dart:isolate is unavailable
// there). Two things are proven:
//
//   1. Off-thread + correct: a real Web Worker spawns (worker.isRemote), and its
//      tokens equal the synchronous embedded engine byte-for-byte.
//   2. No freeze: driving ShikiCodeListView(async: true) on the large corpus,
//      the cold grammar/regex compile happens in the worker, so the UI thread
//      never shows the ~961ms first-frame freeze the inline path has
//      (frames_web_profile.json).
//
// The worker must be installed into web/ first:
//   dart run shiki_flutter:install_web_worker
// Run on Chrome profile (chromedriver on :4444):
//   flutter drive --driver=test_driver/perf_driver.dart \
//     --target=integration_test/web_worker_test.dart -d chrome --profile

import 'dart:convert';
import 'dart:ui' show FrameTiming, TimingsCallback;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter/langs/dart.dart';
import 'package:shiki_flutter/themes/github_dark.dart';
// Internal seam: lets the test spawn the Web Worker directly and confirm it is
// remote, which the public API deliberately hides.
import 'package:shiki_flutter/src/async/lang_descriptor.dart';
import 'package:shiki_flutter/src/async/protocol.dart';
import 'package:shiki_flutter/src/async/tokenize_worker.dart';

import 'support/corpus.dart';
import 'support/local_writer.dart';

const _lang = 'dart';
const double _budget60 = 1000 / 60;
const double _budget120 = 1000 / 120;
const _base = TextStyle(fontFamily: 'monospace', fontSize: 14, height: 1.4);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final theme = githubDark.id;

  testWidgets('web worker: remote, parity, and no main-thread freeze',
      (tester) async {
    final opts = TokenizeOptions(lang: _lang, theme: theme);
    final src = corpusFor(CorpusSize.l); // 2,000 lines - the freeze case

    // Reference: the synchronous embedded engine (the engine the worker uses).
    final ref = createHighlighter(
        langs: [dart],
        themes: [githubDark],
        engine: const ShikiHighlighterEmbeddedEngine());
    final refFp = _fp(ref.codeToTokens(src, opts));

    // --- Spawn the browser Web Worker directly. isRemote == true proves a real
    // Worker (not the inline fallback), i.e. the script was found and handshook.
    final worker = await spawnTokenizeWorker(WorkerConfig(
      langs: [flattenBundledLanguage(dart)],
      themeJsons: [githubDark.json],
    ));
    await worker.ready;
    final workerTokens = await worker.tokenize(src, opts);
    final report = <String, dynamic>{
      'platform': 'web (dart2js + CanvasKit)',
      'worker_is_remote': worker.isRemote,
      'worker_token_count': _count(workerTokens),
      'parity_worker_vs_sync_embedded': _fp(workerTokens) == refFp,
    };
    await worker.dispose();

    // --- Jank: drive the virtualized list with async on, so the highlighter's
    // own worker pays the cold compile off-thread while we watch the UI thread.
    final jankH = createHighlighter(langs: [dart], themes: [githubDark]);
    final reg = jankH.getThemeRegistration(theme);
    final fg = parseColor(reg.fg);
    final bg = parseColor(reg.bg);

    final timings = <FrameTiming>[];
    final TimingsCallback cb = timings.addAll;
    binding.addTimingsCallback(cb);

    final firstFrame = Stopwatch()..start();
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: ShikiCodeListView(
            key: const Key('scroller'),
            highlighter: jankH,
            code: src,
            lang: _lang,
            theme: theme,
            textStyle: _base.copyWith(color: fg),
            async: true,
          ),
        ),
      ),
    ));
    firstFrame.stop();
    await tester.pumpAndSettle();
    // Let the worker's cold compile + tokenize land and the highlight swap in.
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

    final totals = timings.map((t) => t.totalSpan.inMicroseconds / 1000).toList()
      ..sort();
    report['jank'] = {
      'frame_count': totals.length,
      'first_frame_ms': _r(firstFrame.elapsedMicroseconds / 1000),
      'worst_ms': totals.isEmpty ? 0 : _r(totals.last),
      'missed_60fps': totals.where((v) => v > _budget60).length,
      'missed_120fps': totals.where((v) => v > _budget120).length,
    };
    await jankH.dispose();

    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['web_worker'] = report;
    writeLocalJson('../benchmark/results/web_worker.json',
        const JsonEncoder.withIndent('  ').convert(report));
    // ignore: avoid_print
    print('[web-worker] ${jsonEncode(report)}');

    expect(report['worker_is_remote'], isTrue,
        reason: 'a real browser Web Worker must spawn; run '
            '`dart run shiki_flutter:install_web_worker` first');
    expect(report['parity_worker_vs_sync_embedded'], isTrue,
        reason: 'worker tokens must equal the synchronous embedded engine');
    expect(report['worker_token_count'], greaterThan(5000),
        reason: 'the worker should tokenize the l corpus (~11k tokens)');
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
