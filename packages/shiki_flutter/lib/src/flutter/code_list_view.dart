// A virtualized widget for displaying large highlighted files line-by-line.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../async/async_token_resolver.dart';
import '../core/colors.dart';
import '../core/highlighter.dart';
import 'render.dart';

/// Displays [code] highlighted with [lang]/[theme], rendering **one line per
/// row** via a lazily-built [ListView] so large files stay smooth.
///
/// Unlike [ShikiCodeView] — which builds the entire document as a single
/// `Text.rich` — this widget renders one line per row. In the default
/// scrollable mode it only lays out and paints the rows currently on screen, so
/// large files stay smooth. The code is still tokenized eagerly in one pass (a
/// line's highlighting can depend on earlier lines); only rendering is lazy.
///
/// ## Layout modes
/// * **Scrollable (default)** — the widget fills its parent and scrolls
///   vertically. It therefore needs a *bounded height* (e.g. inside an
///   [Expanded], a [SizedBox], or a route body), exactly like any [ListView].
///   This is the virtualized mode.
/// * **Shrink-wrap** — set [shrinkWrap] `true` (usually with
///   [physics] = `NeverScrollableScrollPhysics()`) to grow to fit its content
///   and let an outer scroll view drive it. Note this lays out *all* rows up
///   front (Flutter builds every child to measure the total height), so it is
///   not virtualized — reserve it for small inline blocks.
///
/// Long lines scroll horizontally (unless [softWrap] is `true`). The horizontal
/// extent is derived from the widest line assuming a **monospace** font — the
/// font [ShikiCodeView] already recommends; use [softWrap] for proportional
/// fonts.
///
/// When [showLineNumbers] is `true`, a line-number gutter is painted to the
/// left. The gutter stays fixed while the code scrolls horizontally, stays
/// virtualized while scrolling vertically, and is excluded from text selection.
class ShikiCodeListView extends StatefulWidget {
  const ShikiCodeListView({
    super.key,
    required this.highlighter,
    required this.code,
    required this.lang,
    required this.theme,
    this.lines,
    this.textStyle,
    this.padding = const EdgeInsets.all(16),
    this.paintBackground = true,
    this.textScaler,
    this.softWrap = false,
    this.showLineNumbers = false,
    this.lineNumberColor,
    this.shrinkWrap = false,
    this.physics,
    this.controller,
    this.async,
  }) : assert(
          !(showLineNumbers && softWrap),
          'showLineNumbers requires softWrap: false — wrapped lines cannot '
          'align with a fixed-height line-number gutter.',
        );

  final ShikiHighlighter highlighter;
  final String code;
  final String lang;
  final String theme;

  /// Pre-highlighted spans (from [codeToLineSpans]) to render instead of
  /// tokenizing [code] on every build. Supply this to cache or post-process
  /// highlighting yourself. When set, build it with the same [textStyle] passed
  /// here so line heights stay aligned; [highlighter]/[theme] are still used for
  /// the background and default line-number color, and [code] for the
  /// horizontal extent.
  final List<List<TextSpan>>? lines;

  /// Base text style. A monospace `fontFamily` is recommended.
  final TextStyle? textStyle;

  final EdgeInsetsGeometry padding;

  /// Whether to paint the theme's background color behind the code.
  final bool paintBackground;

  final TextScaler? textScaler;

  /// Wrap long lines instead of scrolling horizontally. Incompatible with
  /// [showLineNumbers].
  final bool softWrap;

  /// Show a line-number gutter to the left of the code.
  final bool showLineNumbers;

  /// Color for the line numbers. Defaults to the theme foreground at low
  /// opacity.
  final Color? lineNumberColor;

  /// Grow to fit content rather than filling (and scrolling within) the parent.
  final bool shrinkWrap;

  final ScrollPhysics? physics;

  /// Vertical scroll controller for the code list. One is created internally
  /// when omitted.
  final ScrollController? controller;

  /// Overrides the global [ShikiHighlighter.asyncDefault] default for this widget. When
  /// null the global default applies. Ignored when [lines] is supplied (the
  /// caller has already produced the spans).
  final bool? async;

  @override
  State<ShikiCodeListView> createState() => _ShikiCodeListViewState();
}

class _ShikiCodeListViewState extends State<ShikiCodeListView> {
  ScrollController? _internalController;

  late final AsyncTokenResolver _resolver =
      AsyncTokenResolver(() => setState(() {}));

  ScrollController get _controller =>
      widget.controller ?? (_internalController ??= ScrollController());

  /// Async is active only when enabled and the caller hasn't already supplied
  /// pre-highlighted [lines].
  bool get _asyncEffective =>
      widget.lines == null && (widget.async ?? ShikiHighlighter.asyncDefault);

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
  void didUpdateWidget(ShikiCodeListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the caller stopped supplying a controller (or supplied one), drop the
    // internal one we may have created so we don't leak or double-drive it.
    if (widget.controller != null && _internalController != null) {
      _internalController!.dispose();
      _internalController = null;
    }
    if (_asyncEffective) {
      _resolver.resolve(widget.highlighter, widget.code, _options);
    }
  }

  @override
  void dispose() {
    _resolver.dispose();
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    final textScaler = widget.textScaler ?? MediaQuery.textScalerOf(context);
    final base = widget.textStyle ?? const TextStyle(fontFamily: 'monospace');

    final registration = widget.highlighter.getThemeRegistration(widget.theme);
    final fg = parseColor(registration.fg);
    final effectiveBase = base.copyWith(color: fg);

    // Reuse the already-resolved effectiveBase rather than letting
    // codeToLineSpans re-resolve the theme foreground — this both avoids the
    // duplicate lookup and guarantees the gutter/strut and the code share one
    // base style.
    final List<List<TextSpan>> lines;
    if (widget.lines != null) {
      lines = widget.lines!;
    } else if (!_asyncEffective) {
      // Synchronous path — unchanged behavior.
      lines = tokensToLineSpans(
        widget.highlighter.codeToTokens(widget.code, _options),
        baseStyle: effectiveBase,
      );
    } else {
      final tokens = _resolver.tokens;
      lines = tokens != null
          ? tokensToLineSpans(tokens, baseStyle: effectiveBase)
          // Placeholder: one plain span per line in the theme's base color,
          // preserving the line count (and thus height) so nothing jumps when
          // the highlighted result swaps in.
          : [
              for (final line in splitLines(widget.code))
                [TextSpan(text: line.content, style: effectiveBase)],
            ];
    }

    final strut = StrutStyle.fromTextStyle(effectiveBase, forceStrutHeight: true);
    final metrics = _measure(effectiveBase, strut, textScaler);
    final pad = widget.padding.resolve(textDirection);

    Widget rowFor(int i) => Text.rich(
          lineToTextSpan(lines[i]),
          textScaler: textScaler,
          softWrap: widget.softWrap,
          maxLines: widget.softWrap ? null : 1,
          strutStyle: strut,
        );

    final codeList = ListView.builder(
      controller: _controller,
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      padding: EdgeInsets.zero,
      itemExtent: widget.softWrap ? null : metrics.rowHeight,
      itemCount: lines.length,
      itemBuilder: (context, i) => rowFor(i),
    );

    // The code column: either wrapping (fills width) or in a horizontal
    // scroller sized to the widest line so long lines never wrap.
    final Widget codeArea;
    if (widget.softWrap) {
      codeArea = Padding(
        padding: EdgeInsets.only(right: pad.right),
        child: codeList,
      );
    } else {
      final contentWidth = (_maxLineLength(widget.code) + 1) * metrics.charWidth;
      codeArea = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: EdgeInsets.only(right: pad.right),
          child: SizedBox(width: contentWidth, child: codeList),
        ),
      );
    }

    final children = <Widget>[];
    if (widget.showLineNumbers) {
      final digits = lines.length.toString().length;
      final numberColor = widget.lineNumberColor ??
          (fg ?? const Color(0xFF808080)).withValues(alpha: 0.4);
      children.add(_LineNumberGutter(
        controller: _controller,
        lineCount: lines.length,
        rowHeight: metrics.rowHeight,
        width: digits * metrics.charWidth,
        style: effectiveBase.copyWith(color: numberColor),
        textScaler: textScaler,
        strut: strut,
        windowed: !widget.shrinkWrap,
      ));
      children.add(SizedBox(width: metrics.charWidth * 2));
    }
    children.add(Expanded(child: codeArea));

    Widget content = Padding(
      padding: EdgeInsets.only(top: pad.top, bottom: pad.bottom, left: pad.left),
      child: Row(
        // Stretch the gutter to the viewport height so it can window its
        // numbers; in shrink-wrap mode there is no viewport to fill.
        crossAxisAlignment: widget.shrinkWrap
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.stretch,
        children: children,
      ),
    );

    if (widget.paintBackground) {
      final bg = parseColor(registration.bg);
      if (bg != null) content = ColoredBox(color: bg, child: content);
    }
    return content;
  }

  /// Measures the monospace advance width and the line height for [style],
  /// under the same strut and scaler used to paint rows, so the gutter and the
  /// [ListView.itemExtent] line up exactly with the rendered text.
  _Metrics _measure(TextStyle style, StrutStyle strut, TextScaler textScaler) {
    final painter = TextPainter(
      text: TextSpan(text: '0' * 10, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      strutStyle: strut,
    )..layout();
    final metrics = _Metrics(
      rowHeight: painter.height,
      charWidth: painter.width / 10,
    );
    painter.dispose();
    return metrics;
  }
}

class _Metrics {
  const _Metrics({required this.rowHeight, required this.charWidth});
  final double rowHeight;
  final double charWidth;
}

/// The line-number gutter. Frozen against horizontal scroll (it lives outside
/// the code's horizontal scroller) and synced to the code's vertical scroll by
/// reading [controller]'s offset — while staying virtualized when [windowed].
class _LineNumberGutter extends StatelessWidget {
  const _LineNumberGutter({
    required this.controller,
    required this.lineCount,
    required this.rowHeight,
    required this.width,
    required this.style,
    required this.textScaler,
    required this.strut,
    required this.windowed,
  });

  final ScrollController controller;
  final int lineCount;
  final double rowHeight;
  final double width;
  final TextStyle style;
  final TextScaler textScaler;
  final StrutStyle strut;
  final bool windowed;

  Widget _label(int index) => Text(
        '${index + 1}',
        style: style,
        textScaler: textScaler,
        strutStyle: strut,
        maxLines: 1,
        textAlign: TextAlign.right,
      );

  /// Every line number stacked in a column — used in shrink-wrap mode (no
  /// viewport to window against) and as the unbounded-height fallback.
  Widget _column() => SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < lineCount; i++)
              SizedBox(
                height: rowHeight,
                child: Align(alignment: Alignment.centerRight, child: _label(i)),
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final Widget gutter;
    if (!windowed) {
      gutter = _column();
    } else {
      gutter = SizedBox(
        width: width,
        child: ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Scrollable mode expects a bounded height (like any ListView). If
              // handed an unbounded height, windowing would call .ceil() on
              // infinity and throw a cryptic error; lay out every number instead
              // and let the code list surface Flutter's clearer viewport error.
              if (!constraints.maxHeight.isFinite || rowHeight <= 0) {
                return _column();
              }
              return AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final offset =
                      controller.hasClients ? controller.offset : 0.0;
                  final first =
                      (offset / rowHeight).floor().clamp(0, lineCount);
                  final visible = (constraints.maxHeight / rowHeight).ceil() + 1;
                  final last = math.min(lineCount, first + visible);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var i = first; i < last; i++)
                        Positioned(
                          top: i * rowHeight - offset,
                          left: 0,
                          width: width,
                          height: rowHeight,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _label(i),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      );
    }
    // Never let line numbers land in a copied selection.
    return SelectionContainer.disabled(child: gutter);
  }
}

/// The largest line length (in UTF-16 code units) in [code], for sizing the
/// horizontal scroll extent. A trailing `\r` on CRLF lines is counted, which
/// only adds a harmless one-character slack.
int _maxLineLength(String code) {
  var max = 0;
  var start = 0;
  for (var i = 0; i < code.length; i++) {
    if (code.codeUnitAt(i) == 0x0A) {
      final len = i - start;
      if (len > max) max = len;
      start = i + 1;
    }
  }
  final len = code.length - start;
  if (len > max) max = len;
  return max;
}
