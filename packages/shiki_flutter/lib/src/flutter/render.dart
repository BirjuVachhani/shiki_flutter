// Flutter rendering helpers: convert themed tokens into styled spans/widgets.

import 'dart:ui' show ColorSpace;

import 'package:flutter/widgets.dart';

import '../core/code_language.dart';
import '../core/highlighter.dart';
import '../core/shiki_theme.dart';
import '../core/themed_token.dart';
import '../textmate/theme.dart' as tm;

/// Parses a CSS color string into a Flutter [Color].
///
/// Supports:
/// * **hex**: `#rgb`, `#rgba`, `#rrggbb`, `#rrggbbaa`.
/// * **CSS Color 4 `color()`**: `color(display-p3 r g b [/ a])` and
///   `color(srgb r g b [/ a])`. Components are numbers in `0..1` or
///   percentages; the result is wide-gamut via [Color.from] + [ColorSpace],
///   so P3 renders richly where the platform/display supports it and is
///   gamut-mapped to sRGB elsewhere.
///
/// Returns null when [input] is null/empty/unrecognized. Shiki carries non-hex
/// theme colors through untouched (see `normalizeTheme`), so wide-gamut themes
/// reach here verbatim.
Color? parseColor(String? input) {
  if (input == null) return null;
  final s = input.trim();
  if (s.isEmpty) return null;
  if (s.startsWith('#')) return _parseHex(s);
  if (s.startsWith('color(') && s.endsWith(')')) return _parseColorFunction(s);
  return null;
}

/// Alias for [parseColor], kept for source compatibility. Despite the name it
/// now also parses `color(display-p3 ...)` and `color(srgb ...)`.
@Deprecated(
  'Use parseColor; it also handles color(display-p3 ...) and color(srgb ...).',
)
Color? parseHexColor(String? hex) => parseColor(hex);

Color? _parseHex(String hex) {
  var value = hex.substring(1);
  switch (value.length) {
    case 3: // rgb -> ffrrggbb
      value = 'ff${value.split('').map((c) => '$c$c').join()}';
    case 4: // rgba -> aarrggbb
      final chars = value.split('').map((c) => '$c$c').toList();
      value = '${chars[3]}${chars.sublist(0, 3).join()}';
    case 6: // rrggbb -> ffrrggbb
      value = 'ff$value';
    case 8: // rrggbbaa -> aarrggbb
      value = '${value.substring(6, 8)}${value.substring(0, 6)}';
    default:
      return null;
  }
  final intValue = int.tryParse(value, radix: 16);
  if (intValue == null) return null;
  return Color(intValue);
}

/// Parses `color(<space> c1 c2 c3 [/ a])`. Returns null on any malformed part
/// or an unsupported color space.
Color? _parseColorFunction(String s) {
  final inner = s.substring('color('.length, s.length - 1).trim();
  if (inner.isEmpty) return null;

  // Peel off an optional "/ alpha" suffix.
  var body = inner;
  var alpha = 1.0;
  final slash = inner.indexOf('/');
  if (slash != -1) {
    final a = _parseComponent(inner.substring(slash + 1).trim());
    if (a == null) return null;
    alpha = a;
    body = inner.substring(0, slash).trim();
  }

  final parts = body.split(RegExp(r'\s+'));
  if (parts.length != 4) return null; // space + exactly 3 channels

  final ColorSpace colorSpace;
  switch (parts.first) {
    case 'display-p3':
      colorSpace = ColorSpace.displayP3;
    case 'srgb':
      colorSpace = ColorSpace.sRGB;
    default:
      return null;
  }

  final r = _parseComponent(parts[1]);
  final g = _parseComponent(parts[2]);
  final b = _parseComponent(parts[3]);
  if (r == null || g == null || b == null) return null;

  return Color.from(
    alpha: alpha,
    red: r,
    green: g,
    blue: b,
    colorSpace: colorSpace,
  );
}

/// Parses a single `color()` component, a `0..1` number or a `0%..100%`
/// percentage, clamped to `0..1`. Returns null if not numeric.
double? _parseComponent(String raw) {
  if (raw.isEmpty) return null;
  double? v;
  if (raw.endsWith('%')) {
    final n = double.tryParse(raw.substring(0, raw.length - 1));
    if (n == null) return null;
    v = n / 100.0;
  } else {
    v = double.tryParse(raw);
  }
  if (v == null) return null;
  return v.clamp(0.0, 1.0);
}

TextDecoration? _decorationFor(int fontStyle) {
  final decorations = <TextDecoration>[];
  if (fontStyle & tm.FontStyle.underline != 0) {
    decorations.add(TextDecoration.underline);
  }
  if (fontStyle & tm.FontStyle.strikethrough != 0) {
    decorations.add(TextDecoration.lineThrough);
  }
  if (decorations.isEmpty) return null;
  return TextDecoration.combine(decorations);
}

/// Builds a [TextStyle] for a single [ThemedToken], layered over [baseStyle].
///
/// A token never contributes a background: the theme's background is painted
/// once by the widget tree (e.g. the [ColoredBox] in [ShikiCodeView]), so a
/// per-token `backgroundColor` here would draw a filled box behind every run.
TextStyle themedTokenStyle(ThemedToken token, {TextStyle? baseStyle}) {
  final base = baseStyle ?? const TextStyle();
  final color = parseColor(token.color);
  return base.copyWith(
    color: color ?? base.color,
    fontWeight: token.fontStyle & tm.FontStyle.bold != 0
        ? FontWeight.bold
        : base.fontWeight,
    fontStyle: token.fontStyle & tm.FontStyle.italic != 0
        ? FontStyle.italic
        : base.fontStyle,
    decoration: _decorationFor(token.fontStyle) ?? base.decoration,
  );
}

/// A single token's [TextSpan], its style layered over [baseStyle].
TextSpan _tokenSpan(ThemedToken token, TextStyle? baseStyle) => TextSpan(
  text: token.content,
  style: themedTokenStyle(token, baseStyle: baseStyle),
);

/// Tokenizes [code] and bakes the theme's foreground into the base style, the
/// shared front half of [codeToTextSpan] and [codeToLineSpans].
({List<List<ThemedToken>> tokens, TextStyle baseStyle}) _tokenizeWithBase(
  ShikiHighlighter highlighter,
  String code, {
  required CodeLanguage lang,
  required ShikiTheme theme,
  TextStyle? baseStyle,
}) {
  highlighter
    ..ensureLanguage(lang)
    ..ensureShikiTheme(theme);
  final tokens = highlighter.codeToTokens(
    code,
    TokenizeOptions(lang: lang.id, theme: theme.id),
  );
  final registration = highlighter.getThemeRegistration(theme.id);
  final fg = parseColor(registration.fg);
  final effectiveBase = (baseStyle ?? const TextStyle()).copyWith(color: fg);
  return (tokens: tokens, baseStyle: effectiveBase);
}

/// Converts a grid of themed tokens (lines of tokens) into a single [TextSpan],
/// inserting newlines between lines.
TextSpan tokensToTextSpan(
  List<List<ThemedToken>> lines, {
  TextStyle? baseStyle,
}) {
  final children = <InlineSpan>[];
  for (var i = 0; i < lines.length; i++) {
    for (final token in lines[i]) {
      children.add(_tokenSpan(token, baseStyle));
    }
    if (i != lines.length - 1) {
      children.add(const TextSpan(text: '\n'));
    }
  }
  return TextSpan(style: baseStyle, children: children);
}

/// Highlights [code] and returns a ready-to-use [TextSpan].
///
/// [lang] and [theme] are loaded into [highlighter] on demand; [theme] is a
/// concrete [ShikiTheme] (resolve a light/dark [ShikiThemeConfig] yourself
/// first, since these helpers have no `BuildContext`).
TextSpan codeToTextSpan(
  ShikiHighlighter highlighter,
  String code, {
  required CodeLanguage lang,
  required ShikiTheme theme,
  TextStyle? baseStyle,
}) {
  final resolved = _tokenizeWithBase(
    highlighter,
    code,
    lang: lang,
    theme: theme,
    baseStyle: baseStyle,
  );
  return tokensToTextSpan(resolved.tokens, baseStyle: resolved.baseStyle);
}

/// Converts a grid of themed tokens into styled spans grouped **by line**.
///
/// Mirrors [tokensToTextSpan] but keeps line boundaries instead of flattening
/// to one span with `'\n'` separators: the outer list is lines, and each inner
/// list holds that line's spans. This is the shape a lazily-built list such as
/// `ListView.builder` wants, so large files only pay layout/paint cost for the
/// lines actually on screen.
///
/// A blank line yields a single empty-text span carrying [baseStyle], so an
/// empty line still reserves one line of height when rendered on its own.
List<List<TextSpan>> tokensToLineSpans(
  List<List<ThemedToken>> lines, {
  TextStyle? baseStyle,
}) {
  return [
    for (final line in lines)
      if (line.isEmpty)
        [TextSpan(text: '', style: baseStyle)]
      else
        [for (final token in line) _tokenSpan(token, baseStyle)],
  ];
}

/// Highlights [code] and returns its styled spans grouped **by line**.
///
/// The outer list is lines; each inner list holds the [TextSpan]s for that
/// line. Feed it to a `ListView.builder` (one row per line) to render large
/// files without building the whole document up front: each inner span already
/// carries its fully resolved style, so a row is just
/// `Text.rich(TextSpan(children: lines[i]))`, or `Text.rich(lineToTextSpan(...))`.
///
/// The theme's foreground is baked into [baseStyle] (matching [codeToTextSpan]),
/// and blank lines are height-preserving (see [tokensToLineSpans]).
///
/// Note the code is tokenized eagerly in a single pass. That's correct, because a
/// line's highlighting can depend on earlier lines (multi-line strings and
/// comments). Only the *rendering* is lazy.
List<List<TextSpan>> codeToLineSpans(
  ShikiHighlighter highlighter,
  String code, {
  required CodeLanguage lang,
  required ShikiTheme theme,
  TextStyle? baseStyle,
}) {
  final resolved = _tokenizeWithBase(
    highlighter,
    code,
    lang: lang,
    theme: theme,
    baseStyle: baseStyle,
  );
  return tokensToLineSpans(resolved.tokens, baseStyle: resolved.baseStyle);
}

/// Assembles one line's [spans] into a single [TextSpan] for `Text.rich`.
///
/// A convenience for callers who prefer a `List<TextSpan>` (one span per line)
/// over a `List<List<TextSpan>>`:
/// `codeToLineSpans(...).map(lineToTextSpan).toList()`.
TextSpan lineToTextSpan(List<InlineSpan> spans) => TextSpan(children: spans);
