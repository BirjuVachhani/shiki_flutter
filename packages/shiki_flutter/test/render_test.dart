import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide FontStyle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shiki_flutter/langs/dart.dart';
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter/themes/github_dark.dart';

ShikiHighlighter buildHighlighter() {
  final hl = ShikiHighlighter();
  hl.loadLanguageFromJson(
    File('test/fixtures/langs/javascript.json').readAsStringSync(),
  );
  hl.loadThemeFromJson(
    File('test/fixtures/themes/github-dark.json').readAsStringSync(),
  );
  return hl;
}

void main() {
  group('parseColor: hex', () {
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

  group('parseColor: CSS color()', () {
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
        (s) =>
            s.text != null &&
            s.text!.trim().isNotEmpty &&
            s.style?.color != null,
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

  group('ShikiCodeView gutter', () {
    // Three digit-free lines: the only digits in the tree are line numbers.
    const code = 'const alpha = a;\nconst bravo = b;\nconst charlie = c;';

    Future<void> pump(
      WidgetTester tester, {
      GutterStyle gutter = const GutterStyle(),
      EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    }) {
      final hl = buildHighlighter();
      return tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 500,
              child: ShikiCodeView(
                highlighter: hl,
                code: code,
                lang: 'javascript',
                theme: 'github-dark',
                showLineNumbers: true,
                gutterStyle: gutter,
                padding: padding,
                async: false,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('shows one number per code line', (tester) async {
      await pump(tester);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsNothing);
    });

    testWidgets('keeps the code one Text.rich, aligned row-for-row', (
      tester,
    ) async {
      await pump(tester);

      // Still a single blob: one RichText holds all three lines.
      final blob = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((rt) => rt.text.toPlainText())
          .firstWhere((t) => t.contains('alpha'));
      expect(blob, contains('bravo'));
      expect(blob, contains('charlie'));

      // Numbers are evenly spaced by one row.
      final y1 = tester.getTopLeft(find.text('1')).dy;
      final y2 = tester.getTopLeft(find.text('2')).dy;
      final y3 = tester.getTopLeft(find.text('3')).dy;
      expect(y2 - y1, greaterThan(0));
      expect(y3 - y2, moreOrLessEquals(y2 - y1, epsilon: 0.5));

      // The first number's top lines up with the code's top (same padding).
      final codeTop = tester
          .getTopLeft(
            find.byWidgetPredicate(
              (w) => w is RichText && w.text.toPlainText().contains('alpha'),
            ),
          )
          .dy;
      expect(y1, moreOrLessEquals(codeTop, epsilon: 1.0));
    });

    testWidgets('draws an edge-to-edge divider when set', (tester) async {
      const dividerColor = Color(0xFF33AA55);
      await pump(
        tester,
        gutter: const GutterStyle(dividerColor: dividerColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      );

      final box = tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .firstWhere((w) => w.color == dividerColor);
      final dividerRect = tester.getRect(find.byWidget(box));
      final widgetRect = tester.getRect(find.byType(ShikiCodeView));
      expect(dividerRect.top, moreOrLessEquals(widgetRect.top, epsilon: 0.5));
      expect(
        dividerRect.bottom,
        moreOrLessEquals(widgetRect.bottom, epsilon: 0.5),
      );
      // Numbers stay inset by the top padding.
      expect(
        tester.getRect(find.text('1')).top,
        greaterThan(dividerRect.top + 15),
      );
    });

    testWidgets('no numbers and a single Text.rich when disabled', (
      tester,
    ) async {
      final hl = buildHighlighter();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ShikiCodeView(
            highlighter: hl,
            code: code,
            lang: 'javascript',
            theme: 'github-dark',
            async: false,
          ),
        ),
      );
      expect(find.text('1'), findsNothing);
      expect(find.byType(RichText), findsOneWidget);
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
      final spans = lines
          .expand((l) => l)
          .where((s) => (s.text ?? '').isNotEmpty);
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
      final text = lines
          .map((l) => l.map((s) => s.text ?? '').join())
          .join('\n');
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

    testWidgets('gutter is wider than multi-digit numbers so none are clipped', (
      tester,
    ) async {
      final hl = buildHighlighter();
      // 12 digit-free lines: the only "12" in the tree is the line number, and
      // its two digits must both fit the gutter.
      final code = List.filled(12, 'const x = y;').join('\n');
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 400,
              child: ShikiCodeListView(
                highlighter: hl,
                code: code,
                lang: 'javascript',
                theme: 'github-dark',
                showLineNumbers: true,
                shrinkWrap: true,
                async: false,
                physics: const NeverScrollableScrollPhysics(),
              ),
            ),
          ),
        ),
      );

      // The gutter box must be strictly wider than the two-digit label. Sizing
      // it to exactly the label width (the previous behavior) left the trailing
      // digit on a knife edge that web text layout rounds off the end.
      final label = find.text('12');
      expect(label, findsOneWidget);
      final labelWidth = tester.getSize(label).width;
      final boxWidth = tester
          .getSize(find.ancestor(of: label, matching: find.byType(Align)).first)
          .width;
      expect(boxWidth, greaterThan(labelWidth));
    });

    testWidgets('GutterStyle.textScale shrinks the gutter font vs the code', (
      tester,
    ) async {
      final hl = buildHighlighter();
      final code = List.filled(12, 'const x = y;').join('\n');
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 400,
              child: ShikiCodeListView(
                highlighter: hl,
                code: code,
                lang: 'javascript',
                theme: 'github-dark',
                textStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 20,
                ),
                showLineNumbers: true,
                gutterStyle: const GutterStyle(textScale: 0.5),
                shrinkWrap: true,
                async: false,
                physics: const NeverScrollableScrollPhysics(),
              ),
            ),
          ),
        ),
      );

      // The gutter label is sized to the scaled font (20 * 0.5), while the code
      // spans keep the full 20.
      final label = tester.widget<Text>(find.text('12'));
      expect(label.style?.fontSize, 10.0);
    });

    testWidgets('GutterStyle.spacing sets the gap between gutter and code', (
      tester,
    ) async {
      final hl = buildHighlighter();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 400,
              child: ShikiCodeListView(
                highlighter: hl,
                code: 'const a = x;\nconst b = y;',
                lang: 'javascript',
                theme: 'github-dark',
                showLineNumbers: true,
                gutterStyle: const GutterStyle(spacing: 37),
                shrinkWrap: true,
                async: false,
                physics: const NeverScrollableScrollPhysics(),
              ),
            ),
          ),
        ),
      );

      final gap = find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 37.0,
      );
      expect(gap, findsOneWidget);
    });

    testWidgets('GutterStyle renders a divider only when dividerColor is set', (
      tester,
    ) async {
      final hl = buildHighlighter();
      const dividerColor = Color(0xFFABCDEF);

      Future<void> pump(GutterStyle style) => tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 400,
              child: ShikiCodeListView(
                highlighter: hl,
                code: 'const a = x;\nconst b = y;\nconst c = z;',
                lang: 'javascript',
                theme: 'github-dark',
                showLineNumbers: true,
                paintBackground: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                gutterStyle: style,
                shrinkWrap: true,
                async: false,
                physics: const NeverScrollableScrollPhysics(),
              ),
            ),
          ),
        ),
      );

      ColoredBox? dividerBox() {
        for (final w in tester.widgetList<ColoredBox>(
          find.byType(ColoredBox),
        )) {
          if (w.color == dividerColor) return w;
        }
        return null;
      }

      // No dividerColor: no divider.
      await pump(const GutterStyle());
      expect(dividerBox(), isNull);

      // dividerColor set: a divider of the requested thickness that runs edge
      // to edge, into the vertical padding, while the numbers stay inset.
      await pump(
        const GutterStyle(dividerColor: dividerColor, dividerThickness: 2),
      );
      final box = dividerBox();
      expect(box, isNotNull);
      final dividerRect = tester.getRect(find.byWidget(box!));
      expect(dividerRect.width, 2.0);

      // Edge to edge: the divider spans the full widget height (top and bottom
      // padding included).
      final widgetRect = tester.getRect(find.byType(ShikiCodeListView));
      expect(dividerRect.top, moreOrLessEquals(widgetRect.top, epsilon: 0.5));
      expect(
        dividerRect.bottom,
        moreOrLessEquals(widgetRect.bottom, epsilon: 0.5),
      );

      // The first line number is inset by the top padding, so it sits well
      // below the divider's top.
      final firstNumberTop = tester.getRect(find.text('1')).top;
      expect(firstNumberTop, greaterThan(dividerRect.top + 15));
    });

    testWidgets('GutterStyle divider fills height in scrollable mode', (
      tester,
    ) async {
      final hl = buildHighlighter();
      const dividerColor = Color(0xFF00CC99);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 400,
              height: 120,
              child: ShikiCodeListView(
                highlighter: hl,
                code: 'const a = x;\nconst b = y;',
                lang: 'javascript',
                theme: 'github-dark',
                showLineNumbers: true,
                gutterStyle: const GutterStyle(dividerColor: dividerColor),
                async: false,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final box = tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .firstWhere((w) => w.color == dividerColor);
      // Stretched to the viewport (minus vertical padding), not collapsed.
      expect(tester.getSize(find.byWidget(box)).height, greaterThan(50));
    });

    testWidgets('selectionColor is exposed via DefaultSelectionStyle', (
      tester,
    ) async {
      final hl = buildHighlighter();
      const color = Color(0xFF00FF88);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 400,
              child: ShikiCodeListView(
                highlighter: hl,
                code: 'const a = x;',
                lang: 'javascript',
                theme: 'github-dark',
                selectionColor: color,
                async: false,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
              ),
            ),
          ),
        ),
      );

      final styles = tester.widgetList<DefaultSelectionStyle>(
        find.byType(DefaultSelectionStyle),
      );
      expect(styles.any((s) => s.selectionColor == color), isTrue);
    });

    testWidgets('shrink-wraps inside an unbounded parent without error', (
      tester,
    ) async {
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
    testWidgets('ShikiCodeView wraps in a SelectionArea when selectable', (
      tester,
    ) async {
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

    testWidgets('ShikiCodeView adds no SelectionArea by default', (
      tester,
    ) async {
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

    testWidgets(
      'ShikiCodeView does not nest inside an ancestor SelectionArea',
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

        // Only the ancestor's. The widget must not add a second, nested one.
        expect(find.byType(SelectionArea), findsOneWidget);
      },
    );

    testWidgets('ShikiCodeListView wraps in a SelectionArea when selectable', (
      tester,
    ) async {
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
      },
    );
  });

  group('span memoization', () {
    // The leaf-span list a code row renders. `Text.rich` wraps the supplied span
    // under a DefaultTextStyle parent (children: [supplied]); the supplied span's
    // own children are the memoized artifact (the token spans for ShikiCodeView,
    // the per-line list for ShikiCodeListView). Identity of that list is stable
    // across a no-op rebuild iff the spans were cached.
    List<InlineSpan> rowChildren(WidgetTester tester) {
      final rt = tester.widget<RichText>(find.byType(RichText).first);
      return ((rt.text as TextSpan).children!.single as TextSpan).children!;
    }

    testWidgets(
      'ShikiCodeView reuses spans on a no-op rebuild, rebuilds on change',
      (tester) async {
        final hl = buildHighlighter();
        var fontSize = 14.0;
        var code = 'const x = 1;';
        late StateSetter setOuter;
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: StatefulBuilder(
              builder: (context, setState) {
                setOuter = setState;
                return ShikiCodeView(
                  highlighter: hl,
                  code: code,
                  lang: 'javascript',
                  theme: 'github-dark',
                  textStyle: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: fontSize,
                  ),
                  async: false,
                );
              },
            ),
          ),
        );

        final first = rowChildren(tester);

        // No-op rebuild (new widget, equal inputs): same span objects reused.
        setOuter(() {});
        await tester.pump();
        expect(identical(rowChildren(tester), first), isTrue);

        // Style change invalidates (base style is part of the key).
        setOuter(() => fontSize = 20.0);
        await tester.pump();
        final afterStyle = rowChildren(tester);
        expect(identical(afterStyle, first), isFalse);

        // Content change invalidates (new tokens).
        setOuter(() => code = 'const y = 2;');
        await tester.pump();
        expect(identical(rowChildren(tester), afterStyle), isFalse);
      },
    );

    testWidgets(
      'ShikiCodeListView reuses spans on a no-op rebuild, rebuilds on change',
      (tester) async {
        final hl = buildHighlighter();
        var fontSize = 14.0;
        var code = 'const x = 1;';
        late StateSetter setOuter;
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: StatefulBuilder(
              builder: (context, setState) {
                setOuter = setState;
                return SizedBox(
                  width: 400,
                  height: 300,
                  child: ShikiCodeListView(
                    highlighter: hl,
                    code: code,
                    lang: 'javascript',
                    theme: 'github-dark',
                    textStyle: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: fontSize,
                    ),
                    async: false,
                  ),
                );
              },
            ),
          ),
        );

        final first = rowChildren(tester);

        setOuter(() {});
        await tester.pump();
        expect(identical(rowChildren(tester), first), isTrue);

        setOuter(() => fontSize = 20.0);
        await tester.pump();
        final afterStyle = rowChildren(tester);
        expect(identical(afterStyle, first), isFalse);

        setOuter(() => code = 'const y = 2;');
        await tester.pump();
        expect(identical(rowChildren(tester), afterStyle), isFalse);
      },
    );
  });

  group('async lifecycle', () {
    testWidgets('disposing while an async tokenize is in flight does not throw', (
      tester,
    ) async {
      final hl = createHighlighter(langs: [dart], themes: [githubDark]);
      addTearDown(hl.dispose);

      // Pump the async widget: first frame is the plain placeholder, an off-thread
      // tokenize is now in flight.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 400,
            height: 300,
            child: ShikiCodeView(
              highlighter: hl,
              code: 'void main() {}',
              lang: 'dart',
              theme: 'github-dark',
              async: true,
            ),
          ),
        ),
      );

      // Dispose the widget's State by swapping the tree before the result lands.
      await tester.pumpWidget(const SizedBox());

      // Let the in-flight isolate result arrive; the resolver's _disposed guard
      // must drop it rather than calling setState on the dead State.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 1)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
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
