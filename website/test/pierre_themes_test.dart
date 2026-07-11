import 'package:flutter_test/flutter_test.dart';
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter/langs/dart.dart';
import 'package:shiki_flutter_website/src/pierre_themes/pierre_themes.dart';

/// Verifies the extracted Pierre themes load and tokenize with real colors —
/// including the two "vibrant" themes, whose wide-gamut `color(display-p3 …)`
/// values are parsed natively by `parseColor`.
void main() {
  final hl = createHighlighter(langs: [dart], themes: [...pierreThemes]);

  const snippet = '''
class Greeter {
  final String name; // a field
  Greeter(this.name);
  String hello() => 'Hi, \$name';
}
''';

  test('all 10 Pierre themes are registered', () {
    expect(pierreThemes.length, 10);
  });

  for (final theme in pierreThemes) {
    test('${theme.id}: bg/fg resolve to valid colors', () {
      final reg = hl.getThemeRegistration(theme.id);
      expect(parseColor(reg.bg), isNotNull,
          reason: 'bg "${reg.bg}" should parse to a Color');
      expect(parseColor(reg.fg), isNotNull,
          reason: 'fg "${reg.fg}" should parse to a Color');
    });

    test('${theme.id}: tokenizes Dart with multiple real colors', () {
      final lines = hl.codeToTokens(
        snippet,
        TokenizeOptions(lang: 'dart', theme: theme.id),
      );
      final colors = <String>{};
      for (final line in lines) {
        for (final token in line) {
          final c = token.color;
          if (c != null && c.isNotEmpty) {
            // Every emitted color must be renderable (hex or color(display-p3 …)).
            expect(parseColor(c), isNotNull,
                reason: '${theme.id} token color "$c" is not parseable');
            colors.add(c.toLowerCase());
          }
        }
      }
      // A syntax-highlighted snippet should use more than one color; if the
      // theme failed to load, everything would fall back to a single color.
      expect(colors.length, greaterThan(3),
          reason: '${theme.id} produced too few distinct colors: $colors');
    });
  }
}
