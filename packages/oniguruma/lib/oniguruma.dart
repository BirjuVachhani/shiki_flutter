/// Dart bindings to the Oniguruma regular-expression library.
///
/// Presents one API on every platform — [OnigScanner], [OnigString],
/// [OnigMatch] — but the engine behind it depends on the platform:
///
///  * **IO** (mobile, desktop, server): the real Oniguruma C library, compiled
///    from source by the build hook and called via `dart:ffi`.
///  * **Web**: no native engine (see below); [isOnigurumaSupported] is `false`
///    and constructing an [OnigScanner] throws. Use a pure-Dart engine there.
///
/// Always check [isOnigurumaSupported] before constructing an [OnigScanner] if
/// your code runs on web:
///
/// ```dart
/// if (isOnigurumaSupported) {
///   final scanner = OnigScanner(patterns);
///   // ...fast native path...
/// } else {
///   // ...pure-Dart fallback...
/// }
/// ```
///
/// Why no WebAssembly on web: driving an Oniguruma WASM build over
/// `dart:js_interop` incurs heavy per-call marshalling and a WASM CSP burden,
/// and Shiki's own data shows native-`RegExp` transpilation is smaller and
/// often faster. The web story therefore belongs to a pure-Dart engine, not
/// this package.
library;

export 'src/types.dart';

// Default to the web backend (no dart:ffi); upgrade to the native FFI backend
// wherever dart:ffi is available.
export 'src/backend_web.dart'
    if (dart.library.ffi) 'src/backend_ffi.dart';
