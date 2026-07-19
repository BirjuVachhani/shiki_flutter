# Off-main-thread highlighting on web (Web Worker)

Web has no isolates, so `async: true` used to run tokenization **inline on the
main thread**: the ~1s cold grammar/regex compile still froze the UI. With the
prebuilt worker installed (`dart run shiki_flutter:install_web_worker`), that
compile now runs in a real browser **Web Worker**.

Chrome 150, dart2js + CanvasKit, profile mode, 2,000-line Dart corpus (~11k tokens).
Harness: `website/integration_test/web_worker_test.dart`.

| Path (l corpus, 2000 lines)                   | Worst main-thread frame |
| --------------------------------------------- | ----------------------- |
| Synchronous, whole-document (`monolithic_l`)  | **960.8 ms** (freeze)   |
| Web Worker, virtualized list (`async: true`)  | **111 ms**              |

- `worker_is_remote: true`: a real Web Worker spawned (not the inline fallback).
- `parity_worker_vs_sync_embedded: true`: tokens are **byte-identical** to the
  synchronous embedded engine.
- Jank: 267 frames, only **2** missed at 60fps. The remaining ~111 ms is the
  one-time virtualized-list layout + base-color placeholder (engine-agnostic, the
  same one-time render cost seen on IO), not a tokenize freeze.

The worker always tokenizes with the pure-Dart **embedded** engine: identical
output, fastest engine on web, and no WebAssembly, so the prebuilt bundle is
small (~159 KB) and grammar-free: grammars/themes arrive as JSON at runtime, so
one prebuilt worker serves every app regardless of which languages it imports.

Without the worker installed, web async falls back to inline tokenization (the
previous behavior), so nothing regresses; the worker is strictly opt-in.
