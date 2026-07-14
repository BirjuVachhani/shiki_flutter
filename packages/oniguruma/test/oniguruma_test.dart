import 'package:oniguruma/oniguruma.dart';
import 'package:test/test.dart';

void main() {
  test('native engine is available on this (IO) platform', () {
    expect(isOnigurumaSupported, isTrue);
  });

  test('links and reports a version', () {
    expect(onigVersion(), matches(RegExp(r'^\d+\.\d+\.\d+')));
  });

  test('scanner finds the left-most / earliest pattern', () {
    final scanner = OnigScanner([r'\d+', r'[a-z]+']);
    final s = OnigString('  abc123');
    addTearDown(() {
      s.dispose();
      scanner.dispose();
    });

    final m = scanner.findNextMatch(s, 0);
    expect(m, isNotNull);
    expect(m!.index, 1); // [a-z]+ matches at 2, before \d+ at 5
    expect(m.captureIndices[0].start, 2);
    expect(m.captureIndices[0].end, 5);
  });

  test('capture group offsets are correct (UTF-16 indices)', () {
    final scanner = OnigScanner([r'(\w+)@(\w+)']);
    final s = OnigString('x foo@bar');
    addTearDown(() {
      s.dispose();
      scanner.dispose();
    });

    final m = scanner.findNextMatch(s, 0)!;
    expect(m.captureIndices[0].start, 2); // whole match "foo@bar"
    expect(m.captureIndices[0].end, 9);
    expect(m.captureIndices[1].start, 2); // group 1 "foo"
    expect(m.captureIndices[1].end, 5);
    expect(m.captureIndices[2].start, 6); // group 2 "bar"
    expect(m.captureIndices[2].end, 9);
  });

  test('no match returns null', () {
    final scanner = OnigScanner([r'\d+']);
    final s = OnigString('no digits here');
    addTearDown(() {
      s.dispose();
      scanner.dispose();
    });
    expect(scanner.findNextMatch(s, 0), isNull);
  });
}
