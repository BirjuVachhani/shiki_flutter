// Runnable demo: switch shiki_flutter to the native Oniguruma engine (when
// available) and tokenize a snippet. Run from this package's directory with:
//
//   dart --enable-experiment=native-assets run example/main.dart
//
// In a Flutter app you'd guard on kIsWeb instead of isOnigurumaSupported:
//
//   if (!kIsWeb) ShikiHighlighter.engine = ShikiHighlighterFFIEngine();
import 'package:shiki_flutter/engine.dart';
import 'package:shiki_flutter/langs/dart.dart';
import 'package:shiki_flutter/themes/github_dark.dart';
import 'package:shiki_flutter_ffi_engine/shiki_flutter_ffi_engine.dart';

void main() {
  if (isOnigurumaSupported) {
    // One line, once at startup: every highlighter now uses native Oniguruma.
    ShikiHighlighter.engine = const ShikiHighlighterFFIEngine();
    // ignore: avoid_print
    print('Using native Oniguruma (FFI).');
  } else {
    // ignore: avoid_print
    print('Native Oniguruma unavailable; using the pure-Dart engine.');
  }

  final hl = createHighlighter(langs: [dart], themes: [githubDark]);
  final lines = hl.codeToTokens(
    "void main() => print('hello');",
    const TokenizeOptions(lang: 'dart', theme: 'github-dark'),
  );
  // ignore: avoid_print
  print('Tokenized ${lines.length} line(s), '
      '${lines.expand((l) => l).length} tokens.');
}
