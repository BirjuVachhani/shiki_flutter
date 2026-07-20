import 'package:flutter/material.dart';
import 'package:shiki_flutter/shiki_flutter.dart';

// Import ONLY the bundled languages and themes you use. Everything you don't
// import here is tree-shaken out of the final app build.
import 'package:shiki_flutter/langs/dart.dart';
import 'package:shiki_flutter/themes/github_dark.dart';

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
  final highlighter = createHighlighter(langs: [dart], themes: [githubDark]);

  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: ShikiCodeView(
            highlighter: highlighter,
            code: _code.trim(),
            lang: dart.id, // 'dart'
            theme: githubDark.id, // 'github-dark'
            textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 16),
          ),
        ),
      ),
    ),
  );
}
