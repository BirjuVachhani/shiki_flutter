// Thin C shim over Oniguruma for the Dart FFI bridge.
//
// It encapsulates the parts that are awkward to bind directly from Dart:
//   * the global encoding/syntax pointers (ONIG_ENCODING_UTF16_LE, etc.),
//   * OnigRegion struct field access, and
//   * the multi-pattern "scanner" scan loop (kept in C so there is exactly one
//     FFI crossing per findNextMatch, like vscode-oniguruma).
//
// Strings are UTF-16LE so offsets line up 1:1 with Dart's UTF-16 String indices
// (Oniguruma reports byte offsets; the Dart side divides by 2).

#include <stdlib.h>
#include <string.h>
#include <oniguruma.h>

#if defined(_WIN32)
#define SHIM_EXPORT __declspec(dllexport)
#else
#define SHIM_EXPORT __attribute__((visibility("default")))
#endif

static int g_inited = 0;

static void ensure_init(void) {
  if (g_inited) return;
  OnigEncoding encs[1];
  encs[0] = ONIG_ENCODING_UTF16_LE;
  onig_initialize(encs, 1);
  g_inited = 1;
}

typedef struct {
  int count;
  regex_t** regs; // NULL entries for patterns that failed to compile
  OnigRegion* region;
} ShimScanner;

// patterns: `count` UTF-16LE byte buffers; patLens: their byte lengths.
// Patterns that fail to compile become NULL (skipped), mirroring the Dart
// engine's forgiving behavior.
SHIM_EXPORT
ShimScanner* onig_shim_scanner_new(const unsigned char** patterns,
                                   const int* patLens, int count) {
  ensure_init();
  ShimScanner* sc = (ShimScanner*)calloc(1, sizeof(ShimScanner));
  sc->count = count;
  sc->regs = (regex_t**)calloc(count, sizeof(regex_t*));
  sc->region = onig_region_new();
  OnigErrorInfo einfo;
  for (int i = 0; i < count; i++) {
    regex_t* reg = NULL;
    const unsigned char* p = patterns[i];
    int r = onig_new(&reg, p, p + patLens[i], ONIG_OPTION_CAPTURE_GROUP,
                     ONIG_ENCODING_UTF16_LE, ONIG_SYNTAX_ONIGURUMA, &einfo);
    sc->regs[i] = (r == ONIG_NORMAL) ? reg : NULL;
  }
  return sc;
}

SHIM_EXPORT
void onig_shim_scanner_free(ShimScanner* sc) {
  if (!sc) return;
  for (int i = 0; i < sc->count; i++) {
    if (sc->regs[i]) onig_free(sc->regs[i]);
  }
  onig_region_free(sc->region, 1);
  free(sc->regs);
  free(sc);
}

// Mirrors OnigScanner.findNextMatch: tries patterns in order; a match exactly
// at `startByte` wins immediately; otherwise the left-most match wins (ties ->
// earliest pattern). Returns the winning pattern index, or -1 for no match.
// On a match, *outNumRegs is set and beg/end are filled with byte offsets of
// each capture group (0 = whole match), up to `capacity` groups.
SHIM_EXPORT
int onig_shim_find(ShimScanner* sc, const unsigned char* str, int endByte,
                   int startByte, int* outNumRegs, int* beg, int* end,
                   int capacity) {
  const unsigned char* s = str;
  const unsigned char* e = str + endByte;
  const unsigned char* start = str + startByte;

  int bestIdx = -1;
  int bestStart = 0x7fffffff;
  OnigRegion* region = sc->region;

  for (int i = 0; i < sc->count; i++) {
    regex_t* reg = sc->regs[i];
    if (!reg) continue;
    int r = onig_search(reg, s, e, start, e, region, ONIG_OPTION_NONE);
    if (r >= 0) {
      int ms = region->beg[0];
      int wins = (ms == startByte) || (ms < bestStart);
      if (wins) {
        bestIdx = i;
        bestStart = ms;
        int n = region->num_regs;
        if (n > capacity) n = capacity;
        *outNumRegs = n;
        for (int g = 0; g < n; g++) {
          beg[g] = region->beg[g];
          end[g] = region->end[g];
        }
        if (ms == startByte) break; // exact-start match wins immediately
      }
    }
  }
  return bestIdx;
}

SHIM_EXPORT
const char* onig_shim_version(void) { return onig_version(); }
