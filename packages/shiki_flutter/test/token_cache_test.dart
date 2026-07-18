import 'package:flutter_test/flutter_test.dart';
import 'package:shiki_flutter/langs/dart.dart';
import 'package:shiki_flutter/langs/html.dart';
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter/src/async/lang_descriptor.dart';

List<List<ThemedToken>> _tokens(String content) => [
      [ThemedToken(content: content, offset: 0)],
    ];

void main() {
  group('TokenCache.keyFor', () {
    test('same inputs produce the same key', () {
      const a = TokenizeOptions(lang: 'dart', theme: 'github-dark');
      const b = TokenizeOptions(lang: 'dart', theme: 'github-dark');
      expect(TokenCache.keyFor('code', a), TokenCache.keyFor('code', b));
    });

    test('lang, theme, and code all affect the key', () {
      const base = TokenizeOptions(lang: 'dart', theme: 'github-dark');
      final k = TokenCache.keyFor('x', base);
      expect(k, isNot(TokenCache.keyFor('y', base)));
      expect(k,
          isNot(TokenCache.keyFor('x', const TokenizeOptions(lang: 'js', theme: 'github-dark'))));
      expect(k,
          isNot(TokenCache.keyFor('x', const TokenizeOptions(lang: 'dart', theme: 'nord'))));
    });

    test('colorReplacements key order does not matter', () {
      final a = TokenizeOptions(
        lang: 'dart',
        theme: 'github-dark',
        colorReplacements: {'#000': '#111', '#fff': '#eee'},
      );
      final b = TokenizeOptions(
        lang: 'dart',
        theme: 'github-dark',
        colorReplacements: {'#fff': '#eee', '#000': '#111'},
      );
      expect(TokenCache.keyFor('code', a), TokenCache.keyFor('code', b));
    });
  });

  group('TokenCache LRU', () {
    test('get returns what was put; miss returns null', () {
      final cache = TokenCache();
      final t = _tokens('a');
      cache.put('k', t, 1);
      expect(cache.get('k'), same(t));
      expect(cache.get('missing'), isNull);
    });

    test('evicts oldest once maxEntries is exceeded', () {
      final cache = TokenCache(maxEntries: 2);
      cache.put('a', _tokens('a'), 1);
      cache.put('b', _tokens('b'), 1);
      cache.put('c', _tokens('c'), 1); // evicts 'a'
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), isNotNull);
      expect(cache.get('c'), isNotNull);
      expect(cache.length, 2);
    });

    test('get marks an entry most-recently-used so it survives eviction', () {
      final cache = TokenCache(maxEntries: 2);
      cache.put('a', _tokens('a'), 1);
      cache.put('b', _tokens('b'), 1);
      cache.get('a'); // 'a' is now newest
      cache.put('c', _tokens('c'), 1); // evicts 'b', not 'a'
      expect(cache.get('a'), isNotNull);
      expect(cache.get('b'), isNull);
      expect(cache.get('c'), isNotNull);
    });

    test('evicts to satisfy the maxChars budget', () {
      final cache = TokenCache(maxEntries: 100, maxChars: 10);
      cache.put('a', _tokens('a'), 6);
      cache.put('b', _tokens('b'), 6); // total 12 > 10 -> evict 'a'
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), isNotNull);
    });

    test('clear empties the cache', () {
      final cache = TokenCache();
      cache.put('a', _tokens('a'), 1);
      cache.clear();
      expect(cache.length, 0);
      expect(cache.get('a'), isNull);
    });
  });

  group('LangDescriptor', () {
    test('flatten captures a leaf language with no embeds', () {
      final d = flattenBundledLanguage(dart);
      expect(d.id, dart.id);
      expect(d.scopeName, dart.scopeName);
      expect(d.json, dart.json);
      expect(d.embedded, isEmpty);
    });

    test('flatten captures embedded grammars (html -> css/js)', () {
      final d = flattenBundledLanguage(html);
      final embeddedScopes = d.embedded.map((e) => e.scopeName).toSet();
      expect(embeddedScopes, contains('source.css'));
      expect(embeddedScopes, contains('source.js'));
    });

    test('rebuild reconstructs an equivalent BundledLanguage', () {
      final rebuilt = rebuildBundledLanguage(flattenBundledLanguage(html));
      expect(rebuilt.id, html.id);
      expect(rebuilt.scopeName, html.scopeName);
      expect(rebuilt.json, html.json);
      // The thunk resolves to the flattened children (a plain closure, so it is
      // safe to send across an isolate boundary as a descriptor).
      final scopes = rebuilt.embeddedLanguages().map((e) => e.scopeName).toSet();
      expect(scopes, contains('source.css'));
      expect(scopes, contains('source.js'));
    });
  });
}
