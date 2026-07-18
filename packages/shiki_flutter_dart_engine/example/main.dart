import 'package:shiki_flutter/engine.dart';
import 'package:shiki_flutter/langs/dart.dart';
import 'package:shiki_flutter/themes/github_dark.dart';

void main() {
  final hl = createHighlighter(langs: [dart], themes: [githubDark]);
  final lines = hl.codeToTokens(
    "void main() => print('hello');",
    const TokenizeOptions(lang: 'dart', theme: 'github-dark'),
  );
  print(
    'Tokenized ${lines.length} line(s), '
    '${lines.expand((l) => l).length} tokens with oniguruma_dart.',
  );
}
