// A virtualized widget for displaying large highlighted files line-by-line.

import 'package:flutter/material.dart' show SelectionArea;
import 'package:flutter/widgets.dart';
import 'package:shiki_flutter/src/flutter/base.dart';

import '../core/code_language.dart';
import '../core/colors.dart';
import 'gutter.dart';
import 'render.dart';
import 'render_cache.dart';

/// Displays [code] highlighted with [lang]/[theme], rendering **one line per
/// row** via a lazily-built [ListView] so large files stay smooth.
///
/// Like [ShikiCodeView], [lang] and [theme] are objects ([CodeLanguage] and
/// [ShikiThemeConfig]) loaded into the [highlighter] on demand; [theme] falls
/// back to `ShikiHighlighter.config.defaultTheme` when omitted, and a
/// [ShikiThemeConfig.dual] pair is resolved from `Theme.of(context)` brightness
/// (override via [brightness]).
///
/// Unlike [ShikiCodeView], which builds the entire document as a single
/// `Text.rich`, this widget renders one line per row. In the default
/// scrollable mode it only lays out and paints the rows currently on screen, so
/// large files stay smooth. The code is still tokenized eagerly in one pass (a
/// line's highlighting can depend on earlier lines); only rendering is lazy.
///
/// ## Layout modes
/// * **Scrollable (default)**: the widget fills its parent and scrolls
///   vertically. It therefore needs a *bounded height* (e.g. inside an
///   [Expanded], a [SizedBox], or a route body), exactly like any [ListView].
///   This is the virtualized mode.
/// * **Shrink-wrap**: set [shrinkWrap] `true` (usually with
///   [physics] = `NeverScrollableScrollPhysics()`) to grow to fit its content
///   and let an outer scroll view drive it. Note this lays out *all* rows up
///   front (Flutter builds every child to measure the total height), so it is
///   not virtualized. Reserve it for small inline blocks.
///
/// Long lines scroll horizontally (unless [softWrap] is `true`). The horizontal
/// extent is derived from the widest line assuming a **monospace** font, the
/// font [ShikiCodeView] already recommends; use [softWrap] for proportional
/// fonts.
///
/// When [showLineNumbers] is `true`, a line-number gutter is painted to the
/// left. The gutter stays fixed while the code scrolls horizontally, stays
/// virtualized while scrolling vertically, and is excluded from text selection.
///
/// Set [selectable] to `true` to let users select and copy the code; it wraps
/// the widget in a [SelectionArea], unless an ancestor already provides one.
/// Selection spans all lines, but because the list is virtualized only the rows
/// currently built participate. Off-screen lines become selectable as they
/// scroll into view.
///
/// Style the line-number gutter (gap and divider) with [gutterStyle].
class ShikiCodeListView extends ShikiBaseWidget {
  const ShikiCodeListView({
    super.key,
    required super.highlighter,
    required super.code,
    required super.lang,
    super.theme,
    super.brightness,
    super.textStyle,
    super.padding = const EdgeInsets.all(16),
    super.paintBackground = true,
    super.selectable = false,
    super.selectionColor,
    super.textScaler,
    super.showLineNumbers = false,
    super.gutterStyle = const GutterStyle(),
    super.async,
    // Specific to ListView.
    this.lines,
    this.softWrap = false,
    this.shrinkWrap = false,
    this.physics,
    this.controller,
  }) : assert(
         !(showLineNumbers && softWrap),
         'showLineNumbers requires softWrap: false. Wrapped lines cannot '
         'align with a fixed-height line-number gutter.',
       );

  /// Pre-highlighted spans (from [codeToLineSpans]) to render instead of
  /// tokenizing [code] on every build. Supply this to cache or post-process
  /// highlighting yourself. When set, build it with the same [textStyle] passed
  /// here so line heights stay aligned; [highlighter]/[theme] are still used for
  /// the background and default line-number color, and [code] for the
  /// horizontal extent.
  final List<List<TextSpan>>? lines;

  /// Wrap long lines instead of scrolling horizontally. Incompatible with
  /// [showLineNumbers].
  final bool softWrap;

  /// Grow to fit content rather than filling (and scrolling within) the parent.
  final bool shrinkWrap;

  final ScrollPhysics? physics;

  /// Vertical scroll controller for the code list. One is created internally
  /// when omitted.
  final ScrollController? controller;

  @override
  State<ShikiCodeListView> createState() => _ShikiCodeListViewState();
}

class _ShikiCodeListViewState extends State<ShikiCodeListView> with ShikiStateMixin<ShikiCodeListView> {
  ScrollController? _internalController;

  final Memoized<String, int> _maxLen = Memoized();
  final RenderMemo<List<List<InlineSpan>>> _spanMemo = RenderMemo();

  ScrollController get _controller => widget.controller ?? (_internalController ??= ScrollController());

  @override
  void resolveLanguage() {
    if (widget.lines != null) return;
    super.resolveLanguage();
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
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    final textScaler = widget.textScaler ?? MediaQuery.textScalerOf(context);
    final base = widget.textStyle ?? const TextStyle(fontFamily: 'monospace');

    final registration = widget.highlighter.getThemeRegistration(
      resolvedTheme!.id,
    );
    final fg = parseColor(registration.fg);
    final effectiveBase = base.copyWith(color: fg);

    // Reuse the already-resolved effectiveBase rather than letting
    // codeToLineSpans re-resolve the theme foreground: this both avoids the
    // duplicate lookup and guarantees the gutter/strut and the code share one
    // base style.
    //
    // Pre-highlighted lines are the final artifact and bypass everything. Otherwise
    // tokens come from the shared resolver (sync-memoized or async-resolved) and the
    // spans are memoized on (tokens identity, effectiveBase), so an unchanged
    // rebuild reuses them and neither re-tokenizes nor rebuilds any TextSpan.
    final List<List<InlineSpan>> lines =
        widget.lines ??
        _spanMemo.resolve(
          tokens: resolver.tokens,
          code: widget.code,
          base: effectiveBase,
          render: (tokens, b) => tokensToLineSpans(tokens, baseStyle: b),
          // Placeholder: one plain span per line in the theme's base color,
          // preserving the line count (and thus height) so nothing jumps when
          // the highlighted result swaps in.
          placeholder: (code, b) => [
            for (final line in splitLines(code)) [TextSpan(text: line.content, style: b)],
          ],
        );

    final strut = StrutStyle.fromTextStyle(
      effectiveBase,
      forceStrutHeight: true,
    );
    final gutterMetrics = metrics.measure(effectiveBase, strut, textScaler);
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
      itemExtent: widget.softWrap ? null : gutterMetrics.rowHeight,
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
      final maxLen = _maxLen.of(widget.code, () => _maxLineLength(widget.code));
      final contentWidth = (maxLen + 1) * gutterMetrics.charWidth;
      codeArea = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: EdgeInsets.only(right: pad.right),
          child: SizedBox(width: contentWidth, child: codeList),
        ),
      );
    }

    Widget content = buildGutterRow(
      context: context,
      codeColumn: codeArea,
      showLineNumbers: widget.showLineNumbers,
      lineCount: lines.length,
      metrics: gutterMetrics,
      effectiveBase: effectiveBase,
      strut: strut,
      textScaler: textScaler,
      fg: fg,
      gutterStyle: widget.gutterStyle,
      padding: pad,
      metricsCache: metrics,
      // Scrollable mode virtualizes the gutter against the shared controller;
      // shrink-wrap mode lays out every number.
      windowed: !widget.shrinkWrap,
      controller: _controller,
    );

    if (widget.paintBackground) {
      final bg = parseColor(registration.bg);
      if (bg != null) content = ColoredBox(color: bg, child: content);
    }

    // Set the selection color for the code rows below. Keep this inside any
    // SelectionArea (ours or an ancestor's) so the selectable rows read it.
    if (widget.selectionColor != null) {
      content = DefaultSelectionStyle(
        selectionColor: widget.selectionColor,
        child: content,
      );
    }

    // Only add our own SelectionArea when asked to and when there isn't one
    // already above us, so an enclosing SelectionArea keeps driving selection.
    if (widget.selectable && SelectionContainer.maybeOf(context) == null) {
      content = SelectionArea(child: content);
    }
    return content;
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
