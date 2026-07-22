# shiki_flutter

A TextMate-grammar based syntax highlighter for Flutter, ported from
[Shiki](https://shiki.style). It tokenizes source code with real VS Code
TextMate grammars and themes and renders it as styled `TextSpan`s: the same
tokenization pipeline Shiki uses, reimplemented in pure, idiomatic Dart.

Because it uses the same grammars and themes as VS Code and Shiki, the output
colors match VS Code exactly. This package's test suite verifies token output
against real Shiki output token-for-token.

## Features

- **Faithful TextMate tokenizer**: a Dart port of `vscode-textmate`: rules,
  repositories, `begin`/`end`/`while` rules, captures, injections, embedded
  languages, and cross-line state.
- **Built-in regex engine**: a from-scratch Oniguruma-subset backtracking
  regex engine with capture-group offsets, `\A`/`\G`/`\z`/`\Z` anchors,
  possessive quantifiers, atomic groups, look-around, POSIX classes, nested
  character classes, `\p{...}` properties, and inline flags. No native code or
  WASM, so it runs everywhere Flutter runs (mobile, web, desktop).
- **VS Code themes**: load any VS Code / TextMate theme JSON; foreground,
  background, and font styles (bold / italic / underline / strikethrough) are
  resolved via scope-selector specificity, exactly like Shiki. Use one theme, or
  a **light/dark pair** that follows the app's brightness (see [Themes](#themes)).
- **Flutter rendering**: turn code straight into a `TextSpan`, or drop in the
  `ShikiCodeView` widget.

## Supported platforms

shiki_flutter runs on **every platform Flutter supports**. The default engines
are pure Dart, so there is no native build, no WebAssembly, and nothing to
install:

| Platform | Highlighting | Off-main-thread async         | Default engine |
| -------- | ------------ | ----------------------------- | -------------- |
| Android  | ✅           | ✅ background isolate          | Dart port      |
| iOS      | ✅           | ✅ background isolate          | Dart port      |
| macOS    | ✅           | ✅ background isolate          | Dart port      |
| Windows  | ✅           | ✅ background isolate          | Dart port      |
| Linux    | ✅           | ✅ background isolate          | Dart port      |
| Web      | ✅           | ⚙️ Web Worker (opt-in)        | Embedded       |

- On native / mobile / desktop, async highlighting runs on a **background
  isolate** and is **on by default** (`asyncIO: true`), so the UI never freezes
  on the one-time grammar compile.
- Web has no isolates. Off-main-thread async there runs in a **browser Web
  Worker** you install once (`dart run shiki_flutter:install`) and opt
  into (`asyncWeb: true`); see [Web async setup](#web-async-setup-off-the-main-thread).
  Without it, web highlights inline on the main thread (still fast for typical
  files).
- Optional faster IO engine: `ShikiHighlighterNativeEngine` (Oniguruma via
  `dart:ffi`; the native library builds automatically on first run). On web it can
  run as WebAssembly, but the embedded engine is faster there. See
  [Configuration](#configuration).

## Getting started

Add the dependency:

```yaml
dependencies:
  shiki_flutter: ^1.0.0
```

**Batteries included:** ~250 languages and ~65 VS Code themes ship inside the
package. You don't bundle any JSON assets: you import the ones you use.

## Usage

One import gives you the full API plus the bundled grammars and themes. Create a
highlighter, referencing the specific members you use (only those get bundled;
the rest are tree-shaken away):

```dart
import 'package:flutter/material.dart';
import 'package:shiki_flutter/shiki_flutter.dart';

final highlighter = createHighlighter(
  langs: [CodeLanguages.dart],
  themes: [ShikiThemes.githubDark],
);
```

Render with the widget. Pass the language and theme as objects (`CodeLanguage`
and `ShikiThemeBase`); the widget loads them into the highlighter on demand:

```dart
ShikiCodeView(
  highlighter: highlighter,
  code: "void main() => print('Hello');",
  lang: CodeLanguages.dart,
  theme: ShikiThemes.githubDark,
  textStyle: const TextStyle(fontFamily: 'FiraCode', fontSize: 14),
)
```

Or build a `TextSpan` yourself (these free functions take a concrete
`ShikiTheme`, since they have no `BuildContext` to resolve a light/dark pair):

```dart
final span = codeToTextSpan(highlighter, sourceCode,
    lang: CodeLanguages.dart, theme: ShikiThemes.githubDark);
```

Or work with the raw themed tokens:

```dart
final lines = highlighter.codeToTokens(
  sourceCode,
  const TokenizeOptions(lang: 'dart', theme: 'github-dark'),
);
for (final line in lines) {
  for (final token in line) {
    print('${token.content} -> ${token.color} (fontStyle ${token.fontStyle})');
  }
}
```

Pass `includeExplanation: true` in `TokenizeOptions` to get each token's
TextMate `scopes`.

## Themes

The widgets take a `ShikiThemeBase`: either a single `ShikiTheme`, or a
`ShikiDualTheme` light/dark pair that follows the ambient brightness.

```dart
// One theme everywhere.
theme: ShikiThemes.githubDark

// Light in light mode, dark in dark mode, chosen from Theme.of(context).
theme: ShikiDualTheme(
  light: ShikiThemes.githubLight,
  dark: ShikiThemes.githubDark,
)
```

A `ShikiDualTheme` resolves from `Theme.of(context).brightness` and re-highlights
when the app toggles between light and dark; override which side is picked with
the widget's `brightness:` argument. (`ShikiThemeBase.dual(light:, dark:)` is an
equivalent `const` factory if you prefer.)

Set a **default theme** once and omit `theme:` on individual widgets. This is
the natural home for a light/dark pair, so every code block follows the app:

```dart
void main() {
  ShikiHighlighter.config = ShikiHighlighter.config.copyWith(
    defaultTheme: ShikiDualTheme(
      light: ShikiThemes.githubLight,
      dark: ShikiThemes.githubDark,
    ),
  );
  runApp(const MyApp());
}

// Later, no theme: needed; it falls back to the default.
ShikiCodeView(highlighter: highlighter, code: code, lang: CodeLanguages.dart)
```

A widget's own `theme:` overrides the default. If neither is set, the widget
throws a `ShikiError`.

## Engines

Tokenization runs through a pluggable regex engine (`ShikiHighlighterEngine`),
configured per platform. **By default, shiki_flutter uses the embedded engine on
web and the Dart-port engine on IO**: both pure Dart, so there is nothing to
install. Change the engine globally through `ShikiHighlighter.config` (its
`ioEngine` / `webEngine` fields, see [Configuration](#configuration)) or per
highlighter with `createHighlighter(engine: ...)`. All engines produce identical
tokens (verified against golden Shiki output); they differ only in speed and
setup.

| Engine | Package | Platforms | When to use |
| ------ | ------- | --------- | ----------- |
| `ShikiHighlighterEmbeddedEngine` | `shiki_flutter` (built in) | Web + IO | **Default on web.** Pure-Dart Oniguruma-subset engine with a native-`RegExp` fast path. Fastest engine on web, zero setup, no native build. |
| `ShikiHighlighterDartEngine` | `shiki_flutter_dart_engine` (uses `oniguruma_dart`) | Web + IO | **Default on IO.** A faithful pure-Dart Oniguruma port with full parity and no native build, so it runs everywhere. Best when you can't enable native assets. Slow on web, so prefer the embedded engine there. |
| `ShikiHighlighterNativeEngine` | `shiki_flutter_native_engine` (uses `oniguruma_native`) | IO (`dart:ffi`) + Web (WebAssembly) | **Fastest on IO** (~2.4x the Dart port), full parity; the native library builds automatically on first run. Best for large files or heavy re-highlighting on IO. On web it runs as WebAssembly (one-time `dart run oniguruma_native:setup` to self-host the module) but is ~2x slower than the embedded engine, so prefer embedded on web. |

The numbers behind these comparisons live in `benchmark/results/`.

## Configuration

Engine and async defaults live in a single `ShikiHighlighterConfig`, split by
platform so IO and web are configured independently. Set it once (e.g. in
`main`), overriding only the fields you need with `copyWith`:

```dart
ShikiHighlighter.config = ShikiHighlighter.config.copyWith(
  ioEngine: const ShikiHighlighterNativeEngine(), // faster on IO (see below)
  asyncWeb: true,                                 // after installing the worker
);
```

| Field       | Type                    | Default                          | What it does |
| ----------- | ----------------------- | -------------------------------- | ------------ |
| `ioEngine`  | `ShikiHighlighterEngine`| `ShikiHighlighterDartEngine()`   | Engine used on native / VM (IO). |
| `webEngine` | `ShikiHighlighterEngine`| `ShikiHighlighterEmbeddedEngine()` | Engine used on web. |
| `asyncIO`   | `bool`                  | `true`                           | Highlight off the UI thread on IO (background isolate). |
| `asyncWeb`  | `bool`                  | `false`                          | Highlight off the UI thread on web (Web Worker; opt-in, see [Web async setup](#web-async-setup-off-the-main-thread)). |
| `defaultTheme` | `ShikiThemeBase?`  | `null`                           | Theme(s) the widgets use when `theme:` is omitted: a single theme or a light/dark pair (see [Themes](#themes)). |

`createHighlighter(engine: ...)` overrides the engine for a single highlighter; a
widget's `async:` argument overrides async for a single widget.

## Recommended settings

The defaults work everywhere with zero setup: the pure-Dart engine on every
platform, plus **async highlighting on IO** (`asyncIO: true`). Async tokenizes on
a background isolate and shows the code in the theme's base color until the
highlighted result arrives, so the UI thread never blocks on the one-time grammar
compile; results are cached (LRU) so rebuilds are instant.

For the best performance beyond the defaults:

**IO (mobile / desktop): the native engine.** The native Oniguruma engine
tokenizes ~2.4x faster than the pure-Dart port, and async (already on for IO)
keeps it off the UI thread, so there is no freeze. Add `shiki_flutter_native_engine`
to your `pubspec.yaml` (the native library builds automatically on first run), then
set `ioEngine` in `main`:

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter_native_engine/shiki_flutter_native_engine.dart';

void main() {
  if (!kIsWeb) {
    ShikiHighlighter.config = ShikiHighlighter.config.copyWith(
      ioEngine: const ShikiHighlighterNativeEngine(),
    );
  }
  runApp(const MyApp());
}
```

**Web: keep the embedded engine (the default). Nothing to do.** It is the
fastest engine on web and needs no setup. For large files on either platform, use
the virtualized `ShikiCodeListView`, which only tokenizes and lays out the lines
on screen.

### Web async setup (off the main thread)

Web has no isolates, so `asyncWeb` is **off by default** and tokenization runs on
the main thread (the embedded engine is fast, so this is fine for most apps). To
move the one-time cold grammar compile *off* the UI thread on web (worth it for
large documents), install the prebuilt **Web Worker** once, then turn `asyncWeb`
on.

**1. Install the worker** (copies it into your app's `web/` folder):

```sh
dart run shiki_flutter:install
```

**2. Enable web async** in `main`:

```dart
import 'package:shiki_flutter/shiki_flutter.dart';

void main() {
  ShikiHighlighter.config =
      ShikiHighlighter.config.copyWith(asyncWeb: true);
  runApp(const MyApp());
}
```

Re-run the install command after upgrading shiki_flutter to refresh the worker.

**Match the worker to your web engine.** The default command installs the worker
for the embedded engine (`webEngine`'s default). If you set `webEngine` to another
engine, install its matching single-purpose worker instead: each is a separate
artifact so the default stays small. Flags can be combined (e.g.
`dart run shiki_flutter:install --default --dart`).

| Web engine (`webEngine`)          | Install command                             | Notes |
| --------------------------------- | ------------------------------------------- | ----- |
| `ShikiHighlighterEmbeddedEngine` (default) | `dart run shiki_flutter:install` (or `--default`) | Zero setup; the default worker. |
| `ShikiHighlighterDartEngine`      | `dart run shiki_flutter:install --dart`     | Worker for the `oniguruma_dart` port. |
| `ShikiHighlighterNativeEngine`    | `dart run shiki_flutter:install --native`   | Needs the `shiki_flutter_native_engine` dependency. Also fetches the Oniguruma WebAssembly module; call `await loadWasm()` at startup. |

**How it works.** The command copies a small (~53 KB gzipped), grammar-free worker
script into `web/`. It tokenizes with your web engine (identical output) and
receives your grammars/themes at runtime, so the *same* prebuilt worker serves any
app regardless of which languages you import: there is nothing to compile. If the
worker isn't installed (or a strict CSP blocks it), web async transparently falls
back to inline tokenization, so nothing breaks. In a 2,000-line benchmark this
turns a ~961 ms first-frame freeze into a ~111 ms one-time layout with
byte-identical tokens (see `benchmark/results/web_worker.md`).

## Bundle size & tree-shaking

Even though the whole catalog ships in the package, **only the languages and
themes you actually import end up in your app.** Each grammar/theme is a
separate Dart library referenced by symbol, so the Dart compiler tree-shakes
away everything unreferenced. In a measured build, importing one language +
one theme produced a ~6 MB binary, while importing *all* of them produced
~15 MB. The difference (~9 MB of grammar data) is dropped when unused.

To keep this working:

- **Do** reference specific members: `CodeLanguages.dart`,
  `ShikiThemes.githubDark`.
- **Don't** reference `CodeLanguages.all` / `ShikiThemes.all` unless you truly
  want every grammar/theme: those lists intentionally reference all of them (no
  tree-shaking). They exist for tools/playgrounds that need everything:

  ```dart
  final hl = createHighlighter(
    langs: CodeLanguages.all,   // pulls in EVERYTHING
    themes: ShikiThemes.all,
  );
  ```

Embedded languages load automatically: referencing `CodeLanguages.html` also
pulls in `css` and `javascript` so `<style>`/`<script>` blocks are highlighted.

### Custom grammars/themes

You can also load any TextMate grammar or VS Code theme JSON at runtime:

```dart
highlighter.loadLanguageFromJson(myGrammarJsonString);
highlighter.loadThemeFromJson(myThemeJsonString);
```

A theme can also be loaded from a decoded map or a hand-built Dart object:

```dart
highlighter.loadTheme(jsonDecode(myThemeJsonString));      // Map
highlighter.loadThemeRegistration(myThemeRegistration);    // ThemeRegistration
```

All of these paths work with async highlighting: the theme is replicated to the
background isolate / web worker, so a custom theme resolves the same whether you
call `codeToTokens` or `codeToTokensAsync` (or set `async: true` on the widgets).

### Pierre themes (opt-in)

The package also bundles the 10 custom **Pierre** themes from
[diffs.com](https://diffs.com), including two wide-gamut `display-p3` variants
and colorblind-friendly (protanopia/deuteranopia, tritanopia) sets. They are a
separate, opt-in collection (not part of `ShikiThemes.all` or the ~65 count):

```dart
import 'package:shiki_flutter/shiki_flutter.dart';

final hl = createHighlighter(
  langs: [CodeLanguages.dart],
  themes: [PierreThemes.pierreDark],
);
```

Pierre's themes are MIT licensed, © The Pierre Computer Company
(https://pierre.co); the attribution is in each theme file's header. See
[`lib/pierre_themes/`](lib/pierre_themes/) for the full list.

## How it compares to Shiki

| Shiki (JS)                     | shiki_flutter (Dart)            |
| ------------------------------ | ------------------------------- |
| `@shikijs/vscode-textmate`     | `lib/src/textmate/`             |
| `oniguruma-to-es` / WASM       | `lib/src/onig/` (pure Dart)     |
| `codeToTokens`                 | `ShikiHighlighter.codeToTokens` |
| `codeToHtml`                   | `codeToTextSpan` / `ShikiCodeView` |

## Regenerating the bundled catalog

The files under `lib/langs/` and `lib/themes/` are generated (pure Dart, no JS
executed) by `tool/generate_bundled.dart` from Shiki's `@shikijs/langs` and
`@shikijs/themes` distribution files:

```sh
dart run tool/generate_bundled.dart <path-to-@shikijs-dir>
```

## Limitations

- The regex engine implements the subset of Oniguruma that TextMate grammars
  use. Unsupported patterns are skipped gracefully (forgiving mode) rather than
  crashing tokenization.
- `\p{...}` Unicode property classes use pragmatic range approximations (ASCII
  is exact); full Unicode category tables are not bundled.

## Additional information

This package began as a direct port of Shiki and `vscode-textmate`. See the test
suite (`test/golden_test.dart`) for the token-for-token comparison against real
Shiki output.
