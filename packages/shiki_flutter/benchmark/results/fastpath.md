# Benchmark results — AFTER native-RegExp fast path (stage 2)

Builds on [optimized.md](optimized.md) (stage 1: allocation reuse + first-char
prefilter + `\G` short-circuit). Same workload/machine/harness.
**Tests: 114/114 passing** (100 original + 14 new differential fast-path-vs-
interpreter cases; golden output vs real Shiki unchanged).

## What changed (`lib/src/onig/regex_engine.dart`)

An **AST → Dart `RegExp` emitter** compiles each pattern to a native, exactly-
equivalent `RegExp` (bailing to `null` on any Oniguruma-only construct: atomic
groups, possessive quantifiers, `\A \z \Z \G`, per-node case, astral ranges).
Parity is by construction — the parser already lowered `\w \d \s`/POSIX/unicode
escapes to explicit ranges and `.` to any-but-newline, so the emitted `RegExp`
matches the interpreter's semantics.

Because `RegExpMatch` exposes offsets only for the whole match (not per capture
group), the fast path uses the compiled `RegExp` **only to locate the left-most
match position**, then re-runs the interpreter at that single position to
produce authoritative capture offsets — with a full-interpreter fallback if the
two ever disagree. Correctness never depends on the RegExp alone.

Safety gate: `test/regex_fastpath_test.dart` asserts the fast path is
byte-identical to the interpreter across every golden sample + Dart corpus.

- Cold start: 73.5 ms → **56.0 ms**

## Highlighting — `codeToTokens` (warm)

| size | baseline (ms) | stage 1 (ms) | stage 2 fast (ms) | stage 2 vs stage 1 | **total vs baseline** |
|------|--------------:|-------------:|------------------:|-------------------:|----------------------:|
| xs | 9.43 | 1.88 | 2.04 | 0.9× | 4.6× |
| s | 69.4 | 9.75 | 8.03 | 1.2× | 8.6× |
| m | 376 | 51.0 | 41.0 | 1.24× | 9.2× |
| l | 1,499 | 204 | 159 | 1.28× | 9.4× |
| **xl** | **4,136** | **577** | **401** | **1.44×** | **10.3×** |

Throughput: baseline ~1,250 → stage 1 ~9,800 → **stage 2 ~12,500 lines/s**
(tokens/s ~68,600 at xl; KB/s ~360).

Note: `xs` is marginally slower than stage 1 — the fast path's per-search
iterator/allocMatches overhead doesn't pay off on 20 lines, but it's
noise-level. The win grows with document size (where it matters).

## End-to-end + widget pump (median ms)

| size | end-to-end (base→s1→s2) | pump monolithic (base→s1→s2) |
|------|:-----------------------:|:----------------------------:|
| m | 389 → 64.2 → 48.8 | 418 → 79.5 → 62.7 |
| l | 1,639 → 266 → 208 | 1,742 → 296 → 243 |
| xl | 4,577 → 853 → 654 | 4,995 → 994 → 700 |

## Rendering — unchanged (sanity, median ms)

layout mono xl: 267 → 264 → 252 · paint mono xl: 4.40 → 4.48 → 4.08 (noise).
Engine changes don't touch rendering.

## Bottom line (stage 2)

| metric | baseline | after stage 2 | gain |
|--------|---------:|--------------:|:----:|
| `codeToTokens` xl (5,000 lines) | 4,136 ms | **401 ms** | **10.3×** |
| Highlighting throughput | ~1,250 lines/s | **~12,500 lines/s** | ~10× |
| Cold start | 118 ms | 56.0 ms | 2.1× |

The fast path is a real but smaller incremental win than stage 1 — the first-
char prefilter had already trimmed most wasted interpreter work, and the fast
path still pays one interpreter run per located match (for capture offsets).
Next: de-CPS the hot matcher nodes and binary-search char classes to speed up
the interpreter runs that remain (which the fast path still relies on).
