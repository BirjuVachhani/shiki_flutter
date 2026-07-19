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

  group('tokensToLineSpans', () {
    test('keeps line grouping and preserves blank lines', () {
      final tokens = <List<ThemedToken>>[
        [const ThemedToken(content: 'a', offset: 0, color: '#ff0000')],
        [],
        [const ThemedToken(content: 'b', offset: 2, color: '#00ff00')],
      ];
      final lines = tokensToLineSpans(tokens, baseStyle: const TextStyle());
      expect(lines.length, 3);
      expect(lines[0].single.text, 'a');
      expect(lines[0].single.style?.color, const Color(0xFFFF0000));
      // A blank line becomes a single height-preserving empty-text span.
      expect(lines[1].single.text, '');
      expect(lines[2].single.text, 'b');
    });
  });

  group('codeToLineSpans', () {
    test('splits into one entry per source line', () {
      final hl = buildHighlighter();
      final lines = codeToLineSpans(
        hl,
        'const a = 1;\nconst b = 2;',
        lang: 'javascript',
        theme: 'github-dark',
      );
      expect(lines.length, 2);
    });

    test('preserves blank lines as a single empty-text span', () {
      final hl = buildHighlighter();
      final lines = codeToLineSpans(
        hl,
        'const a = 1;\n\nconst b = 2;',
        lang: 'javascript',
        theme: 'github-dark',
      );
      expect(lines.length, 3);
      expect(lines[1].single.text, '');
    });

    test('bakes the theme foreground onto every span', () {
      final hl = buildHighlighter();
      final lines = codeToLineSpans(
        hl,
        'const x = y;',
        lang: 'javascript',
        theme: 'github-dark',
      );
      final spans =
          lines.expand((l) => l).where((s) => (s.text ?? '').isNotEmpty);
      expect(spans, isNotEmpty);
      expect(spans.every((s) => s.style?.color != null), isTrue);
    });

    test('joined lines reconstruct the source', () {
      final hl = buildHighlighter();
      const code = 'const a = 1;\nconst b = 2;';
      final lines = codeToLineSpans(
        hl,
        code,
        lang: 'javascript',
        theme: 'github-dark',
      );
      final text =
          lines.map((l) => l.map((s) => s.text ?? '').join()).join('\n');
      expect(text, code);
    });
  });

  test('lineToTextSpan wraps spans as children', () {
    const line = [TextSpan(text: 'a'), TextSpan(text: 'b')];
    final span = lineToTextSpan(line);
    expect(span.children, line);
    expect(_flatten(span), 'ab');
  });

  group('ShikiCodeListView widget', () {
    testWidgets('renders highlighted code with background', (tester) async {
      final hl = buildHighlighter();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 400,
            height: 300,
            child: ShikiCodeListView(
              highlighter: hl,
              code: 'const answer = x;',
              lang: 'javascript',
              theme: 'github-dark',
            ),
          ),
        ),
      );

      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final joined = richTexts.map((rt) => _flatten(rt.text)).join();
      expect(joined, contains('answer'));
      expect(find.byType(ColoredBox), findsWidgets);
    });

    testWidgets('shows a line-number gutter when enabled', (tester) async {
      final hl = buildHighlighter();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 400,
            height: 300,
            child: ShikiCodeListView(
              highlighter: hl,
              code: 'const a = x;\nconst b = y;\nconst c = z;',
              lang: 'javascript',
              theme: 'github-dark',
              showLineNumbers: true,
            ),
          ),
        ),
      );

      // Digits absent from the code, so these only match the gutter.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shrink-wraps inside an unbounded parent without error',
        (tester) async {
      final hl = buildHighlighter();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SingleChildScrollView(
            child: ShikiCodeListView(
              highlighter: hl,
              code: 'const a = x;\nconst b = y;',
              lang: 'javascript',
              theme: 'github-dark',
              showLineNumbers: true,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    test('asserts showLineNumbers requires softWrap: false', () {
      final hl = buildHighlighter();
      expect(
        () => ShikiCodeListView(
          highlighter: hl,
          code: 'x',
          lang: 'javascript',
          theme: 'github-dark',
          showLineNumbers: true,
          softWrap: true,
        ),
        throwsAssertionError,
      );
    });
  });

  group('selectable flag', () {
    testWidgets('ShikiCodeView wraps in a SelectionArea when selectable',
        (tester) async {
      final hl = buildHighlighter();
      await tester.pumpWidget(
        MaterialApp(
          home: ShikiCodeView(
            highlighter: hl,
            code: 'const answer = x;',
            lang: 'javascript',
            theme: 'github-dark',
            selectable: true,
          ),
        ),
      );

      expect(find.byType(SelectionArea), findsOneWidget);
    });

    testWidgets('ShikiCodeView adds no SelectionArea by default',
        (tester) async {
      final hl = buildHighlighter();
      await tester.pumpWidget(
        MaterialApp(
          home: ShikiCodeView(
            highlighter: hl,
            code: 'const answer = x;',
            lang: 'javascript',
            theme: 'github-dark',
          ),
        ),
      );

      expect(find.byType(SelectionArea), findsNothing);
    });

    testWidgets('ShikiCodeView does not nest inside an ancestor SelectionArea',
        (tester) async {
      final hl = buildHighlighter();
      await tester.pumpWidget(
        MaterialApp(
          home: SelectionArea(
            child: ShikiCodeView(
              highlighter: hl,
              code: 'const answer = x;',
              lang: 'javascript',
              theme: 'github-dark',
              selectable: true,
            ),
          ),
        ),
      );

      // Only the ancestor's — the widget must not add a second, nested one.
      expect(find.byType(SelectionArea), findsOneWidget);
    });

    testWidgets('ShikiCodeListView wraps in a SelectionArea when selectable',
        (tester) async {
      final hl = buildHighlighter();
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 400,
            height: 300,
            child: ShikiCodeListView(
              highlighter: hl,
              code: 'const a = x;\nconst b = y;',
              lang: 'javascript',
              theme: 'github-dark',
              selectable: true,
            ),
          ),
        ),
      );

      expect(find.byType(SelectionArea), findsOneWidget);
    });

    testWidgets(
        'ShikiCodeListView does not nest inside an ancestor SelectionArea',
        (tester) async {
      final hl = buildHighlighter();
      await tester.pumpWidget(
        MaterialApp(
          home: SelectionArea(
            child: SizedBox(
              width: 400,
              height: 300,
              child: ShikiCodeListView(
                highlighter: hl,
                code: 'const a = x;\nconst b = y;',
                lang: 'javascript',
                theme: 'github-dark',
                selectable: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SelectionArea), findsOneWidget);
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
