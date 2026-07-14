# oniguruma

Dart bindings to the [Oniguruma](https://github.com/kkos/oniguruma)
regular-expression library — the engine TextMate grammars (and therefore
Shiki / VS Code syntax highlighting) are written for.

One API on every platform (`OnigScanner`, `OnigString`, `OnigMatch`); the engine
behind it depends on where you run:

| Platform | Engine | `isOnigurumaSupported` |
|----------|--------|:----------------------:|
| Android / iOS / macOS / Linux / Windows / server | Real Oniguruma C, compiled from vendored source by a Dart **build hook** and called via `dart:ffi` | `true` |
| Web (dart2js / dart2wasm) | none — construction throws | `false` |

The package **compiles and links on all platforms**; on web it degrades
gracefully so a consumer can detect and fall back:

```dart
import 'package:oniguruma/oniguruma.dart';

if (isOnigurumaSupported) {
  final scanner = OnigScanner([r'\b\w+\b', r'\d+']);
  final s = OnigString('foo 123');
  final m = scanner.findNextMatch(s, 0); // {index, captureIndices[]}
  s.dispose();
  scanner.dispose();
} else {
  // Web: use a pure-Dart highlighter engine instead.
}
```

Offsets are UTF-16 code units (matching Dart `String` indices); the native
backend uses Oniguruma's UTF-16LE encoding so no offset remapping is needed.

## How the native build works

`hook/build.dart` produces the `package:oniguruma/oniguruma_ffi` code asset in
one of two ways:

1. **Prebuilt (default).** If a library ships for the target under `prebuilt/`,
   it is bundled directly — no compiler and no network — after a SHA-256 check
   against `prebuilt/checksums.sha256` (a mismatch fails the build). Each blob is
   one dynamic library containing Oniguruma plus our shim
   (`src/oniguruma_shim.c`). Since Oniguruma is archived, they never change.
2. **Build from source (fallback).** For any target without a prebuilt — or
   when a consumer sets the `oniguruma.from_source` user-define — the hook
   downloads the pinned Oniguruma source release, verifies its SHA-256,
   extracts it, and compiles it with the shim via `package:native_toolchain_c`'s
   `CBuilder`. The C sources are **not** vendored in the package; they are
   fetched on demand. This path needs a C toolchain.

The shim runs the whole multi-pattern `findNextMatch` scan loop in C so there is
exactly one FFI crossing per query.

- Flutter apps must enable native assets: `flutter config --enable-native-assets`.
- Per-platform `config.h` variants for the source fallback live in `src/config/`.

## Why there is no WebAssembly backend on web

Compiling Oniguruma to WASM and driving it from Dart over `dart:js_interop`
would mean:

- heavy per-call **Dart → JS → wasm-heap** marshalling (no shared memory like
  FFI) for the tens of thousands of `findNextMatch` calls a tokenizer makes;
- a WebAssembly `unsafe-eval` **CSP** burden; and
- chasing a speedup that, per Shiki's own measurements, **native `RegExp`
  transpilation already beats** on both bundle size (~4%) and speed.

So on web the right engine is a pure-Dart one whose `RegExp` fast path lowers to
the platform's native regex — that lives in the highlighter
(`shiki_flutter`), not in this package. See
`../benchmark/results/web_wasm_analysis.md` for the full analysis.

## Status

Experimental (0.1.0). Native backend verified on macOS/arm64; web verified to
compile (`dart compile js`) and degrade gracefully.
