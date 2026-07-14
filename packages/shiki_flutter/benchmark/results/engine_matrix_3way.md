# Engine comparison: oniguruma_dart vs FFI vs our engine (VM + web)

Same captured `findNextMatch` query stream (xl corpus, 25,473 queries, Dart /
GitHub Dark), same scanner algorithm — only the per-pattern search engine
differs. All numbers from one session (consistent machine state), darwin-arm64,
median of 5.

`oniguruma_dart` = the pure-Dart Oniguruma port at `../oniguruma`.
Match/no-match parity of `oniguruma_dart` vs the reference: **97.7%** (same as
native Oniguruma — confirms it's doing real, correct work).

| engine | VM ms | VM ops/s | Web ms | Web ops/s |
|--------|------:|---------:|-------:|----------:|
| **FFI Oniguruma (native C)** | **133** | **191k** | — (no `dart:ffi`) | — |
| **our engine — fast path (RegExp)** | 266 | 96k | **96** | **265k** |
| our interpreter (fast path OFF) | 334 | 76k | 1,175 | 22k |
| oniguruma_dart (pure-Dart port) | 366 | 70k | 1,468 | 17k |

## Findings

1. **oniguruma_dart is the slowest option on both platforms.** A faithful
   pure-Dart port of the C library does **not** beat our leaner, workload-tuned
   interpreter — it's ~8% slower on the VM and ~15% slower on web. (The port is
   general/complete and works on UTF-8 bytes with offset mapping; our
   interpreter is a tuned subset on UTF-16 with matcher reuse + first-char
   prefilter + de-CPS'd literal runs.)

2. **On web, every pure-Dart backtracking engine is ~12–15× slower than the
   RegExp fast path.** oniguruma_dart 1,468 ms and our interpreter 1,175 ms vs
   the fast path's 96 ms. Backtracking interpreters compile to slow JS
   (closures, allocation); V8's native `RegExp` is in a different league. A
   pure-Dart Oniguruma port is a non-starter for web performance.

3. **VM ranking:** native FFI (191k) > our fast path (96k) > our interpreter
   (76k) > oniguruma_dart (70k). **Web ranking:** our fast path (265k) ≫
   interpreter (22k) > oniguruma_dart (17k).

## Conclusion

`oniguruma_dart` doesn't improve on what we already have — it's slower than our
existing interpreter on the VM and far slower than the RegExp fast path on web.
The best strategy stays platform-split and unchanged:

- **Web:** our pure-Dart engine's `RegExp` fast path (V8 native regex) — fastest
  by ~15× over any pure-Dart interpreter, including oniguruma_dart.
- **VM/IO:** native FFI Oniguruma is fastest; our fast path is the best no-native
  fallback.

A pure-Dart Oniguruma port would only make sense if the goal were maximum
Oniguruma *compatibility* in pure Dart (it's a full port), not speed — and even
then our fast path + interpreter already covers the workload faster.

> Method: a throwaway `benchmark/tool/engine_compare.dart` replayed the embedded
> workload through all three pure-Dart-capable engines on VM (`dart run`) and web
> (`dart compile js` + node/V8); the native FFI number came from the `oniguruma`
> package's `benchmark/onig_replay.dart` (VM only). Temp files were removed after
> capture.
