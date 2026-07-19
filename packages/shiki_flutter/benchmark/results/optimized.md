# Benchmark results: AFTER engine optimizations

Same workload, machine, and harness as [baseline.md](baseline.md).
Base workload: **Dart / GitHub Dark**. **Test suite: 100/100 passing** (golden
output vs real Shiki unchanged: semantics preserved).

## What changed (pure-Dart regex engine, `lib/src/onig/regex_engine.dart`)

1. **Matcher reuse**: one `_Matcher` (and its two capture arrays) per `search`,
   reset per attempt, instead of allocating a fresh matcher + arrays at every
   candidate position. Removes the O(lineLength) allocation churn per pattern.
2. **First-character prefilter**: each compiled pattern gets a conservative
   set of code units its match can begin with; positions whose character is
   excluded skip the backtracking matcher entirely. Falls back to "try every
   position" whenever the first char can't be safely bounded, so it can never
   change results.
3. **`\G`-anchored short-circuit**: a pattern beginning with a mandatory `\G`
   is only attempted at the anchor position, not scanned across the line.

No rendering code changed; layout/paint numbers are unchanged (confirming the
win is isolated to tokenization).

- Cold start: 118 ms → **73.5 ms**
- RSS delta over sweep: 296.1 MB → **275.4 MB**

## Highlighting: `codeToTokens` (warm)

| size | before (ms) | after (ms) | speedup | before lines/s | after lines/s |
|------|------------:|-----------:|--------:|---------------:|--------------:|
| xs | 9.43 | 1.88 | **5.0×** | 2,122 | 10,638 |
| s | 69.4 | 9.75 | **7.1×** | 1,440 | 10,257 |
| m | 376 | 51.0 | **7.4×** | 1,331 | 9,809 |
| l | 1,499 | 204 | **7.3×** | 1,334 | 9,806 |
| xl | 4,136 | 577 | **7.2×** | 1,209 | 8,666 |

Throughput went from ~1,200–1,300 lines/s to **~8,700–10,600 lines/s**
(tokens/s: ~6,600 → ~48,000–55,000; KB/s: ~35 → ~280).

## End-to-end + widget pump (median ms)

| size | end-to-end before | end-to-end after | speedup | pump mono before | pump mono after | speedup |
|------|------------------:|-----------------:|--------:|-----------------:|----------------:|--------:|
| xs | 10.1 | 2.26 | 4.5× | 21.7 | 12.9 | 1.7× |
| s | 71.0 | 11.8 | 6.0× | 81.8 | 22.0 | 3.7× |
| m | 389 | 64.2 | 6.1× | 418 | 79.5 | 5.3× |
| l | 1,639 | 266 | 6.2× | 1,742 | 296 | 5.9× |
| xl | 4,577 | 853 | 5.4× | 4,995 | 994 | 5.0× |

## Rendering: unchanged (sanity check, median ms)

| size | build spans (before→after) | layout mono | paint mono (CPU) |
|------|:--------------------------:|:-----------:|:----------------:|
| l | 5.34 → 4.81 | 57.9 → 61.3 | 1.76 → 1.78 |
| xl | 21.2 → 12.3 | 267 → 264 | 4.40 → 4.48 |

(Within run-to-run noise; the engine change didn't touch rendering.)

## Bottom line

| metric | before | after | gain |
|--------|-------:|------:|:----:|
| `codeToTokens` xl (5,000 lines) | 4,136 ms | **577 ms** | **7.2× faster** |
| Highlighting throughput | ~1,250 lines/s | **~9,500 lines/s** | ~7× |
| Cold start | 118 ms | 73.5 ms | 1.6× |
| Full benchmark wall-clock | ~2 min | ~24 s | - |

A single short, safe pass on the existing pure-Dart engine reclaimed **~7×** on
the dominant cost with zero behavior change. This meaningfully raises the bar
that native FFI/WASM Oniguruma would need to clear to be worth its complexity:
worth re-evaluating that decision against these new numbers.
