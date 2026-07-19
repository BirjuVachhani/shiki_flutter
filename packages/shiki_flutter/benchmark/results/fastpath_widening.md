# Fast-path coverage widening (oniguruma-to-es techniques)

Borrowed the safe subset of `oniguruma-to-es`'s techniques to widen what the
`_emitDart` fast-path emitter can lower to native `RegExp` instead of bailing to
the interpreter. All gated by the differential test (byte-identical to the
interpreter) + a new construct-level test.

## What was added (`lib/src/onig/regex_engine.dart`)

| Construct | Emission | Notes |
|-----------|----------|-------|
| Atomic group `(?>P)` | `(?=(P))\N` (lookahead-capture + back-ref) | only when the pattern has **no back-references** (helper group would renumber); real groups emitted non-capturing in that mode |
| Case-insensitive char/class (ASCII) | inline flag group `(?i:…)` | Dart + modern V8 support `(?i:…)`; older targets throw → safe interpreter fallback |
| `\A` / `\z` | `(?<![\s\S])` / `(?![\s\S])` | absolute start/end; coexist with our `multiLine` `^`/`$` |

Still bailed (interpreter): possessive quantifiers (interpreter's own semantics
are an approximation), `\Z`/`\G`, dotAll `.`, non-ASCII case folding,
astral-plane ranges, back-ref + atomic combos.

**Not borrowable:** per-group offset recovery (oniguruma-to-es uses JS's
`d`/`hasIndices`; Dart has no match-indices API), so group patterns still use
"RegExp-locate + interpreter-extract."

## Correctness

- New `test/regex_widen_test.dart`: fast-path vs interpreter byte-identical for
  atomic groups (incl. true atomicity / no-backtracking), `\A`/`\z` at start/end/
  mid positions, and case-insensitive chars + classes; plus the backref+atomic
  bail. All pass.
- Full suite: **132/132 pass** (golden vs real Shiki unchanged).

## Coverage impact (all 253 bundled grammars, 32,321 patterns)

- Fast-path coverage: **88.5%** (28,615 / 32,321).
- **2,388 patterns now fast-path via a widened construct** (atomic / `(?i)` /
  `\A` / `\z`): these previously fell back to the interpreter. On web that's
  ~10× faster each.

## Benchmark impact: honest

**Dart (the benchmarked language) is unaffected: its grammar is already 100%
fast-path covered (65/65 patterns), using none of the widened constructs.** So
the Dart numbers don't move:

| | VM xl tokenize | Web xl tokenize (dart2js/V8) |
|--|:--:|:--:|
| before widening | ~394 ms | 134 ms · 37.3k lines/s |
| after widening | ~329 ms¹ | 115 ms · 43.5k lines/s¹ |

¹ Within run-to-run variance: the emitter change doesn't touch any Dart
pattern; these deltas are JIT/timer noise, not the widening.

**The widening's value is for the other ~30% of grammars** that use these
constructs (inline `(?i)` ~31%, atomic `(?>` ~11%, `\A` ~9%): ~2,388 patterns
across the catalog moved onto the native fast path, which matters most on web
(interpreter fallback ≈10× there). It is a package-wide robustness/coverage win,
not a Dart-benchmark win.
