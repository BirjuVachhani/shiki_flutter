# Cross-engine / cross-platform matrix

All numbers replay the **identical** captured `findNextMatch` query stream
(xl corpus, 25,473 queries, Dart / GitHub Dark), so engine and platform are the
only variables. darwin-arm64, warm, median.

| engine / platform | xl findNextMatch | ops/s | relative |
|---|---:|---:|:--:|
| **Web (V8) + our Dart engine** | **96 ms** | **265k** | **1.00×** |
| Oniguruma standalone C (no FFI) | 114 ms | 223k | 0.84× |
| VM + FFI Oniguruma | 161 ms | 158k | 0.60× |
| VM + our Dart engine | 288 ms | 89k | 0.33× |

## Answer: is VM + FFI-Oniguruma faster than web?

**No.** VM + FFI Oniguruma (161 ms) is **~1.7× slower** than our pure-Dart engine
on web/V8 (96 ms). Two compounding effects:

1. **V8's `RegExp` is exceptional**: so good that it beats even *standalone C
   Oniguruma* (96 ms vs 114 ms) on this TextMate workload. Our fast path routes
   matching to it, so pure-Dart-on-web is the fastest option, period.
2. **FFI has a marshalling tax**: native Oniguruma goes 114 ms (pure C) → 161 ms
   (via `dart:ffi`), a ~1.4× crossing cost, widening the gap to web.

## The platform-split takeaway

- **Web:** our pure-Dart engine (V8 RegExp) wins outright. No Oniguruma, no WASM:
  native Oniguruma wouldn't even help here.
- **IO / VM:** the Dart VM's `RegExp` is ~9× slower than V8's, so our fast path
  barely helps there (89k → the RegExp is the bottleneck). **FFI Oniguruma is
  the real lever on the VM** (89k → 158k, ~1.8×), but it still can't reach web's
  numbers because (a) FFI overhead and (b) V8's regex is simply faster than
  Oniguruma for this workload.

So the fastest tokenization we can get, per platform:
- **Web:** ~96 ms (pure Dart / V8), already optimal.
- **IO:** ~161 ms (FFI Oniguruma), ~1.8× over pure-Dart-VM, but still 1.7× slower
  than web.

Counter-intuitively, the "slow" managed web runtime is the fastest place to run
this, because the whole workload is regex-bound and V8 has the best regex engine
in play.
