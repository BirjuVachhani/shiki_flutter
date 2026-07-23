// Bit-packed token metadata, ported from `vscode-textmate`'s
// `encodedTokenAttributes.ts`.
//
// The binary format (32 bits):
//   bbbb bbbb ffff ffff fFFF FBTT LLLL LLLL
//   L = languageId (8)  T = StandardTokenType (2)  B = balanced brackets (1)
//   F = FontStyle (4)   f = foreground color id (9)  b = background color id (9)

import 'theme.dart' show FontStyle;

/// Standard token types.
class StandardTokenType {
  /// No special token type.
  static const int other = 0;

  /// The token is (part of) a comment.
  static const int comment = 1;

  /// The token is (part of) a string literal.
  static const int string = 2;

  /// The token is (part of) a regular expression literal.
  static const int regEx = 3;
}

/// Optional token type; [notSet] means "leave as is".
class OptionalStandardTokenType {
  /// See [StandardTokenType.other].
  static const int other = 0;

  /// See [StandardTokenType.comment].
  static const int comment = 1;

  /// See [StandardTokenType.string].
  static const int string = 2;

  /// See [StandardTokenType.regEx].
  static const int regEx = 3;

  /// Sentinel meaning "no token type specified"; leaves the encoded
  /// metadata's existing token type field untouched.
  static const int notSet = 8;
}

int _fromOptionalTokenType(int type) => type;

/// Converts a [StandardTokenType] value to its [OptionalStandardTokenType]
/// equivalent (the two share the same underlying integers for non-`notSet`
/// values; this exists purely for type clarity at call sites).
int toOptionalTokenType(int standardType) => standardType;

const int _languageIdMask = 0x000000FF;
const int _tokenTypeMask = 0x00000300;
const int _balancedBracketsMask = 0x00000400;
const int _fontStyleMask = 0x00003800;
const int _foregroundMask = 0x00FF8000;
const int _backgroundMask = 0xFF000000;

const int _languageIdOffset = 0;
const int _tokenTypeOffset = 8;
const int _balancedBracketsOffset = 10;
const int _fontStyleOffset = 11;
const int _foregroundOffset = 15;
const int _backgroundOffset = 24;

/// Static helpers to read and write [encodedTokenAttributes] integers.
class EncodedTokenMetadata {
  /// Extracts the language id (bits 0-7) from an encoded [metadata] value.
  static int getLanguageId(int metadata) =>
      (metadata & _languageIdMask) >> _languageIdOffset;

  /// Extracts the [StandardTokenType] (bits 8-9) from an encoded
  /// [metadata] value.
  static int getTokenType(int metadata) =>
      (metadata & _tokenTypeMask) >> _tokenTypeOffset;

  /// Whether the balanced-brackets bit (bit 10) is set on [metadata].
  static bool containsBalancedBrackets(int metadata) =>
      (metadata & _balancedBracketsMask) != 0;

  /// Extracts the [FontStyle] bitmask (bits 11-14) from an encoded
  /// [metadata] value.
  static int getFontStyle(int metadata) =>
      (metadata & _fontStyleMask) >> _fontStyleOffset;

  /// Extracts the foreground color id (bits 15-23) from an encoded
  /// [metadata] value; an id into a theme's [ColorMap].
  static int getForeground(int metadata) =>
      (metadata & _foregroundMask) >> _foregroundOffset;

  /// Extracts the background color id (bits 24-31) from an encoded
  /// [metadata] value; an id into a theme's [ColorMap].
  static int getBackground(int metadata) =>
      (metadata & _backgroundMask) >> _backgroundOffset;

  /// Updates the fields in [metadata]. A value of `0`, `notSet` or `null`
  /// indicates that the corresponding field should be left as is.
  static int set(
    int metadata,
    int languageId,
    int tokenType,
    bool? containsBalancedBrackets,
    int fontStyle,
    int foreground,
    int background,
  ) {
    var langId = getLanguageId(metadata);
    var tokType = getTokenType(metadata);
    var balancedBracketsBit = containsBalancedBrackets == true ? 1 : 0;
    if (containsBalancedBrackets == null) {
      balancedBracketsBit =
          EncodedTokenMetadata.containsBalancedBrackets(metadata) ? 1 : 0;
    }
    var fStyle = getFontStyle(metadata);
    var fg = getForeground(metadata);
    var bg = getBackground(metadata);

    if (languageId != 0) langId = languageId;
    if (tokenType != OptionalStandardTokenType.notSet) {
      tokType = _fromOptionalTokenType(tokenType);
    }
    if (fontStyle != FontStyle.notSet) fStyle = fontStyle;
    if (foreground != 0) fg = foreground;
    if (background != 0) bg = background;

    return (langId << _languageIdOffset) |
        (tokType << _tokenTypeOffset) |
        (balancedBracketsBit << _balancedBracketsOffset) |
        (fStyle << _fontStyleOffset) |
        (fg << _foregroundOffset) |
        (bg << _backgroundOffset);
  }
}
