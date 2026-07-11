import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide FontStyle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shiki_flutter/shiki_flutter.dart';

ShikiHighlighter buildHighlighter() {
  final hl = ShikiHighlighter();
  hl.loadLanguageFromJson(File('test/fixtures/langs/javascript.json').readAsStringSync());
  hl.loadThemeFromJson(File('test/fixtures/themes/github-dark.json').readAsStringSync());
  return hl;
}

void main() {
  group('parseColor — hex', () {
    test('#rrggbb', () {
      expect(parseColor('#ff0000'), const Color(0xFFFF0000));
    });
    test('#rrggbbaa', () {
      expect(parseColor('#00ff0080'), const Color(0x8000FF00));
    });
    test('#rgb', () {
      expect(parseColor('#f00'), const Color(0xFFFF0000));
    });
    test('#rgba', () {
      expect(parseColor('#0f08'), const Color(0x8800FF00));
    });
    test('invalid returns null', () {
      expect(parseColor(null), isNull);
      expect(parseColor(''), isNull);
      expect(parseColor('red'), isNull);
      expect(parseColor('#zz'), isNull);
    });
  });

  group('parseColor — CSS color()', () {
    test('display-p3 with numeric components', () {
      final c = parseColor('color(display-p3 0.451324 0.823458 0.446819)')!;
      expect(c.colorSpace, ui.ColorSpace.displayP3);
      expect(c.r, closeTo(0.451324, 1e-6));
      expect(c.g, closeTo(0.823458, 1e-6));
      expect(c.b, closeTo(0.446819, 1e-6));
      expect(c.a, 1.0);
    });
    test('display-p3 with alpha', () {
      final c = parseColor('color(display-p3 1 0 0 / 0.5)')!;
      expect(c.colorSpace, ui.ColorSpace.displayP3);
      expect(c.r, 1.0);
      expect(c.a, closeTo(0.5, 1e-6));
    });
    test('percentage components', () {
      final c = parseColor('color(display-p3 100% 0% 50%)')!;
      expect(c.r, closeTo(1.0, 1e-6));
      expect(c.g, 0.0);
      expect(c.b, closeTo(0.5, 1e-6));
    });
    test('srgb color space', () {
      final c = parseColor('color(srgb 0.2 0.4 0.6)')!;
      expect(c.colorSpace, ui.ColorSpace.sRGB);
      expect(c.g, closeTo(0.4, 1e-6));
    });
    test('clamps out-of-range components', () {
      final c = parseColor('color(display-p3 1.5 -0.2 0.5)')!;
      expect(c.r, 1.0);
      expect(c.g, 0.0);
    });
    test('malformed / unsupported return null', () {
      expect(parseColor('color(display-p3 0.1 0.2)'), isNull); // 2 channels
      expect(parseColor('color(lab 50 40 30)'), isNull); // unsupported space
      expect(parseColor('color(display-p3 a b c)'), isNull); // non-numeric
      expect(parseColor('color(display-p3 0.1 0.2 0.3'), isNull); // unclosed
    });
  });

  test('parseHexColor delegates to parseColor (deprecated alias)', () {
    // ignore: deprecated_member_use_from_same_package
    expect(parseHexColor('#ff0000'), const Color(0xFFFF0000));
  });

  group('themedTokenStyle', () {
    test('applies color and bold', () {
      const token = ThemedToken(
        content: 'x',
        offset: 0,
        color: '#aabbcc',
        fontStyle: FontStyle.bold,
      );
      final style = themedTokenStyle(token);
      expect(style.color, const Color(0xFFAABBCC));
      expect(style.fontWeight, FontWeight.bold);
    });

    test('applies italic and underline', () {
      const token = ThemedToken(
        content: 'x',
        offset: 0,
        color: '#ffffff',
        fontStyle: FontStyle.italic | FontStyle.underline,
      );
      final style = themedTokenStyle(token);
      expect(style.fontStyle, ui.FontStyle.italic);
      expect(style.decoration, TextDecoration.underline);
    });
  });

  group('codeToTextSpan', () {
    test('produces spans with colors for each token', () {
      final hl = buildHighlighter();
      final span = codeToTextSpan(
        hl,
        'const x = 42;',
        lang: 'javascript',
        theme: 'github-dark',
      );
      final children = span.children!;
      expect(children, isNotEmpty);
      // Every leaf span should carry a color from the theme.
      final colored = children.whereType<TextSpan>().where(
            (s) => s.text != null && s.text!.trim().isNotEmpty && s.style?.color != null,
          );
      expect(colored, isNotEmpty);
    });

    test('inserts newlines between lines', () {
      final hl = buildHighlighter();
      final span = codeToTextSpan(
        hl,
        'const a = 1;\nconst b = 2;',
        lang: 'javascript',
        theme: 'github-dark',
      );
      final text = _flatten(span);
      expect(text, contains('\n'));
      expect(text, 'const a = 1;\nconst b = 2;');
    });
  });

  group('ShikiCodeView widget', () {
    testWidgets('renders highlighted code with background', (tester) async {
      final hl = buildHighlighter();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ShikiCodeView(
            highlighter: hl,
            code: 'const answer = 42;',
            lang: 'javascript',
            theme: 'github-dark',
          ),
        ),
      );

      // The rich text is present.
      final richText = tester.widget<RichText>(find.byType(RichText));
      final span = richText.text as TextSpan;
      expect(_flatten(span), contains('answer'));

      // The theme background is painted.
      expect(find.byType(ColoredBox), findsOneWidget);
    });
  });
}

String _flatten(InlineSpan span) {
  final buffer = StringBuffer();
  span.visitChildren((s) {
    if (s is TextSpan && s.text != null) buffer.write(s.text);
    return true;
  });
  return buffer.toString();
}
