import 'package:shiki_flutter/engine.dart';
import 'package:shiki_flutter/langs.dart';
import 'package:shiki_flutter/themes.dart';

void main() {
  final hl = createHighlighter(
    langs: [CodeLanguages.dart],
    themes: [ShikiThemes.githubDark],
  );
  final lines = hl.codeToTokens(
    "void main() => print('hello');",
    const TokenizeOptions(lang: 'dart', theme: 'github-dark'),
  );
  print(
    'Tokenized ${lines.length} line(s), '
    '${lines.expand((l) => l).length} tokens with oniguruma_dart.',
  );
}
