// Engine comparison: bundled (shiki_flutter's built-in pure-Dart engine) vs
// FFI (native Oniguruma C) vs oniguruma_dart (pure-Dart Oniguruma port).
//
// Same corpus, same grammar + theme, same TextMate tokenizer; only the engine
// (via `createHighlighter(engine: ...)`) differs. Measures full `codeToTokens`, the real
// end-user tokenization cost (dominated by the scanner's findNextMatch calls).
//
// VM only: the FFI engine needs `dart:ffi` + the native asset (built by the
// oniguruma_native build hook on first run). The two pure-Dart engines also run on
// web; this harness stays VM-side where all three coexist.
//
// Run (from packages/shiki_flutter_native_engine):
//   dart run benchmark/engine_compare.dart

import 'package:shiki_flutter/engine.dart';
import 'package:shiki_flutter_dart_engine/shiki_flutter_dart_engine.dart';
import 'package:shiki_flutter_native_engine/shiki_flutter_native_engine.dart';

// Reused from the core package's benchmark harness (both are standalone).
import '../../shiki_flutter/benchmark/src/corpus.dart';
import '../../shiki_flutter/benchmark/src/stats.dart';

const _sizes = [CorpusSize.m, CorpusSize.l, CorpusSize.xl];
const _opts = TokenizeOptions(lang: 'dart', theme: 'github-dark');

({int warmup, int iters}) _budget(CorpusSize size) => switch (size) {
  CorpusSize.xl => (warmup: 2, iters: 8),
  CorpusSize.l => (warmup: 2, iters: 10),
  _ => (warmup: 3, iters: 20),
};

class _EngineUnderTest {
  const _EngineUnderTest(this.label, this.engine);

  final String label;
  final ShikiHighlighterEngine engine;
}

void main() {
  final engines = <_EngineUnderTest>[
    const _EngineUnderTest('bundled (built-in Dart)', ShikiHighlighterEmbeddedEngine()),
    const _EngineUnderTest('oniguruma_dart (port)', ShikiHighlighterDartEngine()),
    const _EngineUnderTest('FFI Oniguruma (native C)', ShikiHighlighterNativeEngine()),
  ];

  // Corpus structure + token counts (identical across engines). Tokenize once
  // with the bundled engine to get the token count per size.
  final structure = <CorpusSize, ({int lines, int bytes, int tokens})>{};
  {
    final hl = ShikiHighlighter(engine: engines.first.engine);
    for (final size in _sizes) {
      final src = corpusFor(size);
      final w = WorkloadStats(src);
      final toks = hl.codeToTokens(src, _opts).fold<int>(0, (s, line) => s + line.length);
      structure[size] = (lines: w.lines, bytes: w.bytes, tokens: toks);
    }
  }

  // engineLabel -> sizeLabel -> Sample
  final samples = <String, Map<CorpusSize, Sample>>{};
  for (final e in engines) {
    final hl = ShikiHighlighter(engine: e.engine);
    samples[e.label] = {};
    for (final size in _sizes) {
      final src = corpusFor(size);
      final b = _budget(size);
      samples[e.label]![size] = measure(
        '${e.label}/${size.label}',
        warmup: b.warmup,
        iters: b.iters,
        body: () => hl.codeToTokens(src, _opts),
      );
    }
  }

  _report(engines, structure, samples);
}

void _report(
  List<_EngineUnderTest> engines,
  Map<CorpusSize, ({int lines, int bytes, int tokens})> structure,
  Map<String, Map<CorpusSize, Sample>> samples,
) {
  final buf = StringBuffer();
  buf.writeln('\n${'=' * 78}');
  buf.writeln('Engine comparison: codeToTokens (lang=dart, theme=github-dark)');
  buf.writeln('darwin · median of iters · VM');
  buf.writeln('=' * 78);

  buf.writeln('\nWorkload');
  final ts = ConsoleTable(['size', 'lines', 'bytes', 'tokens']);
  for (final size in _sizes) {
    final s = structure[size]!;
    ts.addRow([size.label, count(s.lines), count(s.bytes), count(s.tokens)]);
  }
  buf.write(ts.render());

  // Per-size: engine | median ms | p90 | tokens/s | vs bundled.
  const bundled = 'bundled (built-in Dart)';
  for (final size in _sizes) {
    buf.writeln(
      '\n${size.label} (${count(structure[size]!.lines)} lines, '
      '${count(structure[size]!.tokens)} tokens)',
    );
    final t = ConsoleTable(['engine', 'median ms', 'p90 ms', 'tokens/s', 'vs bundled']);
    final base = samples[bundled]![size]!.medianMs;
    for (final e in engines) {
      final s = samples[e.label]![size]!;
      final tokPerSec = (structure[size]!.tokens / (s.medianMs / 1000)).round();
      final rel = s.medianMs == 0 ? '-' : '${(base / s.medianMs).toStringAsFixed(2)}x';
      t.addRow([e.label, ms(s.medianMs), ms(s.p90Ms), count(tokPerSec), e.label == bundled ? '1.00x' : rel]);
    }
    buf.write(t.render());
  }

  buf.writeln('\n"vs bundled" > 1.00x means faster than the built-in engine.');
  buf.writeln('=' * 78);
  // ignore: avoid_print
  print(buf.toString());
}
