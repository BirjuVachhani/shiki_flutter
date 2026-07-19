# Async offloading: `compute()` / `Isolate.run` vs a dedicated warm isolate

The question: on IO/VM, synchronous tokenization can freeze the UI thread for up
to ~1s (the first tokenize of a grammar builds the rule tree and compiles
hundreds of Oniguruma regexes). Moving that work off the UI thread fixes the
freeze; the choice is *how*.

- **`compute()` / `Isolate.run`** spawns a fresh isolate with a fresh
  `ShikiHighlighter` per call, so it re-pays the grammar compile every call.
- **A dedicated long-lived worker** spawns once, holds a warm highlighter, and
  pays the compile only once (off-thread, at warm-up).

Both remove the freeze. The dedicated worker additionally avoids repeating the
compile, which is exactly the cost that dominates the common docs-site pattern of
many small code blocks and theme/lang switches.

Method: `benchmark/isolate_benchmark.dart` (`flutter test`), Dart / GitHub Dark,
darwin-arm64, medians. Numbers are for relative comparison on one machine.

## Per-call tokenize latency (ms)

`sync cold` = fresh highlighter, first call (the freeze). `sync warm` = same
highlighter reused. `isolate-run` = fresh isolate + highlighter per call. `worker
1st`/`worker warm` = one spawned, warmed worker, first vs steady-state.

| size | lines | sync cold | sync warm | isolate-run | worker 1st | worker warm |
|------|------:|----------:|----------:|------------:|-----------:|------------:|
| m    |   500 |       349 |      46.0 |        64.5 |       58.9 |        40.3 |
| l    | 2,000 |       231 |       203 |         221 |        232 |         226 |
| xl   | 5,000 |       566 |       394 |         463 |        366 |         386 |

For one large document, tokenize time dominates, so `isolate-run` and the warm
worker look close: the per-call compile is amortized over a lot of tokenizing.

## Many small snippets (30 x ~20 lines): the docs-site pattern

| strategy | total ms |
|----------|---------:|
| isolate-run (fresh isolate each) | 170 |
| warm worker (reused) | 58.2 (**2.9x faster**) |

Here per-call compile dominates: `isolate-run` rebuilds the grammar 30 times, the
warm worker builds it once. This is the case that matters for a page full of code
blocks, and it is where the dedicated worker wins decisively.

## Main-thread responsiveness (xl, 16ms heartbeat, worst stall)

| strategy | worst stall |
|----------|------------:|
| sync on the main isolate | 489 ms (UI frozen) |
| warm worker isolate | 18.7 ms (UI responsive) |

Synchronous tokenization starves a 16ms heartbeat for ~489ms: a visible freeze,
even warm. Offloaded to the worker, the heartbeat keeps ticking near 16ms.

## Device frame benchmark (macOS profile, real build/raster/jank)

`benchmark/results/frames_isolate_profile.json`, captured with
`website/integration_test/frame_benchmark_test.dart` via
`flutter drive --profile -d macos`. Each case pumps the first frame, then flings a
scroll 6x up/down while the engine's `FrameTiming`s are collected. Three
strategies at 500 (`m`) and 2,000 (`l`) lines of token-dense Dart, GitHub Dark:

- **monolithic**: synchronous `ShikiCodeView` (one `Text.rich`, tokenizes on
  build, on the UI thread).
- **lazy**: hand-rolled virtualized `ListView` over spans tokenized *before* the
  test (an idealized "tokens already in hand" reference).
- **isolate**: the production `ShikiCodeListView` with `async: true`: tokenizes on
  the background worker, shows a base-color placeholder, swaps to the highlighted
  result when the worker replies. A 3s grace lets the first-view worker spawn +
  one-time compile + tokenize settle before the scroll is measured.

| case         | first frame | worst frame |  p99  | missed @60 | missed @120 |
|--------------|------------:|------------:|------:|-----------:|------------:|
| monolithic m |     16.5 ms |     53.5 ms | 4.7ms |          2 |           2 |
| lazy m       |     11.6 ms |      8.0 ms | 7.5ms |          0 |           0 |
| isolate m    |      6.2 ms |      6.9 ms | 6.5ms |          0 |           0 |
| monolithic l |     26.7 ms | **686.2 ms**| 2.0ms |          2 |           2 |
| lazy l       |     10.7 ms |      3.4 ms | 3.3ms |          0 |           0 |
| isolate l    |     10.2 ms |      7.3 ms | 6.7ms |          0 |           0 |

At 2,000 lines the synchronous monolithic path stalls the UI thread for a single
**686 ms** frame: a ~41-frame freeze at 60fps, the exact complaint. The isolate
path has **zero janky frames** (worst 7.3 ms, nothing over even the 8.33 ms 120fps
budget): the compile+tokenize ran on the worker behind the placeholder, so the
main thread never blocked. It matches the idealized pre-tokenized `lazy` case for
scroll smoothness while doing the highlighting live.

Read the columns together: `missed_frames` counts *how often* a frame missed
budget, not *how bad*. monolithic l reports only "2 missed @60fps", but one of
those two is the 686 ms freeze: severity lives in `worst`/`p99`, frequency in
`missed_frames`.

## Web frame benchmark (Chrome profile, no isolates)

`benchmark/results/frames_web_profile.json`, same harness and corpus, run with
`flutter drive --profile -d chrome` (dart2js, CanvasKit) plus Chrome anti-throttle
flags so a background tab keeps rendering at full rate. Web is single-threaded: it
has **no isolates**, so `async: true` runs *inline*: it still paints the
base-color placeholder first, but tokenization runs on the main thread, only
deferred off the first frame. The meaningful web comparison is therefore
synchronous **monolithic** vs virtualized **lazy**.

On web the dominant cost is the **first frame** (initial build + tokenize +
layout), which `FrameTiming` does not include: it lives in `first frame` below,
not in the scroll `worst`/`missed` columns.

| case         | first frame | worst (scroll) | missed @60 | missed @120 |
|--------------|------------:|---------------:|-----------:|------------:|
| monolithic m |    248.7 ms |        249.2 ms |          1 |           4 |
| lazy m       |    129.4 ms |         14.0 ms |          0 |          60 |
| isolate m    |     26.2 ms |          9.7 ms |          0 |           1 |
| monolithic l | **960.8 ms**|         11.7 ms |          0 |          11 |
| lazy l       |     36.9 ms |         32.8 ms |          2 |          46 |
| isolate l    |     19.3 ms |         11.6 ms |          0 |           3 |

Takeaways:

- The synchronous monolithic path freezes the (single) web thread for **961 ms** on
  the 2,000-line first paint. Because web has no isolates, this freeze **cannot be
  offloaded**: the only mitigations are rendering less and tokenizing less.
- Virtualized **lazy** rendering is the web win: first paint drops to 37 ms and
  scrolling holds 60fps. It is what `ShikiCodeListView` does.
- The **inline async** path gives the cheapest first paint (content appears in
  ~20 ms as the placeholder), but note its scroll numbers *understate* the picture:
  the deferred main-thread tokenize freeze lands during the harness's pre-scroll
  grace window, so it is not counted here. On web, async is a *perceived*
  responsiveness affordance (instant content), not a real freeze fix.
- Web/CanvasKit frames run ~8–14 ms, above the 8.33 ms 120fps budget but under the
  16.67 ms 60fps budget, so the high `missed @120` counts are a renderer baseline,
  not a highlighting cost. Judge web by `missed @60`.

## Decision

Use a **dedicated long-lived worker** plus a main-isolate LRU token cache:

- It fixes the freeze (the actual complaint) like `compute()` does.
- It does not re-pay the grammar compile per call, so repeated highlighting (many
  blocks, theme/lang switches, re-highlight on edit) stays fast.
- The cache makes repeat highlights of unchanged inputs instant, with no isolate
  round trip at all.

`compute()` / `Isolate.run` remains reasonable only for a single one-shot
highlight where a resident isolate is not worth its keep. On web (single-threaded,
no isolates) the same API runs inline; the fast RegExp engine and the cache carry
it there.
