# Engine comparison: FFI vs bundled vs oniguruma_dart (VM + web)

Three real `ShikiHighlighterEngine` implementations tokenizing the **same**
corpus (generated Dart source), grammar (Dart), and theme (GitHub Dark) through
the **same** TextMate tokenizer — only the engine behind `OnigScanner` differs.
Metric is full `ShikiHighlighter.codeToTokens` (the real end-user tokenization
cost, dominated by `findNextMatch`). darwin-arm64, medians.

The three engines:

- **bundled** — shiki_flutter's built-in pure-Dart engine
  (`ShikiHighlighterEmbeddedEngine`): a tuned interpreter with a native-`RegExp`
  fast path. The web default; ships with the package.
- **oniguruma_dart (port)** — `ShikiHighlighterDartEngine` from
  `shiki_flutter_dart_engine`, backed by the `oniguruma_dart` pure-Dart
  Oniguruma port (backtracking bytecode VM). Pure Dart, runs everywhere.
- **FFI Oniguruma (native C)** — `ShikiHighlighterNativeEngine` from
  `shiki_flutter_native_engine`, the real Oniguruma C library over `dart:ffi`.
  IO/VM only (no web).

Correctness: the port reaches **full parity** with the golden-proven bundled
engine on the sampled fixtures (all languages, including CSS/HTML). The FFI
engine matches too except CSS/HTML, where its UTF-16LE mode can't compile
2-digit `\xHH` escapes (see `shiki_flutter_native_engine`).

## Workload

| size | lines | bytes | tokens |
|------|------:|------:|-------:|
| m    |   500 | 14,733 |  2,760 |
| l    | 2,000 | 59,082 | 11,002 |
| xl   | 5,000 | 148,164 | 27,493 |

## VM (`dart run`) — all three engines

median ms (lower is better); "vs bundled" > 1.00× means faster than the bundled
engine.

| engine | m | l | xl | xl tokens/s | vs bundled (xl) |
|--------|--:|--:|---:|------------:|----------------:|
| **FFI Oniguruma (native C)** | **15.8** | **62.3** | **163** | **168.7k** | **1.94×** |
| oniguruma_dart (port) | 28.5 | 108 | 295 | 93.3k | 1.07× |
| bundled (built-in Dart) | 29.8 | 118 | 316 | 87.0k | 1.00× |

## Web (`dart compile js` + node) — no FFI backend

median ms; "× bundled" is median relative to bundled (lower is faster).

| engine | m | l | xl | xl × bundled |
|--------|--:|--:|---:|-------------:|
| **bundled (built-in Dart, RegExp fast path)** | **16.0** | **57.0** | **139** | **1.00×** |
| oniguruma_dart (port) | 71.0 | 284 | 750 | 5.40× |

## Findings

1. **VM: FFI is fastest by ~1.9×.** Native Oniguruma tokenizes the xl corpus in
   163 ms (169k tokens/s) versus 316 ms for the bundled engine — consistent
   across sizes (1.89×–1.94×). The FFI scan loop runs in C with one crossing per
   query, so the per-call overhead stays low.

2. **VM: the port now edges out the bundled engine (~1.05–1.10×).** This
   reverses the earlier measurement, where an early in-repo port was the slowest
   option. The matured `oniguruma_dart` v1.0.0 (a bytecode VM) is now marginally
   faster than the bundled interpreter on the VM — and it does so at **full
   parity**, including the CSS/HTML cases the FFI engine skips.

3. **Web: the bundled engine wins decisively (~5×).** Its `RegExp` fast path
   compiles to V8's native regex; the port's backtracking VM compiles to slower
   JS (closures, allocation). The gap did narrow from the old ~15× to ~5.4×
   (both engines got faster), but a pure-Dart backtracking engine remains the
   wrong choice for web hot paths.

## Conclusion

The platform-split recommendation stands, with the pure-Dart ranking updated:

- **Web:** the **bundled** engine (RegExp fast path) — ~5× faster than the port.
- **VM / IO:** **FFI** is fastest (~1.9× over bundled). Where native isn't an
  option (or you want maximum Oniguruma fidelity in pure Dart), the
  **oniguruma_dart port** is the best pick — full parity and now marginally
  faster than the bundled engine on the VM.

So the default stays the **bundled** engine (fast everywhere, no native build,
best on web), with two opt-in upgrades for IO: `shiki_flutter_native_engine` for
raw speed, `shiki_flutter_dart_engine` for a faithful, web-safe Oniguruma.

> Method: `packages/shiki_flutter_native_engine/benchmark/engine_compare.dart`
> (VM, all three) and
> `packages/shiki_flutter_dart_engine/benchmark/web_engine_compare.dart`
> (web, bundled + port via `dart compile js` + node). Both reuse the core
> package's corpus generator, so runs are comparable. One session each,
> consistent machine state.
