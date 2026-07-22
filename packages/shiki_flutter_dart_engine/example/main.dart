import 'package:shiki_flutter/engine.dart';

void main() {
  final hl = ShikiHighlighter();
  final lines = hl.codeToTokens(
    "void main() => print('hello');",
    const TokenizeOptions(lang: 'dart', theme: 'github-dark'),
  );
  print(
    'Tokenized ${lines.length} line(s), '
    '${lines.expand((l) => l).length} tokens with oniguruma_dart.',
  );
}
