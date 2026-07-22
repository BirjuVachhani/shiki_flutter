// A ready-to-use widget for displaying highlighted code.

import 'package:flutter/material.dart' show SelectionArea;
import 'package:flutter/widgets.dart';
import 'base.dart';

import '../core/code_language.dart';
import '../core/colors.dart';
import 'gutter.dart';
import 'render.dart';
import 'render_cache.dart';

/// Displays [code] highlighted with the given [lang] and [theme].
///
/// [lang] is a [CodeLanguage] and [theme] is a single `ShikiTheme` or a
/// `ShikiDualTheme` light/dark pair; the widget loads them into the
/// [highlighter] on demand, so no pre-loading is required. When [theme] is
/// omitted it falls back to the global `ShikiHighlighter.config.defaultTheme`,
/// throwing a `ShikiError` if that is also unset. A dual pair is resolved from
/// the ambient `Theme.of(context)` brightness (override it with [brightness]).
/// The widget paints the resolved theme's background color behind the code and
/// applies its foreground as the default text color.
///
/// When [async] highlighting is active (see `ShikiHighlighter.config.async`), the code
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
class ShikiCodeView extends ShikiBaseWidget {
  const ShikiCodeView({
    super.key,
    super.highlighter,
    required super.code,
    required super.lang,
    super.theme,
    super.brightness,
    super.textStyle,
    super.padding = const EdgeInsets.all(16),
    super.paintBackground = true,
    super.selectable = false,
    super.textScaler,
    super.showLineNumbers = false,
    super.gutterStyle = const GutterStyle(),
    super.async,
  });

  @override
  State<ShikiCodeView> createState() => _ShikiCodeViewState();
}

class _ShikiCodeViewState extends State<ShikiCodeView>
    with ShikiStateMixin<ShikiCodeView> {
  // Per-build memoization (see render_cache.dart). Each recomputes only when its
  // real inputs change; unchanged rebuilds (resize, ancestor rebuilds) reuse them.
  @protected
  final RenderMemo<InlineSpan> _spanMemo = RenderMemo();

  @override
  Widget build(BuildContext context) {
    final base = widget.textStyle ?? const TextStyle(fontFamily: 'monospace');
    final registration = effectiveHighlighter.getThemeRegistration(
      resolvedTheme!.id,
    );
    final fg = parseColor(registration.fg);
    final bg = widget.paintBackground ? parseColor(registration.bg) : null;
    final effectiveBase = base.copyWith(color: fg);

    // Tokens come from the shared resolver (sync-memoized or async-resolved); the
    // span is memoized on (tokens identity, effectiveBase), so an unchanged
    // rebuild reuses it and neither re-tokenizes nor rebuilds any TextSpan. The
    // sync path is byte-for-byte the old codeToTextSpan(baseStyle: base), which
    // bakes the same fg into effectiveBase.
    final span = _spanMemo.resolve(
      tokens: resolver.tokens,
      code: widget.code,
      base: effectiveBase,
      render: (tokens, b) => tokensToTextSpan(tokens, baseStyle: b),
      // Placeholder: the same code in the theme's base color.
      placeholder: (code, b) => TextSpan(text: code, style: b),
    );

    if (widget.showLineNumbers) {
      return _buildWithGutter(context, span, effectiveBase, fg, bg);
    }

    // Default: the whole document as one Text.rich in a horizontal scroller.
    Widget child = Padding(
      padding: widget.padding,
      child: Text.rich(span, textScaler: widget.textScaler, softWrap: false),
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
    InlineSpan span,
    TextStyle effectiveBase,
    Color? fg,
    Color? bg,
  ) {
    final textDirection = Directionality.of(context);
    final textScaler = widget.textScaler ?? MediaQuery.textScalerOf(context);
    final strut = StrutStyle.fromTextStyle(
      effectiveBase,
      forceStrutHeight: true,
    );
    final gutterMetrics = metrics.measure(effectiveBase, strut, textScaler);
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
      lineCount: lineCount.of(
        widget.code,
        () => splitLines(widget.code).length,
      ),
      metrics: gutterMetrics,
      effectiveBase: effectiveBase,
      strut: strut,
      textScaler: textScaler,
      fg: fg,
      gutterStyle: widget.gutterStyle,
      padding: pad,
      metricsCache: metrics,
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
