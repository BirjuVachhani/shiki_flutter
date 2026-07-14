// Proves the package compiles to JS (web-safe: no dart:ffi leakage) and that
// the web backend degrades gracefully. Not a runtime test — the check is that
// `dart compile js tool/web_smoke.dart` succeeds.
//
//   dart compile js tool/web_smoke.dart -o /tmp/oniguruma_web_smoke.js
// ignore_for_file: avoid_print

import 'package:oniguruma/oniguruma.dart';

void main() {
  print('isOnigurumaSupported = $isOnigurumaSupported');
  if (isOnigurumaSupported) {
    final scanner = OnigScanner([r'\d+']);
    final s = OnigString('abc123');
    print(scanner.findNextMatch(s, 0)?.captureIndices.first.start);
    s.dispose();
    scanner.dispose();
  } else {
    print('web: use a pure-Dart engine');
  }
}
