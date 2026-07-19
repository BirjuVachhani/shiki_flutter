# Benchmark results: FINAL (stage 3: interpreter micro-opts)

Builds on [fastpath.md](fastpath.md). Same workload/machine/harness.
**Tests: 114/114 passing** (incl. the differential fast-path-vs-interpreter
gate and golden-vs-real-Shiki).

## What changed (`lib/src/onig/regex_engine.dart`)

1. **De-CPS'd literal runs in `_matchSeq`**: a leading run of deterministic
   nodes (chars, classes, `.`, anchors) is matched in a loop with no
   continuation closures; CPS resumes only at the first backtracking node.
   Behaviour-identical (those nodes can't backtrack); per-node step budget
   preserved.
2. **Group-free fast-path direct return**: when a translatable pattern has no
   capture groups, the compiled `RegExp`'s whole-match offsets are returned
   directly, skipping the interpreter re-run.
3. **Binary-search char classes**: each class's ranges are merged+sorted once,
   then membership is O(log n) instead of a linear scan.

- Cold start: 56.0 ms → **56.4 ms** (flat)
- RSS delta over sweep: 277 MB → **260 MB**

## Highlighting: `codeToTokens` (warm), all stages

| size | baseline | s1 (alloc+filter) | s2 (fast path) | s3 (final) | **total** |
|------|---------:|------------------:|---------------:|-----------:|----------:|
| xs | 9.43 | 1.88 | 2.04 | 2.04 | 4.6× |
| s | 69.4 | 9.75 | 8.03 | 7.93 | 8.8× |
| m | 376 | 51.0 | 41.0 | 40.1 | 9.4× |
| l | 1,499 | 204 | 159 | 157 | 9.5× |
| **xl** | **4,136** | **577** | **401** | **394** | **10.5×** |

Throughput at xl: 1,209 → 6,648 → 12,482 → **12,675 lines/s**.

## Per-stage gain (honest breakdown)

| stage | xl time | vs previous | what did the work |
|-------|--------:|:-----------:|-------------------|
| baseline | 4,136 ms | - | pure interpreter, per-position allocation |
| stage 1 | 577 ms | **7.2×** | matcher reuse + first-char prefilter + `\G` short-circuit |
| stage 2 | 401 ms | **1.44×** | native `RegExp` locates matches |
| stage 3 | 394 ms | **1.02×** | interpreter micro-opts (marginal) |

**The wins were stages 1–2.** Stage 3 is ~2% because the fast path already
routes most patterns to compiled `RegExp`, so the remaining interpreter work
(capture-offset extraction for group patterns; non-translatable patterns) is a
small slice, and Dart uses mostly tiny ASCII classes, so binary search barely
matters here. It's kept because it's safe and trims memory (and it helps
grammars with large unicode classes more than Dart).

## End-to-end + widget pump at xl (median ms)

| metric | baseline | final | gain |
|--------|---------:|------:|:----:|
| end-to-end | 4,577 | 635 | 7.2× |
| pump monolithic | 4,995 | 710 | 7.0× |

## Bottom line

| metric | baseline | final | gain |
|--------|---------:|------:|:----:|
| `codeToTokens` xl (5,000 lines) | 4,136 ms | **394 ms** | **10.5×** |
| Highlighting throughput | ~1,250 lines/s | **~12,700 lines/s** | ~10× |
| Cold start | 118 ms | 56.4 ms | 2.1× |
| RSS delta | 296 MB | 260 MB | −12% |

All gains are zero-behavior-change (byte-identical tokens vs the original
interpreter and vs real Shiki), verified by 114 tests including a dedicated
differential gate.

## Re-evaluating native FFI

Tokenization went from ~1,250 to ~12,700 lines/s (10.5×) in pure Dart, on every
platform, with no new dependencies. A 5,000-line file now tokenizes in ~0.4 s
(was ~4.1 s). Native/WASM Oniguruma would still be faster in absolute terms, but
the gap it must justify, against a three-engine (FFI + WASM + JS) maintenance
burden and the loss of zero-dep portability, is now much smaller. Recommend
banking these wins and deferring native unless a concrete workload still needs
it. Remaining pure-Dart headroom (if pursued): widen fast-path coverage (fewer
interpreter fallbacks) and a fuller de-CPS of the backtracking core.
