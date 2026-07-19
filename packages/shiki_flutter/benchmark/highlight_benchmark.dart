// Headless performance benchmark for shiki_flutter.
//
// Measures the two costs that dominate "showing a lot of highlighted spans",
// separated so each can be reasoned about independently:
//
//   1. Highlighting  : ShikiHighlighter.codeToTokens (pure-Dart tokenization).
//   2. Rendering     : span-tree build (tokensToTextSpan), Text.rich layout
//                      (via TextPainter), CPU paint-record, and the full widget
//                      pump pipeline, comparing the monolithic single-Text.rich
//                      strategy against a lazy per-line ListView.
//
// It runs under `flutter test`, which gives us a real dart:ui text engine, so
// layout numbers are meaningful for *relative* comparison across sizes and
// strategies. They are not absolute device numbers: the test font is used and
// paint is CPU-side recording, not GPU raster. For real frame build/raster and
// jank, run the device layer in website/integration_test (see benchmark/README).
//
// Run:  flutter test benchmark/highlight_benchmark.dart
// Base: language = Dart, theme = GitHub Dark.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter/langs/dart.dart';
import 'package:shiki_flutter/themes/github_dark.dart';

import 'src/corpus.dart';
import 'src/stats.dart';

/// Base monospace style, matching ShikiCodeView's default intent.
const _baseStyle = TextStyle(fontFamily: 'monospace', fontSize: 14, height: 1.4);

/// The test viewport a lazy ListView virtualizes against (Flutter's default).
const _viewport = Size(800, 600);

/// Per-size warmup/iteration budget for the cheap CPU stages. Larger documents
/// run fewer times to keep total wall-clock reasonable.
({int warmup, int iters}) _budget(CorpusSize size) => switch (size) {
      CorpusSize.xl => (warmup: 2, iters: 5),
      CorpusSize.l => (warmup: 2, iters: 8),
      _ => (warmup: 3, iters: 15),
    };

void main() {
  testWidgets('shiki_flutter performance sweep (Dart / GitHub Dark)',
      (tester) async {
    final highlighter = createHighlighter(langs: [dart], themes: [githubDark]);
    const langId = 'dart';
    final themeName = githubDark.id; // 'github-dark'
    final fg = parseColor(highlighter.getThemeRegistration(themeName).fg);
    final bg = parseColor(highlighter.getThemeRegistration(themeName).bg);
    final base = _baseStyle.copyWith(color: fg);

    // ---- Cold start: fresh highlighter, first ever highlight -----------------
    // Captures the one-time grammar-load + Oniguruma regex-compile latency that
    // a user pays on the very first highlight of a session.
    final coldStartMicros = measureOnce(() {
      final fresh = createHighlighter(langs: [dart], themes: [githubDark]);
      fresh.codeToTokens(
        corpusFor(CorpusSize.s),
        TokenizeOptions(lang: langId, theme: themeName),
      );
    });

    final results = <String, dynamic>{
      'meta': {
        'lang': langId,
        'theme': themeName,
        'generated': DateTime.now().toIso8601String(),
        'cold_start_ms':
            double.parse((coldStartMicros / 1000).toStringAsFixed(3)),
        'note': 'Headless flutter-test timings: relative comparison only. '
            'Test font + CPU paint; see benchmark/README.md.',
      },
      'sizes': <String, dynamic>{},
    };

    final rssBefore = ProcessInfo.currentRss;

    for (final size in CorpusSize.values) {
      final source = corpusFor(size);
      final work = WorkloadStats(source);
      final budget = _budget(size);

      // ---- Highlighting (tokenization) --------------------------------------
      late List<List<ThemedToken>> tokens;
      final tokenize = measure(
        'tokenize',
        warmup: budget.warmup,
        iters: budget.iters,
        body: () => tokens = highlighter.codeToTokens(
          source,
          TokenizeOptions(lang: langId, theme: themeName),
        ),
      );

      // Structural facts derived from the tokenized output.
      final tokenCount = tokens.fold<int>(0, (sum, line) => sum + line.length);
      final maxTokensPerLine =
          tokens.fold<int>(0, (m, line) => line.length > m ? line.length : m);
      final spanCount = tokenCount + (tokens.length - 1); // + newline spans
      final avgTokensPerLine =
          tokens.isEmpty ? 0.0 : tokenCount / tokens.length;

      // ---- Span-tree build --------------------------------------------------
      late TextSpan span;
      final buildSpans = measure(
        'build_spans',
        warmup: budget.warmup,
        iters: budget.iters,
        body: () => span = tokensToTextSpan(tokens, baseStyle: base),
      );

      // ---- Layout: monolithic (one Text.rich for the whole document) --------
      // A fresh TextPainter each iteration defeats layout caching.
      final layoutMono = measure(
        'layout_monolithic',
        warmup: budget.warmup,
        iters: budget.iters,
        body: () {
          final tp = TextPainter(
            text: span,
            textDirection: TextDirection.ltr,
            maxLines: null,
          )..layout(maxWidth: double.infinity);
          tp.dispose();
        },
      );

      // ---- Layout: lazy per-line, one viewport window -----------------------
      // What a lazy ListView actually pays to lay out one screen of lines.
      const window = 50;
      final start = (tokens.length ~/ 2 - window ~/ 2).clamp(0, tokens.length);
      final end = (start + window).clamp(0, tokens.length);
      final windowSpans = [
        for (var i = start; i < end; i++)
          tokensToTextSpan([tokens[i]], baseStyle: base),
      ];
      final layoutWindow = measure(
        'layout_lazy_window_50',
        warmup: budget.warmup,
        iters: budget.iters,
        body: () {
          for (final s in windowSpans) {
            final tp = TextPainter(
              text: s,
              textDirection: TextDirection.ltr,
            )..layout(maxWidth: double.infinity);
            tp.dispose();
          }
        },
      );

      // ---- Layout: lazy per-line, total (every line as its own paragraph) ---
      final lazyIters = (budget.iters / 3).ceil().clamp(2, budget.iters);
      final layoutLazyTotal = measure(
        'layout_lazy_total',
        warmup: 1,
        iters: lazyIters,
        body: () {
          for (final line in tokens) {
            final s = tokensToTextSpan([line], baseStyle: base);
            final tp = TextPainter(
              text: s,
              textDirection: TextDirection.ltr,
            )..layout(maxWidth: double.infinity);
            tp.dispose();
          }
        },
      );

      // ---- Paint (CPU record) of the laid-out monolithic document -----------
      final paintTp = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
        maxLines: null,
      )..layout(maxWidth: double.infinity);
      final paintMono = measure(
        'paint_monolithic_cpu',
        warmup: budget.warmup,
        iters: budget.iters,
        body: () {
          final recorder = ui.PictureRecorder();
          final canvas = ui.Canvas(recorder);
          paintTp.paint(canvas, Offset.zero);
          recorder.endRecording().dispose();
        },
      );
      paintTp.dispose();

      // ---- Full widget pump pipeline: monolithic vs lazy --------------------
      // Monolithic re-tokenizes + builds + lays out the whole tree each pump
      // (the real ShikiCodeView cost). Lazy tokenizes once, then builds/layouts
      // only the visible per-line Text.rich widgets.
      final pumpBudget = switch (size) {
        CorpusSize.xl => (warmup: 1, iters: 3),
        CorpusSize.l => (warmup: 1, iters: 4),
        _ => (warmup: 2, iters: 6),
      };

      final pumpMono = await _measurePump(
        tester,
        'pump_monolithic',
        warmup: pumpBudget.warmup,
        iters: pumpBudget.iters,
        build: () => _wrap(
          bg,
          ShikiCodeView(
            highlighter: highlighter,
            code: source,
            lang: langId,
            theme: themeName,
            textStyle: _baseStyle,
          ),
        ),
      );

      final pumpLazy = await _measurePump(
        tester,
        'pump_lazy',
        warmup: pumpBudget.warmup,
        iters: pumpBudget.iters,
        build: () => _wrap(bg, _LazyCodeView(lines: tokens, baseStyle: base)),
      );

      // ---- End-to-end (tokenize + build + layout + paint) -------------------
      final endToEnd = measure(
        'end_to_end',
        warmup: 1,
        iters: (budget.iters / 2).ceil().clamp(2, budget.iters),
        body: () {
          final t = highlighter.codeToTokens(
            source,
            TokenizeOptions(lang: langId, theme: themeName),
          );
          final sp = tokensToTextSpan(t, baseStyle: base);
          final tp = TextPainter(
            text: sp,
            textDirection: TextDirection.ltr,
            maxLines: null,
          )..layout(maxWidth: double.infinity);
          final recorder = ui.PictureRecorder();
          tp.paint(ui.Canvas(recorder), Offset.zero);
          recorder.endRecording().dispose();
          tp.dispose();
        },
      );

      results['sizes'][size.label] = {
        'structure': {
          'lines': work.lines,
          'chars': work.chars,
          'bytes': work.bytes,
          'tokens': tokenCount,
          'spans': spanCount,
          'avg_tokens_per_line':
              double.parse(avgTokensPerLine.toStringAsFixed(2)),
          'max_tokens_per_line': maxTokensPerLine,
        },
        'timings': {
          for (final s in [
            tokenize,
            buildSpans,
            layoutMono,
            layoutWindow,
            layoutLazyTotal,
            paintMono,
            pumpMono,
            pumpLazy,
            endToEnd,
          ])
            s.label: s.toJson(),
        },
        'throughput': {
          'lines_per_sec': (work.lines / (tokenize.medianMs / 1000)).round(),
          'tokens_per_sec': (tokenCount / (tokenize.medianMs / 1000)).round(),
          'kb_per_sec': double.parse(
              (work.bytes / 1024 / (tokenize.medianMs / 1000))
                  .toStringAsFixed(1)),
        },
      };
    }

    // Coarse RSS delta across the whole sweep (allocations are not freed
    // deterministically, so treat this as an upper-bound signal, not a leak).
    final rssDeltaMb = (ProcessInfo.currentRss - rssBefore) / (1024 * 1024);
    results['meta']['rss_delta_mb'] =
        double.parse(rssDeltaMb.toStringAsFixed(1));

    final path = writeJsonResult('headless', results);
    _printReport(results, coldStartMicros, path);
  }, timeout: const Timeout(Duration(minutes: 15)));
}

/// Wraps content in a minimal, fully-constrained app for pumping.
Widget _wrap(Color? bg, Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ColoredBox(
        color: bg ?? const Color(0xFF24292E),
        child: SizedBox.fromSize(size: _viewport, child: child),
      ),
    );

/// A lazy, virtualized code view: tokenizes are done up-front; each visible
/// line becomes its own Text.rich, built on demand by the ListView.
class _LazyCodeView extends StatelessWidget {
  const _LazyCodeView({required this.lines, required this.baseStyle});

  final List<List<ThemedToken>> lines;
  final TextStyle baseStyle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 4000, // wide enough to avoid wrapping, like ShikiCodeView
        child: ListView.builder(
          itemCount: lines.length,
          itemExtent: baseStyle.fontSize! * (baseStyle.height ?? 1.4),
          itemBuilder: (context, i) => Text.rich(
            tokensToTextSpan([lines[i]], baseStyle: baseStyle),
            softWrap: false,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

/// Times `pumpWidget(build())` from a cleared tree, [iters] times.
Future<Sample> _measurePump(
  WidgetTester tester,
  String label, {
  required int warmup,
  required int iters,
  required Widget Function() build,
}) async {
  for (var i = 0; i < warmup; i++) {
    await tester.pumpWidget(build());
    await tester.pump();
  }
  final sample = Sample(label);
  for (var i = 0; i < iters; i++) {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final sw = Stopwatch()..start();
    await tester.pumpWidget(build());
    sw.stop();
    sample.add(sw.elapsedMicroseconds);
  }
  return sample;
}

void _printReport(Map<String, dynamic> r, int coldStartMicros, String path) {
  final sizes = r['sizes'] as Map<String, dynamic>;
  final buf = StringBuffer();

  buf.writeln('\n${'=' * 78}');
  buf.writeln('shiki_flutter headless benchmark  '
      '(lang=${r['meta']['lang']}, theme=${r['meta']['theme']})');
  buf.writeln('=' * 78);
  buf.writeln('Cold start (first ever highlight, incl. regex compile): '
      '${ms(coldStartMicros / 1000)} ms');
  buf.writeln('RSS delta over sweep: ${r['meta']['rss_delta_mb']} MB '
      '(coarse)');

  double med(String size, String metric) =>
      (sizes[size]['timings'][metric]['median_ms'] as num).toDouble();
  double p90(String size, String metric) =>
      (sizes[size]['timings'][metric]['p90_ms'] as num).toDouble();

  // Structure.
  buf.writeln('\nWorkload structure');
  final t0 = ConsoleTable(
      ['size', 'lines', 'chars', 'tokens', 'spans', 'avg tok/ln', 'max tok/ln']);
  for (final s in sizes.keys) {
    final st = sizes[s]['structure'];
    t0.addRow([
      s,
      count(st['lines']),
      count(st['chars']),
      count(st['tokens']),
      count(st['spans']),
      '${st['avg_tokens_per_line']}',
      '${st['max_tokens_per_line']}',
    ]);
  }
  buf.write(t0.render());

  // Highlighting.
  buf.writeln('\nHighlighting: codeToTokens (warm)');
  final t1 = ConsoleTable(
      ['size', 'median ms', 'p90 ms', 'lines/s', 'tokens/s', 'KB/s']);
  for (final s in sizes.keys) {
    final tp = sizes[s]['throughput'];
    t1.addRow([
      s,
      ms(med(s, 'tokenize')),
      ms(p90(s, 'tokenize')),
      count(tp['lines_per_sec']),
      count(tp['tokens_per_sec']),
      count(tp['kb_per_sec']),
    ]);
  }
  buf.write(t1.render());

  // Rendering stages.
  buf.writeln('\nRendering: build / layout / paint (median ms)');
  final t2 = ConsoleTable([
    'size',
    'build spans',
    'layout mono',
    'layout lazy(50)',
    'layout lazy(all)',
    'paint mono(cpu)',
  ]);
  for (final s in sizes.keys) {
    t2.addRow([
      s,
      ms(med(s, 'build_spans')),
      ms(med(s, 'layout_monolithic')),
      ms(med(s, 'layout_lazy_window_50')),
      ms(med(s, 'layout_lazy_total')),
      ms(med(s, 'paint_monolithic_cpu')),
    ]);
  }
  buf.write(t2.render());

  // Widget pump + end-to-end.
  buf.writeln('\nFull widget pipeline via pump + end-to-end (median ms)');
  final t3 = ConsoleTable([
    'size',
    'pump monolithic',
    'pump lazy',
    'speedup',
    'end-to-end',
  ]);
  for (final s in sizes.keys) {
    final mono = med(s, 'pump_monolithic');
    final lazy = med(s, 'pump_lazy');
    t3.addRow([
      s,
      ms(mono),
      ms(lazy),
      lazy == 0 ? '-' : '${(mono / lazy).toStringAsFixed(1)}x',
      ms(med(s, 'end_to_end')),
    ]);
  }
  buf.write(t3.render());

  buf.writeln('\nKey takeaway: "layout mono" and "pump monolithic" grow with '
      'document size, while the lazy window/pump stay ~flat: that gap is the '
      'cost of rendering all spans at once.');
  buf.writeln('\nJSON written to: $path');
  buf.writeln('=' * 78);

  // Use print so it shows in `flutter test` output.
  // ignore: avoid_print
  print(buf.toString());
}
