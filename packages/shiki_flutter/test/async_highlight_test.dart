import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter/src/textmate/theme.dart'
    show RawThemeSetting, ThemeSettingStyle;

const dart = CodeLanguages.dart;
const githubDark = ShikiThemes.githubDark;

const _code = '''
void main() {
  final greeting = 'hello';
  // a comment
  print('\$greeting, world');
}
''';

const _options = TokenizeOptions(lang: 'dart', theme: 'github-dark');

Widget _wrap(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: const MediaQueryData(),
    child: Center(child: SizedBox(width: 400, height: 300, child: child)),
  ),
);

/// Counts leaf text spans in [span]'s subtree. `Text.rich` wraps the supplied
/// span under a DefaultTextStyle parent, so the placeholder (one span for the
/// whole code) has exactly one leaf, while a highlighted result has many.
int _leafCount(InlineSpan span) {
  if (span is! TextSpan) return 1;
  final children = span.children;
  var n = (span.text ?? '').isNotEmpty ? 1 : 0;
  if (children != null) {
    for (final child in children) {
      n += _leafCount(child);
    }
  }
  return n;
}

void _expectTokensEqual(
  List<List<ThemedToken>> actual,
  List<List<ThemedToken>> expected,
) {
  expect(actual.length, expected.length);
  for (var i = 0; i < actual.length; i++) {
    expect(actual[i].length, expected[i].length, reason: 'line $i length');
    for (var j = 0; j < actual[i].length; j++) {
      final a = actual[i][j];
      final e = expected[i][j];
      expect(a.content, e.content);
      expect(a.offset, e.offset);
      expect(a.color, e.color);
      expect(a.bgColor, e.bgColor);
      expect(a.fontStyle, e.fontStyle);
    }
  }
}

void main() {
  test(
    'codeToTokensAsync matches synchronous codeToTokens byte-for-byte',
    () async {
      final sync = createHighlighter(
        langs: [dart],
        themes: [githubDark],
      ).codeToTokens(_code, _options);

      final asyncHl = createHighlighter(langs: [dart], themes: [githubDark]);
      addTearDown(asyncHl.dispose);
      final result = await asyncHl.codeToTokensAsync(_code, _options);

      _expectTokensEqual(result, sync);
    },
  );

  test(
    'results are cached: peek hits and repeat calls return the same list',
    () async {
      final hl = createHighlighter(langs: [dart], themes: [githubDark]);
      addTearDown(hl.dispose);

      expect(hl.peekTokens(_code, _options), isNull); // cold

      final first = await hl.codeToTokensAsync(_code, _options);
      expect(hl.peekTokens(_code, _options), same(first)); // warm, synchronous
      expect(await hl.codeToTokensAsync(_code, _options), same(first));
    },
  );

  test(
    'loadThemeRegistration (object theme) reaches the async worker',
    () async {
      // A theme built as a Dart object, not from JSON. Before the worker seam
      // forwarded it, codeToTokensAsync threw "theme not loaded" on the isolate.
      final custom = ThemeRegistration(
        name: 'custom-object-theme',
        type: 'dark',
        settings: [
          RawThemeSetting(
            settings: ThemeSettingStyle(
              foreground: '#c9d1d9',
              background: '#0d1117',
            ),
          ),
          RawThemeSetting(
            scope: 'keyword',
            settings: ThemeSettingStyle(foreground: '#ff7b72'),
          ),
        ],
      );

      final hl = createHighlighter(langs: [dart]);
      addTearDown(hl.dispose);
      final themeName = hl.loadThemeRegistration(custom);
      final options = TokenizeOptions(lang: 'dart', theme: themeName);

      final sync = hl.codeToTokens(_code, options);
      // Computed on the background isolate, which only knows this theme because
      // loadThemeRegistration serialized and forwarded it to the worker.
      final result = await hl.codeToTokensAsync(_code, options);

      _expectTokensEqual(result, sync);
      // The theme genuinely applied (colored tokens), not a plain fallback.
      expect(
        sync.expand((line) => line).any((t) => (t.color ?? '').isNotEmpty),
        isTrue,
      );
    },
  );

  test('plain language is served synchronously without a worker', () {
    final hl = createHighlighter(themes: [githubDark]);
    addTearDown(hl.dispose);
    const plain = TokenizeOptions(lang: 'text', theme: 'github-dark');
    // peek returns immediately (no round trip) for a plain language.
    final peeked = hl.peekTokens('hello\nworld', plain);
    expect(peeked, isNotNull);
    expect(peeked!.length, 2);
  });

  testWidgets(
    'async miss shows the plain code as a placeholder on the first frame',
    (tester) async {
      final hl = createHighlighter(langs: [dart], themes: [githubDark]);
      addTearDown(hl.dispose); // non-blocking; safe even with a spawn in flight

      await tester.pumpWidget(
        _wrap(
          ShikiCodeView(
            highlighter: hl,
            code: _code,
            lang: dart,
            theme: ShikiThemes.githubDark,
            async: true,
          ),
        ),
      );

      // First frame while tokenization is pending: one plain span for the whole
      // code, and the code text is fully present.
      final span =
          tester.widget<RichText>(find.byType(RichText)).text as TextSpan;
      expect(_leafCount(span), 1);
      expect(span.toPlainText(), contains('greeting'));
    },
  );

  testWidgets('a warm cache highlights on the first frame (no placeholder)', (
    tester,
  ) async {
    final hl = createHighlighter(langs: [dart], themes: [githubDark]);
    await tester.runAsync(() => hl.codeToTokensAsync(_code, _options));

    await tester.pumpWidget(
      _wrap(
        ShikiCodeView(
          highlighter: hl,
          code: _code,
          lang: dart,
          theme: ShikiThemes.githubDark,
          async: true,
        ),
      ),
    );

    final span =
        tester.widget<RichText>(find.byType(RichText)).text as TextSpan;
    expect(_leafCount(span), greaterThan(1));

    await tester.runAsync(hl.dispose);
  });

  testWidgets('async: false tokenizes synchronously on the first frame', (
    tester,
  ) async {
    final hl = createHighlighter(langs: [dart], themes: [githubDark]);
    addTearDown(hl.dispose);

    await tester.pumpWidget(
      _wrap(
        ShikiCodeView(
          highlighter: hl,
          code: _code,
          lang: dart,
          theme: ShikiThemes.githubDark,
          async: false,
        ),
      ),
    );

    final span =
        tester.widget<RichText>(find.byType(RichText)).text as TextSpan;
    expect(_leafCount(span), greaterThan(1));
  });
}
