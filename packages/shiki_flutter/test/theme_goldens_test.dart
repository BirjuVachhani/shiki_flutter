// Golden tests for every bundled theme.
//
// Each theme renders one representative line of code with the theme's
// background painted explicitly by the widget tree (a [ColoredBox]), never by
// the token [TextStyle]. This is the invariant these goldens lock in: no theme
// may draw a filled box behind individual tokens. See [themedTokenStyle].
//
// The renders are intentionally simple and identical across themes (same
// snippet, same fixed size, same monospace font) so the only thing that varies
// between goldens is the theme's own colors, keeping them stable and easy to
// review. Regenerate with:
//
//   flutter test test/theme_goldens_test.dart --update-goldens
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiki_flutter/shiki_flutter.dart';

/// A single line exercising several token kinds (keyword, identifier,
/// operator, type, number, punctuation, comment) so each golden shows a slice
/// of the theme's palette over its background.
const _code = "const origin = Point(0, 0); // start";

const _rowSize = Size(560, 44);

const _codeStyle = TextStyle(
  fontFamily: 'GeistMono',
  fontSize: 18,
  height: 1.5,
);

Future<void> _loadFont() async {
  final bytes = File('test/fonts/GeistMono-400.ttf').readAsBytesSync();
  final loader = FontLoader('GeistMono')
    ..addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
  await loader.load();
}

/// One theme's row: the theme background filling the whole row, with the
/// highlighted line on top. The background comes from the widget tree, so a
/// stray per-token background would show up immediately as a lighter box.
Widget _themeRow(ShikiHighlighter hl, ShikiTheme theme) {
  final registration = hl.getThemeRegistration(theme.id);
  final bg = parseColor(registration.bg)!;
  final span = codeToTextSpan(
    hl,
    _code,
    lang: CodeLanguages.dart,
    theme: theme,
    baseStyle: _codeStyle,
  );
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: SizedBox.fromSize(
        size: _rowSize,
        child: ColoredBox(
          color: bg,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text.rich(
              span,
              softWrap: false,
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  late ShikiHighlighter hl;

  setUpAll(() async {
    await _loadFont();
    hl = ShikiHighlighter()
      ..preload(
        langs: [CodeLanguages.dart],
        themes: ShikiThemes.all,
      );
  });

  for (final theme in ShikiThemes.all) {
    testWidgets('theme golden: ${theme.id}', (tester) async {
      await tester.binding.setSurfaceSize(_rowSize);
      await tester.pumpWidget(_themeRow(hl, theme));
      await expectLater(
        find.byType(ColoredBox),
        matchesGoldenFile('goldens/themes/${theme.id}.png'),
      );
    });
  }
}
