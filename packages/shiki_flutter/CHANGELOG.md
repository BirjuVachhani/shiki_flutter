## 1.0.0

* Light/dark theme support. `ShikiCodeView` / `ShikiCodeListView` take a
  `ShikiThemeBase` as `theme:`: either a single `ShikiTheme` (e.g.
  `ShikiThemes.githubDark`), or a `ShikiDualTheme(light:, dark:)` pair that
  follows the ambient `Theme.of(context).brightness` and re-highlights when the
  app toggles light / dark (override the picked side with the widget's
  `brightness:` argument).
* Global default theme. Set `ShikiHighlighter.config.defaultTheme` (a
  `ShikiThemeBase`) once and omit `theme:` on individual widgets; a widget's own
  `theme:` overrides it. If neither is set, the widget throws a `ShikiError`.
* The rendering API now takes objects instead of string ids: widgets and
  `codeToTextSpan` / `codeToLineSpans` take a `CodeLanguage` for `lang:` (and a
  `ShikiTheme` / `ShikiThemeBase` for `theme:`) rather than name strings. The
  widgets load the language and resolved theme into the highlighter on demand
  (new idempotent `ShikiHighlighter.ensureLanguage` / `ensureShikiTheme`), so a
  global default works without pre-loading every highlighter.
* Simpler highlighter model. The highlighter is engine-only: construct it with
  `ShikiHighlighter(...)` (the top-level `createHighlighter` function is removed),
  and warm grammars/themes up front with `highlighter.preload(langs:, themes:)`.
  `preload` is now awaitable (returns a `Future`); pass `warmAsync: true` to also
  spawn and warm the background worker, so `await`ing it makes the first async
  render pay no isolate-spawn or grammar-build cost. A widget's `highlighter:` is
  now optional and falls back to a shared default you can set via
  `ShikiHighlighter.config.defaultHighlighter`. The low-level JSON loaders are
  `@internal`; pass custom content as `CodeLanguage` / `ShikiTheme` objects
  instead.
* Async, non-blocking highlighting. `ShikiCodeView` / `ShikiCodeListView` can now
  tokenize off the UI thread: the code appears immediately in the theme's base
  color and swaps to the highlighted result when it is ready, so the UI thread no
  longer freezes on the one-time grammar/regex compile. On native/VM this runs on
  a background isolate; on web, in a browser Web Worker (see below). Toggle it via
  `ShikiHighlighter.config` (`asyncIO`, default on; `asyncWeb`, default off) or per
  widget with the `async:` argument.
* Off-main-thread highlighting on **web** via a browser Web Worker (web has no
  isolates). Install the prebuilt worker once with
  `dart run shiki_flutter:install`, then set `asyncWeb: true`; the
  one-time grammar compile runs in the worker, producing tokens byte-identical to
  the synchronous engine. Without it, web async falls back to inline tokenization,
  so nothing breaks.
* The web worker honors the selected engine: each engine ships its own
  single-purpose worker (so the default stays small), and the web transport loads
  the one matching `webEngine`. One install command with a flag per engine:
  `dart run shiki_flutter:install` (embedded, or `--default`),
  `dart run shiki_flutter:install --dart` (the `oniguruma_dart` port), and
  `dart run shiki_flutter:install --native` (the native/WebAssembly engine; needs
  the `shiki_flutter_native_engine` dependency). Build a worker for a custom engine
  with the Flutter-free `package:shiki_flutter/worker_runtime.dart`
  (`runTokenizeWorker`) + `worker_protocol.dart`.
* Results are cached in a bounded LRU (`TokenCache`, keyed by code + lang + theme),
  so rebuilds and repeat views are instant with no isolate round trip. Size it via
  `ShikiHighlighter(cache: TokenCache(maxEntries: …, maxChars: …))`.
* New highlighter API for custom async UIs: `codeToTokensAsync`, the synchronous
  cache probe `peekTokens`, and `dispose` (tears down the worker). On web (no
  isolates) the same API runs inline, reusing the loaded grammars.
* `TokenizeOptions.tokenizeTimeLimit` now defaults to `0` (unlimited) instead of
  `500` ms. The old default let a line that exceeded the budget stop tokenizing
  early and emit its remainder as one coarse token, which made output depend on
  machine load and diverge from Shiki (and the goldens) under CPU pressure. Output
  is now a pure function of the input and byte-identical to Shiki regardless of
  load. Set a positive value to opt back into a main-thread safety budget.
* The regex-engine seam is now a standalone package,
  `shiki_flutter_engine_interface` (`ShikiHighlighterEngine`, `OnigScanner`,
  `OnigString`, `OnigMatch`, `OnigCaptureIndex`, `kUnmatchedOffset`), so any
  backend can implement it without depending on all of `shiki_flutter`.
* Engines and async behavior are consolidated into one `ShikiHighlighterConfig`
  (`ShikiHighlighter.config`), split by platform: `ioEngine` / `webEngine` and
  `asyncIO` / `asyncWeb`. The default engines are the faithful Oniguruma port
  (`ShikiHighlighterDartEngine`, from `shiki_flutter_dart_engine`) on native/VM and
  the built-in pure-Dart `ShikiHighlighterEmbeddedEngine` on web. Override per
  platform in the config, or per highlighter with `ShikiHighlighter(engine: ...)`.
  (Replaces the former `ShikiHighlighter.engine` / `ShikiHighlighter.async`
  statics.)
* Renamed the built-in engine class `ShikiHighlighterDartEngine` →
  `ShikiHighlighterEmbeddedEngine`. Note that `ShikiHighlighterDartEngine` now
  names a different engine (the `oniguruma_dart` port); update any code that set
  the engine by name.
* An experimental native FFI backend is available as `shiki_flutter_native_engine`.
* `ShikiCodeView` now supports a line-number gutter via `showLineNumbers` /
  `gutterStyle`, while staying a single `Text.rich` (numbers sit in a fixed
  column beside the code and never scroll horizontally).
* Unified all gutter styling under `GutterStyle`, now shared by both code
  widgets: it carries `spacing`, `dividerColor`, `dividerThickness`, `textColor`,
  and `textScale`. **Breaking:** the `ShikiCodeListView.lineNumberColor` and
  `lineNumberTextScale` parameters moved into `GutterStyle` as `textColor` and
  `textScale`.

## 0.3.0

* Added `ShikiCodeListView`, a virtualized widget that renders one line per
  `ListView` row for smooth display of large files, with an optional line-number
  gutter and horizontal scrolling for long lines.
* New line-based rendering helpers: `codeToLineSpans` / `tokensToLineSpans`
  return `List<List<TextSpan>>` (spans grouped by line, blank lines
  height-preserving) for building your own lazy code UI, plus `lineToTextSpan`
  to assemble one line into a single `TextSpan`.
* Added the **Pierre** theme collection (`lib/pierre_themes/`): 10 custom Shiki
  themes from diffs.com, including two wide-gamut `display-p3` variants and
  colorblind-friendly sets. Import individually
  (`package:shiki_flutter/pierre_themes/pierre_dark.dart`) or via the
  `pierreThemes` barrel list. It's a separate, opt-in collection: not part of
  `themes/all.dart` or the bundled-theme count, and tree-shaken unless imported.
* Pierre's themes are MIT licensed, © The Pierre Computer Company
  (https://pierre.co); the attribution is in each theme file's header.

## 0.2.0

* Batteries-included: ~250 languages and ~65 themes now ship in the package
  under `lib/langs/` and `lib/themes/`, generated by `tool/generate_bundled.dart`.
* New `createHighlighter(langs: [...], themes: [...])` API and
  `loadBundledLanguage`/`loadShikiTheme`, taking bundled entries by symbol.
* Bundled grammars/themes are tree-shakeable: only the ones you import are
  included in your app build. `langs/all.dart` / `themes/all.dart` barrels are
  available for the everything-included case.
* Embedded languages (e.g. HTML → CSS/JS) load automatically.

## 0.1.0

Initial release: a TextMate-grammar syntax highlighter for Flutter, ported from
Shiki and `vscode-textmate`.

* Pure-Dart Oniguruma-subset regex engine with capture-group offsets.
* Full TextMate tokenizer: match / begin-end / begin-while rules, captures,
  repositories, includes, injections, embedded languages, and cross-line state.
* VS Code theme loading with scope-selector specificity and font styles.
* `ShikiHighlighter.codeToTokens`, `codeToTextSpan`, and the `ShikiCodeView`
  widget.
* Token output verified against real Shiki output (see `test/golden_test.dart`).
