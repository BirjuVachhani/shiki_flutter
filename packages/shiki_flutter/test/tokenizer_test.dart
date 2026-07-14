import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiki_flutter/src/onig/onig.dart';
import 'package:shiki_flutter/src/textmate/encoded_token_metadata.dart';
import 'package:shiki_flutter/src/textmate/grammar.dart';
import 'package:shiki_flutter/src/textmate/raw_grammar.dart';
import 'package:shiki_flutter/src/textmate/registry.dart';
import 'package:shiki_flutter/src/textmate/theme.dart';

const _toyGrammarJson = r'''
{
  "scopeName": "source.toy",
  "patterns": [
    { "include": "#comment" },
    { "include": "#keyword" },
    { "include": "#string" },
    { "include": "#number" }
  ],
  "repository": {
    "comment": {
      "match": "//.*$",
      "name": "comment.line.double-slash.toy"
    },
    "keyword": {
      "match": "\\b(if|else|while|return|let)\\b",
      "name": "keyword.control.toy"
    },
    "string": {
      "name": "string.quoted.double.toy",
      "begin": "\"",
      "end": "\"",
      "beginCaptures": {
        "0": { "name": "punctuation.definition.string.begin.toy" }
      },
      "endCaptures": {
        "0": { "name": "punctuation.definition.string.end.toy" }
      },
      "patterns": [
        { "match": "\\\\.", "name": "constant.character.escape.toy" }
      ]
    },
    "number": {
      "match": "\\b[0-9]+(\\.[0-9]+)?\\b",
      "name": "constant.numeric.toy"
    }
  }
}
''';

Grammar buildToyGrammar() {
  final theme = Theme.createFromRawTheme(RawTheme(settings: [
    RawThemeSetting(
        settings:
            ThemeSettingStyle(foreground: '#ffffff', background: '#1e1e1e')),
    RawThemeSetting(
        scope: 'keyword.control',
        settings: ThemeSettingStyle(foreground: '#ff0000', fontStyle: 'bold')),
    RawThemeSetting(
        scope: 'string',
        settings: ThemeSettingStyle(foreground: '#00ff00')),
    RawThemeSetting(
        scope: 'constant.numeric',
        settings: ThemeSettingStyle(foreground: '#0000ff')),
    RawThemeSetting(
        scope: 'comment',
        settings:
            ThemeSettingStyle(foreground: '#888888', fontStyle: 'italic')),
  ]));

  final registry = SyncRegistry(theme, const ShikiHighlighterDartEngine());
  registry.addGrammar(
      RawGrammar.fromJson(jsonDecode(_toyGrammarJson) as Map<String, dynamic>));
  return registry.grammarForScopeName('source.toy', 0, null, null, null)!;
}

/// Returns [scope-list] for the token covering [needle] in [tokens].
List<String> scopesForContent(
    List<Token> tokens, String line, String needle) {
  final index = line.indexOf(needle);
  for (final t in tokens) {
    if (t.startIndex <= index && index < t.endIndex) {
      return t.scopes;
    }
  }
  return const [];
}

void main() {
  group('basic tokenization', () {
    late Grammar grammar;
    setUp(() => grammar = buildToyGrammar());

    test('keyword scope', () {
      const line = 'let x = 42';
      final result = grammar.tokenizeLine(line, null);
      final scopes = scopesForContent(result.tokens, line, 'let');
      expect(scopes, contains('source.toy'));
      expect(scopes, contains('keyword.control.toy'));
    });

    test('number scope', () {
      const line = 'let x = 42';
      final result = grammar.tokenizeLine(line, null);
      final scopes = scopesForContent(result.tokens, line, '42');
      expect(scopes, contains('constant.numeric.toy'));
    });

    test('comment scope', () {
      const line = 'x // hello world';
      final result = grammar.tokenizeLine(line, null);
      final scopes = scopesForContent(result.tokens, line, 'hello');
      expect(scopes, contains('comment.line.double-slash.toy'));
    });

    test('plain identifier only has root scope', () {
      const line = 'foobar';
      final result = grammar.tokenizeLine(line, null);
      expect(result.tokens.first.scopes, ['source.toy']);
    });
  });

  group('begin/end string with captures', () {
    late Grammar grammar;
    setUp(() => grammar = buildToyGrammar());

    test('string content and escapes', () {
      const line = r'x = "a\nb"';
      final result = grammar.tokenizeLine(line, null);

      final contentScopes = scopesForContent(result.tokens, line, 'a');
      expect(contentScopes, contains('string.quoted.double.toy'));

      final escapeScopes = scopesForContent(result.tokens, line, r'\n');
      expect(escapeScopes, contains('constant.character.escape.toy'));

      // Opening quote should have the begin-capture scope.
      final openQuoteToken = result.tokens
          .firstWhere((t) => t.startIndex == line.indexOf('"'));
      expect(openQuoteToken.scopes,
          contains('punctuation.definition.string.begin.toy'));
    });

    test('multi-line string keeps state across lines', () {
      final line1 = grammar.tokenizeLine('x = "start', null);
      // The string is still open at end of line 1.
      final line2 = grammar.tokenizeLine('still string"', line1.ruleStack);
      final scopes = scopesForContent(line2.tokens, 'still string"', 'still');
      expect(scopes, contains('string.quoted.double.toy'));
    });
  });

  group('binary tokens + theme metadata', () {
    late Grammar grammar;
    setUp(() => grammar = buildToyGrammar());

    test('keyword gets bold font style', () {
      const line = 'return 1';
      final result = grammar.tokenizeLine2(line, null);
      // tokens are [start, metadata, start, metadata, ...]
      final metadata = result.tokens[1];
      final fontStyle = EncodedTokenMetadata.getFontStyle(metadata);
      expect(fontStyle & FontStyle.bold, FontStyle.bold);
    });

    test('token count is reasonable', () {
      const line = 'let x = 42';
      final result = grammar.tokenizeLine2(line, null);
      expect(result.tokens.length, greaterThan(2));
      expect(result.tokens.length.isEven, isTrue);
    });
  });
}
