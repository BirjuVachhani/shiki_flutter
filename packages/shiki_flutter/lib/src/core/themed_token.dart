// The public token representation produced by the highlighter.

/// A single highlighted token: a run of characters sharing one style.
class ThemedToken {
  const ThemedToken({
    required this.content,
    required this.offset,
    this.color,
    this.bgColor,
    this.fontStyle = 0,
    this.scopes,
  });

  /// The text of this token.
  final String content;

  /// The start offset of this token relative to the whole input, 0-indexed.
  final int offset;

  /// Foreground color as a hex string (e.g. `#ff0000`), if any.
  final String? color;

  /// Background color as a hex string, if any.
  final String? bgColor;

  /// Font-style bit flags (see [FontStyle] in `theme.dart`).
  final int fontStyle;

  /// The TextMate scopes for this token, when explanations are requested.
  final List<String>? scopes;

  @override
  String toString() =>
      'ThemedToken(${content.replaceAll('\n', r'\n')}, color: $color, '
      'fontStyle: $fontStyle)';
}
