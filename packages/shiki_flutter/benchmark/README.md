# shiki_flutter benchmark suite

Reproducible performance measurements for highlighting and rendering a lot of
syntax-highlighted spans. Base workload: **language = Dart**, **theme = GitHub
Dark**, swept across document sizes.

The pipeline has two costs, measured separately:

| Stage | What runs | Where measured |
|-------|-----------|----------------|
| **Highlighting** | `codeToTokens()`: TextMate tokenization (pure Dart) | headless |
| **Rendering** | `tokensToTextSpan()` build → `Text.rich` layout → paint → GPU raster | headless + device |

It also compares two rendering **strategies** at every size:

- **Monolithic**: the whole document as one `Text.rich` (what `ShikiCodeView`
  does today).
- **Lazy**: a virtualized per-line `ListView` of `Text.rich` widgets, so only
  the visible lines are built/laid out per frame.

---

## Layout of the suite

```
benchmark/
  highlight_benchmark.dart   # headless core (flutter test): the main suite
  src/corpus.dart            # deterministic Dart corpus generator + WorkloadStats
  src/stats.dart             # percentiles, timing runner, table + JSON reporters
  results/                   # JSON output (…_latest.json + timestamped copies)
website/
  integration_test/
    frame_benchmark_test.dart  # device frame build/raster/jank
    support/corpus.dart        # identical corpus generator (kept standalone)
  test_driver/perf_driver.dart # flutter drive entrypoint
```

The corpus generator is **deterministic** (no randomness), so a given size is
byte-for-byte identical across runs and across both layers. Sizes:

| size | lines |
|------|-------|
| `xs` | 20 |
| `s`  | 100 |
| `m`  | 500 |
| `l`  | 2,000 |
| `xl` | 5,000 |

---

## 1. Headless core (primary, no device needed)

```bash
flutter test benchmark/highlight_benchmark.dart
```

Runs under `flutter test`, which provides a real `dart:ui` text engine. For each
size it measures (warmup + N timed iterations, reported as median / p90):

- **Highlighting**: `codeToTokens`, plus a one-time **cold start** (first ever
  highlight, including Oniguruma regex compilation). Derived throughput:
  lines/s, tokens/s, KB/s.
- **Span build**: `tokensToTextSpan`.
- **Layout**: `TextPainter` layout of the whole document (monolithic) vs one
  50-line viewport window and vs every line as its own paragraph (lazy).
- **Paint (CPU)**: recording the monolithic paint into a `PictureRecorder`.
- **Full widget pipeline**: `pumpWidget` timing of `ShikiCodeView` (monolithic)
  vs the lazy `ListView`, the headline monolithic-vs-lazy comparison.
- **End-to-end**: tokenize + build + layout + paint combined.
- **Structure**: lines, chars, bytes, token/span counts, tokens/line.
- **RSS delta**: coarse process-memory growth across the sweep.

Output: a set of console tables plus `benchmark/results/headless_latest.json`
(and a timestamped copy).

### Reading it

The monolithic layout/pump columns grow with document size; the lazy
window/pump columns stay roughly flat. That gap is the cost of realizing every
span at once. Note that highlighting (`codeToTokens`) is often the single
largest term for big documents: tokenize once and cache the result.

> **Caveat.** Headless numbers use the test font and CPU-side paint (no GPU
> raster). They're for *relative* comparison across sizes and strategies, not
> absolute device performance. For real raster/jank use layer 2.

---

## 2. Device frames (real build / raster / jank)

Hosted in the `website/` app (it already has macOS + web runners). Adds
`integration_test` as a dev-dependency only.

Quick smoke (runs the cases, first-frame times are real; frame timings may be
sparse depending on device):

```bash
cd website
flutter pub get
flutter test integration_test/frame_benchmark_test.dart -d macos
```

Full timeline in profile mode (accurate build + GPU raster + jank):

```bash
cd website
flutter drive \
  --driver=test_driver/perf_driver.dart \
  --target=integration_test/frame_benchmark_test.dart \
  -d macos --profile
```

For each `(size × strategy)` (sizes `m` and `l`) it displays the document,
then scripts a back-and-forth scroll and records every `FrameTiming`:

- **first_frame_ms**: time to build + lay out the initial tree (the dominant
  jank source for the monolithic strategy).
- **build_ms / raster_ms / total_ms**: avg / p50 / p90 / p99 / worst per frame.
- **missed_frames_60fps / _120fps**: frames whose total span exceeded the
  16.67 ms / 8.33 ms budget (i.e. jank).

Where the metrics go:

- **`flutter test -d …`** → printed to stdout as `[frame-bench] <label> => {…}`
  (the app sandbox usually can't write into the repo, so read them from stdout).
- **`flutter drive`** → also written to the binding's `reportData`, which the
  driver persists to `website/build/integration_response_data.json`.

> **Why cap at `l`?** At `xl` (5,000 lines / ~32k spans) the monolithic
> `Text.rich` is pathological on-device: a debug macOS run took ~16 minutes to
> lay out its first frame. The device layer deliberately stops at `l`
> (2,000 lines, ~2.5 s first frame); use the headless layer for `xl`.

### Reading it

The **monolithic** strategy shows a large `first_frame_ms` and few missed frames
*while scrolling* (once laid out, a single paragraph just translates). The
**lazy** strategy shows a tiny `first_frame_ms` but more missed frames *during
scroll*, because each newly-visible line's `Text.rich` is built on the fly. The
fix for lazy jank: cache per-line spans and/or raise the `ListView` cacheExtent.

A representative debug macOS baseline is committed at
`benchmark/results/frames_macos_baseline.json`.

---

## Interpreting results / acting on them

- **Highlighting dominates at scale** → tokenize off the build path and cache
  `List<List<ThemedToken>>`; never re-highlight inside `build()`.
- **Monolithic layout is superlinear** → for large documents, prefer a lazy /
  virtualized per-line view over a single `Text.rich`.
- Compare `results/headless_latest.json` before/after a change to catch
  regressions; commit a copy when you want a baseline.
