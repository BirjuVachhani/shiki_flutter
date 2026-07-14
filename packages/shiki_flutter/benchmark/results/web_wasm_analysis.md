# Web / WASM: critical analysis (vscode-oniguruma & Shiki)

Investigated whether we can reuse Microsoft's `vscode-oniguruma` WASM and/or
Shiki's WASM for a web backend of the `oniguruma` package. Conclusion: **no
WASM on web** — it's high-cost and, by the ecosystem's own data, slower than the
native-`RegExp` approach we already have in pure Dart.

## vscode-oniguruma (source-level findings)

- It's Oniguruma compiled to WASM **with Emscripten**. `loadWASM` does **not**
  do a plain `WebAssembly.instantiate` with a small import object — it goes
  through an Emscripten factory (`instantiateWasm` hook) that supplies `env` /
  `wasi_snapshot_preview1` imports and provides `HEAPU8`/`HEAPU32`/`UTF8ToString`
  from the Emscripten `binding`. So the `.wasm` is **not standalone**.
- Exports it drives: `_omalloc`, `_ofree`, `_createOnigScanner`,
  `_freeOnigScanner`, `_findNextOnigScannerMatch`, `_getLastOnigError`.
- Strings cross as **UTF-8**, with per-string utf16↔utf8 offset tables.
- README: "not intended to grow to have general Oniguruma WASM bindings."

**Reuse implication:** "use it directly" from Dart ⇒ bundle its JS glue + wasm
and call the JS `OnigScanner` API over `dart:js_interop`. There is no way to
just link the `.wasm`.

## Shiki's WASM

- `@shikijs/engine-oniguruma` **inlines vscode-oniguruma's wasm** (vscode-oniguruma
  is only a devDependency). So "Shiki's wasm" *is* vscode-oniguruma's wasm —
  nothing separate to reuse, and Shiki itself is a JS library we can't consume
  from Dart except by interop.
- Shiki's real web innovation is the **JavaScript engine**
  (`@shikijs/engine-javascript` → `oniguruma-to-es`): it transpiles Oniguruma
  patterns to **native JS `RegExp`**. Per Shiki's docs it is **~4% of the wasm
  bundle size and "often runs much faster… since they run as native
  JavaScript,"** and it avoids the wasm `unsafe-eval` **CSP** problem. Shiki is
  moving to make the JS engine the default.

Sources: shiki.style/guide/regex-engines; github.com/slevithan/oniguruma-to-es;
shikijs/shiki#870; github.com/microsoft/vscode-oniguruma.

## Why WASM is the wrong tool for us on web

1. **No `dart:ffi` on web.** The FFI backend can't run there at all; web needs a
   separate path regardless.
2. **Marshalling kills the win.** On IO, FFI shared memory dropped Oniguruma's
   3.0× (pure C) to 2.1×. On web there's no shared memory — every one of the
   ~25k `findNextMatch` calls would cross **Dart → JS → wasm heap** with a UTF-8
   encode + offset map. Far heavier than FFI.
3. **Native RegExp already wins.** Shiki measured native `RegExp` beating their
   own wasm even with zero cross-language penalty. Our pure-Dart **RegExp fast
   path is the Dart analog of `oniguruma-to-es`**, and on web Dart's `RegExp`
   lowers to the platform's native regex. So our engine already does the thing
   that beats wasm.
4. **Packaging + CSP.** Shipping JS+wasm into a Flutter web app and inheriting
   `unsafe-eval` CSP is real friction for a negative expected payoff.

## Decision

- **`oniguruma` package:** native (FFI) on IO; on web it compiles and links but
  exposes `isOnigurumaSupported == false` and throws on use. No wasm.
- **Web engine:** the pure-Dart `shiki_flutter` engine, whose `RegExp` fast path
  (built earlier, stage 2) already lowers to native JS RegExp on web. Optional
  future work: widen fast-path coverage (more patterns → `RegExp`), i.e. our own
  small `oniguruma-to-es`-style translation.

Net: web is best served by pure Dart; WASM would add complexity and CSP pain to
(most likely) go slower. Revisit only if a measured web workload proves
otherwise.
