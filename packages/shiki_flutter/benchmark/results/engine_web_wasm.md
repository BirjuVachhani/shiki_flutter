# Web engine benchmark: pure-Dart (embedded) vs Oniguruma WASM (`oniguruma_native`)

`oniguruma_native` now ships a WebAssembly build of the real Oniguruma C engine,
so on web it can back a `ShikiHighlighterEngine` (via `ShikiHighlighterNativeEngine`)
as an alternative to shiki_flutter's built-in pure-Dart engine
(`ShikiHighlighterEmbeddedEngine`, the web default). This benchmarks the two on
web, through the same `codeToTokens` path — only the regex engine differs.

Method: `website/integration_test/engine_web_benchmark_test.dart` via
`flutter drive --profile -d chrome` (dart2js + CanvasKit), chromedriver 150,
Dart grammar / GitHub Dark, corpus `m` = 500 lines, `l` = 2,000 lines.
`oniguruma_native` @ `69abb99` (embedded ~900 KB base64 wasm, loaded once with
`await loadWasm()`). `cold` = first `codeToTokens` on a fresh highlighter
(rule-tree build + regex compile + tokenize); `warm` = median of 8 steady-state
calls (`codeToTokens` caches no results, so each call re-tokenizes).

| engine             | size | cold ms | warm median ms | warm min ms |
|--------------------|:----:|--------:|---------------:|------------:|
| embedded (Dart)    |  m   |    30.9 |           11.6 |        10.8 |
| oniguruma_native   |  m   |    40.9 |           24.2 |        23.7 |
| embedded (Dart)    |  l   |    45.7 |           42.7 |        39.6 |
| oniguruma_native   |  l   |    96.8 |           95.8 |        94.1 |

Steady-state ratio (native ÷ embedded): **2.09× (m)**, **2.24× (l)**.

## Verdict: the embedded pure-Dart engine wins on web

- **~2× faster.** The pure-Dart engine tokenizes about twice as fast as the
  Oniguruma WASM backend at steady state, at both sizes.
- **Byte-identical output.** Token counts and a full content+offset+color+style
  fingerprint match exactly for the Dart grammar (m: 2,760 tokens; l: 11,002).
  So there is no correctness reason to prefer WASM here.
- **Why WASM loses despite Oniguruma being a fast C engine:** every
  `findNextMatch` crosses the JS↔WASM boundary and UTF-16LE-encodes the line into
  the wasm heap, then reads capture arrays back out. That per-call boundary tax
  outweighs Oniguruma's raw matching speed. dart2js lowers the embedded engine's
  `RegExp` use straight to native V8 regex with no boundary crossing.
- **Bundle cost.** The WASM path also embeds a ~900 KB (base64) module.

On `cold`: regex/grammar compile is cheap on web for both engines, so cold is
close to warm. The one exception is the process's very first call (embedded/m),
whose larger cold-minus-warm gap is one-time V8 JIT warmup, not compile.

### Recommendation

Keep `ShikiHighlighterEmbeddedEngine` as the web default. `oniguruma_native`'s
WASM backend is valuable for *exact* Oniguruma semantics where the pure-Dart
engine can't match (e.g. the UTF-16LE `\xHH` cases noted in
`shiki_flutter_native_engine`), but for typical grammars on web it is ~2× slower and
adds ~900 KB, with no output difference. On single-threaded web there is no
isolate to hide either engine's cold call behind, which is a further reason to
pick the faster one.
