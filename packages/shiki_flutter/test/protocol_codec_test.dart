// Round-trip tests for the Web Worker protocol codec. Everything that crosses a
// `postMessage` boundary is encoded to JSON-able structures; here we encode ->
// jsonEncode -> jsonDecode -> decode and assert the value survives byte-for-byte,
// which is exactly the trip a browser Web Worker message makes.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter/src/async/lang_descriptor.dart';
import 'package:shiki_flutter/src/async/protocol.dart';
import 'package:shiki_flutter/src/async/protocol_codec.dart';

/// jsonEncode then jsonDecode, so the test exercises the real wire format (a
/// String), catching anything that is encodable in memory but not as JSON.
Map<String, dynamic> _roundTripMap(Map<String, dynamic> m) =>
    (jsonDecode(jsonEncode(m)) as Map).cast<String, dynamic>();

List<dynamic> _roundTripList(List<dynamic> l) =>
    jsonDecode(jsonEncode(l)) as List;

void main() {
  group('LangDescriptor codec', () {
    test('round-trips a nested (embedded) descriptor', () {
      const d = LangDescriptor(
        id: 'html',
        scopeName: 'text.html.basic',
        json: '{"name":"html"}',
        aliases: ['htm'],
        embedded: [
          LangDescriptor(
            id: 'css',
            scopeName: 'source.css',
            json: '{"name":"css"}',
            aliases: [],
            embedded: [
              LangDescriptor(
                  id: 'js', scopeName: 'source.js', json: '{"name":"js"}'),
            ],
          ),
        ],
      );

      final back = langDescriptorFromJson(_roundTripMap(langDescriptorToJson(d)));

      expect(back.id, d.id);
      expect(back.scopeName, d.scopeName);
      expect(back.json, d.json);
      expect(back.aliases, d.aliases);
      expect(back.embedded.single.id, 'css');
      expect(back.embedded.single.embedded.single.id, 'js');
      expect(back.embedded.single.embedded.single.scopeName, 'source.js');
    });
  });

  group('TokenizeOptions codec', () {
    test('round-trips all fields including colorReplacements', () {
      const o = TokenizeOptions(
        lang: 'dart',
        theme: 'github-dark',
        includeExplanation: true,
        tokenizeMaxLineLength: 4000,
        tokenizeTimeLimit: 250,
        colorReplacements: {'#ffffff': '#000000', '#ff0000': '#00ff00'},
      );

      final back = tokenizeOptionsFromJson(_roundTripMap(tokenizeOptionsToJson(o)));

      expect(back.lang, 'dart');
      expect(back.theme, 'github-dark');
      expect(back.includeExplanation, isTrue);
      expect(back.tokenizeMaxLineLength, 4000);
      expect(back.tokenizeTimeLimit, 250);
      expect(back.colorReplacements, o.colorReplacements);
    });

    test('applies defaults for a minimal (null-field) options', () {
      const o = TokenizeOptions();
      final back = tokenizeOptionsFromJson(_roundTripMap(tokenizeOptionsToJson(o)));
      expect(back.lang, isNull);
      expect(back.theme, isNull);
      expect(back.includeExplanation, isFalse);
      expect(back.tokenizeMaxLineLength, 0);
      expect(back.tokenizeTimeLimit, 500);
      expect(back.colorReplacements, isNull);
    });
  });

  group('ThemedToken codec', () {
    test('round-trips every field, including scopes', () {
      const tokens = <List<ThemedToken>>[
        [
          ThemedToken(
            content: 'void',
            offset: 0,
            color: '#ff0000',
            bgColor: '#111111',
            fontStyle: 3,
            scopes: ['source.dart', 'keyword'],
          ),
          ThemedToken(content: ' ', offset: 4),
        ],
        [
          ThemedToken(content: 'main', offset: 5, color: '#00ff00'),
        ],
      ];

      final back = tokensFromJson(_roundTripList(tokensToJson(tokens)));

      expect(back.length, 2);
      final first = back[0][0];
      expect(first.content, 'void');
      expect(first.offset, 0);
      expect(first.color, '#ff0000');
      expect(first.bgColor, '#111111');
      expect(first.fontStyle, 3);
      expect(first.scopes, ['source.dart', 'keyword']);
      // Defaults preserved for the sparse token.
      final space = back[0][1];
      expect(space.color, isNull);
      expect(space.bgColor, isNull);
      expect(space.fontStyle, 0);
      expect(space.scopes, isNull);
      expect(back[1][0].content, 'main');
      expect(back[1][0].color, '#00ff00');
    });
  });

  group('WorkerConfig codec', () {
    test('round-trips langs, raw langs, and themes', () {
      const config = WorkerConfig(
        langs: [
          LangDescriptor(
              id: 'dart', scopeName: 'source.dart', json: '{"name":"dart"}'),
        ],
        rawLangJsons: ['{"name":"custom"}'],
        themeJsons: ['{"name":"github-dark"}', '{"name":"nord"}'],
      );

      final back = workerConfigFromJson(_roundTripMap(workerConfigToJson(config)));

      expect(back.langs.single.id, 'dart');
      expect(back.langs.single.scopeName, 'source.dart');
      expect(back.rawLangJsons, ['{"name":"custom"}']);
      expect(back.themeJsons, ['{"name":"github-dark"}', '{"name":"nord"}']);
      // Engine is deliberately not reconstructed (the worker uses its default).
      expect(back.engine, isNull);
    });

    test('engineTag derives a stable tag from the engine type', () {
      expect(engineTag(const ShikiHighlighterEmbeddedEngine()), 'embedded');
      expect(engineTag(null), isNull);
    });
  });
}
