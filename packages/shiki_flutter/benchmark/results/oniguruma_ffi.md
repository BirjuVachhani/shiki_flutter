# Oniguruma via Dart FFI (IO) vs our optimized Dart engine

A real, working `oniguruma` Dart package (`/oniguruma`) now compiles Oniguruma
6.9.10 from vendored C source via **Dart build hooks** (`hook/build.dart` →
`CBuilder` → bundled code asset) and exposes an FFI bridge. A thin C shim
(`src/oniguruma_shim.c`) runs the whole multi-pattern `findNextMatch` scan loop
in C (one FFI crossing per query, like vscode-oniguruma) and uses UTF-16LE so
offsets line up 1:1 with Dart `String` indices.

Benchmarked by replaying the **exact same captured query stream** used for the
standalone-C comparison (`/tmp/onig_bench/workload_*.bin`) through the FFI
bridge — so all three numbers are directly comparable.

## Results (darwin-arm64, warm, median of 5)

| workload | our Dart engine | Oniguruma **via FFI** | Oniguruma standalone C (no FFI) |
|----------|----------------:|----------------------:|--------------------------------:|
| corpus m (2,558 ops)  | 35.3 ms · 72.5k ops/s | 16.2 ms · **157.9k ops/s** | 11.4 ms · 224.6k ops/s |
| corpus xl (25,473 ops) | 342 ms · 74.2k ops/s | 160.8 ms · **158.4k ops/s** | 114 ms · 223.3k ops/s |

FFI matched exactly the same ops as the standalone C build (20,352 at xl),
confirming the shim reproduces Oniguruma's match decisions.

## What this tells us

- **Oniguruma via Dart FFI is ~2.1× faster** than our optimized pure-Dart
  engine on this workload (158.4k vs 74.2k ops/s at xl).
- **FFI overhead is real but modest**: FFI runs at ~71% of standalone-C speed
  (158k vs 223k ops/s) — i.e. the Dart↔C crossings cost ~1.4×. The C-side scan
  loop (one crossing per `findNextMatch`) is what keeps it this cheap; a
  per-pattern crossing design would have been far worse.
- The pure-C 3.0× advantage becomes **~2.1× once used from Dart via FFI.**

## End-to-end projection (xl tokenize)

`findNextMatch` is ~87% of our xl tokenize time (~342 of ~394 ms). Substituting
the FFI engine (160.8 ms for the same work):

| | xl tokenize | vs ours |
|--|-----------:|:-------:|
| our Dart engine (final) | ~394 ms | 1× |
| with Oniguruma FFI | ~213 ms | **~1.85×** |

So an FFI-backed engine would make end-to-end tokenization **~1.85× faster** on
IO platforms (plus a small per-line UTF-16LE encoding cost not shown here).

## Status & caveats

- **Works today** on this machine via `dart test` / `dart run` with native
  assets — the build hook compiled ~50 C files and bundled them; 4/4 FFI smoke
  tests pass (version, leftmost selection, capture-group offsets, no-match).
- **IO only.** The vendored `config.h` is the macOS/arm64 one from `configure`;
  other platforms need their own `config.h` (or a portable one) before this
  builds there. Flutter apps also need `flutter config --enable-native-assets`.
- **Web is not covered** — no FFI in the browser. That's the next step (compile
  Oniguruma to WebAssembly, or use the `oniguruma-to-es`→`RegExp` approach).

## Bottom line for the native decision

| engine | xl findNextMatch | vs our engine |
|--------|-----------------:|:-------------:|
| our final Dart engine | 342 ms | 1× |
| Oniguruma via Dart FFI (IO) | 161 ms | **2.1× faster** |
| Oniguruma standalone C | 114 ms | 3.0× faster |

The realistic, usable win from native on IO is **~2.1× (≈1.85× end-to-end)** —
meaningful, but far less than the 10.5× we already reclaimed in pure Dart, and
it buys nothing on web. Worth adopting only where IO tokenization of very large
files is a proven bottleneck; otherwise the pure-Dart engine remains the better
default. Web still needs the WASM backend (next).
