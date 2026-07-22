import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiki_flutter_website/src/pages/docs_content.dart';
import 'package:shiki_flutter_website/src/theme/tokens.dart';

/// Flattens [spans] to leaf `(text, style)` pairs, merging each ancestor's
/// style into its children the way Flutter paints a `TextSpan` tree. This lets
/// the assertions read the *effective* style a glyph is drawn with, so a code
/// span nested under a bold parent reports the inherited weight.
List<(String, TextStyle)> _leaves(List<InlineSpan> spans, [TextStyle? parent]) {
  final out = <(String, TextStyle)>[];
  for (final span in spans) {
    if (span is! TextSpan) continue;
    final merged = parent == null
        ? (span.style ?? const TextStyle())
        : parent.merge(span.style);
    if ((span.text ?? '').isNotEmpty) out.add((span.text!, merged));
    final children = span.children;
    if (children != null) out.addAll(_leaves(children, merged));
  }
  return out;
}

bool _isMono(TextStyle s) => s.fontFamily == AppFonts.mono;
bool _isBold(TextStyle s) => s.fontWeight == FontWeight.w600;

void main() {
  const colors = AppColors.dark;

  (String, TextStyle) leafWith(String source, String text) {
    final leaves = _leaves(inlineSpans(source, colors));
    return leaves.firstWhere(
      (l) => l.$1 == text,
      orElse: () => fail('no leaf "$text" in ${leaves.map((l) => l.$1)}'),
    );
  }

  test('inline code inside bold renders mono AND bold', () {
    // The regression: `**`code`**` used to render the backticks literally in
    // bold instead of parsing the code.
    final (text, style) = leafWith('**`preload()`.** rest', 'preload()');
    expect(_isMono(style), isTrue, reason: 'code should be mono');
    expect(_isBold(style), isTrue, reason: 'code inside ** ** should be bold');
    // The backticks are gone (parsed, not literal).
    final all = _leaves(inlineSpans('**`preload()`.** rest', colors));
    expect(all.map((l) => l.$1).join(), isNot(contains('`')));
    // The trailing "." inside the bold run stays bold too.
    expect(_isBold(leafWith('**`preload()`.** rest', '.').$2), isTrue);
  });

  test('standalone inline code is mono but not bold', () {
    final (_, style) = leafWith('use `preload()` now', 'preload()');
    expect(_isMono(style), isTrue);
    expect(_isBold(style), isFalse);
  });

  test('standalone bold is bold but not mono', () {
    final (_, style) = leafWith('**Note** this', 'Note');
    expect(_isBold(style), isTrue);
    expect(_isMono(style), isFalse);
  });

  test('bold then separate code render independently', () {
    const src = '**Set it once.** Point `config.defaultHighlighter` at it';
    expect(_isBold(leafWith(src, 'Set it once.').$2), isTrue);
    final code = leafWith(src, 'config.defaultHighlighter').$2;
    expect(_isMono(code), isTrue);
    expect(_isBold(code), isFalse);
  });

  test('double-asterisks inside a code span stay literal (not bold)', () {
    // `allMatches` consumes the code run first, so the inner ** is not bold.
    final (text, style) = leafWith('call `a ** b ** c` here', 'a ** b ** c');
    expect(text, contains('**'));
    expect(_isMono(style), isTrue);
  });
}
