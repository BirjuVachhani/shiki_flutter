// A ready-to-use widget for displaying highlighted code.
library;

import 'package:flutter/material.dart' show SelectionArea;
import 'package:flutter/widgets.dart';

import '../async/async_token_resolver.dart';
import '../core/colors.dart';
import '../core/highlighter.dart';
import 'gutter.dart';
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
///
/// Set [showLineNumbers] to `true` for a line-number gutter (styled via
/// [gutterStyle]). The code stays a single `Text.rich`; a fixed numbers column
/// is placed beside it and never scrolls horizontally.
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
    this.showLineNumbers = false,
    this.gutterStyle = const GutterStyle(),
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

  /// Show a line-number gutter to the left of the code.
  ///
  /// The code remains a single `Text.rich`; a fixed numbers column sits beside
  /// it (so numbers never scroll horizontally). Enabling this forces a uniform
  /// line height on the code so the numbers stay row-aligned. Style it with
  /// [gutterStyle].
  final bool showLineNumbers;

  /// Styling for the line-number gutter: the numbers' color and scale, the gap
  /// between the gutter and the code, and an optional divider. Only used when
  /// [showLineNumbers] is `true`.
  final GutterStyle gutterStyle;

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
    // Re-measure the gutter after fonts finish loading. Like ShikiCodeListView,
    // the gutter is sized from a build-time TextPainter; on web the bundled
    // monospace font loads asynchronously, so the first measurement uses a
    // fallback whose metrics differ. Text relayouts on this signal on its own,
    // but our manual measurement does not, so we listen and rebuild.
    PaintingBinding.instance.systemFonts.addListener(_onSystemFontsChanged);
    if (_asyncEffective) {
      _resolver.resolve(widget.highlighter, widget.code, _options);
    }
  }

  void _onSystemFontsChanged() {
    if (mounted) setState(() {});
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
    PaintingBinding.instance.systemFonts.removeListener(_onSystemFontsChanged);
    _resolver.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.textStyle ?? const TextStyle(fontFamily: 'monospace');
    final registration = widget.highlighter.getThemeRegistration(widget.theme);
    final fg = parseColor(registration.fg);
    final bg = widget.paintBackground ? parseColor(registration.bg) : null;
    final effectiveBase = base.copyWith(color: fg);

    final TextSpan span;
    if (!_asyncEffective) {
      // Synchronous path: unchanged behavior (codeToTextSpan bakes in the fg).
      span = codeToTextSpan(
        widget.highlighter,
        widget.code,
        lang: widget.lang,
        theme: widget.theme,
        baseStyle: base,
      );
    } else {
      final tokens = _resolver.tokens;
      span = tokens != null
          ? tokensToTextSpan(tokens, baseStyle: effectiveBase)
          // Placeholder: the same code in the theme's base color.
          : TextSpan(text: widget.code, style: effectiveBase);
    }

    if (widget.showLineNumbers) {
      return _buildWithGutter(context, span, effectiveBase, fg, bg);
    }

    // Default: the whole document as one Text.rich in a horizontal scroller.
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

  /// The line-number variant: keep the code as one [Text.rich] (with a forced
  /// uniform strut so rows align) and place a fixed gutter column beside it.
  Widget _buildWithGutter(
    BuildContext context,
    TextSpan span,
    TextStyle effectiveBase,
    Color? fg,
    Color? bg,
  ) {
    final textDirection = Directionality.of(context);
    final textScaler = widget.textScaler ?? MediaQuery.textScalerOf(context);
    final strut = StrutStyle.fromTextStyle(effectiveBase, forceStrutHeight: true);
    final metrics = measureGutter(effectiveBase, strut, textScaler);
    final pad = widget.padding.resolve(textDirection);

    // The code stays one Text.rich; the strut forces each line to the measured
    // row height so the fixed numbers column lines up. It scrolls horizontally
    // inside the row; the gutter sits outside the scroller and stays fixed.
    final codeColumn = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsets.only(right: pad.right),
        child: Text.rich(
          span,
          textScaler: textScaler,
          softWrap: false,
          strutStyle: strut,
        ),
      ),
    );

    Widget content = buildGutterRow(
      context: context,
      codeColumn: codeColumn,
      showLineNumbers: true,
      lineCount: splitLines(widget.code).length,
      metrics: metrics,
      effectiveBase: effectiveBase,
      strut: strut,
      textScaler: textScaler,
      fg: fg,
      gutterStyle: widget.gutterStyle,
      padding: pad,
      // ShikiCodeView never scrolls vertically, so the gutter is a full column.
      windowed: false,
    );

    if (bg != null) {
      content = ColoredBox(color: bg, child: content);
    }

    if (widget.selectable && SelectionContainer.maybeOf(context) == null) {
      content = SelectionArea(child: content);
    }
    return content;
  }
}
