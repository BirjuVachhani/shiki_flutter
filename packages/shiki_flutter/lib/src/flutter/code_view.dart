// A ready-to-use widget for displaying highlighted code.
library;

import 'package:flutter/widgets.dart';

import '../core/highlighter.dart';
import 'render.dart';

/// Displays [code] highlighted with the given [lang] and [theme].
///
/// The [highlighter] must already have the language and theme loaded. The
/// widget paints the theme's background color behind the code and applies the
/// theme's foreground as the default text color.
class ShikiCodeView extends StatelessWidget {
  const ShikiCodeView({
    super.key,
    required this.highlighter,
    required this.code,
    required this.lang,
    required this.theme,
    this.textStyle,
    this.padding = const EdgeInsets.all(16),
    this.paintBackground = true,
    this.textScaler,
  });

  final ShikiHighlighter highlighter;
  final String code;
  final String lang;
  final String theme;

  /// Base text style. A monospace `fontFamily` is recommended.
  final TextStyle? textStyle;

  final EdgeInsetsGeometry padding;

  /// Whether to paint the theme's background color behind the code.
  final bool paintBackground;

  final TextScaler? textScaler;

  @override
  Widget build(BuildContext context) {
    final base = (textStyle ?? const TextStyle(fontFamily: 'monospace'));
    final span = codeToTextSpan(
      highlighter,
      code,
      lang: lang,
      theme: theme,
      baseStyle: base,
    );

    final registration = highlighter.getThemeRegistration(theme);
    final bg = paintBackground ? parseColor(registration.bg) : null;

    Widget child = Padding(
      padding: padding,
      child: Text.rich(
        span,
        textScaler: textScaler,
        softWrap: false,
      ),
    );

    if (bg != null) {
      child = ColoredBox(color: bg, child: child);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: child,
    );
  }
}
