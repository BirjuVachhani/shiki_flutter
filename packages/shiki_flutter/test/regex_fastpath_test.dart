// Differential test: the native-RegExp fast path must produce byte-identical
// tokens to the pure interpreter. This is the correctness gate for the fast
// path — if the emitted RegExp ever diverges from the interpreter on real code,
// this fails. Coverage: every golden sample (json/js/css/python/html across
// several themes) plus generated + hand-written Dart.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter/langs/dart.dart' as bundled_dart;
import 'package:shiki_flutter/themes/github_dark.dart' as bundled_theme;
import 'package:shiki_flutter/src/onig/regex_engine.dart' show OnigRegex;

import '../benchmark/src/corpus.dart';

ShikiHighlighter _buildHighlighter() {
  final hl = ShikiHighlighter();
  for (final lang in ['json', 'javascript', 'css', 'python', 'html']) {
    final file = File('test/fixtures/langs/$lang.json');
    if (file.existsSync()) hl.loadLanguageFromJson(file.readAsStringSync());
  }
  for (final theme in ['github-dark', 'github-light', 'nord', 'min-light']) {
    final file = File('test/fixtures/themes/$theme.json');
    if (file.existsSync()) hl.loadThemeFromJson(file.readAsStringSync());
  }
  hl.loadBundledLanguage(bundled_dart.dart);
  hl.loadBundledTheme(bundled_theme.githubDark);
  return hl;
}

/// A fully-comparable, order-sensitive serialization of one tokenization.
String _serialize(List<List<ThemedToken>> lines) {
  final buf = StringBuffer();
  for (final line in lines) {
    for (final t in line) {
      buf.write('${jsonEncode(t.content)}|${t.offset}|${t.color}|'
          '${t.bgColor}|${t.fontStyle}\n');
    }
    buf.write('--\n');
  }
  return buf.toString();
}

void main() {
  final hl = _buildHighlighter();

  // Always leave the fast path enabled for the rest of the suite.
  tearDown(() => OnigRegex.fastPathEnabled = true);

  String tokenize(String code, String lang, String theme) => _serialize(
        hl.codeToTokens(code, TokenizeOptions(lang: lang, theme: theme)),
      );

  void expectIdentical(String code, String lang, String theme, String label) {
    OnigRegex.fastPathEnabled = false;
    final interpreter = tokenize(code, lang, theme);
    OnigRegex.fastPathEnabled = true;
    final fastPath = tokenize(code, lang, theme);
    expect(fastPath, interpreter,
        reason: 'fast path diverged from interpreter for $label');
  }

  // --- Every golden sample (json/js/css/python/html) -------------------------
  final golden = (jsonDecode(File('test/fixtures/golden.json').readAsStringSync())
          as List)
      .cast<Map<String, dynamic>>();
  for (var i = 0; i < golden.length; i++) {
    final c = golden[i];
    final lang = c['lang'] as String;
    final theme = c['theme'] as String;
    test('fast path == interpreter · golden[$i] $lang/$theme', () {
      expectIdentical(c['code'] as String, lang, theme, 'golden[$i] $lang');
    });
  }

  // --- Generated Dart at several sizes ---------------------------------------
  for (final size in [CorpusSize.xs, CorpusSize.s, CorpusSize.m]) {
    test('fast path == interpreter · dart corpus ${size.label}', () {
      expectIdentical(
          corpusFor(size), 'dart', 'github-dark', 'dart ${size.label}');
    });
  }

  // --- Hand-written Dart exercising tricky constructs ------------------------
  const tricky = r'''
/// Doc comment with [link] and `code`.
@immutable
class Foo<T extends Bar> implements Baz {
  static const int _mask = 0xDEAD_BEEF;
  final double ratio = 3.14e-2;
  var s = "a ${x + 1} b\n\t";
  var r = r'raw\nstring';
  Future<void> run() async => await for (final e in stream) print('$e!');
}
''';
  test('fast path == interpreter · tricky dart', () {
    expectIdentical(tricky, 'dart', 'github-dark', 'tricky dart');
  });
}
