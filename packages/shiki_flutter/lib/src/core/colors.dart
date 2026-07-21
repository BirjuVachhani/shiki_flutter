// Color-replacement and line-splitting helpers, ported from Shiki's
// `utils/colors.ts` and `utils/general.ts`.

/// Merges a theme's own `colorReplacements` with any per-call replacements.
Map<String, String> resolveColorReplacements(
  String themeName,
  Map<String, String>? themeReplacements,
  Map<String, dynamic>? optionReplacements,
) {
  final replacements = <String, String>{...?themeReplacements};
  if (optionReplacements != null) {
    optionReplacements.forEach((key, value) {
      if (value is String) {
        replacements[key] = value;
      } else if (key == themeName && value is Map) {
        value.forEach((k, v) {
          if (v is String) replacements[k.toString()] = v;
        });
      }
    });
  }
  return replacements;
}

/// Applies color replacements to a resolved color (case-insensitive key).
String? applyColorReplacements(
  String? color,
  Map<String, String>? replacements,
) {
  if (color == null || color.isEmpty) return color;
  return replacements?[color.toLowerCase()] ?? color;
}

/// Splits [code] into `(lineContent, offset)` pairs, preserving offsets into the
/// original string and excluding the newline characters from the content.
List<({String content, int offset})> splitLines(String code) {
  if (code.isEmpty) return [(content: '', offset: 0)];

  final lines = <({String content, int offset})>[];
  var start = 0;
  for (var i = 0; i < code.length; i++) {
    if (code.codeUnitAt(i) == 0x0a) {
      // \n
      var contentEnd = i;
      if (contentEnd > start && code.codeUnitAt(contentEnd - 1) == 0x0d) {
        contentEnd -= 1; // strip trailing \r
      }
      lines.add((content: code.substring(start, contentEnd), offset: start));
      start = i + 1;
    }
  }
  lines.add((content: code.substring(start), offset: start));
  return lines;
}

bool isPlainLang(String? lang) =>
    lang == null || lang == 'text' || lang == 'plaintext' || lang == 'txt';

bool isNoneTheme(String? theme) => theme == 'none';
