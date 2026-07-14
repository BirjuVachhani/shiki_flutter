import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiki_flutter/shiki_flutter.dart';

ShikiHighlighter buildHighlighter() {
  final hl = ShikiHighlighter();
  hl.loadLanguageFromJson(
      File('test/fixtures/langs/javascript.json').readAsStringSync());
  hl.loadLanguageFromJson(
      File('test/fixtures/langs/json.json').readAsStringSync());
  hl.loadThemeFromJson(
      File('test/fixtures/themes/github-dark.json').readAsStringSync());
  hl.addLanguageAlias('js', 'javascript');
  return hl;
}

void main() {
  group('ShikiHighlighter public API', () {
    test('loaded languages and themes are reported', () {
      final hl = buildHighlighter();
      expect(hl.loadedThemes, contains('github-dark'));
      expect(hl.loadedLanguages, contains('source.js'));
    });

    test('codeToTokens returns one entry per line', () {
      final hl = buildHighlighter();
      final tokens = hl.codeToTokens(
        'const a = 1;\nconst b = 2;',
        const TokenizeOptions(lang: 'javascript', theme: 'github-dark'),
      );
      expect(tokens.length, 2);
      expect(tokens.every((line) => line.isNotEmpty), isTrue);
    });

    test('tokens reconstruct the original line', () {
      final hl = buildHighlighter();
      const code = 'function f(x) { return x + 1; }';
      final tokens = hl.codeToTokens(
        code,
        const TokenizeOptions(lang: 'javascript', theme: 'github-dark'),
      );
      final reconstructed = tokens.first.map((t) => t.content).join();
      expect(reconstructed, code);
    });

    test('tokens carry offsets into the original code', () {
      final hl = buildHighlighter();
      const code = 'let value = true;';
      final tokens = hl.codeToTokens(
        code,
        const TokenizeOptions(lang: 'javascript', theme: 'github-dark'),
      );
      for (final token in tokens.first) {
        expect(
            code.substring(token.offset, token.offset + token.content.length),
            token.content);
      }
    });

    test('keywords receive a theme color', () {
      final hl = buildHighlighter();
      final tokens = hl.codeToTokens(
        'const x = 1;',
        const TokenizeOptions(lang: 'javascript', theme: 'github-dark'),
      );
      final constToken = tokens.first.firstWhere((t) => t.content == 'const');
      expect(constToken.color, isNotNull);
      expect(constToken.color, isNot(''));
    });

    test('language alias resolves', () {
      final hl = buildHighlighter();
      final viaAlias = hl.codeToTokens('const x = 1;',
          const TokenizeOptions(lang: 'js', theme: 'github-dark'));
      final viaName = hl.codeToTokens('const x = 1;',
          const TokenizeOptions(lang: 'javascript', theme: 'github-dark'));
      expect(viaAlias.first.map((t) => t.content).toList(),
          viaName.first.map((t) => t.content).toList());
    });

    test('includeExplanation attaches scopes', () {
      final hl = buildHighlighter();
      final tokens = hl.codeToTokens(
        'const x = 1;',
        const TokenizeOptions(
            lang: 'javascript',
            theme: 'github-dark',
            includeExplanation: true),
      );
      final constToken = tokens.first.firstWhere((t) => t.content == 'const');
      expect(constToken.scopes, isNotNull);
      expect(constToken.scopes, contains('source.js'));
      expect(
        constToken.scopes!.any((s) => s.startsWith('storage.type')),
        isTrue,
      );
    });

    test('plain text language yields raw lines', () {
      final hl = buildHighlighter();
      final tokens = hl.codeToTokens(
        'just some text\nmore',
        const TokenizeOptions(lang: 'text', theme: 'github-dark'),
      );
      expect(tokens.length, 2);
      expect(tokens[0].single.content, 'just some text');
      expect(tokens[0].single.color, isNull);
    });

    test('unknown language throws ShikiError', () {
      final hl = buildHighlighter();
      expect(
        () => hl.codeToTokens(
            'x', const TokenizeOptions(lang: 'nope', theme: 'github-dark')),
        throwsA(isA<ShikiError>()),
      );
    });

    test('unknown theme throws ShikiError', () {
      final hl = buildHighlighter();
      expect(
        () => hl.codeToTokens('const x = 1;',
            const TokenizeOptions(lang: 'javascript', theme: 'nope')),
        throwsA(isA<ShikiError>()),
      );
    });

    test('empty lines produce empty token lists', () {
      final hl = buildHighlighter();
      final tokens = hl.codeToTokens(
        'const a = 1;\n\nconst b = 2;',
        const TokenizeOptions(lang: 'javascript', theme: 'github-dark'),
      );
      expect(tokens.length, 3);
      expect(tokens[1], isEmpty);
    });
  });
}
