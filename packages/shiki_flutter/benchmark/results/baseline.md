# Benchmark baseline: BEFORE engine optimizations

Captured on the pure-Dart backtracking regex engine as-is (no changes).
Base workload: **Dart / GitHub Dark**. Machine: darwin-arm64, Flutter 3.44.6.

- Test suite at capture time: **100/100 passing**.
- Cold start (first-ever highlight, incl. regex compile): **118 ms**
- RSS delta over sweep: **296.1 MB**

## Workload structure

| size | lines | chars | tokens | spans | avg tok/ln | max tok/ln |
|------|------:|------:|-------:|------:|-----------:|-----------:|
| xs | 20 | 578 | 105 | 124 | 5.25 | 16 |
| s | 100 | 2,943 | 536 | 635 | 5.36 | 19 |
| m | 500 | 14,733 | 2,760 | 3,259 | 5.52 | 19 |
| l | 2,000 | 59,082 | 11,002 | 13,001 | 5.5 | 19 |
| xl | 5,000 | 148,164 | 27,493 | 32,492 | 5.5 | 19 |

## Highlighting: `codeToTokens` (warm)  ← the optimization target

| size | median ms | p90 ms | lines/s | tokens/s | KB/s |
|------|----------:|-------:|--------:|---------:|-----:|
| xs | 9.43 | 12.0 | 2,122 | 11,141 | 60 |
| s | 69.4 | 69.6 | 1,440 | 7,720 | 41 |
| m | 376 | 383 | 1,331 | 7,348 | 38 |
| l | 1,499 | 1,540 | 1,334 | 7,338 | 39 |
| xl | 4,136 | 4,357 | 1,209 | 6,648 | 35 |

## Rendering: build / layout / paint (median ms)

| size | build spans | layout mono | layout lazy(50) | layout lazy(all) | paint mono (CPU) |
|------|------------:|------------:|----------------:|-----------------:|-----------------:|
| xs | 0.22 | 0.44 | 0.80 | 1.01 | 0.02 |
| s | 0.51 | 2.18 | 1.47 | 3.08 | 0.08 |
| m | 0.45 | 6.74 | 1.49 | 19.0 | 0.42 |
| l | 5.34 | 57.9 | 1.30 | 69.0 | 1.76 |
| xl | 21.2 | 267 | 1.15 | 172 | 4.40 |

## Full widget pipeline via pump + end-to-end (median ms)

| size | pump monolithic | pump lazy | speedup | end-to-end |
|------|----------------:|----------:|--------:|-----------:|
| xs | 21.7 | 17.3 | 1.3× | 10.1 |
| s | 81.8 | 21.5 | 3.8× | 71.0 |
| m | 418 | 17.4 | 24.0× | 389 |
| l | 1,742 | 15.5 | 112.6× | 1,639 |
| xl | 4,995 | 16.2 | 309.2× | 4,577 |

## Device frames: macOS desktop (debug), reference

| case | first frame | missed @60fps | scroll build p99 |
|------|------------:|--------------:|-----------------:|
| monolithic · l | 2,462 ms | 3 | 4.2 ms |
| lazy · l | 82 ms | 75 | 58.8 ms |
| monolithic · xl | ~948,000 ms | 39 | 8.7 ms |
| lazy · xl | 188 ms | 243 | 137.7 ms |

---

**Headline numbers to beat** (warm `codeToTokens` median):
xs 9.43 · s 69.4 · m 376 · l 1,499 · **xl 4,136 ms** · throughput ~1,200–1,300 lines/s · RSS +296 MB.
