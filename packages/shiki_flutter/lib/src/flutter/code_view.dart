// A ready-to-use widget for displaying highlighted code.
library;

import 'package:flutter/widgets.dart';

import '../async/async_token_resolver.dart';
import '../core/highlighter.dart';
import 'render.dart';

/// Displays [code] highlighted with the given [lang] and [theme].
///
/// The [highlighter] must already have the language and theme loaded. The
/// widget paints the theme's background color behind the code and applies the
/// theme's foreground as the default text color.
///
/// When [async] highlighting is active (see [ShikiHighlighter.asyncDefault]), the code
/// first appears as plain text in the theme's base color while it is tokenized
/// on a background isolate, then swaps to the highlighted result — which is
/// cached, so later rebuilds are instant.
class ShikiCodeView extends StatefulWidget {
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
    this.async,
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

  /// Overrides the global [ShikiHighlighter.asyncDefault] default for this widget.
  /// When null, the global default applies.
  final bool? async;

  @override
  State<ShikiCodeView> createState() => _ShikiCodeViewState();
}

class _ShikiCodeViewState extends State<ShikiCodeView> {
  late final AsyncTokenResolver _resolver =
      AsyncTokenResolver(() => setState(() {}));

  bool get _asyncEffective => widget.async ?? ShikiHighlighter.asyncDefault;

  TokenizeOptions get _options =>
      TokenizeOptions(lang: widget.lang, theme: widget.theme);

  @override
  void initState() {
    super.initState();
    if (_asyncEffective) {
      _resolver.resolve(widget.highlighter, widget.code, _options);
    }
  }

  @override
  void didUpdateWidget(ShikiCodeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_asyncEffective) {
      _resolver.resolve(widget.highlighter, widget.code, _options);
    }
  }

  @override
  void dispose() {
    _resolver.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.textStyle ?? const TextStyle(fontFamily: 'monospace');
    final registration = widget.highlighter.getThemeRegistration(widget.theme);
    final bg = widget.paintBackground ? parseColor(registration.bg) : null;

    final TextSpan span;
    if (!_asyncEffective) {
      // Synchronous path — unchanged behavior.
      span = codeToTextSpan(
        widget.highlighter,
        widget.code,
        lang: widget.lang,
        theme: widget.theme,
        baseStyle: base,
      );
    } else {
      final effectiveBase = base.copyWith(color: parseColor(registration.fg));
      final tokens = _resolver.tokens;
      span = tokens != null
          ? tokensToTextSpan(tokens, baseStyle: effectiveBase)
          // Placeholder: the same code in the theme's base color.
          : TextSpan(text: widget.code, style: effectiveBase);
    }

    Widget child = Padding(
      padding: widget.padding,
      child: Text.rich(
        span,
        textScaler: widget.textScaler,
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
