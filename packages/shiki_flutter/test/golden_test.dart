import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiki_flutter/shiki_flutter.dart';

/// Loads all fixture languages/themes into a highlighter.
ShikiHighlighter buildHighlighter() {
  final hl = ShikiHighlighter();
  for (final lang in ['json', 'javascript', 'css', 'python', 'html']) {
    final file = File('test/fixtures/langs/$lang.json');
    if (file.existsSync()) {
      hl.loadLanguageFromJson(file.readAsStringSync());
    }
  }
  for (final theme in ['github-dark', 'github-light', 'nord', 'min-light']) {
    final file = File('test/fixtures/themes/$theme.json');
    if (file.existsSync()) {
      hl.loadThemeFromJson(file.readAsStringSync());
    }
  }
  return hl;
}

void main() {
  test('matches real Shiki golden output', () {
    final hl = buildHighlighter();
    final golden = jsonDecode(
            File('test/fixtures/golden.json').readAsStringSync()) as List;

    var totalTokens = 0;
    var colorMatches = 0;
    var fontStyleMatches = 0;
    final failures = <String>[];

    for (final caseData in golden.cast<Map<String, dynamic>>()) {
      final lang = caseData['lang'] as String;
      final theme = caseData['theme'] as String;
      final code = caseData['code'] as String;
      final expectedLines = (caseData['tokens'] as List).cast<List>();

      final actualLines =
          hl.codeToTokens(code, TokenizeOptions(lang: lang, theme: theme));

      expect(actualLines.length, expectedLines.length,
          reason: 'line count mismatch for $lang/$theme');

      for (var i = 0; i < expectedLines.length; i++) {
        final expected = expectedLines[i].cast<Map<String, dynamic>>();
        final actual = actualLines[i];

        // Compare the concatenated content first (must be identical).
        final expectedContent = expected.map((t) => t['content']).join();
        final actualContent = actual.map((t) => t.content).join();
        expect(actualContent, expectedContent,
            reason: 'content mismatch on $lang/$theme line $i');

        // Compare token boundaries.
        if (actual.length != expected.length) {
          failures.add(
              '$lang/$theme line $i: token count ${actual.length} != ${expected.length}\n'
              '  expected: ${expected.map((t) => t['content']).toList()}\n'
              '  actual:   ${actual.map((t) => t.content).toList()}');
          continue;
        }

        for (var j = 0; j < expected.length; j++) {
          final e = expected[j];
          final a = actual[j];
          expect(a.content, e['content'],
              reason: 'content mismatch $lang/$theme line $i token $j');

          totalTokens++;
          final expColor = (e['color'] as String?)?.toLowerCase();
          final actColor = a.color?.toLowerCase();
          if (expColor == actColor ||
              (expColor == null && (actColor == null || actColor.isEmpty))) {
            colorMatches++;
          } else {
            failures.add(
                '$lang/$theme line $i token $j "${a.content}": color $actColor != $expColor');
          }

          final expFont = e['fontStyle'] as int? ?? 0;
          if (a.fontStyle == expFont) {
            fontStyleMatches++;
          } else {
            failures.add(
                '$lang/$theme line $i token $j "${a.content}": fontStyle ${a.fontStyle} != $expFont');
          }
        }
      }
    }

    // Print a summary for visibility.
    // ignore: avoid_print
    print('Golden comparison: $colorMatches/$totalTokens colors match, '
        '$fontStyleMatches/$totalTokens font styles match');
    if (failures.isNotEmpty) {
      // ignore: avoid_print
      print('First failures:\n${failures.take(25).join('\n')}');
    }

    expect(failures, isEmpty,
        reason: '${failures.length} token mismatches vs real Shiki');
  });
}
