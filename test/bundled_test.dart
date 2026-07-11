import 'package:flutter_test/flutter_test.dart';
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter/langs/dart.dart';
import 'package:shiki_flutter/langs/html.dart';
import 'package:shiki_flutter/langs/javascript.dart';
import 'package:shiki_flutter/themes/github_dark.dart';

void main() {
  group('bundled createHighlighter', () {
    test('loads a bundled language and theme and highlights', () {
      final hl = createHighlighter(langs: [dart], themes: [githubDark]);
      final tokens = hl.codeToTokens(
        'void main() => print("hi");',
        TokenizeOptions(lang: dart.id, theme: githubDark.id),
      );
      expect(tokens, isNotEmpty);
      // Content round-trips and at least one token is themed.
      expect(tokens.first.map((t) => t.content).join(), 'void main() => print("hi");');
      expect(tokens.first.any((t) => t.color != null && t.color!.isNotEmpty), isTrue);
    });

    test('embedded languages are loaded automatically (html -> css + js)', () {
      final hl = createHighlighter(langs: [html], themes: [githubDark]);
      expect(hl.loadedLanguages, contains('text.html.basic'));
      expect(hl.loadedLanguages, contains('source.css'));
      expect(hl.loadedLanguages, contains('source.js'));

      final lines = hl.codeToTokens(
        '<style>.a{color:red}</style>',
        TokenizeOptions(
            lang: html.id, theme: githubDark.id, includeExplanation: true),
      );
      final tokens = lines.expand((l) => l);
      // The CSS inside <style> should be tokenized by the embedded CSS grammar.
      expect(
        tokens.any((t) => (t.scopes ?? const []).any((s) => s.contains('source.css'))),
        isTrue,
      );
    });

    test('aliases resolve (js -> javascript)', () {
      final hl = createHighlighter(langs: [javascript], themes: [githubDark]);
      final viaAlias = hl.codeToTokens(
        'const x = 1;',
        TokenizeOptions(lang: 'js', theme: githubDark.id),
      );
      expect(viaAlias.first.map((t) => t.content).join(), 'const x = 1;');
    });

    test('loadBundledLanguage is idempotent', () {
      final hl = ShikiHighlighter()
        ..loadBundledTheme(githubDark)
        ..loadBundledLanguage(dart)
        ..loadBundledLanguage(dart);
      expect(hl.loadedLanguages.where((s) => s == 'source.dart').length, 1);
    });

    test('bundled metadata is sane', () {
      expect(dart.id, 'dart');
      expect(dart.scopeName, 'source.dart');
      expect(githubDark.id, 'github-dark');
      expect(githubDark.type, anyOf('dark', 'light'));
      expect(html.embeddedLanguages().map((l) => l.id), containsAll(['css', 'javascript']));
    });
  });
}
