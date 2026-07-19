# Sliver-native code widgets (phased): `ShikiCodeSliverView` → `ShikiCodeSliverListView`

> **Status: Deferred (post-1.0.0).** Explicitly out of scope for the 1.0.0
> release. Recorded here as future work; not started.

## Context

`shiki_flutter` ships two box widgets: `ShikiCodeView` (whole document as one
`Text.rich`) and `ShikiCodeListView` (one line per row, virtualized via
`ListView.builder`). Both own their own viewport, so neither can be dropped into
a caller's `CustomScrollView`.

We want sliver-native analogs so highlighted code can live inline in a page's
single scroll (docs pages, chat transcripts, feeds): **vertical position and
visibility are governed by the enclosing `CustomScrollView`'s viewport, while the
code block still scrolls horizontally as one unit.**

Decision (from discussion): build in two phases, and the widgets must be
**genuinely lazy slivers**. Wrapping `ShikiCodeView` in `SliverToBoxAdapter` is
rejected: for a single monolithic `Text.rich` the adapter still builds and lays
out the entire paragraph off-screen, which defeats the lazy layout a sliver
exists to provide. Both widgets therefore virtualize **per line** using Flutter's
real lazy-sliver building blocks (`SliverFixedExtentList.builder` /
`SliverList.builder`), building only on-screen lines.

- **Phase 1** (`ShikiCodeSliverView`): the plain code block as a true virtualized
  sliver (no line-number gutter). This phase carries the hard part: synced
  horizontal scroll across virtualized rows.
- **Phase 2** (`ShikiCodeSliverListView`): the same virtualized core plus a
  per-row line-number gutter and line-oriented options.

### Why the box widgets' horizontal trick doesn't port

`ShikiCodeListView` gets synced horizontal scroll by wrapping its *entire*
`ListView` in one horizontal `SingleChildScrollView` sized to the widest line
(`code_list_view.dart:241-256`). A `RenderSliver` isn't a box you can nest inside
a horizontal box scroller, and its cross-axis width is fixed by the viewport, so
that trick is unavailable. Synced horizontal scroll across lazily-built rows must
instead be achieved with one horizontal `ScrollController` **per row**, linked by
listeners (a single shared controller is asserted against; see
`scroll_controller.dart:172`).

---

## Phase 1: `ShikiCodeSliverView`

**New file** `packages/shiki_flutter/lib/src/flutter/code_sliver_view.dart`;
export `ShikiCodeSliverView` from `lib/shiki_flutter.dart`.

A `StatefulWidget` whose `build` returns a **sliver** usable directly in
`CustomScrollView.slivers` / `NestedScrollView`.

### API

Mirror `ShikiCodeView`, plus `softWrap` and optional pre-highlighted `lines`
(this widget is the virtualized core, so it shares `ShikiCodeListView`'s
`lines`/`softWrap` surface):

`highlighter, code, lang, theme, lines?, textStyle, padding, paintBackground,
textScaler, softWrap = false, async`.

**Dropped vs the box widget:** `controller` / `physics` / `shrinkWrap` (the outer
viewport owns them) and `selectable`: a bare sliver can't wrap itself in a box
`SelectionArea`; document that callers wrap their `CustomScrollView` in a
`SelectionArea`.

### Sliver structure

```
DecoratedSliver(                         // only when paintBackground && bg != null
  decoration: BoxDecoration(color: bg),
  sliver: SliverPadding(
    padding: padding,
    sliver: softWrap
        ? SliverList.builder(itemCount: lines.length, itemBuilder: rowFor)
        : SliverFixedExtentList.builder(
            itemExtent: metrics.rowHeight,
            itemCount: lines.length,
            itemBuilder: rowFor,
          ),
  ),
)
```

`SliverFixedExtentList.builder` / `SliverList.builder` are true lazy slivers:
only on-screen lines are built, and vertical scroll is the outer viewport's. This
is the "not cheating" part: real per-line virtualization, no `SliverToBoxAdapter`.

### Per-row build (`rowFor(i)`)

- `softWrap: true` → `Text.rich(line, softWrap: true, strut...)` (fills cross-axis
  width; no horizontal scroll).
- `softWrap: false` → `_LinkedHRow(group: _hGroup, contentWidth: contentWidth,
  child: Text.rich(line, softWrap: false, maxLines: 1, strut...))`.

`contentWidth = (_maxLineLength(code) + 1) * metrics.charWidth`; `metrics`
(monospace advance + row height) measured with a `TextPainter` exactly as in
`code_list_view.dart` (`_measure`, `_maxLineLength`, small file-private helpers
duplicated here, consistent with the existing duplication between the two box
widgets).

### Synced horizontal scroll: `_HLinkedGroup` + `_LinkedHRow`

Non-wrapped rows each own a horizontal `SingleChildScrollView`/`ScrollController`
over a `SizedBox(width: contentWidth)`, linked so a drag / trackpad-pan /
shift-wheel on any row moves them all in unison (the `linked_scroll_controller`
pattern, implemented inline, no new dependency):

- `_HLinkedGroup`: holds the shared `offset` and the set of registered
  controllers; on any controller's change, records the offset and `jumpTo`s every
  *other* attached controller, guarded by a `_syncing` reentrancy flag. All rows
  share one `contentWidth`, so their `maxScrollExtent`s match and clamping is a
  no-op. Created in `initState`, disposed in `dispose`.
- `_LinkedHRow` (StatefulWidget): creates its controller with
  `initialScrollOffset: group.offset` (rows entering mid-scroll start synced),
  registers/unregisters with the group, forwards its scroll events to it, and
  disables scrollbars via `ScrollConfiguration` (Material already suppresses
  horizontal scrollbars (`app.dart:859`), but this keeps it clean under a bare
  `WidgetsApp` too). Real `Scrollable`s (not a `GestureDetector`) so
  `PointerScrollEvent` sources work on desktop/web.

### Async placeholder + colors

Reuse the box widget's path verbatim: `AsyncTokenResolver`
(`src/async/async_token_resolver.dart`) in `initState`/`didUpdateWidget`/
`dispose`; when tokens aren't ready, render one plain span per line in the theme
base color (preserving line count/height so nothing jumps on swap-in). Bake the
theme foreground into the base style and reuse `tokensToLineSpans`,
`lineToTextSpan`, `parseColor` from `render.dart`; background from
`registration.bg` via `DecoratedSliver`.

### Phase 1 tests (`test/render_test.dart`, new `ShikiCodeSliverView widget` group)

Following existing `buildHighlighter()` / `_flatten` conventions:
- renders inside `CustomScrollView(slivers: [ShikiCodeSliverView(...)])` in a
  bounded `SizedBox`; `RichText` text contains the code; `ColoredBox`/
  `DecoratedSliver` background present.
- non-wrap: a horizontal drag on a row's `SingleChildScrollView` does not throw
  and shifts the shared offset; a second row reflects the same offset (synced).
- `softWrap: true` builds without a horizontal scroller.

---

## Phase 2: `ShikiCodeSliverListView` (sketch, built after Phase 1 lands)

**New file** `code_sliver_list_view.dart`; export `ShikiCodeSliverListView`.
Reuses Phase 1's virtualized core + linked-scroll helpers (promote
`_HLinkedGroup` / `_LinkedHRow` / metrics helpers to an internal
`code_sliver_support.dart` shared by both, rather than re-duplicating).

Adds on top of the Phase 1 core:
- `showLineNumbers`, `lineNumberColor`, and the assert
  `!(showLineNumbers && softWrap)` (parity with `ShikiCodeListView`).
- Line numbers as a **per-row leading cell**:
  `Row(crossAxisAlignment: start, children: [SelectionContainer.disabled(gutterCell(i)), gap, Expanded(codeCell)])`.
  The gutter cell sits outside the row's horizontal scroller (fixed horizontally)
  and rides the sliver's vertical virtualization for free, so the box widget's
  windowed `_LineNumberGutter` offset math is not needed.

Phase 2 tests: line-number gutter shows `1`/`2`/`3` inside a `CustomScrollView`;
`showLineNumbers + softWrap` throws `AssertionError`.

---

## Verification (each phase)

1. `cd packages/shiki_flutter && flutter analyze`: clean.
2. `flutter test test/render_test.dart`: the phase's new group passes.
3. Optional dogfood: drop the widget into a `CustomScrollView` in `website/`
   between prose slivers; confirm it scrolls vertically with the page and
   horizontally within itself, and that `flutter build web` still succeeds
   (guards against dart2js / web-only regressions per project convention).
