import 'package:flutter_test/flutter_test.dart';
import 'package:shiki_flutter/shiki_flutter.dart';

// Regression guard for the wall-clock tokenize-time-limit bug: with a positive
// `tokenizeTimeLimit`, a line that exceeds the budget stopped mid-way and dumped
// its remainder as one coarse token, so output depended on machine load and
// diverged from Shiki (and the goldens) under CPU pressure. The default is now
// 0 (unlimited), so tokenization is a pure function of the input.
//
// This is the exact JavaScript that flaked in golden/parity runs: an early bail
// merged the arrow and `**` operators into one big token.
const _js =
    'const arr = [1, 2].map(n => n ** 2);\nexport default function () {}';

const _jsLang = CodeLanguages.javascript;
const _theme = ShikiThemes.githubDark;
const _opts = TokenizeOptions(lang: 'javascript', theme: 'github-dark');

String _encode(List<List<ThemedToken>> lines) => lines
    .map((l) => l.map((t) => '${t.offset}:${t.content}').join(''))
    .join('\n');

void main() {
  test('the default tokenizeTimeLimit is 0 (unlimited)', () {
    // Locks the fix: a positive default reintroduces load-dependent output.
    expect(const TokenizeOptions().tokenizeTimeLimit, 0);
  });

  test('operators tokenize fine-grained at the default (no early bail)', () {
    final hl = ShikiHighlighter()..preload(langs: [_jsLang], themes: [_theme]);
    final flat = hl.codeToTokens(_js, _opts).expand((l) => l).toList();

    // A timed bail would swallow these into a coarse token like `=> n ** 2);`.
    expect(
      flat.any((t) => t.content.trim() == '=>'),
      isTrue,
      reason: 'arrow operator must be its own token',
    );
    expect(
      flat.any((t) => t.content.trim() == '**'),
      isTrue,
      reason: 'exponent operator must be its own token',
    );
    // No token may span a line break (a bail dumps the line remainder as one).
    expect(flat.every((t) => !t.content.contains('\n')), isTrue);
  });

  test('tokenization is deterministic across repeated runs', () {
    final hl = ShikiHighlighter()..preload(langs: [_jsLang], themes: [_theme]);
    final first = _encode(hl.codeToTokens(_js, _opts));
    for (var i = 0; i < 100; i++) {
      expect(_encode(hl.codeToTokens(_js, _opts)), first);
    }
  });
}
