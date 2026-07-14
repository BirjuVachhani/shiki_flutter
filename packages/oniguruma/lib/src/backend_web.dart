/// Web backend — selected when `dart:ffi` is unavailable (browsers).
///
/// There is deliberately **no** Oniguruma engine here. Compiling Oniguruma to
/// WebAssembly and driving it over `dart:js_interop` means heavy per-call
/// Dart→JS→wasm marshalling, a WASM `unsafe-eval` CSP burden, and — per Shiki's
/// own measurements — a result that native `RegExp` transpilation (their JS
/// engine / oniguruma-to-es) already beats on size and speed. So on web the
/// right engine is a pure-Dart one whose `RegExp` fast path lowers to the
/// platform's native regex (that lives in `shiki_flutter`, not here).
///
/// This backend exists so the package **compiles and links on every platform**.
/// Guard construction with [isOnigurumaSupported] and fall back accordingly.
library;

import 'types.dart';

/// False: no native Oniguruma engine on web.
const bool isOnigurumaSupported = false;

Never _unsupported() => throw UnsupportedError(
      'The native Oniguruma engine is unavailable on web (no dart:ffi). '
      'Check `isOnigurumaSupported` and use a pure-Dart highlighter engine on '
      'web instead.',
    );

/// Not available on web — see [isOnigurumaSupported].
String onigVersion() => _unsupported();

/// API-compatible with the FFI backend, but inert. Holding a string is cheap
/// and never throws; only scanning does.
class OnigString {
  OnigString(this.text);
  final String text;
  void dispose() {}
}

/// API-compatible with the FFI backend. Throws on construction because there is
/// no web engine; callers must gate on [isOnigurumaSupported].
class OnigScanner {
  OnigScanner(List<String> patterns) {
    _unsupported();
  }

  OnigMatch? findNextMatch(OnigString string, int startPosition) =>
      _unsupported();

  void dispose() {}
}
