// Shared line-number gutter machinery: styling, measurement, the gutter widget,
// and the row composition used by both ShikiCodeView and ShikiCodeListView.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Styling for the line-number gutter: the numbers themselves, the gap between
/// the gutter and the code, and an optional divider between them.
///
/// Only used when a code widget's `showLineNumbers` is `true`.
class GutterStyle {
  const GutterStyle({
    this.spacing,
    this.dividerColor,
    this.dividerThickness = 1.0,
    this.textColor,
    this.textScale = 1.0,
  }) : assert(dividerThickness >= 0, 'dividerThickness must be non-negative.'),
       assert(textScale > 0, 'textScale must be greater than 0.');

  /// Horizontal gap between the gutter and the code, in logical pixels. When
  /// null, defaults to two character widths of the base text style, so the gap
  /// scales with the font size.
  final double? spacing;

  /// Color of the vertical divider drawn between the gutter and the code,
  /// centered in the [spacing] gap. When null, no divider is rendered.
  final Color? dividerColor;

  /// Thickness of the divider in logical pixels. Defaults to `1.0`. Ignored
  /// when [dividerColor] is null.
  final double dividerThickness;

  /// Color for the line numbers. Defaults to the theme foreground at low
  /// opacity.
  final Color? textColor;

  /// Scales the line-number font size relative to the code. Defaults to `1.0`
  /// (numbers match the code size).
  ///
  /// A value below `1.0` renders smaller numbers, e.g. `0.9`, matching the
  /// convention in editors where the gutter recedes behind the code. Numbers
  /// keep the code's baseline and row height, so they stay aligned; only the
  /// glyph size shrinks.
  final double textScale;
}

/// The monospace advance width and strut-forced line height for a text style,
/// measured under the same strut and scaler used to paint the code, so the
/// gutter and the code rows line up exactly.
class GutterMetrics {
  const GutterMetrics({required this.rowHeight, required this.charWidth});

  final double rowHeight;
  final double charWidth;
}

/// Measures the monospace advance width and the line height for [style] under
/// [strut] and [textScaler]. Assumes a monospace font (averages ten glyphs).
GutterMetrics measureGutter(
  TextStyle style,
  StrutStyle strut,
  TextScaler textScaler,
) {
  final painter = TextPainter(
    text: TextSpan(text: '0' * 10, style: style),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
    strutStyle: strut,
  )..layout();
  final metrics = GutterMetrics(
    rowHeight: painter.height,
    charWidth: painter.width / 10,
  );
  painter.dispose();
  return metrics;
}

/// Memoizes [measureGutter] results, keyed on the font-affecting inputs and the
/// scaler, so a code widget doesn't lay out a `TextPainter` on every build.
///
/// Measurement (row height, monospace advance) depends only on the style's font
/// fields and the [TextScaler] — **never on color** — so the key normalizes color
/// out: a theme, foreground, or any color-only change reuses the cached metrics.
/// The two live styles a widget measures (the code base style and, when the gutter
/// numbers are scaled, the smaller number style) differ in `fontSize`, so they get
/// distinct keys without any extra discriminator. Bounded to a few entries.
class MetricsCache {
  // Color is folded to a constant in the key; its value is irrelevant since it
  // never affects the measured result.
  static const Color _keyColor = Color(0xFF000000);

  final Map<Object, GutterMetrics> _cache = {};

  GutterMetrics measure(
    TextStyle style,
    StrutStyle strut,
    TextScaler textScaler,
  ) {
    final key = (style.copyWith(color: _keyColor), textScaler);
    final hit = _cache[key];
    if (hit != null) return hit;
    if (_cache.length >= 8) _cache.clear(); // bound; only a few live keys
    return _cache[key] = measureGutter(style, strut, textScaler);
  }
}

/// Composes the line-number gutter, the gap/divider, and the code column into a
/// row shared by both code widgets.
///
/// [codeColumn] is the code (a `ListView` area or a horizontally-scrolling
/// `Text.rich`) with its own right padding already applied. The top/bottom of
/// [padding] is split into the gutter and code columns (so a divider can run
/// edge to edge), and only the left is applied around the whole row.
///
/// [windowed] selects the virtualized gutter (synced to [controller], required
/// when windowed) with a viewport-stretched divider; when false, the gutter is
/// a full column and the divider gets an explicit height covering the padding.
/// Background and selection wrapping stay with the caller.
Widget buildGutterRow({
  required BuildContext context,
  required Widget codeColumn,
  required bool showLineNumbers,
  required int lineCount,
  required GutterMetrics metrics,
  required TextStyle effectiveBase,
  required StrutStyle strut,
  required TextScaler textScaler,
  required Color? fg,
  required GutterStyle gutterStyle,
  required EdgeInsets padding,
  required bool windowed,
  ScrollController? controller,
  MetricsCache? metricsCache,
}) {
  // Split the vertical padding into the gutter and code columns rather than
  // wrapping the whole row, so a gutter divider between them can run edge to
  // edge (into the top and bottom padding) instead of being inset by it.
  final vpad = EdgeInsets.only(top: padding.top, bottom: padding.bottom);

  final children = <Widget>[];
  if (showLineNumbers) {
    final digits = lineCount.toString().length;
    final numberColor =
        gutterStyle.textColor ??
        (fg ?? const Color(0xFF808080)).withValues(alpha: 0.4);
    // Line numbers may be rendered smaller than the code, but keep the code's
    // strut and row height so they share its baseline and stay row-aligned;
    // only the glyph size shrinks.
    final scale = gutterStyle.textScale;
    final baseFontSize =
        effectiveBase.fontSize ??
        DefaultTextStyle.of(context).style.fontSize ??
        14.0;
    final numberStyle = effectiveBase.copyWith(
      color: numberColor,
      fontSize: baseFontSize * scale,
    );
    // Size the gutter to the widest number plus a one-pixel guard. Sizing it to
    // exactly `digits * charWidth` leaves the label on a knife edge: web text
    // layout rounds line width up, pushing the last glyph past the box and, with
    // maxLines: 1, dropping it entirely, so multi-digit numbers rendered as just
    // their leading digit(s). Measure the gutter's own advance so a scaled-down
    // font still gets a snug box.
    final numberCharWidth = scale == 1.0
        ? metrics.charWidth
        : (metricsCache?.measure(numberStyle, strut, textScaler) ??
                  measureGutter(numberStyle, strut, textScaler))
              .charWidth;
    final gutterWidth = digits * numberCharWidth + 1;
    children.add(
      Padding(
        padding: vpad,
        child: LineNumberGutter(
          controller: controller,
          lineCount: lineCount,
          rowHeight: metrics.rowHeight,
          width: gutterWidth,
          style: numberStyle,
          textScaler: textScaler,
          strut: strut,
          windowed: windowed,
        ),
      ),
    );

    // The gap between gutter and code, with an optional divider centered in it.
    // The divider is not padded, so it runs the full column height. A windowed
    // (scrollable) row stretches it to the viewport; a non-windowed row
    // (crossAxisAlignment.start) does not, so give it the explicit height,
    // including the vertical padding it now spans.
    final spacing = gutterStyle.spacing ?? metrics.charWidth * 2;
    final dividerColor = gutterStyle.dividerColor;
    if (dividerColor == null) {
      children.add(SizedBox(width: spacing));
    } else {
      final dividerHeight = windowed
          ? null
          : padding.top + lineCount * metrics.rowHeight + padding.bottom;
      children.add(
        SizedBox(
          width: spacing,
          height: dividerHeight,
          child: Center(
            child: SizedBox(
              width: gutterStyle.dividerThickness,
              height: double.infinity,
              child: ColoredBox(color: dividerColor),
            ),
          ),
        ),
      );
    }
  }
  children.add(
    Expanded(
      child: Padding(padding: vpad, child: codeColumn),
    ),
  );

  return Padding(
    padding: EdgeInsets.only(left: padding.left),
    child: Row(
      // Stretch the gutter to the viewport height so it can window its numbers;
      // when not windowed there is no viewport to fill.
      crossAxisAlignment: windowed
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.start,
      children: children,
    ),
  );
}

/// The line-number gutter. Frozen against horizontal scroll (it lives outside
/// the code's horizontal scroller). When [windowed] it syncs to the code's
/// vertical scroll by reading [controller]'s offset and stays virtualized;
/// otherwise it lays out every number in a plain column.
class LineNumberGutter extends StatelessWidget {
  const LineNumberGutter({
    super.key,
    required this.controller,
    required this.lineCount,
    required this.rowHeight,
    required this.width,
    required this.style,
    required this.textScaler,
    required this.strut,
    required this.windowed,
  }) : assert(
         !windowed || controller != null,
         'a windowed gutter requires a controller',
       );

  /// Vertical scroll controller of the code; only read when [windowed].
  final ScrollController? controller;
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

  /// Every line number stacked in a column, used when not windowed (no viewport
  /// to window against) and as the unbounded-height fallback.
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
      final controller = this.controller!;
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
                  final offset = controller.hasClients
                      ? controller.offset
                      : 0.0;
                  final first = (offset / rowHeight).floor().clamp(
                    0,
                    lineCount,
                  );
                  final visible =
                      (constraints.maxHeight / rowHeight).ceil() + 1;
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
