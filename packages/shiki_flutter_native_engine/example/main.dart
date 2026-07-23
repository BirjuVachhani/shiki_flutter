// ignore_for_file: avoid_print
import 'package:shiki_flutter/engine.dart';
import 'package:shiki_flutter_native_engine/shiki_flutter_native_engine.dart';

Future<void> main() async {
  // Load the WebAssembly module once at startup. It is a no-op on IO (where the
  // engine runs through Dart FFI), so this same code is portable across native
  // and web.
  await loadWasm();

  // One line, once at startup: every highlighter now uses the real Oniguruma
  // engine (Dart FFI on IO, WebAssembly on web) on both platforms.
  ShikiHighlighter.config = ShikiHighlighter.config.copyWith(
    ioEngine: const ShikiHighlighterNativeEngine(),
    webEngine: const ShikiHighlighterNativeEngine(),
  );
  print('Using the native Oniguruma engine.');

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
