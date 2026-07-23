// ignore_for_file: avoid_print
import 'package:flutter/foundation.dart';
import 'package:shiki_flutter/engine.dart';
import 'package:shiki_flutter_native_engine/shiki_flutter_native_engine.dart';

void main() {
  if (!kIsWeb) {
    // One line, once at startup: every highlighter now uses native Oniguruma
    // through Dart FFI on IO.
    ShikiHighlighter.config = ShikiHighlighter.config.copyWith(
      ioEngine: const ShikiHighlighterNativeEngine(),
    );
    print('Using native Oniguruma (FFI).');
  } else {
    print('Native Oniguruma unavailable; using the pure-Dart engine.');
  }

  final hl = ShikiHighlighter();
  final lines = hl.codeToTokens(
    "void main() => print('hello');",
    const TokenizeOptions(lang: 'dart', theme: 'github-dark'),
  );
  print(
    'Tokenized ${lines.length} line(s), '
    '${lines.expand((l) => l).length} tokens.',
  );
}
