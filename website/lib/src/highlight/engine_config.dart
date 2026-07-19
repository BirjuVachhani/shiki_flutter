// Platform-split highlighter configuration for the site.
//
// The native Oniguruma engine (dart:ffi) is referenced ONLY from the IO variant,
// so the web build never compiles in `oniguruma_native` or its WebAssembly glue:
// the web target stays on the pure-Dart embedded engine. `dart.library.js_interop`
// is defined only on web, so the VM resolves to the IO file and web to the web
// file (the same conditional-import idiom shiki_flutter uses for its workers).
export 'engine_config_io.dart'
    if (dart.library.js_interop) 'engine_config_web.dart';
