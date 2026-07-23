import 'package:flutter/material.dart';

import '../async/async_token_resolver.dart';
import '../core/code_language.dart';
import '../core/highlighter.dart';
import '../core/shiki_theme.dart';
import 'gutter.dart';
import 'render_cache.dart';

/// @docImport 'code_view.dart';
/// @docImport 'code_list_view.dart';
/// A base widget for Shiki code views. It handles theme resolution, language loading, and async tokenization.
/// Use this with [ShikiStateMixin] on the widget's state to manage the async tokenization and theme resolution.
/// The concrete widget should implement the build method to render the highlighted code.
///
/// See [ShikiCodeView].
/// See [ShikiCodeListView].
abstract class ShikiBaseWidget extends StatefulWidget {
  /// Creates a Shiki code widget. [code] and [lang] are required; every other
  /// parameter has a documented default or falls back to the global
  /// [ShikiHighlighter.config].
  const ShikiBaseWidget({
    super.key,
    this.highlighter,
    required this.code,
    required this.lang,
    this.theme,
    this.brightness,
    this.textStyle,
    this.padding = const EdgeInsets.all(16),
    this.paintBackground = true,
    this.selectable = false,
    this.textScaler,
    this.showLineNumbers = false,
    this.gutterStyle = const GutterStyle(),
    this.async,
    this.selectionColor,
  });

  /// The highlighter to render with. Optional: when null, the widget uses the
  /// shared default (`ShikiHighlighter.config.defaultHighlighter`, or a
  /// lazily-created instance). The language and resolved theme are loaded into it
  /// on demand, so no pre-loading is required.
  final ShikiHighlighter? highlighter;

  /// The code to highlight. It is tokenized on demand, then cached for later rebuilds.
  final String code;

  /// The language to highlight [code] as. Loaded into [highlighter] on demand.
  final CodeLanguage lang;

  /// The theme(s) to render with: a single theme or a light/dark pair. When
  /// null, falls back to the global `ShikiHighlighter.config.defaultTheme`; if both are
  /// null a [ShikiError] is thrown.
  final ShikiThemeBase? theme;

  /// Overrides the brightness used to pick a [ShikiDualTheme] theme. When
  /// null, the ambient `Theme.of(context).brightness` is used.
  final Brightness? brightness;

  /// Base text style. A monospace `fontFamily` is recommended.
  final TextStyle? textStyle;

  /// Padding around the code.
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

  /// Optional text scaling factor for the code. When null, the ambient
  /// text scaling factor is used.
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

  /// Overrides the global `ShikiHighlighter.config.async` default for this widget.
  /// When null, the global default applies.
  final bool? async;

  /// Highlight color for selected code. Defaults to the ambient selection color
  /// (e.g. the app theme's [TextSelectionThemeData.selectionColor]).
  ///
  /// Applies whether selection is driven by this widget's own [SelectionArea]
  /// (see [selectable]) or by an enclosing one, since the code is wrapped in a
  /// [DefaultSelectionStyle] the selectable rows read from. The line-number
  /// gutter is excluded from selection and unaffected.
  final Color? selectionColor;
}

/// Shared [State] behavior for [ShikiBaseWidget] subclasses: theme
/// resolution against the ambient brightness, on-demand language/theme
/// loading, and driving [AsyncTokenResolver] to (re)tokenize the code.
///
/// Mix this into a widget's [State] alongside [ShikiBaseWidget] and call the
/// `@protected` members from `build`.
mixin ShikiStateMixin<W extends ShikiBaseWidget> on State<W> {
  /// Drives synchronous/async tokenization and caches the result, rebuilding
  /// this state (via its callback) when the tokens for the current inputs
  /// become available.
  late final AsyncTokenResolver resolver = AsyncTokenResolver(() {
    if (mounted) setState(() {});
  });

  // Per-build memoization (see render_cache.dart). Each recomputes only when its
  // real inputs change; unchanged rebuilds (resize, ancestor rebuilds) reuse them.
  /// Caches gutter measurements ([GutterMetrics]) across rebuilds.
  @protected
  final MetricsCache metrics = MetricsCache();

  // Per-build memoization (see render_cache.dart). Each recomputes only when its
  // real inputs change; unchanged rebuilds (resize, ancestor rebuilds) reuse them.
  /// Caches the number of lines in the code across rebuilds.
  @protected
  final Memoized<String, int> lineCount = Memoized();

  /// The highlighter this widget renders with: its own
  /// [ShikiBaseWidget.highlighter], or the shared default
  /// ([ShikiHighlighter.effectiveDefault]) when none was given.
  @protected
  ShikiHighlighter get effectiveHighlighter =>
      widget.highlighter ?? ShikiHighlighter.effectiveDefault;

  /// Whether this widget tokenizes asynchronously: [ShikiBaseWidget.async]
  /// when set, otherwise the global `ShikiHighlighter.config.async` default.
  @protected
  bool get asyncEffective => widget.async ?? ShikiHighlighter.config.async;

  /// The concrete theme resolved from [ShikiCodeView.theme] (or the global
  /// default) and the ambient brightness; set in [didChangeDependencies].
  @protected
  ShikiTheme? resolvedTheme;

  /// The [TokenizeOptions] for the current widget: [ShikiBaseWidget.lang] and
  /// [resolvedTheme]. Only valid after [resolveTheme] has run.
  @protected
  TokenizeOptions get options =>
      TokenizeOptions(lang: widget.lang.id, theme: resolvedTheme!.id);

  /// Resolves the theme for the current brightness, loads the language and theme
  /// into the highlighter on demand, then (re)kicks tokenization.
  void _resolveAndKick() {
    resolveTheme();
    resolveLanguage();
  }

  /// Resolves [ShikiBaseWidget.theme] (or the global default) against the
  /// current brightness into [resolvedTheme], and ensures it is loaded into
  /// [effectiveHighlighter]. Throws [ShikiError] when no theme is available.
  @protected
  void resolveTheme() {
    final theme = widget.theme ?? ShikiHighlighter.config.defaultTheme;
    if (theme == null) {
      throw ShikiError(
        'No theme to render with: pass a `theme:` to the widget or set '
        'ShikiHighlighter.config.defaultTheme.',
      );
    }
    final isDark = (widget.brightness ?? Theme.brightnessOf(context)) == .dark;
    resolvedTheme = theme.resolve(isDark: isDark);
    effectiveHighlighter.ensureShikiTheme(resolvedTheme!);
  }

  /// Ensures [ShikiBaseWidget.lang] is loaded into [effectiveHighlighter],
  /// then kicks off (or reuses cached) tokenization via [resolver].
  @protected
  void resolveLanguage() {
    effectiveHighlighter.ensureLanguage(widget.lang);
    resolver.resolve(
      effectiveHighlighter,
      widget.code,
      options,
      async: asyncEffective,
    );
  }

  @override
  void initState() {
    super.initState();
    // Re-measure the gutter after fonts finish loading. Like ShikiCodeListView,
    // the gutter is sized from a build-time TextPainter; on web the bundled
    // monospace font loads asynchronously, so the first measurement uses a
    // fallback whose metrics differ. Text relayouts on this signal on its own,
    // but our manual measurement does not, so we listen and rebuild.
    PaintingBinding.instance.systemFonts.addListener(onSystemFontsChanged);
  }

  /// Called when the system fonts finish loading, to rebuild with the
  /// now-accurate gutter measurements. Override to react to font changes, but
  /// call `super.onSystemFontsChanged()`.
  @protected
  @mustCallSuper
  void onSystemFontsChanged() {
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
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolveAndKick();
  }

  @override
  void dispose() {
    PaintingBinding.instance.systemFonts.removeListener(onSystemFontsChanged);
    resolver.dispose();
    super.dispose();
  }
}
