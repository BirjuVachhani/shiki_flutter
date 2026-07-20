// Headless benchmark for async isolate offloading.
//
// Answers the design question: for repeated highlighting, is a fresh isolate
// per call (`Isolate.run` / `compute`) or one long-lived warm worker faster, and
// does offloading actually keep the UI thread responsive?
//
// Three strategies tokenize the same corpus (Dart / GitHub Dark):
//   sync            : ShikiHighlighter.codeToTokens on the main isolate.
//   isolate-run     : a fresh isolate + fresh highlighter per call.
//   warm-worker     : one spawned worker holding a warm highlighter.
//
// It also measures a 16ms heartbeat's worst stall while an xl document is
// tokenized, to show the main thread freezes under sync but stays live when the
// work is offloaded.
//
// Run:  flutter test benchmark/isolate_benchmark.dart
// Numbers are for relative comparison on one machine, not absolute device times.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiki_flutter/langs/dart.dart';
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter/src/async/lang_descriptor.dart';
import 'package:shiki_flutter/src/async/protocol.dart';
import 'package:shiki_flutter/src/async/tokenize_worker.dart';
import 'package:shiki_flutter/themes/github_dark.dart';

import 'src/corpus.dart';
import 'src/stats.dart';

const _opts = TokenizeOptions(lang: 'dart', theme: 'github-dark');

Future<int> _timeMicros(Future<void> Function() body) async {
  final sw = Stopwatch()..start();
  await body();
  sw.stop();
  return sw.elapsedMicroseconds;
}

double _medianMs(List<int> micros) {
  final sorted = [...micros]..sort();
  return sorted[(sorted.length - 1) ~/ 2] / 1000;
}

/// Runs [action] while a 16ms heartbeat ticks; returns the worst gap (ms)
/// between ticks. A blocked main isolate starves the timer, so a large gap means
/// the UI thread was frozen for roughly that long.
Future<double> _maxHeartbeatGapMs(Future<void> Function() action) async {
  final since = Stopwatch()..start();
  var maxGap = 0.0;
  final timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
    final gap = since.elapsedMicroseconds / 1000;
    if (gap > maxGap) maxGap = gap;
    since.reset();
  });
  // Yield so the timer is armed before the (possibly blocking) work begins.
  await Future<void>.delayed(const Duration(milliseconds: 32));
  since.reset();
  await action();
  // Let the overdue tick fire and record the stall before cancelling. A
  // synchronous block starves the timer, so the big gap only lands now.
  await Future<void>.delayed(const Duration(milliseconds: 24));
  timer.cancel();
  return maxGap;
}

void main() {
  test(
    'isolate offloading: sync vs isolate-run vs warm-worker',
    () async {
      const sizes = [CorpusSize.m, CorpusSize.l, CorpusSize.xl];
      final perSize = <Map<String, dynamic>>[];

      final table = ConsoleTable([
        'size',
        'lines',
        'sync cold',
        'sync warm',
        'isolate-run',
        'worker 1st',
        'worker warm',
      ]);

      for (final size in sizes) {
        final code = corpusFor(size);
        final iters = size == CorpusSize.xl ? 2 : 3;

        // --- sync: cold (fresh highlighter) then warm (same highlighter) --------
        final syncHl = createHighlighter(langs: [dart], themes: [githubDark]);
        final syncCold =
            measureOnce(() => syncHl.codeToTokens(code, _opts)) / 1000;
        final syncWarmSamples = [
          for (var i = 0; i < iters; i++)
            measureOnce(() => syncHl.codeToTokens('$code\n// s$i', _opts)),
        ];
        final syncWarm = _medianMs(syncWarmSamples);

        // --- isolate-run: a fresh isolate + highlighter every call --------------
        final runSamples = <int>[];
        for (var i = 0; i < iters; i++) {
          final variant = '$code\n// r$i';
          runSamples.add(
            await _timeMicros(() async {
              await Isolate.run(() {
                final h = createHighlighter(
                  langs: [dart],
                  themes: [githubDark],
                );
                return h.codeToTokens(variant, _opts);
              });
            }),
          );
        }
        final isolateRun = _medianMs(runSamples);

        // --- warm-worker: spawn once (warmed), then reuse -----------------------
        final worker = await spawnTokenizeWorker(
          WorkerConfig(
            langs: [flattenBundledLanguage(dart)],
            themeJsons: [githubDark.json],
            warmups: const [WarmupSpec('dart', 'github-dark')],
          ),
        );
        await worker.ready;
        final workerFirst =
            await _timeMicros(() => worker.tokenize(code, _opts)) / 1000;
        final workerWarmSamples = <int>[];
        for (var i = 0; i < iters; i++) {
          workerWarmSamples.add(
            await _timeMicros(() => worker.tokenize('$code\n// w$i', _opts)),
          );
        }
        final workerWarm = _medianMs(workerWarmSamples);
        await worker.dispose();

        perSize.add({
          'size': size.label,
          'lines': size.lines,
          'sync_cold_ms': syncCold,
          'sync_warm_ms': syncWarm,
          'isolate_run_ms': isolateRun,
          'worker_first_ms': workerFirst,
          'worker_warm_ms': workerWarm,
        });
        table.addRow([
          size.label,
          '${size.lines}',
          ms(syncCold),
          ms(syncWarm),
          ms(isolateRun),
          ms(workerFirst),
          ms(workerWarm),
        ]);
      }

      // --- Many small snippets: the docs-site pattern where per-call compile
      // dominates. isolate-run re-pays the grammar compile for every snippet; the
      // warm worker pays it once and reuses it. -------------------------------
      const snippetCount = 30;
      final snippets = [
        for (var i = 0; i < snippetCount; i++)
          '${corpusFor(CorpusSize.xs)}\n// n$i',
      ];

      final batchRunMs =
          await _timeMicros(() async {
            for (final s in snippets) {
              await Isolate.run(() {
                final h = createHighlighter(
                  langs: [dart],
                  themes: [githubDark],
                );
                return h.codeToTokens(s, _opts);
              });
            }
          }) /
          1000;

      final batchWorker = await spawnTokenizeWorker(
        WorkerConfig(
          langs: [flattenBundledLanguage(dart)],
          themeJsons: [githubDark.json],
          warmups: const [WarmupSpec('dart', 'github-dark')],
        ),
      );
      await batchWorker.ready;
      final batchWorkerMs =
          await _timeMicros(() async {
            for (final s in snippets) {
              await batchWorker.tokenize(s, _opts);
            }
          }) /
          1000;
      await batchWorker.dispose();

      // --- Main-thread responsiveness (xl): sync freezes, worker stays live -----
      final xl = corpusFor(CorpusSize.xl);
      final warmHl = createHighlighter(langs: [dart], themes: [githubDark]);
      warmHl.codeToTokens(xl, _opts); // warm so this measures work, not compile
      final syncGap = await _maxHeartbeatGapMs(
        () async => warmHl.codeToTokens('$xl\n//j', _opts),
      );

      final jankWorker = await spawnTokenizeWorker(
        WorkerConfig(
          langs: [flattenBundledLanguage(dart)],
          themeJsons: [githubDark.json],
          warmups: const [WarmupSpec('dart', 'github-dark')],
        ),
      );
      await jankWorker.ready;
      await jankWorker.tokenize(xl, _opts); // warm the worker's grammar
      final workerGap = await _maxHeartbeatGapMs(
        () => jankWorker.tokenize('$xl\n//j', _opts),
      );
      await jankWorker.dispose();

      // ignore: avoid_print
      print(
        '\n==== tokenize latency (Dart / GitHub Dark), ms ====\n'
        '${table.render()}',
      );
      // ignore: avoid_print
      print(
        '==== $snippetCount small snippets, total ms ====\n'
        'isolate-run (fresh each) : ${ms(batchRunMs)} ms\n'
        'warm worker (reused)     : ${ms(batchWorkerMs)} ms  '
        '(${(batchRunMs / batchWorkerMs).toStringAsFixed(1)}x faster)\n',
      );
      // ignore: avoid_print
      print(
        '==== main-thread 16ms heartbeat, worst stall (xl) ====\n'
        'sync on main isolate : ${ms(syncGap)} ms  (UI frozen)\n'
        'warm worker isolate  : ${ms(workerGap)} ms  (UI responsive)\n',
      );

      writeJsonResult('isolate', {
        'workload': 'dart/github-dark',
        'per_size': perSize,
        'small_snippets': {
          'count': snippetCount,
          'isolate_run_total_ms': _round(batchRunMs),
          'worker_total_ms': _round(batchWorkerMs),
        },
        'heartbeat_xl': {
          'sync_worst_stall_ms': _round(syncGap),
          'worker_worst_stall_ms': _round(workerGap),
        },
      });

      // Sanity: offloading keeps the main isolate far more responsive than sync.
      expect(workerGap, lessThan(syncGap));
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}

double _round(double v) => double.parse(v.toStringAsFixed(4));
