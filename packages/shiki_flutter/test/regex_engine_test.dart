import 'package:flutter_test/flutter_test.dart';
import 'package:shiki_flutter/src/onig/regex_engine.dart';

/// Helper: match [pattern] against [input] from [from] and return the matched
/// substring, or null.
String? matchStr(String pattern, String input, {int from = 0}) {
  final re = OnigRegex(pattern);
  final m = re.search(input, from);
  if (m == null) return null;
  return input.substring(m.start[0], m.end[0]);
}

void main() {
  group('literals and basics', () {
    test('literal match', () {
      expect(matchStr('abc', 'xxabcxx'), 'abc');
    });

    test('search from offset', () {
      final re = OnigRegex('a');
      final m = re.search('banana', 2);
      expect(m!.index, 3);
    });

    test('dot does not match newline', () {
      expect(matchStr('a.c', 'a\nc'), isNull);
      expect(matchStr('a.c', 'abc'), 'abc');
    });

    test('alternation', () {
      expect(matchStr('cat|dog', 'a dog'), 'dog');
    });
  });

  group('quantifiers', () {
    test('greedy star', () {
      expect(matchStr('a*', 'aaab'), 'aaa');
    });

    test('lazy star', () {
      expect(matchStr('a*?b', 'aaab'), 'aaab');
      expect(matchStr('".*?"', 'x "a" "b"'), '"a"');
    });

    test('plus', () {
      expect(matchStr(r'\d+', 'abc123def'), '123');
    });

    test('interval {n,m}', () {
      expect(matchStr('a{2,3}', 'aaaa'), 'aaa');
      expect(matchStr('a{2}', 'aaaa'), 'aa');
      expect(matchStr('a{2,}', 'aaaa'), 'aaaa');
    });

    test('optional', () {
      expect(matchStr('colou?r', 'color'), 'color');
      expect(matchStr('colou?r', 'colour'), 'colour');
    });

    test('possessive does not over-match wrongly', () {
      expect(matchStr('a++', 'aaa'), 'aaa');
    });
  });

  group('character classes', () {
    test('range', () {
      expect(matchStr('[a-f]+', '123abcz'), 'abc');
    });

    test('negated class', () {
      expect(matchStr('[^0-9]+', 'abc123'), 'abc');
    });

    test('shorthand in class', () {
      expect(matchStr(r'[\w]+', ' hello '), 'hello');
      expect(matchStr(r'[\d.]+', 'v1.2.3'), '1.2.3');
    });

    test('posix class', () {
      expect(matchStr('[[:alpha:]]+', '12ab34'), 'ab');
    });

    test('escaped chars in class', () {
      expect(matchStr(r'[\t ]+', 'x\t  y'), '\t  ');
    });
  });

  group('groups and captures', () {
    test('capture indices', () {
      final re = OnigRegex(r'(\w+)\s+(\w+)');
      final m = re.search('  foo bar  ', 0)!;
      expect(m.start[0], 2);
      expect(m.end[0], 9);
      expect('foo bar'.substring(0), 'foo bar');
      expect(m.start[1], 2);
      expect(m.end[1], 5); // foo
      expect(m.start[2], 6);
      expect(m.end[2], 9); // bar
    });

    test('non-capturing group', () {
      final re = OnigRegex(r'(?:ab)+');
      final m = re.search('ababab', 0)!;
      expect(m.end[0], 6);
      expect(re.groupCount, 0);
    });

    test('named group', () {
      final re = OnigRegex(r'(?<word>\w+)');
      final m = re.search('  hi', 0)!;
      expect(m.start[1], 2);
      expect(m.end[1], 4);
    });

    test('nested groups', () {
      final re = OnigRegex(r'((a)(b))');
      final m = re.search('ab', 0)!;
      expect(m.end[1], 2);
      expect(m.start[2], 0);
      expect(m.end[2], 1);
      expect(m.start[3], 1);
      expect(m.end[3], 2);
    });
  });

  group('anchors', () {
    test('caret line start', () {
      final re = OnigRegex(r'^\w+');
      expect(re.search('  ab', 0), isNull);
      expect(matchStr(r'^\s*x', '   x'), '   x');
    });

    test('A buffer start only matches at 0', () {
      final re = OnigRegex(r'\Aabc');
      expect(re.search('abc', 0)!.index, 0);
      expect(re.search('xabc', 1), isNull);
    });

    test('G anchor matches only at gAnchor', () {
      final re = OnigRegex(r'\Gabc');
      expect(re.search('xxabc', 2, gAnchor: 2)!.index, 2);
      expect(re.search('xxabc', 0, gAnchor: 0), isNull);
    });

    test('word boundary', () {
      expect(matchStr(r'\bword\b', 'a word here'), 'word');
      expect(matchStr(r'\bcat\b', 'category'), isNull);
    });

    test('dollar end of line', () {
      expect(matchStr(r'x$', 'ax\nb'), 'x');
    });
  });

  group('lookaround', () {
    test('positive lookahead', () {
      expect(matchStr(r'foo(?=bar)', 'foobar'), 'foo');
      expect(matchStr(r'foo(?=bar)', 'foobaz'), isNull);
    });

    test('negative lookahead', () {
      expect(matchStr(r'foo(?!bar)', 'foobaz'), 'foo');
      expect(matchStr(r'foo(?!bar)', 'foobar'), isNull);
    });

    test('positive lookbehind', () {
      expect(matchStr(r'(?<=\$)\d+', r'price $42'), '42');
    });

    test('negative lookbehind', () {
      expect(matchStr(r'(?<!\d)x', '1x'), isNull);
      expect(matchStr(r'(?<!\d)\w', ' a1'), 'a');
    });
  });

  group('escapes and flags', () {
    test('escaped metacharacters', () {
      expect(matchStr(r'\.\+', 'a.+b'), '.+');
      expect(matchStr(r'a\|b', 'a|b'), 'a|b');
    });

    test('hex and unicode escapes', () {
      expect(matchStr(r'\x41', 'ABC'), 'A');
      expect(matchStr(r'A', 'ABC'), 'A');
    });

    test('inline case-insensitive flag', () {
      expect(matchStr('(?i)abc', 'ABC'), 'ABC');
      expect(matchStr('(?i:foo)bar', 'FOObar'), 'FOObar');
    });

    test('constructor ignoreCase', () {
      final re = OnigRegex('abc', ignoreCase: true);
      expect(re.search('xABC', 0)!.index, 1);
    });
  });

  group('backreferences', () {
    test('numeric backref', () {
      expect(matchStr(r'(ab)\1', 'abab'), 'abab');
      expect(matchStr(r'(a+)\1', 'aaaa'), 'aaaa');
    });
  });

  group('real grammar patterns', () {
    test('number literal', () {
      expect(matchStr(r'\b\d+(\.\d+)?\b', 'x = 3.14;'), '3.14');
    });

    test('double-quoted string', () {
      expect(matchStr(r'"[^"\\]*(\\.[^"\\]*)*"', r'say "a\"b" end'), r'"a\"b"');
    });

    test('identifier', () {
      expect(matchStr(r'[A-Za-z_][A-Za-z0-9_]*', '123 foo_bar42'), 'foo_bar42');
    });

    test('line comment', () {
      expect(matchStr('//.*', 'code // comment'), '// comment');
    });
  });
}
