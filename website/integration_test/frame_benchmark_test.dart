// Device-level frame benchmark for shiki_flutter.
//
// Measures REAL frame build + GPU raster times and missed-frame (jank) counts
// while displaying and scrolling a large highlighted Dart document, comparing
// the monolithic single-Text.rich strategy (ShikiCodeView) against a lazy,
// virtualized per-line ListView.
//
// Two ways to run (from website/):
//
//   • Quick smoke (host, build times only, may capture few/no frame timings):
//       flutter test integration_test/frame_benchmark_test.dart
//
//   • Full timeline on a real device/desktop (build + raster + jank):
//       flutter drive \
//         --driver=test_driver/perf_driver.dart \
//         --target=integration_test/frame_benchmark_test.dart \
//         -d macos --profile
//
// Metrics land in three places: printed to the console, in the binding's
// reportData (written by the driver to build/integration_response_data.json),
// and - on desktop - copied to ../benchmark/results/frames_*.json.

import 'dart:convert';
import 'dart:ui' show FrameTiming, TimingsCallback;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter/langs/dart.dart';
import 'package:shiki_flutter/themes/github_dark.dart';

import 'support/corpus.dart';
import 'support/local_writer.dart';

const double _budget60 = 1000 / 60; // 16.67 ms - one 60Hz frame
const double _budget120 = 1000 / 120; // 8.33 ms - one 120Hz frame

const _baseStyle = TextStyle(
  fontFamily: 'monospace',
  fontSize: 14,
  height: 1.4,
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // macOS `flutter drive` can launch the profile app without foregrounding its
  // window ("Failed to foreground app; open returned 1"). An occluded window
  // gets no vsync, so the very first `pumpWidget` blocks until something brings
  // the window forward, poisoning the first case's first_frame_ms. This idle
  // gap gives an external activation (or the user clicking the window) time to
  // foreground it before the first frame is pumped. Harmless on other targets.
  setUpAll(() async {
    await Future<void>.delayed(const Duration(seconds: 4));
  });

  final highlighter = createHighlighter(langs: [dart], themes: [githubDark]);
  const langId = 'dart';
  final themeName = githubDark.id;
  final fg = parseColor(highlighter.getThemeRegistration(themeName).fg);
  final bg = parseColor(highlighter.getThemeRegistration(themeName).bg);
  final base = _baseStyle.copyWith(color: fg);

  // Capped at `l` (2,000 lines) on purpose. At `xl` the monolithic strategy
  // is pathological on-device: laying out ~32k spans in a single Text.rich took
  // ~16 MINUTES in a debug macOS run - so the device layer would look hung.
  // The headless layer (benchmark/highlight_benchmark.dart) safely
  // characterizes `xl` via TextPainter. `l` already surfaces the jank tradeoff.
  for (final size in [CorpusSize.m, CorpusSize.l]) {
    final source = corpusFor(size);
    // Tokenize once up-front. The lazy strategy renders from these cached
    // tokens; the monolithic ShikiCodeView re-tokenizes internally on build
    // (its real cost), so its first frame includes highlighting too.
    final tokens = highlighter.codeToTokens(
      source,
      TokenizeOptions(lang: langId, theme: themeName),
    );

    testWidgets('frames · monolithic · ${size.label}', (tester) async {
      await _runCase(
        tester,
        binding,
        label: 'monolithic_${size.label}',
        widget: _scaffold(
          bg,
          SingleChildScrollView(
            key: const Key('scroller'),
            child: ShikiCodeView(
              highlighter: highlighter,
              code: source,
              lang: langId,
              theme: themeName,
              textStyle: base,
            ),
          ),
        ),
      );
    });

    testWidgets('frames · lazy · ${size.label}', (tester) async {
      await _runCase(
        tester,
        binding,
        label: 'lazy_${size.label}',
        widget: _scaffold(
          bg,
          ListView.builder(
            key: const Key('scroller'),
            itemCount: tokens.length,
            itemExtent: base.fontSize! * (base.height ?? 1.4),
            itemBuilder: (context, i) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text.rich(
                tokensToTextSpan([tokens[i]], baseStyle: base),
                softWrap: false,
                maxLines: 1,
              ),
            ),
          ),
        ),
      );
    });

    // Isolate-enabled path: the real virtualized production widget with async
    // highlighting on. Tokenization runs on the background worker, so the first
    // frame is a cheap plain-text placeholder and the highlighted result swaps
    // in a frame later - no synchronous tokenize freezing the UI thread. Uses a
    // fresh highlighter per size so the FIRST view pays the worker spawn + the
    // one-time grammar/regex compile (off-thread), which is the case the isolate
    // is meant to fix; scroll jank is then measured after the swap settles.
    testWidgets('frames · isolate · ${size.label}', (tester) async {
      final asyncHighlighter = createHighlighter(
        langs: [dart],
        themes: [githubDark],
      );
      addTearDown(asyncHighlighter.dispose);
      await _runCase(
        tester,
        binding,
        label: 'isolate_${size.label}',
        // Cover the first-view worker spawn + one-time grammar compile +
        // tokenize so the highlight swap settles before the scroll is measured;
        // scroll jank then reflects steady state, not the one-time swap.
        asyncGrace: const Duration(seconds: 3),
        widget: _scaffold(
          bg,
          ShikiCodeListView(
            key: const Key('scroller'),
            highlighter: asyncHighlighter,
            code: source,
            lang: langId,
            theme: themeName,
            textStyle: base,
            async: true,
          ),
        ),
      );
    });
  }
}

Widget _scaffold(Color? bg, Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: Scaffold(
    backgroundColor: bg ?? const Color(0xFF24292E),
    body: SafeArea(child: child),
  ),
);

/// Pumps [widget], scripts a scroll, and records the frames produced.
Future<void> _runCase(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding, {
  required String label,
  required Widget widget,
  Duration asyncGrace = Duration.zero,
}) async {
  // First-frame cost: building + laying out the initial tree. For monolithic
  // this is where the whole span tree is realized - the dominant jank source.
  // For the isolate case this is the cheap plain-text placeholder.
  final firstFrame = Stopwatch()..start();
  await tester.pumpWidget(widget);
  firstFrame.stop();
  await tester.pumpAndSettle();

  // The background worker replies after the placeholder frame, so
  // `pumpAndSettle` above can return before the highlight lands (no frame is
  // scheduled until the isolate responds). Wait out the worker's spawn +
  // one-time compile with real time, then settle the swap frame, so it is
  // counted as an initial-load cost and not mixed into the scroll jank below.
  if (asyncGrace > Duration.zero) {
    await Future<void>.delayed(asyncGrace);
    await tester.pumpAndSettle();
  }

  final collector = _FrameCollector()..start(binding);
  final scroller = find.byKey(const Key('scroller'));
  for (var i = 0; i < 6; i++) {
    await tester.fling(scroller, const Offset(0, -600), 3000);
    await tester.pumpAndSettle();
    await tester.fling(scroller, const Offset(0, 600), 3000);
    await tester.pumpAndSettle();
  }
  // Bounded flush for batched FrameTimings (engine may report ~1/s), then stop.
  await Future<void>.delayed(const Duration(seconds: 1));
  await tester.pump();
  collector.stop(binding);

  final metrics = collector.summarize(
    firstFrameMs: firstFrame.elapsedMicroseconds / 1000,
  );
  binding.reportData ??= <String, dynamic>{};
  binding.reportData![label] = metrics;
  _tryWriteLocal(label, metrics);

  // ignore: avoid_print
  print('[frame-bench] $label => ${jsonEncode(metrics)}');
}

/// Accumulates [FrameTiming]s reported by the engine between [start] and [stop].
class _FrameCollector {
  final List<FrameTiming> _timings = [];
  late final TimingsCallback _cb = _timings.addAll;

  void start(WidgetsBinding b) => b.addTimingsCallback(_cb);
  void stop(WidgetsBinding b) => b.removeTimingsCallback(_cb);

  Map<String, dynamic> summarize({required double firstFrameMs}) {
    final build = _msValues((t) => t.buildDuration.inMicroseconds);
    final raster = _msValues((t) => t.rasterDuration.inMicroseconds);
    final total = _msValues((t) => t.totalSpan.inMicroseconds);
    return {
      'frame_count': _timings.length,
      'first_frame_ms': _r(firstFrameMs),
      'build_ms': _statsOf(build),
      'raster_ms': _statsOf(raster),
      'total_ms': _statsOf(total),
      'missed_frames_60fps': total.where((v) => v > _budget60).length,
      'missed_frames_120fps': total.where((v) => v > _budget120).length,
      if (_timings.isEmpty)
        'note':
            'No FrameTimings captured - run via flutter drive on a device '
            '(-d macos --profile) for real build/raster numbers.',
    };
  }

  List<double> _msValues(int Function(FrameTiming) pick) =>
      (_timings.map((t) => pick(t) / 1000).toList())..sort();

  Map<String, dynamic> _statsOf(List<double> sorted) {
    if (sorted.isEmpty) {
      return {'avg': 0, 'p50': 0, 'p90': 0, 'p99': 0, 'worst': 0};
    }
    double pct(double p) =>
        sorted[(p / 100 * sorted.length).ceil().clamp(1, sorted.length) - 1];
    final avg = sorted.reduce((a, b) => a + b) / sorted.length;
    return {
      'avg': _r(avg),
      'p50': _r(pct(50)),
      'p90': _r(pct(90)),
      'p99': _r(pct(99)),
      'worst': _r(sorted.last),
    };
  }
}

double _r(double v) => double.parse(v.toStringAsFixed(3));

/// Best-effort local file copy (works on desktop; silently skipped on mobile
/// where the app sandbox has no access to the repo tree, and on web which has
/// no filesystem - see support/local_writer.dart). reportData carries the
/// numbers regardless.
void _tryWriteLocal(String label, Map<String, dynamic> metrics) {
  final json = const JsonEncoder.withIndent('  ').convert(metrics);
  for (final path in [
    'build/frames_$label.json',
    '../benchmark/results/frames_$label.json',
  ]) {
    writeLocalJson(path, json);
  }
}
