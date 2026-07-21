import 'package:flutter/material.dart';
import 'package:shiki_flutter/shiki_flutter.dart';

const _code = '''
void main() {
  final greeting = 'Hello, Shiki!';
  for (var i = 0; i < 3; i++) {
    print('\$greeting (\$i)'); // batteries included
  }
}
''';

void main() {
  // Batteries-included: pass bundled languages/themes by symbol.
  final highlighter = createHighlighter(
    langs: [CodeLanguages.dart],
    themes: [ShikiThemes.githubDark],
  );

  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: ShikiCodeView(
            highlighter: highlighter,
            code: _code.trim(),
            lang: CodeLanguages.dart,
            theme: ShikiThemeConfig.single(ShikiThemes.githubDark),
            textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 16),
          ),
        ),
      ),
    ),
  );
}
