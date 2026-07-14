# Web benchmark + oniguruma-to-es analysis

## Web tokenization (dart2js → V8, same engine as Chrome)

Pure-Dart core compiled with `dart compile js -O2`, run on V8. `codeToTokens`,
Dart / GitHub Dark, median.

| size | lines | fast-path ms | interpreter ms | fast-path speedup | lines/s (fast) |
|------|------:|-------------:|---------------:|:-----------------:|---------------:|
| xs | 20 | 1.0 | 4.0 | 4.0× | 20,000 |
| s | 100 | 3.0 | 27.0 | 9.0× | 33,333 |
| m | 500 | 15.0 | 141.0 | 9.4× | 33,333 |
| l | 2,000 | 55.0 | 553.0 | 10.1× | 36,364 |
| xl | 5,000 | 134.0 | — | — | 37,313 |

**Headline: on web the RegExp fast path is ~10× faster than the interpreter**
(vs only ~1.1× on the Dart VM). Two reasons:

1. V8's native `RegExp` is extremely fast, and our fast path routes matching to
   it (`dart:core` `RegExp` → JS `RegExp` under dart2js).
2. Our hand-written backtracking interpreter compiles to *slow* JS — closures,
   allocation, no value types — exactly the style JS engines handle worst.

Cross-runtime (caveat: different engines/JIT/timers), web fast-path throughput
(~37k lines/s, xl 134 ms) is **~3× faster than the Dart VM** (~12.7k lines/s,
xl 394 ms) — V8's regex + JIT are excellent here. The robust signal is the
per-platform ratio; the absolute cross-runtime numbers are indicative.

**Consequences:**
- The earlier decision to *not* ship WASM on web is strongly confirmed: pure
  Dart already tokenizes 5,000 lines in ~134 ms on web, with no wasm, no JS dep,
  no CSP issue.
- **Fast-path coverage matters far more on web than on IO** — every pattern that
  falls back to the interpreter costs ~10× there. Widening coverage is the
  single highest-leverage web optimization.

## oniguruma-to-es: what we can borrow

Shiki's JS engine transpiles Oniguruma → native `RegExp` via `oniguruma-to-es`.
Probed which of its techniques are usable in Dart (Dart `RegExp` = irregexp on
VM, JS `RegExp` on web):

### Usable — would widen our fast-path coverage (validated in Dart)

| Oniguruma construct | oniguruma-to-es trick | Dart status |
|--------------------|------------------------|-------------|
| Atomic group `(?>P)` | lookahead + backref `(?=(P))\N` | ✅ works (`(?=(a+))\1` → `aaa`) |
| Possessive `P++` | same atomic emulation | ✅ (via the same trick) |
| Case-insensitive subpattern | inline flag group `(?i:…)` | ✅ Dart supports `(?i:…)` |
| `\A` / `\z` | absolute anchors | ✅ map to `(?<![\s\S])` / `(?![\s\S])` (coexist with our `multiLine` `^`/`$`) |

Today our emitter (`regex_engine.dart _emitDart`) **bails** on all of these
(falls back to the interpreter). Since the fast path uses the RegExp only to
*locate* the match (the interpreter still extracts captures), adding these
emulations is safe — helper capture groups don't affect the match position, and
the differential test (`test/regex_fastpath_test.dart`) gates correctness.

### Not usable — hard Dart limitation

- **Per-group offset recovery.** oniguruma-to-es gets capture positions via JS's
  `d`/`hasIndices` flag (or its `EmulatedRegExp` subclass). **Dart `RegExp` has
  no match-indices API and no `d` flag** — `RegExpMatch` exposes start/end for
  group 0 only. This is *why* our fast path must "locate with RegExp, then
  re-run the interpreter at that position for capture offsets," instead of being
  RegExp-only like oniguruma-to-es. Not fixable via transpilation.
- **`v` flag (unicodeSets)** class set-operations — Dart has no `v` flag; moot
  since our parser already lowers classes to explicit ranges.

## Recommendation

Widen `_emitDart` coverage using the four usable techniques above. Expected
impact is **largest on web** (interpreter fallback ≈10× there), modest on IO.
Each technique lands behind the existing differential test, so correctness stays
byte-verified. The per-group-offset gap is a permanent Dart limitation — our
locate-then-extract design already works around it.
