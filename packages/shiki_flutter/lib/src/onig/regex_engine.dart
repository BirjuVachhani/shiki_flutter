// A small backtracking regular-expression engine that understands the subset of
// the Oniguruma syntax used by TextMate grammars.
//
// Dart's built-in [RegExp] cannot be used to back the tokenizer because it does
// not expose per-capture-group offsets (which the grammar interpreter relies on
// for `captures`/`beginCaptures`/`endCaptures` and back-references), and it does
// not support several Oniguruma constructs (`\A`, `\G`, `\h`, `\z`, `\Z`,
// possessive quantifiers, atomic groups, inline flag groups, ...). This engine
// fills that role, playing the same part that `oniguruma-to-es` plays in Shiki's
// JavaScript engine.
//
// Matching operates on UTF-16 code units, exactly like Shiki's JavaScript engine
// (and JavaScript `RegExp` without the `u` flag), so the reported offsets line up
// with Dart string indices without any conversion.

/// Thrown when a pattern cannot be parsed by [OnigRegex].
class RegexSyntaxException implements Exception {
  RegexSyntaxException(this.message, this.source);

  final String message;
  final String source;

  @override
  String toString() => 'RegexSyntaxException: $message (in /$source/)';
}

/// The result of a successful match.
///
/// [start] and [end] hold the half-open range for every capture group; index 0
/// is the whole match. A value of -1 means the group did not participate in the
/// match.
class OnigEngineMatch {
  OnigEngineMatch(this.start, this.end);

  final List<int> start;
  final List<int> end;

  int get index => start[0];
}

// --- Anchor kinds ------------------------------------------------------------

const int _anchorLineStart = 0; // ^
const int _anchorLineEnd = 1; // $
const int _anchorWordBoundary = 2; // \b
const int _anchorNotWordBoundary = 3; // \B
const int _anchorBufferStart = 4; // \A
const int _anchorBufferEnd = 5; // \z
const int _anchorBufferEndBeforeNewline = 6; // \Z
const int _anchorG = 7; // \G

// --- AST ---------------------------------------------------------------------

abstract class _Node {}

class _EmptyNode extends _Node {}

class _CharNode extends _Node {
  _CharNode(this.ch, this.ignoreCase);

  final int ch;
  final bool ignoreCase;
}

class _AnyNode extends _Node {
  _AnyNode(this.dotAll);

  final bool dotAll;
}

class _Range {
  const _Range(this.lo, this.hi);

  final int lo;
  final int hi;
}

class _ClassNode extends _Node {
  _ClassNode(this.ranges, this.negated, this.ignoreCase);

  final List<_Range> ranges;
  final bool negated;
  final bool ignoreCase;

  /// Disjoint, ascending copy of [ranges] for O(log n) membership. Built once
  /// on first use; the positive set is identical to [ranges].
  late final List<_Range> _merged = _mergeSortedRanges(ranges);

  /// Whether code unit [c] is in the (positive, pre-negation) range set.
  bool containsCode(int c) {
    final ranges = _merged;
    var lo = 0;
    var hi = ranges.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final r = ranges[mid];
      if (c < r.lo) {
        hi = mid - 1;
      } else if (c > r.hi) {
        lo = mid + 1;
      } else {
        return true;
      }
    }
    return false;
  }
}

/// Sorts by low bound and merges overlapping/adjacent ranges into a disjoint,
/// ascending list. The input needn't be sorted or disjoint.
List<_Range> _mergeSortedRanges(List<_Range> input) {
  if (input.length <= 1) return input;
  final sorted = [...input]..sort((a, b) => a.lo.compareTo(b.lo));
  final out = <_Range>[];
  var curLo = sorted.first.lo;
  var curHi = sorted.first.hi;
  for (var i = 1; i < sorted.length; i++) {
    final r = sorted[i];
    if (r.lo <= curHi + 1) {
      if (r.hi > curHi) curHi = r.hi;
    } else {
      out.add(_Range(curLo, curHi));
      curLo = r.lo;
      curHi = r.hi;
    }
  }
  out.add(_Range(curLo, curHi));
  return out;
}

class _AnchorNode extends _Node {
  _AnchorNode(this.kind);

  final int kind;
}

class _GroupNode extends _Node {
  _GroupNode(this.child, this.captureIndex, this.atomic);

  final _Node child;
  final int? captureIndex; // null for non-capturing
  final bool atomic;
}

class _ConcatNode extends _Node {
  _ConcatNode(this.parts);

  final List<_Node> parts;
}

class _AltNode extends _Node {
  _AltNode(this.options);

  final List<_Node> options;
}

class _QuantNode extends _Node {
  _QuantNode(this.child, this.min, this.max, this.greedy, this.possessive);

  final _Node child;
  final int min;
  final int max; // -1 == unbounded
  final bool greedy;
  final bool possessive;
}

class _LookNode extends _Node {
  _LookNode(this.child, this.ahead, this.negative);

  final _Node child;
  final bool ahead;
  final bool negative;
}

class _BackrefNode extends _Node {
  _BackrefNode(this.group, this.ignoreCase);

  int group;
  final bool ignoreCase;
}

// --- Parser ------------------------------------------------------------------

class _Flags {
  _Flags(this.ignoreCase, this.dotAll, this.extended);

  bool ignoreCase;
  bool dotAll;
  bool extended;

  _Flags clone() => _Flags(ignoreCase, dotAll, extended);
}

class _Parser {
  _Parser(this.src, this.flags);

  final String src;
  _Flags flags;
  int pos = 0;
  int groupCount = 0;
  final Map<String, int> groupNames = {};

  int get _len => src.length;

  int? _peek() => pos < _len ? src.codeUnitAt(pos) : null;

  int _cur() => src.codeUnitAt(pos);

  Never _error(String message) => throw RegexSyntaxException(message, src);

  _Node parse() {
    final node = _parseAlternation();
    if (pos < _len) {
      _error('Unexpected "${src[pos]}" at $pos');
    }
    return node;
  }

  void _skipExtended() {
    if (!flags.extended) return;
    while (pos < _len) {
      final c = _cur();
      if (c == 0x20 || c == 0x09 || c == 0x0a || c == 0x0d || c == 0x0c) {
        pos++;
      } else if (c == 0x23) {
        // # comment to end of line
        pos++;
        while (pos < _len && src.codeUnitAt(pos) != 0x0a) {
          pos++;
        }
      } else {
        break;
      }
    }
  }

  _Node _parseAlternation() {
    final first = _parseConcat();
    if (_peek() != 0x7c) {
      return first;
    }
    final options = <_Node>[first];
    while (_peek() == 0x7c) {
      pos++; // consume |
      options.add(_parseConcat());
    }
    return _AltNode(options);
  }

  _Node _parseConcat() {
    final parts = <_Node>[];
    while (true) {
      _skipExtended();
      final c = _peek();
      if (c == null || c == 0x7c /* | */ || c == 0x29 /* ) */ ) {
        break;
      }
      final atom = _parseQuantified();
      if (atom != null) {
        parts.add(atom);
      }
    }
    if (parts.isEmpty) return _EmptyNode();
    if (parts.length == 1) return parts.first;
    return _ConcatNode(parts);
  }

  _Node? _parseQuantified() {
    final atom = _parseAtom();
    if (atom == null) return null;
    _skipExtended();
    final c = _peek();
    if (c == null) return atom;

    int min;
    int max;
    if (c == 0x2a) {
      // *
      pos++;
      min = 0;
      max = -1;
    } else if (c == 0x2b) {
      // +
      pos++;
      min = 1;
      max = -1;
    } else if (c == 0x3f) {
      // ?
      pos++;
      min = 0;
      max = 1;
    } else if (c == 0x7b) {
      // { possibly interval
      final interval = _tryParseInterval();
      if (interval == null) {
        return atom; // literal '{', already handled as char by _parseAtom? No: treat here.
      }
      min = interval[0];
      max = interval[1];
    } else {
      return atom;
    }

    // Greedy / lazy / possessive suffix.
    bool greedy = true;
    bool possessive = false;
    final s = _peek();
    if (s == 0x3f) {
      greedy = false;
      pos++;
    } else if (s == 0x2b) {
      possessive = true;
      pos++;
    }
    return _QuantNode(atom, min, max, greedy, possessive);
  }

  // Returns [min, max] or null if not a valid interval (leaves pos unchanged).
  List<int>? _tryParseInterval() {
    final start = pos;
    pos++; // consume {
    final digitsMinStart = pos;
    while (pos < _len && _isDigit(_cur())) {
      pos++;
    }
    final minStr = src.substring(digitsMinStart, pos);
    int min;
    int max;
    if (_peek() == 0x2c) {
      // comma
      pos++;
      final digitsMaxStart = pos;
      while (pos < _len && _isDigit(_cur())) {
        pos++;
      }
      final maxStr = src.substring(digitsMaxStart, pos);
      if (_peek() != 0x7d) {
        pos = start;
        return null;
      }
      pos++; // consume }
      if (minStr.isEmpty && maxStr.isEmpty) {
        pos = start;
        return null;
      }
      min = minStr.isEmpty ? 0 : int.parse(minStr);
      max = maxStr.isEmpty ? -1 : int.parse(maxStr);
    } else if (_peek() == 0x7d) {
      pos++; // consume }
      if (minStr.isEmpty) {
        pos = start;
        return null;
      }
      min = int.parse(minStr);
      max = min;
    } else {
      pos = start;
      return null;
    }
    return [min, max];
  }

  _Node? _parseAtom() {
    final c = _peek();
    if (c == null) return null;

    switch (c) {
      case 0x28: // (
        return _parseGroup();
      case 0x5b: // [
        return _parseClass();
      case 0x2e: // .
        pos++;
        return _AnyNode(flags.dotAll);
      case 0x5e: // ^
        pos++;
        return _AnchorNode(_anchorLineStart);
      case 0x24: // $
        pos++;
        return _AnchorNode(_anchorLineEnd);
      case 0x5c: // backslash
        return _parseEscape();
      case 0x29: // ) handled by caller
      case 0x7c: // | handled by caller
        return null;
      case 0x2a: // * + ? at atom position -> treat as literal (lenient)
      case 0x2b:
      case 0x3f:
        pos++;
        return _CharNode(c, flags.ignoreCase);
      default:
        pos++;
        return _CharNode(c, flags.ignoreCase);
    }
  }

  _Node _parseGroup() {
    pos++; // consume (
    if (_peek() == 0x3f) {
      // (? ...
      pos++;
      final c = _peek();
      if (c == 0x3a) {
        // (?:
        pos++;
        final child = _parseAlternation();
        _expect(0x29);
        return _GroupNode(child, null, false);
      } else if (c == 0x3e) {
        // (?> atomic
        pos++;
        final child = _parseAlternation();
        _expect(0x29);
        return _GroupNode(child, null, true);
      } else if (c == 0x3d) {
        // (?= lookahead
        pos++;
        final child = _parseAlternation();
        _expect(0x29);
        return _LookNode(child, true, false);
      } else if (c == 0x21) {
        // (?! negative lookahead
        pos++;
        final child = _parseAlternation();
        _expect(0x29);
        return _LookNode(child, true, true);
      } else if (c == 0x23) {
        // (?# comment
        pos++;
        while (pos < _len && _cur() != 0x29) {
          pos++;
        }
        _expect(0x29);
        return _EmptyNode();
      } else if (c == 0x3c) {
        // (?< ...
        pos++;
        final c2 = _peek();
        if (c2 == 0x3d) {
          // (?<= lookbehind
          pos++;
          final child = _parseAlternation();
          _expect(0x29);
          return _LookNode(child, false, false);
        } else if (c2 == 0x21) {
          // (?<! negative lookbehind
          pos++;
          final child = _parseAlternation();
          _expect(0x29);
          return _LookNode(child, false, true);
        } else {
          // (?<name> named group
          final name = _parseGroupName(0x3e);
          final index = ++groupCount;
          groupNames[name] = index;
          final child = _parseAlternation();
          _expect(0x29);
          return _GroupNode(child, index, false);
        }
      } else if (c == 0x27) {
        // (?'name' named group
        pos++;
        final name = _parseGroupNameUntilQuote();
        final index = ++groupCount;
        groupNames[name] = index;
        final child = _parseAlternation();
        _expect(0x29);
        return _GroupNode(child, index, false);
      } else {
        // Inline flags: (?flags) or (?flags:...) or (?flags-flags...)
        return _parseInlineFlags();
      }
    }
    // Plain capturing group.
    final index = ++groupCount;
    final child = _parseAlternation();
    _expect(0x29);
    return _GroupNode(child, index, false);
  }

  _Node _parseInlineFlags() {
    // pos is at the first flag char (after "(?").
    bool add = true;
    final newFlags = flags.clone();
    var sawFlag = false;
    while (true) {
      final c = _peek();
      if (c == null) _error('Unterminated inline flags');
      if (c == 0x69) {
        // i
        newFlags.ignoreCase = add;
        sawFlag = true;
        pos++;
      } else if (c == 0x6d) {
        // m -> Oniguruma "multi-line" == dot matches newline (dotAll here)
        newFlags.dotAll = add;
        sawFlag = true;
        pos++;
      } else if (c == 0x78) {
        // x extended
        newFlags.extended = add;
        sawFlag = true;
        pos++;
      } else if (c == 0x73 || c == 0x75 || c == 0x64) {
        // s, u, d: accepted but ignored
        sawFlag = true;
        pos++;
      } else if (c == 0x2d) {
        // -
        add = false;
        pos++;
      } else if (c == 0x3a) {
        // : scoped flags -> apply within this group only
        pos++;
        final saved = flags;
        flags = newFlags;
        final child = _parseAlternation();
        flags = saved;
        _expect(0x29);
        return _GroupNode(child, null, false);
      } else if (c == 0x29) {
        // ) flags apply to the rest of the current group
        pos++;
        if (!sawFlag) {
          // e.g. (?) -- treat as empty
        }
        flags = newFlags;
        return _EmptyNode();
      } else {
        _error('Unexpected flag "${src[pos]}"');
      }
    }
  }

  String _parseGroupName(int terminator) {
    final start = pos;
    while (pos < _len && _cur() != terminator) {
      pos++;
    }
    if (_peek() != terminator) _error('Unterminated group name');
    final name = src.substring(start, pos);
    pos++; // consume terminator
    return name;
  }

  String _parseGroupNameUntilQuote() {
    return _parseGroupName(0x27);
  }

  void _expect(int codeUnit) {
    if (_peek() != codeUnit) {
      _error('Expected "${String.fromCharCode(codeUnit)}" at $pos');
    }
    pos++;
  }

  _Node _parseEscape() {
    pos++; // consume backslash
    final c = _peek();
    if (c == null) _error('Trailing backslash');

    switch (c) {
      case 0x41: // A
        pos++;
        return _AnchorNode(_anchorBufferStart);
      case 0x5a: // Z
        pos++;
        return _AnchorNode(_anchorBufferEndBeforeNewline);
      case 0x7a: // z
        pos++;
        return _AnchorNode(_anchorBufferEnd);
      case 0x47: // G
        pos++;
        return _AnchorNode(_anchorG);
      case 0x62: // b
        pos++;
        return _AnchorNode(_anchorWordBoundary);
      case 0x42: // B
        pos++;
        return _AnchorNode(_anchorNotWordBoundary);
      case 0x6b: // k<name> backref
        pos++;
        final open = _peek();
        if (open == 0x3c || open == 0x27) {
          final term = open == 0x3c ? 0x3e : 0x27;
          pos++;
          final name = _parseGroupName(term);
          final ref = _BackrefNode(-1, flags.ignoreCase);
          _pendingNamed.add(_PendingNamed(ref, name));
          return ref;
        }
        // Not a named backref; treat as literal 'k'.
        return _CharNode(0x6b, flags.ignoreCase);
      case 0x67: // g<name> subroutine call -- unsupported, treat as empty
        pos++;
        final open = _peek();
        if (open == 0x3c || open == 0x27) {
          final term = open == 0x3c ? 0x3e : 0x27;
          pos++;
          _parseGroupName(term);
          return _EmptyNode();
        }
        return _CharNode(0x67, flags.ignoreCase);
    }

    // Numeric back-reference (\1 .. \99) when a group with that number exists so
    // far; otherwise fall through to octal/char escape.
    if (c >= 0x31 && c <= 0x39) {
      final start = pos;
      var num = 0;
      while (pos < _len && _isDigit(_cur())) {
        final d = _cur() - 0x30;
        final next = num * 10 + d;
        if (next > groupCount) break;
        num = next;
        pos++;
      }
      if (num > 0) {
        return _BackrefNode(num, flags.ignoreCase);
      }
      pos = start;
    }

    // Character-class shorthands.
    final cls = _tryEscapeClass();
    if (cls != null) return cls;

    // Single escaped character (metachar, control, hex, unicode, octal...).
    final code = _parseEscapedChar();
    return _CharNode(code, flags.ignoreCase);
  }

  // Handles \d \D \w \W \s \S \h \H \p{..} \P{..} as class nodes; null if not one.
  _Node? _tryEscapeClass() {
    final c = _cur();
    switch (c) {
      case 0x64: // d
        pos++;
        return _ClassNode([_Range(0x30, 0x39)], false, false);
      case 0x44: // D
        pos++;
        return _ClassNode([_Range(0x30, 0x39)], true, false);
      case 0x77: // w
        pos++;
        return _ClassNode(_wordRanges(), false, false);
      case 0x57: // W
        pos++;
        return _ClassNode(_wordRanges(), true, false);
      case 0x73: // s
        pos++;
        return _ClassNode(_spaceRanges(), false, false);
      case 0x53: // S
        pos++;
        return _ClassNode(_spaceRanges(), true, false);
      case 0x68: // h  hex digit
        pos++;
        return _ClassNode(_hexRanges(), false, false);
      case 0x48: // H
        pos++;
        return _ClassNode(_hexRanges(), true, false);
      case 0x70: // p{..}
      case 0x50: // P{..}
        final negated = c == 0x50;
        pos++;
        final ranges = _parseUnicodeProperty();
        return _ClassNode(ranges, negated, false);
    }
    return null;
  }

  List<_Range> _parseUnicodeProperty() {
    if (_peek() != 0x7b) {
      // \p without braces -> single-letter property like \pL
      final c = _peek();
      if (c == null) _error('Bad \\p');
      pos++;
      return _unicodePropertyRanges(String.fromCharCode(c));
    }
    pos++; // consume {
    final start = pos;
    while (pos < _len && _cur() != 0x7d) {
      pos++;
    }
    final name = src.substring(start, pos);
    _expect(0x7d);
    return _unicodePropertyRanges(name);
  }

  // Parse a single escaped character value (assumes leading backslash consumed
  // and current char is the escape body).
  int _parseEscapedChar() {
    final c = _cur();
    switch (c) {
      case 0x6e: // n
        pos++;
        return 0x0a;
      case 0x74: // t
        pos++;
        return 0x09;
      case 0x72: // r
        pos++;
        return 0x0d;
      case 0x66: // f
        pos++;
        return 0x0c;
      case 0x76: // v
        pos++;
        return 0x0b;
      case 0x61: // a
        pos++;
        return 0x07;
      case 0x65: // e
        pos++;
        return 0x1b;
      case 0x30: // 0 -> NUL (octal handled loosely)
        pos++;
        return 0x00;
      case 0x78: // x
        pos++;
        return _parseHexEscape();
      case 0x75: // u
        pos++;
        return _parseUnicodeEscape();
      case 0x63: // cX control
        pos++;
        if (pos < _len) {
          final ctrl = _cur();
          pos++;
          return ctrl & 0x1f;
        }
        return 0x63;
      default:
        pos++;
        return c;
    }
  }

  int _parseHexEscape() {
    if (_peek() == 0x7b) {
      // \x{...}
      pos++;
      final start = pos;
      while (pos < _len && _cur() != 0x7d) {
        pos++;
      }
      final hex = src.substring(start, pos);
      _expect(0x7d);
      return int.parse(hex, radix: 16);
    }
    // up to 2 hex digits
    final start = pos;
    var count = 0;
    while (pos < _len && count < 2 && _isHexDigit(_cur())) {
      pos++;
      count++;
    }
    if (count == 0) return 0x78; // 'x'
    return int.parse(src.substring(start, pos), radix: 16);
  }

  int _parseUnicodeEscape() {
    if (_peek() == 0x7b) {
      pos++;
      final start = pos;
      while (pos < _len && _cur() != 0x7d) {
        pos++;
      }
      final hex = src.substring(start, pos);
      _expect(0x7d);
      return int.parse(hex, radix: 16);
    }
    final start = pos;
    var count = 0;
    while (pos < _len && count < 4 && _isHexDigit(_cur())) {
      pos++;
      count++;
    }
    if (count == 0) return 0x75; // 'u'
    return int.parse(src.substring(start, pos), radix: 16);
  }

  _Node _parseClass() {
    pos++; // consume [
    bool negated = false;
    if (_peek() == 0x5e) {
      negated = true;
      pos++;
    }
    final ranges = _parseClassSet();
    return _ClassNode(ranges, negated, flags.ignoreCase);
  }

  // Parses a class body up to and including the closing `]`, handling Oniguruma
  // set intersection (`&&`) between operands.
  List<_Range> _parseClassSet() {
    var acc = _parseClassOperand();
    while (_peek() == 0x26 &&
        pos + 1 < _len &&
        src.codeUnitAt(pos + 1) == 0x26) {
      pos += 2; // consume &&
      final next = _parseClassOperand();
      acc = _intersectRanges(acc, next);
    }
    if (_peek() == 0x5d) {
      pos++; // consume ]
    } else {
      _error('Unterminated character class');
    }
    return acc;
  }

  // Parses a union of class items up to `]` or `&&` (without consuming either).
  List<_Range> _parseClassOperand() {
    final ranges = <_Range>[];
    var first = true;
    while (true) {
      final c = _peek();
      if (c == null) _error('Unterminated character class');
      if (c == 0x5d) {
        if (first) {
          // A leading ']' is a literal.
          ranges.add(const _Range(0x5d, 0x5d));
          pos++;
          first = false;
          continue;
        }
        break;
      }
      if (c == 0x26 && pos + 1 < _len && src.codeUnitAt(pos + 1) == 0x26) {
        break; // && -> intersection handled by caller
      }
      first = false;

      if (c == 0x5b) {
        // POSIX class [[:alpha:]] or a nested class.
        if (pos + 1 < _len && src.codeUnitAt(pos + 1) == 0x3a) {
          final posix = _tryParsePosixClass();
          if (posix != null) {
            ranges.addAll(posix);
            continue;
          }
        }
        // Nested class: [a-z[^\x00-\x7F]] (union).
        pos++; // consume [
        var innerNegated = false;
        if (_peek() == 0x5e) {
          innerNegated = true;
          pos++;
        }
        final inner = _parseClassSet();
        ranges.addAll(innerNegated ? _complementRanges(inner) : inner);
        continue;
      }

      final lo = _parseClassAtom(ranges);
      if (lo == null) {
        // A shorthand class (e.g. \d) was appended to [ranges] directly.
        continue;
      }
      // Range?
      if (_peek() == 0x2d &&
          pos + 1 < _len &&
          src.codeUnitAt(pos + 1) != 0x5d) {
        pos++; // consume -
        final hi = _parseClassAtom(ranges);
        if (hi == null) {
          ranges.add(_Range(lo, lo));
          ranges.add(const _Range(0x2d, 0x2d));
        } else {
          ranges.add(_Range(lo, hi));
        }
      } else {
        ranges.add(_Range(lo, lo));
      }
    }
    return ranges;
  }

  // Parses a single char inside a class and returns its code unit, or appends a
  // shorthand class (e.g. `\d`, `\p{L}`) directly to [ranges] and returns null.
  int? _parseClassAtom(List<_Range> ranges) {
    final c = _cur();
    if (c == 0x5c) {
      pos++;
      final e = _peek();
      if (e == null) _error('Trailing backslash in class');
      switch (e) {
        case 0x64: // \d
          pos++;
          ranges.add(_Range(0x30, 0x39));
          return null;
        case 0x44: // \D
          pos++;
          ranges.addAll(_complementRanges([_Range(0x30, 0x39)]));
          return null;
        case 0x77: // \w
          pos++;
          ranges.addAll(_wordRanges());
          return null;
        case 0x57: // \W
          pos++;
          ranges.addAll(_complementRanges(_wordRanges()));
          return null;
        case 0x73: // \s
          pos++;
          ranges.addAll(_spaceRanges());
          return null;
        case 0x53: // \S
          pos++;
          ranges.addAll(_complementRanges(_spaceRanges()));
          return null;
        case 0x68: // \h
          pos++;
          ranges.addAll(_hexRanges());
          return null;
        case 0x48: // \H
          pos++;
          ranges.addAll(_complementRanges(_hexRanges()));
          return null;
        case 0x70: // \p{..}
        case 0x50: // \P{..}
          final negated = e == 0x50;
          pos++;
          final props = _parseUnicodeProperty();
          ranges.addAll(negated ? _complementRanges(props) : props);
          return null;
        default:
          return _parseEscapedChar();
      }
    }
    pos++;
    return c;
  }

  List<_Range>? _tryParsePosixClass() {
    // current: '[' then ':' ... ':]'
    final start = pos;
    pos += 2; // consume [:
    bool negated = false;
    if (_peek() == 0x5e) {
      negated = true;
      pos++;
    }
    final nameStart = pos;
    while (pos < _len && _cur() != 0x3a) {
      pos++;
    }
    final name = src.substring(nameStart, pos);
    if (_peek() != 0x3a || pos + 1 >= _len || src.codeUnitAt(pos + 1) != 0x5d) {
      pos = start;
      return null;
    }
    pos += 2; // consume :]
    final ranges = _posixRanges(name);
    if (ranges == null) {
      pos = start;
      return null;
    }
    return negated ? _complementRanges(ranges) : ranges;
  }

  final List<_PendingNamed> _pendingNamed = [];

  void resolveNamed() {
    for (final p in _pendingNamed) {
      final idx = groupNames[p.name];
      if (idx == null) {
        throw RegexSyntaxException('Unknown group name <${p.name}>', src);
      }
      p.ref.group = idx;
    }
  }
}

class _PendingNamed {
  _PendingNamed(this.ref, this.name);

  final _BackrefNode ref;
  final String name;
}

bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

bool _isHexDigit(int c) =>
    (c >= 0x30 && c <= 0x39) ||
    (c >= 0x41 && c <= 0x46) ||
    (c >= 0x61 && c <= 0x66);

List<_Range> _wordRanges() => [
  _Range(0x41, 0x5a), // A-Z
  _Range(0x61, 0x7a), // a-z
  _Range(0x30, 0x39), // 0-9
  _Range(0x5f, 0x5f), // _
];

List<_Range> _spaceRanges() => [
  _Range(0x09, 0x0d), // \t \n \v \f \r
  _Range(0x20, 0x20), // space
];

List<_Range> _hexRanges() => [
  _Range(0x30, 0x39),
  _Range(0x41, 0x46),
  _Range(0x61, 0x66),
];

List<_Range>? _posixRanges(String name) {
  switch (name) {
    case 'alpha':
      return [_Range(0x41, 0x5a), _Range(0x61, 0x7a)];
    case 'digit':
      return [_Range(0x30, 0x39)];
    case 'alnum':
      return [_Range(0x30, 0x39), _Range(0x41, 0x5a), _Range(0x61, 0x7a)];
    case 'upper':
      return [_Range(0x41, 0x5a)];
    case 'lower':
      return [_Range(0x61, 0x7a)];
    case 'space':
      return [_Range(0x09, 0x0d), _Range(0x20, 0x20)];
    case 'blank':
      return [_Range(0x09, 0x09), _Range(0x20, 0x20)];
    case 'punct':
      return [
        _Range(0x21, 0x2f),
        _Range(0x3a, 0x40),
        _Range(0x5b, 0x60),
        _Range(0x7b, 0x7e),
      ];
    case 'cntrl':
      return [_Range(0x00, 0x1f), _Range(0x7f, 0x7f)];
    case 'xdigit':
      return [_Range(0x30, 0x39), _Range(0x41, 0x46), _Range(0x61, 0x66)];
    case 'print':
      return [_Range(0x20, 0x7e)];
    case 'graph':
      return [_Range(0x21, 0x7e)];
    case 'word':
      return [
        _Range(0x30, 0x39),
        _Range(0x41, 0x5a),
        _Range(0x61, 0x7a),
        _Range(0x5f, 0x5f),
      ];
    default:
      return null;
  }
}

// Approximate Unicode property support. Full category tables are impractical to
// bundle, so we use pragmatic approximations that cover the common uses in
// TextMate grammars (identifiers, letters, digits). ASCII is always exact.
const List<_Range> _letterRanges = [
  _Range(0x41, 0x5a),
  _Range(0x61, 0x7a),
  _Range(0x00aa, 0x00aa),
  _Range(0x00b5, 0x00b5),
  _Range(0x00ba, 0x00ba),
  _Range(0x00c0, 0x00d6),
  _Range(0x00d8, 0x00f6),
  _Range(0x00f8, 0x02ff),
  _Range(0x0370, 0x1fff),
  _Range(0x2c00, 0x2fef),
  _Range(0x3040, 0xd7ff),
  _Range(0xf900, 0xfdcf),
  _Range(0xfdf0, 0xffff),
];

List<_Range> _unicodePropertyRanges(String prop) {
  // Property names are matched case-insensitively (`\p{L}` and `\p{word}` are
  // both common); general-category codes such as `Lu`/`Ll` are distinguished by
  // dedicated cases below.
  final p = prop.replaceAll('_', '').replaceAll(' ', '').toLowerCase();
  switch (p) {
    case 'l':
    case 'letter':
    case 'alpha':
    case 'alphabetic':
      return _letterRanges;
    case 'lu':
    case 'uppercase':
    case 'upper':
      return const [_Range(0x41, 0x5a), _Range(0x00c0, 0x00de)];
    case 'll':
    case 'lowercase':
    case 'lower':
      return const [_Range(0x61, 0x7a), _Range(0x00df, 0x00ff)];
    case 'n':
    case 'nd':
    case 'number':
    case 'digit':
      return const [
        _Range(0x30, 0x39),
        _Range(0x0660, 0x0669),
        _Range(0xff10, 0xff19),
      ];
    case 'p':
    case 'punct':
    case 'punctuation':
      return const [
        _Range(0x21, 0x2f),
        _Range(0x3a, 0x40),
        _Range(0x5b, 0x60),
        _Range(0x7b, 0x7e),
      ];
    case 'z':
    case 'zs':
    case 'space':
    case 'whitespace':
      return const [
        _Range(0x09, 0x0d),
        _Range(0x20, 0x20),
        _Range(0x00a0, 0x00a0),
      ];
    case 'alnum':
      return const [_Range(0x30, 0x39), _Range(0x41, 0x5a), _Range(0x61, 0x7a)];
    case 'word':
      // Oniguruma `\p{word}` = alphanumeric + underscore + Unicode letters.
      return const [
        _Range(0x30, 0x39),
        _Range(0x41, 0x5a),
        _Range(0x61, 0x7a),
        _Range(0x5f, 0x5f),
        _Range(0x00aa, 0x00aa),
        _Range(0x00b5, 0x00b5),
        _Range(0x00ba, 0x00ba),
        _Range(0x00c0, 0x00d6),
        _Range(0x00d8, 0x00f6),
        _Range(0x00f8, 0x02ff),
        _Range(0x0370, 0x1fff),
        _Range(0x2c00, 0x2fef),
        _Range(0x3040, 0xd7ff),
        _Range(0xf900, 0xfdcf),
        _Range(0xfdf0, 0xffff),
      ];
    default:
      // Unknown property -> match nothing rather than crash.
      return const [];
  }
}

List<_Range> _intersectRanges(List<_Range> a, List<_Range> b) {
  final result = <_Range>[];
  for (final ra in a) {
    for (final rb in b) {
      final lo = ra.lo > rb.lo ? ra.lo : rb.lo;
      final hi = ra.hi < rb.hi ? ra.hi : rb.hi;
      if (lo <= hi) result.add(_Range(lo, hi));
    }
  }
  return result;
}

List<_Range> _complementRanges(List<_Range> ranges) {
  if (ranges.isEmpty) return [_Range(0, 0x10ffff)];
  final sorted = [...ranges]..sort((a, b) => a.lo.compareTo(b.lo));
  final result = <_Range>[];
  var next = 0;
  for (final r in sorted) {
    if (r.lo > next) {
      result.add(_Range(next, r.lo - 1));
    }
    if (r.hi + 1 > next) {
      next = r.hi + 1;
    }
  }
  if (next <= 0x10ffff) {
    result.add(_Range(next, 0x10ffff));
  }
  return result;
}

// --- Matcher -----------------------------------------------------------------

typedef _Cont = bool Function(int pos);

const int _stepBudget = 2000000;

class _Matcher {
  _Matcher(this.input, this.groupCount, this.gAnchor);

  final String input;
  final int groupCount;
  final int gAnchor;
  late final int len = input.length;
  late final List<int> groupStart = List<int>.filled(groupCount + 1, -1);
  late final List<int> groupEnd = List<int>.filled(groupCount + 1, -1);
  int steps = 0;

  /// Resets per-attempt state so a single [_Matcher] can be reused across the
  /// candidate positions of one search, instead of allocating a fresh matcher
  /// (and two group arrays) at every position. This exactly reproduces the
  /// prior "new matcher per position" semantics: each attempt starts with a
  /// fresh step budget and cleared capture groups.
  void resetForAttempt() {
    steps = 0;
    groupStart.fillRange(0, groupCount + 1, -1);
    groupEnd.fillRange(0, groupCount + 1, -1);
  }

  bool _budgetOk() => ++steps <= _stepBudget;

  bool matchNode(_Node node, int pos, _Cont k) {
    if (!_budgetOk()) return false;
    if (node is _CharNode) {
      if (pos < len &&
          _charEquals(input.codeUnitAt(pos), node.ch, node.ignoreCase)) {
        return k(pos + 1);
      }
      return false;
    }
    if (node is _ClassNode) {
      if (pos < len && _classMatches(node, input.codeUnitAt(pos))) {
        return k(pos + 1);
      }
      return false;
    }
    if (node is _AnyNode) {
      if (pos < len) {
        final c = input.codeUnitAt(pos);
        if (node.dotAll || c != 0x0a) {
          return k(pos + 1);
        }
      }
      return false;
    }
    if (node is _ConcatNode) {
      return _matchSeq(node.parts, 0, pos, k);
    }
    if (node is _AltNode) {
      for (final opt in node.options) {
        if (matchNode(opt, pos, k)) return true;
      }
      return false;
    }
    if (node is _QuantNode) {
      return _matchQuant(node, pos, k);
    }
    if (node is _GroupNode) {
      return _matchGroup(node, pos, k);
    }
    if (node is _AnchorNode) {
      if (_anchorMatches(node.kind, pos)) return k(pos);
      return false;
    }
    if (node is _LookNode) {
      return _matchLook(node, pos, k);
    }
    if (node is _BackrefNode) {
      return _matchBackref(node, pos, k);
    }
    if (node is _EmptyNode) {
      return k(pos);
    }
    return false;
  }

  bool _matchSeq(List<_Node> parts, int idx, int pos, _Cont k) {
    var i = idx;
    var p = pos;
    // Fast-forward the leading run of deterministic (non-backtracking) nodes
    // iteratively, so a literal/anchor run costs no continuation closures. Each
    // node still consumes one step, exactly matching matchNode's budget. This
    // is behaviour-identical to the CPS path for these node kinds: they either
    // match one way or fail; there is nothing to backtrack.
    while (i < parts.length) {
      if (!_budgetOk()) return false;
      final node = parts[i];
      if (node is _CharNode) {
        if (p < len &&
            _charEquals(input.codeUnitAt(p), node.ch, node.ignoreCase)) {
          p++;
          i++;
          continue;
        }
        return false;
      }
      if (node is _ClassNode) {
        if (p < len && _classMatches(node, input.codeUnitAt(p))) {
          p++;
          i++;
          continue;
        }
        return false;
      }
      if (node is _AnyNode) {
        if (p < len && (node.dotAll || input.codeUnitAt(p) != 0x0a)) {
          p++;
          i++;
          continue;
        }
        return false;
      }
      if (node is _AnchorNode) {
        if (_anchorMatches(node.kind, p)) {
          i++;
          continue;
        }
        return false;
      }
      if (node is _EmptyNode) {
        i++;
        continue;
      }
      break; // first backtracking node: hand the tail off to CPS.
    }
    if (i >= parts.length) return k(p);
    return matchNode(parts[i], p, (p2) => _matchSeq(parts, i + 1, p2, k));
  }

  bool _matchGroup(_GroupNode node, int pos, _Cont k) {
    final idx = node.captureIndex;
    if (node.atomic) {
      // Match the child greedily and commit to the first result found, then run
      // the continuation without allowing the child to backtrack.
      int? committed;
      matchNode(node.child, pos, (p2) {
        committed = p2;
        return true;
      });
      if (committed == null) return false;
      if (idx != null) {
        final savedS = groupStart[idx], savedE = groupEnd[idx];
        groupStart[idx] = pos;
        groupEnd[idx] = committed!;
        if (k(committed!)) return true;
        groupStart[idx] = savedS;
        groupEnd[idx] = savedE;
        return false;
      }
      return k(committed!);
    }
    if (idx == null) {
      return matchNode(node.child, pos, k);
    }
    final savedS = groupStart[idx], savedE = groupEnd[idx];
    final ok = matchNode(node.child, pos, (p2) {
      final innerS = groupStart[idx], innerE = groupEnd[idx];
      groupStart[idx] = pos;
      groupEnd[idx] = p2;
      if (k(p2)) return true;
      groupStart[idx] = innerS;
      groupEnd[idx] = innerE;
      return false;
    });
    if (!ok) {
      groupStart[idx] = savedS;
      groupEnd[idx] = savedE;
    }
    return ok;
  }

  bool _matchQuant(_QuantNode node, int pos, _Cont k) {
    final child = node.child;
    // Fast path for single-character children (avoids deep recursion).
    if (_isSingleChar(child)) {
      return _matchQuantSingle(node, pos, k);
    }
    if (node.possessive) {
      // Approximate possessive as greedy-with-commit at the top level.
      return _matchRep(node, 0, pos, k);
    }
    return _matchRep(node, 0, pos, k);
  }

  bool _matchRep(_QuantNode node, int count, int pos, _Cont k) {
    if (!_budgetOk()) return false;
    final canStop = count >= node.min;
    if (node.max != -1 && count >= node.max) {
      return k(pos);
    }
    if (node.greedy) {
      final more = matchNode(node.child, pos, (p2) {
        if (p2 == pos) {
          // zero-width; stop expanding to avoid infinite recursion
          return false;
        }
        return _matchRep(node, count + 1, p2, k);
      });
      if (more) return true;
      if (canStop) return k(pos);
      return false;
    } else {
      if (canStop && k(pos)) return true;
      return matchNode(node.child, pos, (p2) {
        if (p2 == pos) return false;
        return _matchRep(node, count + 1, p2, k);
      });
    }
  }

  bool _matchQuantSingle(_QuantNode node, int pos, _Cont k) {
    final child = node.child;
    final max = node.max;
    // Collect the run of matching positions.
    var p = pos;
    var count = 0;
    final positions = <int>[pos];
    while ((max == -1 || count < max) &&
        p < len &&
        _singleCharMatches(child, input.codeUnitAt(p))) {
      p++;
      count++;
      positions.add(p);
    }
    if (count < node.min) return false;
    if (node.greedy || node.possessive) {
      final lowest = node.min;
      for (var c = count; c >= lowest; c--) {
        if (k(positions[c])) return true;
        if (node.possessive) break; // no backtracking for possessive
      }
      return false;
    } else {
      for (var c = node.min; c <= count; c++) {
        if (k(positions[c])) return true;
      }
      return false;
    }
  }

  bool _matchLook(_LookNode node, int pos, _Cont k) {
    if (node.ahead) {
      final matched = matchNode(node.child, pos, (_) => true);
      if (matched != node.negative) {
        return k(pos);
      }
      return false;
    }
    // Lookbehind: does some start s in [0..pos] let child match exactly [s..pos]?
    var matched = false;
    for (var s = pos; s >= 0; s--) {
      if (matchNode(node.child, s, (e) => e == pos)) {
        matched = true;
        break;
      }
    }
    if (matched != node.negative) {
      return k(pos);
    }
    return false;
  }

  bool _matchBackref(_BackrefNode node, int pos, _Cont k) {
    final g = node.group;
    if (g < 0 || g > groupCount) return false;
    final s = groupStart[g];
    final e = groupEnd[g];
    if (s < 0 || e < 0) {
      // Unset group: match the empty string (lenient, JavaScript-like).
      return k(pos);
    }
    final length = e - s;
    if (pos + length > len) return false;
    for (var i = 0; i < length; i++) {
      if (!_charEquals(
        input.codeUnitAt(pos + i),
        input.codeUnitAt(s + i),
        node.ignoreCase,
      )) {
        return false;
      }
    }
    return k(pos + length);
  }

  bool _anchorMatches(int kind, int pos) {
    switch (kind) {
      case _anchorLineStart:
        return pos == 0 || input.codeUnitAt(pos - 1) == 0x0a;
      case _anchorLineEnd:
        return pos == len || input.codeUnitAt(pos) == 0x0a;
      case _anchorWordBoundary:
        return _isWordChar(_charBefore(pos)) != _isWordChar(_charAt(pos));
      case _anchorNotWordBoundary:
        return _isWordChar(_charBefore(pos)) == _isWordChar(_charAt(pos));
      case _anchorBufferStart:
        return pos == 0;
      case _anchorBufferEnd:
        return pos == len;
      case _anchorBufferEndBeforeNewline:
        return pos == len || (pos == len - 1 && input.codeUnitAt(pos) == 0x0a);
      case _anchorG:
        return pos == gAnchor;
    }
    return false;
  }

  int _charAt(int pos) => pos < len ? input.codeUnitAt(pos) : -1;

  int _charBefore(int pos) => pos > 0 ? input.codeUnitAt(pos - 1) : -1;
}

bool _isWordChar(int c) =>
    (c >= 0x41 && c <= 0x5a) ||
    (c >= 0x61 && c <= 0x7a) ||
    (c >= 0x30 && c <= 0x39) ||
    c == 0x5f;

bool _charEquals(int a, int b, bool ignoreCase) {
  if (a == b) return true;
  if (!ignoreCase) return false;
  return _toLower(a) == _toLower(b);
}

int _toLower(int c) {
  if (c >= 0x41 && c <= 0x5a) return c + 0x20;
  if (c < 0x80) return c;
  // Fallback for non-ASCII using Dart's Unicode-aware lowercasing.
  return String.fromCharCode(c).toLowerCase().codeUnitAt(0);
}

bool _classMatches(_ClassNode node, int c) {
  var inSet = node.containsCode(c);
  if (!inSet && node.ignoreCase) {
    final lower = _toLower(c);
    final upper = _toUpper(c);
    if (lower != c) inSet = node.containsCode(lower);
    if (!inSet && upper != c) inSet = node.containsCode(upper);
  }
  return inSet != node.negated;
}

int _toUpper(int c) {
  if (c >= 0x61 && c <= 0x7a) return c - 0x20;
  if (c < 0x80) return c;
  return String.fromCharCode(c).toUpperCase().codeUnitAt(0);
}

bool _isSingleChar(_Node node) =>
    node is _CharNode || node is _ClassNode || node is _AnyNode;

bool _singleCharMatches(_Node node, int c) {
  if (node is _CharNode) return _charEquals(c, node.ch, node.ignoreCase);
  if (node is _ClassNode) return _classMatches(node, c);
  if (node is _AnyNode) return node.dotAll || c != 0x0a;
  return false;
}

// --- Public API --------------------------------------------------------------

/// A compiled Oniguruma-subset regular expression.
class OnigRegex {
  OnigRegex._(
    this.source,
    this._root,
    this._groupCount,
    this._firstFilter,
    this._gAnchored,
    this._fast,
  );

  /// Compiles [source]. Throws [RegexSyntaxException] on unsupported syntax.
  factory OnigRegex(
    String source, {
    bool ignoreCase = false,
    bool dotAll = false,
    bool extended = false,
  }) {
    final parser = _Parser(source, _Flags(ignoreCase, dotAll, extended));
    final root = parser.parse();
    parser.resolveNamed();
    // Compile-time search prefilters (see _computeFirst / _startsWithGAnchor).
    final first = _computeFirst(root);
    final filter = (first.unknown || first.nullable || first.ranges.isEmpty)
        ? null
        : _FirstFilter.fromRanges(first.ranges);
    final gAnchored = _startsWithGAnchor(root);
    // Native-RegExp fast path: emit a Dart-RegExp-equivalent pattern (bails to
    // null on any Oniguruma-only construct). `\G`-anchored patterns already cost
    // one position in the interpreter, so they don't need it.
    RegExp? fast;
    if (!gAnchored) {
      final emitted = _emitDartRoot(root);
      if (emitted != null) {
        try {
          fast = RegExp(emitted, multiLine: true);
        } on Object {
          fast = null; // Any incompatibility -> stay on the interpreter.
        }
      }
    }
    return OnigRegex._(
      source,
      root,
      parser.groupCount,
      filter,
      gAnchored,
      fast,
    );
  }

  /// Global kill-switch for the RegExp fast path (used by the differential
  /// test to compare fast-path output against the interpreter). Read per
  /// search, so toggling it needs no recompilation.
  static bool fastPathEnabled = true;

  final String source;
  final _Node _root;
  final int _groupCount;

  /// When non-null, any match must begin by consuming a character in this set,
  /// so positions whose character is excluded are skipped before running the
  /// (expensive) backtracking matcher. Null whenever the pattern can match
  /// empty or its first character cannot be safely bounded, in which case
  /// every position is tried, exactly as before.
  final _FirstFilter? _firstFilter;

  /// True when the pattern begins with a mandatory `\G`, so a match can only
  /// occur at the anchor position and the line scan is skipped entirely.
  final bool _gAnchored;

  /// A native [RegExp] exactly equivalent to this pattern, or null when the
  /// pattern uses constructs that can't be faithfully represented in Dart
  /// RegExp. When present, it locates the left-most match position; the
  /// interpreter then re-runs there to produce authoritative capture offsets
  /// (RegExpMatch exposes none), falling back entirely on any disagreement.
  final RegExp? _fast;

  int get groupCount => _groupCount;

  /// Whether this pattern compiled to a native-`RegExp` fast path (vs. falling
  /// back to the interpreter). Exposed for diagnostics/coverage measurement.
  bool get hasFastPath => _fast != null;

  /// Searches for the left-most match at or after [from].
  ///
  /// [gAnchor] is the position that `\G` anchors to (the search start position).
  OnigEngineMatch? search(String input, int from, {int? gAnchor}) {
    final anchor = gAnchor ?? from;
    final end = input.length;
    // One matcher, reused across every candidate position in this search.
    final matcher = _Matcher(input, _groupCount, anchor);

    if (_gAnchored) {
      if (anchor < from || anchor > end) return null;
      return _matchAt(matcher, input, anchor);
    }

    final fast = _fast;
    if (fast != null && fastPathEnabled) {
      // Locate the left-most match at or after `from` with the compiled engine.
      final it = fast.allMatches(input, from).iterator;
      if (!it.moveNext()) return null;
      final rm = it.current;
      if (_groupCount == 0) {
        // No capture groups: the whole-match offsets are everything the
        // tokenizer needs, so skip the interpreter entirely.
        return OnigEngineMatch(<int>[rm.start], <int>[rm.end]);
      }
      // Otherwise re-run the interpreter at that single position to recover the
      // per-group offsets (RegExpMatch exposes none).
      final m = _matchAt(matcher, input, rm.start);
      if (m != null) return m;
      // Parity broke (should not happen for the emitted subset): fall back to a
      // full interpreter scan so correctness never depends on the fast path.
      return _interpretSearch(matcher, input, from, end);
    }

    return _interpretSearch(matcher, input, from, end);
  }

  OnigEngineMatch? _interpretSearch(
    _Matcher matcher,
    String input,
    int from,
    int end,
  ) {
    final filter = _firstFilter;
    for (var pos = from; pos <= end; pos++) {
      if (filter != null) {
        // A non-nullable pattern can't match at the end, and can only start on
        // a character in its first-set.
        if (pos == end) break;
        final c = input.codeUnitAt(pos);
        if (c < 128 ? !filter.ascii[c] : !filter.anyAbove) continue;
      }
      final m = _matchAt(matcher, input, pos);
      if (m != null) return m;
    }
    return null;
  }

  OnigEngineMatch? _matchAt(_Matcher matcher, String input, int pos) {
    matcher.resetForAttempt();
    int? endPos;
    final ok = matcher.matchNode(_root, pos, (p) {
      endPos = p;
      return true;
    });
    if (!ok || endPos == null) return null;
    final start = List<int>.filled(_groupCount + 1, -1);
    final end = List<int>.filled(_groupCount + 1, -1);
    start[0] = pos;
    end[0] = endPos!;
    for (var i = 1; i <= _groupCount; i++) {
      start[i] = matcher.groupStart[i];
      end[i] = matcher.groupEnd[i];
    }
    return OnigEngineMatch(start, end);
  }
}

// --- Search prefilters -------------------------------------------------------

/// Conservative description of how a node can begin matching, used to build the
/// first-character search filter. Everything defaults to "unknown" so the
/// filter can only ever skip a position when it is provably safe to do so.
class _FirstInfo {
  _FirstInfo({
    required this.nullable,
    required this.unknown,
    required this.ranges,
  });

  /// The node can match while consuming no input.
  final bool nullable;

  /// The first consumed character can't be safely bounded (so: don't filter).
  final bool unknown;

  /// Possible first code units (valid only when [unknown] is false).
  final List<_Range> ranges;

  static final _FirstInfo zeroWidth = _FirstInfo(
    nullable: true,
    unknown: false,
    ranges: const [],
  );
  static final _FirstInfo any = _FirstInfo(
    nullable: false,
    unknown: true,
    ranges: const [],
  );
}

/// Fast membership test for the first-character filter.
class _FirstFilter {
  _FirstFilter(this.ascii, this.anyAbove);

  final List<bool> ascii; // length 128
  final bool anyAbove; // some allowed code unit is >= 128

  factory _FirstFilter.fromRanges(List<_Range> ranges) {
    final ascii = List<bool>.filled(128, false);
    var anyAbove = false;
    for (final r in ranges) {
      final start = r.lo < 0 ? 0 : r.lo;
      final hiAscii = r.hi < 128 ? r.hi : 127;
      for (var c = start; c <= hiAscii; c++) {
        ascii[c] = true;
      }
      if (r.hi > 127) anyAbove = true;
    }
    return _FirstFilter(ascii, anyAbove);
  }
}

/// Computes a conservative [_FirstInfo] for [node]. Any construct whose first
/// character can't be pinned down (`.`, negated/`i`-folded classes, backrefs,
/// unknown nodes) yields [_FirstInfo.any], which disables filtering.
_FirstInfo _computeFirst(_Node node) {
  if (node is _EmptyNode) return _FirstInfo.zeroWidth;
  if (node is _AnchorNode) return _FirstInfo.zeroWidth; // zero-width
  if (node is _LookNode) return _FirstInfo.zeroWidth; // zero-width assertion
  if (node is _CharNode) {
    if (node.ignoreCase) {
      final lo = _toLower(node.ch);
      final up = _toUpper(node.ch);
      if (node.ch > 0x7f) return _FirstInfo.any; // non-ASCII folding: be safe
      final ranges = <_Range>[_Range(node.ch, node.ch)];
      if (lo != node.ch) ranges.add(_Range(lo, lo));
      if (up != node.ch) ranges.add(_Range(up, up));
      return _FirstInfo(nullable: false, unknown: false, ranges: ranges);
    }
    return _FirstInfo(
      nullable: false,
      unknown: false,
      ranges: [_Range(node.ch, node.ch)],
    );
  }
  if (node is _ClassNode) {
    if (node.negated || node.ignoreCase) return _FirstInfo.any;
    return _FirstInfo(nullable: false, unknown: false, ranges: node.ranges);
  }
  if (node is _AnyNode) return _FirstInfo.any;
  if (node is _BackrefNode) return _FirstInfo.any;
  if (node is _GroupNode) return _computeFirst(node.child);
  if (node is _ConcatNode) {
    final ranges = <_Range>[];
    for (final part in node.parts) {
      final pf = _computeFirst(part);
      if (pf.unknown) return _FirstInfo.any;
      ranges.addAll(pf.ranges);
      if (!pf.nullable) {
        return _FirstInfo(nullable: false, unknown: false, ranges: ranges);
      }
    }
    return _FirstInfo(nullable: true, unknown: false, ranges: ranges);
  }
  if (node is _AltNode) {
    final ranges = <_Range>[];
    var nullable = false;
    for (final opt in node.options) {
      final of = _computeFirst(opt);
      if (of.unknown) return _FirstInfo.any;
      ranges.addAll(of.ranges);
      nullable = nullable || of.nullable;
    }
    return _FirstInfo(nullable: nullable, unknown: false, ranges: ranges);
  }
  if (node is _QuantNode) {
    if (node.max == 0) return _FirstInfo.zeroWidth;
    final cf = _computeFirst(node.child);
    if (cf.unknown) return _FirstInfo.any;
    return _FirstInfo(
      nullable: node.min == 0 || cf.nullable,
      unknown: false,
      ranges: cf.ranges,
    );
  }
  return _FirstInfo.any; // unknown node kind -> safe
}

/// True when the leading mandatory node of [node] is `\G`, meaning a match can
/// only occur at the anchor position.
bool _startsWithGAnchor(_Node node) {
  if (node is _AnchorNode) return node.kind == _anchorG;
  if (node is _GroupNode) return _startsWithGAnchor(node.child);
  if (node is _ConcatNode) {
    return node.parts.isNotEmpty && _startsWithGAnchor(node.parts.first);
  }
  return false;
}

// --- AST -> Dart RegExp emitter (native fast path) ---------------------------

/// Emit-time state so a single pattern can be lowered consistently.
class _EmitCtx {
  _EmitCtx({required this.emulate});

  /// Whether it is safe to add capturing helper groups (for atomic-group
  /// emulation). True only when the pattern has no back-references, so that
  /// inserting helper groups can't renumber anything the pattern refers to.
  final bool emulate;

  /// Count of capturing groups emitted so far, used to number atomic helper
  /// groups and their back-references. In [emulate] mode the real groups are
  /// emitted non-capturing, so the only capturing groups are the helpers.
  int groups = 0;
}

/// True if [node] contains any back-reference (which pins group numbering).
bool _hasBackref(_Node node) {
  if (node is _BackrefNode) return true;
  if (node is _GroupNode) return _hasBackref(node.child);
  if (node is _QuantNode) return _hasBackref(node.child);
  if (node is _LookNode) return _hasBackref(node.child);
  if (node is _ConcatNode) {
    for (final p in node.parts) {
      if (_hasBackref(p)) return true;
    }
    return false;
  }
  if (node is _AltNode) {
    for (final o in node.options) {
      if (_hasBackref(o)) return true;
    }
    return false;
  }
  return false;
}

String? _emitDartRoot(_Node root) =>
    _emitDart(root, _EmitCtx(emulate: !_hasBackref(root)));

/// Emits a Dart-`RegExp`-compatible source string that is *exactly* equivalent
/// to [node], or null if any construct can't be faithfully represented.
///
/// Parity is by construction: the parser has already lowered `\w \d \s`, POSIX
/// classes and unicode-property escapes into explicit code-unit ranges, and `.`
/// into an [_AnyNode], so we emit concrete `\uXXXX` ranges (ASCII-exact) rather
/// than re-serializing shorthand whose meaning could drift between engines.
/// Every literal is emitted as a `\uXXXX` escape to sidestep metacharacter
/// escaping entirely.
///
/// Emulated constructs (widen coverage; validated by the differential test):
///  * atomic groups `(?>P)` -> `(?=(P))\N` (a lookahead-capture + back-ref),
///    only when the pattern has no back-references (see [_EmitCtx.emulate]);
///  * case-insensitive nodes (ASCII) -> inline flag group `(?i:…)`;
///  * `\A` -> `(?<![\s\S])`, `\z` -> `(?![\s\S])` (absolute start/end that
///    coexist with our `multiLine` `^`/`$`).
///
/// Still bailed to the interpreter: possessive quantifiers, `\Z`/`\G`, dotAll
/// `.`, non-ASCII case folding, astral-plane ranges.
String? _emitDart(_Node node, _EmitCtx ctx) {
  if (node is _EmptyNode) return '';
  if (node is _CharNode) {
    if (node.ignoreCase) {
      if (node.ch > 0x7f) return null; // non-ASCII folding: stay on interpreter
      return '(?i:${_uEsc(node.ch)})';
    }
    return _uEsc(node.ch);
  }
  if (node is _AnyNode) {
    if (node.dotAll) return null;
    return '[^${_uEsc(0x0a)}]'; // interpreter '.' == any-but-newline
  }
  if (node is _ClassNode) {
    final sb = StringBuffer('[');
    if (node.negated) sb.write('^');
    for (final r in node.ranges) {
      if (r.lo > 0xffff || r.hi > 0xffff) {
        return null; // BMP only (UTF-16 units)
      }
      if (node.ignoreCase && r.hi > 0x7f) return null; // ASCII folding only
      if (r.lo == r.hi) {
        sb.write(_uEsc(r.lo));
      } else {
        sb
          ..write(_uEsc(r.lo))
          ..write('-')
          ..write(_uEsc(r.hi));
      }
    }
    sb.write(']');
    return node.ignoreCase ? '(?i:${sb.toString()})' : sb.toString();
  }
  if (node is _AnchorNode) {
    switch (node.kind) {
      case _anchorLineStart:
        return '^';
      case _anchorLineEnd:
        return r'$';
      case _anchorWordBoundary:
        return r'\b';
      case _anchorNotWordBoundary:
        return r'\B';
      case _anchorBufferStart:
        return r'(?<![\s\S])'; // \A: only the absolute start of input
      case _anchorBufferEnd:
        return r'(?![\s\S])'; // \z: only the absolute end of input
      default:
        return null; // \Z, \G have no faithful Dart equivalent here
    }
  }
  if (node is _GroupNode) {
    if (node.atomic) {
      if (!ctx.emulate)
        return null; // can't add helper groups when back-refs exist
      final n = ++ctx.groups; // helper is the next capturing group
      final child = _emitDart(node.child, ctx);
      if (child == null) return null;
      return '(?=($child))\\$n';
    }
    final child = _emitDart(node.child, ctx);
    if (child == null) return null;
    // In emulate mode there are no back-refs, so real groups need not capture.
    if (ctx.emulate) return '(?:$child)';
    return node.captureIndex == null ? '(?:$child)' : '($child)';
  }
  if (node is _ConcatNode) {
    final sb = StringBuffer();
    for (final part in node.parts) {
      final e = _emitDart(part, ctx);
      if (e == null) return null;
      sb.write(e);
    }
    return sb.toString();
  }
  if (node is _AltNode) {
    final parts = <String>[];
    for (final opt in node.options) {
      final e = _emitDart(opt, ctx);
      if (e == null) return null;
      parts.add(e);
    }
    return '(?:${parts.join('|')})';
  }
  if (node is _QuantNode) {
    if (node.possessive) return null;
    final child = _emitDart(node.child, ctx);
    if (child == null) return null;
    final q = _quantStr(node.min, node.max);
    return '(?:$child)$q${node.greedy ? '' : '?'}';
  }
  if (node is _LookNode) {
    final child = _emitDart(node.child, ctx);
    if (child == null) return null;
    if (node.ahead) return node.negative ? '(?!$child)' : '(?=$child)';
    return node.negative ? '(?<!$child)' : '(?<=$child)';
  }
  if (node is _BackrefNode) {
    if (node.ignoreCase || node.group <= 0) return null;
    return '\\${node.group}';
  }
  return null; // unknown node kind -> interpreter
}

String _quantStr(int min, int max) {
  if (min == 0 && max == -1) return '*';
  if (min == 1 && max == -1) return '+';
  if (min == 0 && max == 1) return '?';
  if (max == -1) return '{$min,}';
  if (min == max) return '{$min}';
  return '{$min,$max}';
}

/// A code unit as a `\uXXXX` escape, unambiguous inside and outside classes.
String _uEsc(int c) => '\\u${c.toRadixString(16).padLeft(4, '0')}';
