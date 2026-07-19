// A ready-to-use widget for displaying highlighted code.
library;

import 'package:flutter/material.dart' show SelectionArea;
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
/// on a background isolate, then swaps to the highlighted result, which is
/// cached, so later rebuilds are instant.
///
/// Set [selectable] to `true` to let users select and copy the code; it wraps
/// the subtree in a [SelectionArea], unless an ancestor already provides one.
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
    this.selectable = false,
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

  /// Whether to make the code selectable by wrapping the subtree in a
  /// [SelectionArea]. Defaults to `false`.
  ///
  /// When an ancestor already provides a selection registrar (e.g. the widget
  /// is inside another [SelectionArea]), this flag is ignored: the code is
  /// already selectable through that ancestor, and wrapping again would nest
  /// two selection contexts.
  final bool selectable;

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
      // Synchronous path: unchanged behavior.
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

    Widget result = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: child,
    );

    // Only add our own SelectionArea when asked to and when there isn't one
    // already above us, so an enclosing SelectionArea keeps driving selection.
    if (widget.selectable && SelectionContainer.maybeOf(context) == null) {
      result = SelectionArea(child: result);
    }
    return result;
  }
}
