# Native Oniguruma vs. our optimized Dart engine

Apples-to-apples on the **identical regex workload**. We captured every
`findNextMatch` query our tokenizer issues while highlighting the Dart corpus
(GitHub Dark), then replayed that exact query stream through both engines,
mirroring `OnigScanner.findNextMatch` (try patterns in order; exact-start match
wins immediately; else left-most). Same inputs, same algorithm — only the
regex engine differs.

- **Ours**: the final optimized Dart engine (alloc reuse + first-char prefilter
  + `\G` short-circuit + native-`RegExp` fast path + interpreter micro-opts),
  in-process.
- **Oniguruma**: v6.9.10, built from source (`libonig.a`), driven by a
  standalone C program (`/tmp/onig_bench/bench.c`), UTF-8 encoding
  (corpus is ASCII, so byte offsets == our UTF-16 offsets), single reused
  `OnigRegion`, patterns compiled once. **No FFI** — pure native speed.

## Results (darwin-arm64, warm, median of 5)

| workload | ops (findNextMatch) | ours | Oniguruma | **Oniguruma speedup** |
|----------|--------------------:|-----:|----------:|----------------------:|
| corpus m (500 ln) | 2,558 | 35.3 ms · 72.5k ops/s | 11.4 ms · 224.6k ops/s | **3.1×** |
| corpus xl (5,000 ln) | 25,473 | 343 ms · 74.2k ops/s | 114 ms · 223.3k ops/s | **3.0×** |

Parity check: all 90 patterns compiled in Oniguruma; when both engines matched,
they chose the **same** winning pattern in 100% of cases (idxMismatch=0);
overall match-start agreement **97.7%**. The ~2.3% disagreement is expected —
our engine uses approximations for a few Oniguruma constructs (unicode-property
tables, possessive≈greedy) and my quick `\G` replication via `onig_search`
isn't a bit-exact match of our `gAnchor` — but it's low enough that the timing
is a fair comparison.

## Interpretation

- **Native Oniguruma is ~3× faster** than our optimized pure-Dart engine on this
  workload (~223k vs ~74k `findNextMatch`/s).
- This is the **best case for Oniguruma**: standalone C with zero FFI crossings.
  Called from Dart via `dart:ffi`, each `findNextMatch` would incur crossing
  overhead unless the scan loop itself is pushed into C (as vscode-oniguruma
  does). Real-world FFI would narrow the 3× somewhat.
- **End-to-end projection**: `findNextMatch` is ~87% of xl tokenize time
  (~343 of ~394 ms). Swapping in Oniguruma (114 ms) would cut xl tokenize to
  **~165 ms — about 2.4× faster end-to-end** (native, best case).

## The decision context

| engine | xl `findNextMatch` | vs original |
|--------|-------------------:|:-----------:|
| original Dart engine (pre-optimization) | ~343 ms × 10.5 ≈ heavy¹ | 1× |
| our optimized Dart engine | 343 ms | ~10.5× faster |
| native Oniguruma (C, no FFI) | 114 ms | ~31× faster |

¹ Baseline tokenize was 4,136 ms (≈10.5× our current); `findNextMatch` dominates.

Our optimization pass closed most of the gap: we went from ~31× slower than
native to **~3× slower**, in pure Dart, on every platform, with zero native
dependencies. Native Oniguruma would still win ~2.4× end-to-end, but:

- it doesn't help **web** (no FFI; needs the WASM or `oniguruma-to-es` path), and
- it reintroduces the native-build/three-engine complexity and portability cost
  discussed earlier.

**Recommendation:** the 3× (≈2.4× end-to-end) native advantage no longer
justifies that complexity for most use — bank the pure-Dart 10.5× and revisit
native FFI only if a specific IO-platform workload needs the last 2.4×.
