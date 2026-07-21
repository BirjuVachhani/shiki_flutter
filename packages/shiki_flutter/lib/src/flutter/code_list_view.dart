// A virtualized widget for displaying large highlighted files line-by-line.

import 'package:flutter/material.dart' show SelectionArea, Theme;
import 'package:flutter/widgets.dart';

import '../async/async_token_resolver.dart';
import '../core/code_language.dart';
import '../core/colors.dart';
import '../core/highlighter.dart';
import '../core/shiki_theme.dart';
import '../core/shiki_theme_config.dart';
import 'gutter.dart';
import 'render.dart';
import 'render_cache.dart';

/// Displays [code] highlighted with [lang]/[theme], rendering **one line per
/// row** via a lazily-built [ListView] so large files stay smooth.
///
/// Like [ShikiCodeView], [lang] and [theme] are objects ([CodeLanguage] and
/// [ShikiThemeConfig]) loaded into the [highlighter] on demand; [theme] falls
/// back to [ShikiHighlighter.defaultTheme] when omitted, and a
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
class ShikiCodeListView extends StatefulWidget {
  const ShikiCodeListView({
    super.key,
    required this.highlighter,
    required this.code,
    required this.lang,
    this.theme,
    this.brightness,
    this.lines,
    this.textStyle,
    this.padding = const EdgeInsets.all(16),
    this.paintBackground = true,
    this.selectable = false,
    this.selectionColor,
    this.textScaler,
    this.softWrap = false,
    this.showLineNumbers = false,
    this.gutterStyle = const GutterStyle(),
    this.shrinkWrap = false,
    this.physics,
    this.controller,
    this.async,
  }) : assert(
         !(showLineNumbers && softWrap),
         'showLineNumbers requires softWrap: false. Wrapped lines cannot '
         'align with a fixed-height line-number gutter.',
       );

  final ShikiHighlighter highlighter;
  final String code;

  /// The language to highlight [code] as. Loaded into [highlighter] on demand.
  final CodeLanguage lang;

  /// The theme(s) to render with: a single theme or a light/dark pair. When
  /// null, falls back to the global [ShikiHighlighter.defaultTheme]; if both are
  /// null a [ShikiError] is thrown.
  final ShikiThemeConfig? theme;

  /// Overrides the brightness used to pick a [ShikiThemeConfig.dual] theme. When
  /// null, the ambient `Theme.of(context).brightness` is used.
  final Brightness? brightness;

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

  /// Whether to make the code selectable by wrapping the widget in a
  /// [SelectionArea]. Defaults to `false`.
  ///
  /// When an ancestor already provides a selection registrar (e.g. the widget
  /// is inside another [SelectionArea]), this flag is ignored: the code is
  /// already selectable through that ancestor, and wrapping again would nest
  /// two selection contexts.
  final bool selectable;

  /// Highlight color for selected code. Defaults to the ambient selection color
  /// (e.g. the app theme's [TextSelectionThemeData.selectionColor]).
  ///
  /// Applies whether selection is driven by this widget's own [SelectionArea]
  /// (see [selectable]) or by an enclosing one, since the code is wrapped in a
  /// [DefaultSelectionStyle] the selectable rows read from. The line-number
  /// gutter is excluded from selection and unaffected.
  final Color? selectionColor;

  final TextScaler? textScaler;

  /// Wrap long lines instead of scrolling horizontally. Incompatible with
  /// [showLineNumbers].
  final bool softWrap;

  /// Show a line-number gutter to the left of the code.
  final bool showLineNumbers;

  /// Styling for the line-number gutter: the numbers' color and scale, the gap
  /// between the gutter and the code, and an optional divider. Only used when
  /// [showLineNumbers] is `true`.
  final GutterStyle gutterStyle;

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

  late final AsyncTokenResolver _resolver = AsyncTokenResolver(() {
    if (mounted) setState(() {});
  });

  // Per-build memoization (see render_cache.dart). Each recomputes only when its
  // real inputs change; unchanged rebuilds (resize, ancestor rebuilds) reuse them.
  final RenderMemo<List<List<TextSpan>>> _spanMemo = RenderMemo();
  final MetricsCache _metrics = MetricsCache();
  final Memoized<String, int> _maxLen = Memoized();

  ScrollController get _controller =>
      widget.controller ?? (_internalController ??= ScrollController());

  /// Async is active only when enabled and the caller hasn't already supplied
  /// pre-highlighted [lines].
  bool get _asyncEffective =>
      widget.lines == null && (widget.async ?? ShikiHighlighter.asyncDefault);

  /// The concrete theme resolved from [ShikiCodeListView.theme] (or the global
  /// default) and the ambient brightness; set in [didChangeDependencies].
  ShikiTheme? _resolvedTheme;

  TokenizeOptions get _options =>
      TokenizeOptions(lang: widget.lang.id, theme: _resolvedTheme!.id);

  /// Resolves the theme for the current brightness and loads it into the
  /// highlighter (always, since the theme drives the background/foreground even
  /// when [ShikiCodeListView.lines] is supplied). When we actually tokenize
  /// (no pre-highlighted lines), also loads the language and (re)kicks the
  /// resolver.
  void _resolveAndKick() {
    final config = widget.theme ?? ShikiHighlighter.defaultTheme;
    if (config == null) {
      throw ShikiError(
        'ShikiCodeListView has no theme: pass a `theme:` or set '
        'ShikiHighlighter.config.defaultTheme.',
      );
    }
    final isDark =
        (widget.brightness ?? Theme.of(context).brightness) == Brightness.dark;
    _resolvedTheme = config.resolve(isDark: isDark);
    widget.highlighter.ensureShikiTheme(_resolvedTheme!);
    if (widget.lines == null) {
      widget.highlighter.ensureLanguage(widget.lang);
      _resolver.resolve(
        widget.highlighter,
        widget.code,
        _options,
        async: _asyncEffective,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Re-measure when fonts finish loading. This widget sizes the gutter and
    // row height from a build-time TextPainter; on web the bundled monospace
    // font loads asynchronously, so the first measurement uses a fallback whose
    // metrics differ. Text widgets relayout on this signal on their own, but
    // our manual measurement does not, so we listen and rebuild.
    PaintingBinding.instance.systemFonts.addListener(_onSystemFontsChanged);
  }

  void _onSystemFontsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Runs after initState and whenever an inherited dependency changes — in
    // particular a `Theme` brightness flip, which does not trigger
    // didUpdateWidget. Re-resolving here keeps a dual theme in sync with it.
    _resolveAndKick();
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
    _resolveAndKick();
  }

  @override
  void dispose() {
    PaintingBinding.instance.systemFonts.removeListener(_onSystemFontsChanged);
    _resolver.dispose();
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    final textScaler = widget.textScaler ?? MediaQuery.textScalerOf(context);
    final base = widget.textStyle ?? const TextStyle(fontFamily: 'monospace');

    final registration = widget.highlighter.getThemeRegistration(
      _resolvedTheme!.id,
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
    final List<List<TextSpan>> lines =
        widget.lines ??
        _spanMemo.resolve(
          tokens: _resolver.tokens,
          code: widget.code,
          base: effectiveBase,
          render: (tokens, b) => tokensToLineSpans(tokens, baseStyle: b),
          // Placeholder: one plain span per line in the theme's base color,
          // preserving the line count (and thus height) so nothing jumps when
          // the highlighted result swaps in.
          placeholder: (code, b) => [
            for (final line in splitLines(code))
              [TextSpan(text: line.content, style: b)],
          ],
        );

    final strut = StrutStyle.fromTextStyle(
      effectiveBase,
      forceStrutHeight: true,
    );
    final metrics = _metrics.measure(effectiveBase, strut, textScaler);
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
      final maxLen = _maxLen.of(widget.code, () => _maxLineLength(widget.code));
      final contentWidth = (maxLen + 1) * metrics.charWidth;
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
      metrics: metrics,
      effectiveBase: effectiveBase,
      strut: strut,
      textScaler: textScaler,
      fg: fg,
      gutterStyle: widget.gutterStyle,
      padding: pad,
      metricsCache: _metrics,
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
