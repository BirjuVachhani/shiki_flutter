// Validates the widened fast-path emitter (atomic groups, \A/\z anchors,
// case-insensitivity) against the interpreter at the OnigScanner level. For
// each pattern: assert whether it takes the fast path, then assert the fast
// path and interpreter return byte-identical matches on crafted inputs.

import 'package:flutter_test/flutter_test.dart';
import 'package:shiki_flutter/src/onig/onig.dart';
import 'package:shiki_flutter/src/onig/regex_engine.dart';

String? _desc(OnigMatch? m) => m == null
    ? null
    : '${m.index}:${m.captureIndices.map((c) => '${c.start}-${c.end}').join(',')}';

/// Asserts fast-path output == interpreter output for [pattern] on [input].
void _diff(String pattern, String input, {int from = 0}) {
  final sc = DartOnigScanner([pattern]);
  OnigRegex.fastPathEnabled = false;
  final interp = _desc(sc.findNextMatch(input, from));
  OnigRegex.fastPathEnabled = true;
  final fast = _desc(sc.findNextMatch(input, from));
  expect(
    fast,
    interp,
    reason: 'fast vs interpreter for /$pattern/ @$from on "$input"',
  );
}

void main() {
  tearDown(() => OnigRegex.fastPathEnabled = true);

  group('atomic groups', () {
    test('take the fast path', () {
      expect(OnigRegex(r'(?>a+)b').hasFastPath, isTrue);
      expect(OnigRegex(r'(?>(a+))(b+)').hasFastPath, isTrue);
    });
    test('match parity incl. true atomicity (no backtracking)', () {
      _diff(r'(?>a+)b', 'aaab'); // matches "aaab"
      _diff(r'(?>a+)ab', 'aaab'); // atomic -> no match (greedy would match)
      _diff(r'(?>a+)ab', 'ab'); // no match
      _diff(r'(?>(a+))(b+)', 'aaabbb'); // captures via interpreter-extract
      _diff(r'x(?>\d+)y', 'x123y');
    });
  });

  group(r'anchors \A \z', () {
    test('take the fast path', () {
      expect(OnigRegex(r'\Aabc').hasFastPath, isTrue);
      expect(OnigRegex(r'abc\z').hasFastPath, isTrue);
    });
    test('match parity at start/end and mid positions', () {
      _diff(r'\Aabc', 'abc');
      _diff(r'\Aabc', 'xabc', from: 1); // \A only at absolute start
      _diff(r'abc\z', 'abc');
      _diff(r'abc\z', 'abcd'); // \z requires end -> no match
    });
  });

  group('case-insensitive', () {
    test('take the fast path', () {
      expect(OnigRegex(r'(?i)abc').hasFastPath, isTrue);
      expect(OnigRegex(r'(?i)[a-f]+').hasFastPath, isTrue);
    });
    test('match parity for chars and classes', () {
      _diff(r'(?i)abc', 'ABC');
      _diff(r'(?i)aBc', 'AbC');
      _diff(r'(?i)[a-f]+', 'ABCdefG');
      _diff(r'(?i)key', 'the KEY here');
    });
  });

  group('safe bail: back-ref + atomic stays on the interpreter', () {
    test('no fast path, still correct', () {
      expect(OnigRegex(r'(a)\1(?>b+)').hasFastPath, isFalse);
      _diff(r'(a)\1(?>b+)', 'aabbb');
    });
  });
}
