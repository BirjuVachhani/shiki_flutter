@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:shiki_flutter/engine.dart';
import 'package:shiki_flutter_dart_engine/shiki_flutter_dart_engine.dart';
import 'package:test/test.dart';

// The core package's golden fixtures are proven byte-identical to real Shiki
// (which tokenizes with Oniguruma). Reusing them as the parity corpus: if the
// built-in pure-Dart engine matches them (golden_test asserts it does) and this
// oniguruma_dart-backed engine matches the built-in engine here, the port path
// is correct. Resolved relative to this package's dir, where `dart test` runs.
const _fixtures = '../shiki_flutter/test/fixtures';
const _langs = ['json', 'javascript', 'css', 'python', 'html'];
const _themes = ['github-dark', 'github-light', 'nord', 'min-light'];

// Unlike the FFI engine (UTF-16LE, which can't compile 2-digit `\xHH` escapes),
// oniguruma_dart drives the engine in UTF-8, so `\xHH` behaves like the C
// library and CSS/HTML are expected to reach full parity too. No skips.

/// Serializes every field the tokenizer produces, so the comparison is exact.
String _encode(List<List<ThemedToken>> lines) => lines
    .map(
      (line) => line
          .map(
            (t) =>
                '${t.offset}|${t.content}|${t.color}|${t.bgColor}|${t.fontStyle}',
          )
          .join(''),
    )
    .join('\n');

ShikiHighlighter _build(ShikiHighlighterEngine engine) {
  final hl = ShikiHighlighter(engine: engine);
  for (final lang in _langs) {
    final f = File('$_fixtures/langs/$lang.json');
    if (f.existsSync()) hl.ensureLanguage(_language(lang, f.readAsStringSync()));
  }
  for (final theme in _themes) {
    final f = File('$_fixtures/themes/$theme.json');
    if (f.existsSync()) hl.ensureShikiTheme(_theme(theme, f.readAsStringSync()));
  }
  return hl;
}

/// Wraps a raw TextMate grammar JSON fixture as a [CodeLanguage] so it loads
/// through the public API. A fixture is either a single grammar object or an
/// array (main grammar + embedded); the main grammar is the one whose `name`
/// matches [id].
CodeLanguage _language(String id, String json) {
  final decoded = jsonDecode(json);
  final grammars = (decoded is List ? decoded : [decoded])
      .cast<Map<String, dynamic>>();
  final main = grammars.firstWhere(
    (g) => (g['name'] as String?)?.toLowerCase() == id,
    orElse: () => grammars.first,
  );
  return CodeLanguage(
    id: id,
    scopeName: main['scopeName'] as String,
    displayName: id,
    json: json,
  );
}

/// Wraps a raw VS Code theme JSON fixture as a [ShikiTheme].
ShikiTheme _theme(String id, String json) {
  final type = (jsonDecode(json) as Map<String, dynamic>)['type'] as String?;
  return ShikiTheme(id: id, type: type ?? 'dark', json: json);
}

void main() {
  final goldenFile = File('$_fixtures/golden.json');
  if (!goldenFile.existsSync()) {
    test(
      'parity',
      () {},
      skip: 'golden fixtures not found (run from the package dir)',
    );
    return;
  }

  final dartHl = _build(const ShikiHighlighterEmbeddedEngine());
  final portHl = _build(const ShikiHighlighterDartEngine());
  final golden = (jsonDecode(goldenFile.readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();

  for (final c in golden) {
    final lang = c['lang'] as String;
    final theme = c['theme'] as String;
    final code = c['code'] as String;
    final opts = TokenizeOptions(lang: lang, theme: theme);

    test('oniguruma_dart == pure-Dart · $lang/$theme', () {
      expect(
        _encode(portHl.codeToTokens(code, opts)),
        _encode(dartHl.codeToTokens(code, opts)),
      );
    });
  }
}
