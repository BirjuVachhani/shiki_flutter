// Isolates raw RegExp throughput (VM vs V8), independent of our tokenizer.
// ignore_for_file: avoid_print
import '../src/corpus.dart';

void main() {
  final text = generateDartSource(5000);
  final lines = text.split('\n');
  final pats = <RegExp>[
    RegExp(
      r'\b(?:if|else|for|while|return|class|final|const|var|void|import|export|async|await)\b',
    ),
    RegExp(r'[A-Za-z_$][A-Za-z0-9_$]*'),
    RegExp(r'"(?:[^"\\]|\\.)*"'),
    RegExp(r'\b[0-9]+(?:\.[0-9]+)?\b'),
    RegExp(r'\s+'),
    RegExp(r'//.*'),
    RegExp(r'@[A-Za-z]+'),
  ];
  var sink = 0;
  // warmup
  for (var w = 0; w < 3; w++) {
    for (final line in lines) {
      for (final re in pats) {
        for (final _ in re.allMatches(line)) {
          sink++;
          break;
        }
      }
    }
  }
  const iters = 20;
  // Per-line scan (mimics findNextMatch: many short-string searches).
  final sw = Stopwatch()..start();
  for (var it = 0; it < iters; it++) {
    for (final line in lines) {
      for (final re in pats) {
        for (final _ in re.allMatches(line)) {
          sink++;
          break;
        }
      }
    }
  }
  sw.stop();
  // Big single-scan (RegExp engine raw speed, minimal per-call overhead).
  final sw2 = Stopwatch()..start();
  for (var it = 0; it < iters; it++) {
    for (final re in pats) {
      sink += re.allMatches(text).length;
    }
  }
  sw2.stop();
  print(
    'per-line-scan: ${sw.elapsedMilliseconds} ms   big-scan: ${sw2.elapsedMilliseconds} ms   (sink=$sink)',
  );
}
