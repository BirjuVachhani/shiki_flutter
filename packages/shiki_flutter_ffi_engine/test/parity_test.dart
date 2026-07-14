@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:shiki_flutter/engine.dart';
import 'package:shiki_flutter_ffi_engine/shiki_flutter_ffi_engine.dart';
import 'package:test/test.dart';

// The core package's golden fixtures are proven byte-identical to real Shiki
// (which tokenizes with Oniguruma). Reusing them as the parity corpus: if the
// pure-Dart engine matches them (golden_test asserts it does) and the native
// FFI engine matches the pure-Dart engine here, the FFI path is correct.
// Resolved relative to this package's dir, where `dart test` runs.
const _fixtures = '../shiki_flutter/test/fixtures';
const _langs = ['json', 'javascript', 'css', 'python', 'html'];
const _themes = ['github-dark', 'github-light', 'nord', 'min-light'];

// KNOWN LIMITATION (see README): the `oniguruma` package drives Oniguruma in
// UTF-16LE so match offsets line up with Dart String indices. A side effect is
// that the 2-digit `\xHH` byte escape (pervasive in TextMate grammars for ASCII
// ranges, e.g. `[^\x00-\x7F]`) is read as a raw byte, not a codepoint, so those
// patterns fail to compile and are skipped. Shiki drives Oniguruma in UTF-8
// (where `\xHH` == the ASCII codepoint) and doesn't hit this. Among the fixtures
// it affects CSS class selectors and HTML's embedded CSS.
const _knownDivergent = {'css', 'html'};

/// Serializes every field the tokenizer produces, so the comparison is exact.
String _encode(List<List<ThemedToken>> lines) => lines
    .map((line) => line
        .map((t) =>
            '${t.offset}|${t.content}|${t.color}|${t.bgColor}|${t.fontStyle}')
        .join(''))
    .join('\n');

ShikiHighlighter _build(ShikiHighlighterEngine engine) {
  final hl = ShikiHighlighter(engine: engine);
  for (final lang in _langs) {
    final f = File('$_fixtures/langs/$lang.json');
    if (f.existsSync()) hl.loadLanguageFromJson(f.readAsStringSync());
  }
  for (final theme in _themes) {
    final f = File('$_fixtures/themes/$theme.json');
    if (f.existsSync()) hl.loadThemeFromJson(f.readAsStringSync());
  }
  return hl;
}

void main() {
  if (!isOnigurumaSupported) {
    test('parity', () {},
        skip: 'Oniguruma FFI unavailable on this platform');
    return;
  }
  final goldenFile = File('$_fixtures/golden.json');
  if (!goldenFile.existsSync()) {
    test('parity', () {},
        skip: 'golden fixtures not found (run from the package dir)');
    return;
  }

  final dartHl = _build(const ShikiHighlighterDartEngine());
  final ffiHl = _build(const ShikiHighlighterFFIEngine());
  final golden = (jsonDecode(goldenFile.readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();

  for (final c in golden) {
    final lang = c['lang'] as String;
    final theme = c['theme'] as String;
    final code = c['code'] as String;
    final opts = TokenizeOptions(lang: lang, theme: theme);

    test('FFI Oniguruma == pure-Dart · $lang/$theme', () {
      expect(_encode(ffiHl.codeToTokens(code, opts)),
          _encode(dartHl.codeToTokens(code, opts)));
    },
        skip: _knownDivergent.contains(lang)
            ? r"native Oniguruma (UTF-16LE) can't compile 2-digit \xHH escapes "
                '(CSS selectors use [^\\x00-\\x7F]); see README Known limitations'
            : null);
  }
}
