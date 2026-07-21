# shiki_flutter

> Syntax highlighting for Flutter, ported from Shiki in pure Dart. It tokenizes source code with real VS Code TextMate grammars and themes and renders it as styled `TextSpan`s, so highlighted code looks exactly like it does in VS Code, on iOS, Android, web, macOS, Windows, and Linux.

This file is the complete shiki_flutter documentation in a single Markdown file, meant to be fed to an LLM or read offline. It mirrors the live docs at https://shiki.birju.dev/docs (the docs page is the source of truth).

- Package: https://pub.dev/packages/shiki_flutter
- Source: https://github.com/BirjuVachhani/shiki_flutter

## Introduction

shiki_flutter is a syntax highlighter for Flutter. It tokenizes source code with real VS Code TextMate grammars and themes and renders it as styled `TextSpan`s, so highlighted code looks exactly like it does in VS Code.

Out of the box, it's pure Dart and runs everywhere Flutter runs: **iOS, Android, web, macOS, Windows, and Linux**. On native and desktop, highlighting runs **off the UI thread by default**, so the one-time grammar compile never freezes a frame (see **Async highlighting**).

- **~250** supported languages
- **65+** built-in themes

From all the themes and languages, you import only the ones you use, and everything else is **tree-shaken** out of your app. Reach for the `ShikiCodeView` widget for the common case, `ShikiCodeListView` for large files, or drop down to `codeToTextSpan` and raw tokens when you need more control.

## Installation

Add shiki_flutter to your `pubspec.yaml`:

**`pubspec.yaml`**

```yaml
dependencies:
  shiki_flutter: ^1.0.0
```

Or add it from the command line:

```shellscript
flutter pub add shiki_flutter
```

## Quick start

Import the specific bundled languages and themes you need, create a highlighter, and hand it to `ShikiCodeView`:

**`main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:shiki_flutter/shiki_flutter.dart';

// Import ONLY what you use. The rest is tree-shaken away.
import 'package:shiki_flutter/langs/dart.dart';
import 'package:shiki_flutter/themes/github_dark.dart';

final highlighter = createHighlighter(
  langs: [dart],
  themes: [githubDark],
);

class CodeCard extends StatelessWidget {
  const CodeCard({super.key, required this.source});
  final String source;

  @override
  Widget build(BuildContext context) {
    return ShikiCodeView(
      highlighter: highlighter,
      code: source,
      lang: dart.id,        // 'dart'
      theme: githubDark.id, // 'github-dark'
      textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
    );
  }
}
```

## Rendering code

There are three ways to render tokenized code. The calls below are synchronous; for the non-blocking variants that keep the UI thread free, see **Async highlighting**. For very large files, see **Large files** for a lazily rendered, line-based option.

### As a TextSpan

Use `codeToTextSpan` to build an `InlineSpan` for any `Text.rich` or `RichText`:

**`text_span.dart`**

```dart
final span = codeToTextSpan(
  highlighter,
  sourceCode,
  lang: 'dart',
  theme: 'github-dark',
  baseStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
);

// Drop the span into any Text.rich / RichText.
Text.rich(span);
```

### With the widget

`ShikiCodeView` paints the theme background and handles horizontal scrolling for you:

**`widget.dart`**

```dart
ShikiCodeView(
  highlighter: highlighter,
  code: sourceCode,
  lang: 'dart',
  theme: 'github-dark',
  textStyle: const TextStyle(fontFamily: 'FiraCode', fontSize: 14),
)
```

### Raw tokens

For full control, read the `ThemedToken`s directly. Pass `includeExplanation: true` in `TokenizeOptions` to also get each token's TextMate scopes.

**`tokens.dart`**

```dart
final lines = highlighter.codeToTokens(
  sourceCode,
  const TokenizeOptions(lang: 'dart', theme: 'github-dark'),
);

for (final line in lines) {
  for (final token in line) {
    print('${token.content} -> ${token.color} (${token.fontStyle})');
  }
}
```

## Widgets

shiki_flutter ships two widgets for rendering highlighted code. Both take the same core inputs (a loaded `highlighter`, the `code`, and a `lang`/`theme` id) and share the same optional features: a line-number gutter (`showLineNumbers` + `gutterStyle`), text selection, and async highlighting. Pick the one that fits how much code you are showing.

### ShikiCodeView

The quickest way to display a snippet. It builds the whole document as a single `Text.rich` and sizes to its content, scrolling horizontally for long lines, so it is best for small-to-medium blocks. On IO it highlights off the UI thread by default; see **Async highlighting**.

**`code_view.dart`**

```dart
ShikiCodeView(
  highlighter: highlighter,
  code: sourceCode,
  lang: 'dart',
  theme: 'github-dark',
  textStyle: const TextStyle(fontFamily: 'FiraCode', fontSize: 14),
)
```

### ShikiCodeListView

Renders one line per row in a lazily built `ListView`, laying out only the lines on screen, so it stays smooth on large files. Give it a bounded height like any `ListView`. See **Large files** for the full walkthrough.

**`code_list_view.dart`**

```dart
// Give it a bounded height, like any ListView (here, an Expanded parent).
Expanded(
  child: ShikiCodeListView(
    highlighter: highlighter,
    code: sourceCode,
    lang: 'dart',
    theme: 'github-dark',
    textStyle: const TextStyle(fontFamily: 'FiraCode', fontSize: 14),
  ),
)
```

### Properties

Both widgets accept these core properties:

| Property | Type | Description |
| --- | --- | --- |
| `highlighter` | `ShikiHighlighter` | Loaded highlighter. |
| `code` | `String` | Source to render. |
| `lang` | `String` | Language id, e.g. `dart`. |
| `theme` | `String` | Theme id, e.g. `github-dark`. |
| `textStyle` | `TextStyle?` | Base style; use a monospace font. |
| `padding` | `EdgeInsetsGeometry` | Defaults to `16` all round. |
| `paintBackground` | `bool` | Paint the theme's background. |
| `selectable` | `bool` | Wrap in a `SelectionArea` (default off). |
| `showLineNumbers` | `bool` | Show a line-number gutter (default off). |
| `gutterStyle` | `GutterStyle` | Gutter numbers, gap, and divider. |
| `async` | `bool?` | Override the global async default. |
| `textScaler` | `TextScaler?` | Optional text scaling. |

`ShikiCodeListView` adds a few more for scrolling and wrapping:

| Property | Type | Description |
| --- | --- | --- |
| `softWrap` | `bool` | Wrap long lines instead of scrolling. |
| `shrinkWrap` | `bool` | Grow to fit instead of filling its parent. |
| `physics` | `ScrollPhysics?` | Physics for the vertical list. |
| `controller` | `ScrollController?` | External vertical scroll controller. |
| `selectionColor` | `Color?` | Highlight color for selected code. |
| `lines` | `List<List<TextSpan>>?` | Pre-highlighted spans to skip tokenizing. |

> **Note:** `showLineNumbers` requires `softWrap: false` on `ShikiCodeListView`: wrapped lines cannot align with a fixed-height gutter.

## Large files

Rendering a whole file as one `TextSpan` (via `codeToTextSpan` or `ShikiCodeView`) lays out every line up front, which gets expensive for very large files. shiki_flutter can group the highlighting by line instead, so a `ListView.builder` renders only the lines currently on screen.

`ShikiCodeListView` (see **Widgets**) is the drop-in option. Give it a bounded height, like any `ListView`:

**`large_file.dart`**

```dart
// A drop-in virtualized view: renders one line per row and only lays out
// the lines on screen. Give it a bounded height, like any ListView.
ShikiCodeListView(
  highlighter: highlighter,
  code: sourceCode,
  lang: 'dart',
  theme: 'github-dark',
  showLineNumbers: true,
  textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
)
```

### Build your own list

Prefer to build the list yourself? `codeToLineSpans` returns the spans grouped by line, as a `List<List<TextSpan>>` (one inner list per line), ready to feed straight into a `ListView.builder`:

**`line_spans.dart`**

```dart
// codeToLineSpans groups the highlighting by line: a List<List<TextSpan>>,
// one inner list per line. Feed it to a ListView.builder so only the lines
// on screen are ever laid out.
final lines = codeToLineSpans(
  highlighter,
  sourceCode,
  lang: 'dart',
  theme: 'github-dark',
  baseStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
);

ListView.builder(
  itemCount: lines.length,
  itemBuilder: (context, i) => Text.rich(TextSpan(children: lines[i])),
);
```

> **Note:** The file is still tokenized eagerly in one pass, because highlighting on one line can depend on earlier lines (multi-line strings and comments), so only the rendering is lazy. The horizontal extent assumes a monospace font; use `softWrap: true` for proportional fonts.

## Themes

A theme is a real VS Code / TextMate theme: foreground, background, and font styles resolve through scope-selector specificity, exactly like Shiki. There are two ways to get one: pick from the **65 bundled themes**, or load your own JSON at runtime.

### Using a bundled theme

Import a theme by symbol, pass it to `createHighlighter`, and reference it by id when you render. Load several and switch per render:

**`themes.dart`**

```dart
import 'package:shiki_flutter/themes/one_dark_pro.dart';
import 'package:shiki_flutter/themes/vitesse_light.dart';

final highlighter = createHighlighter(
  langs: [dart],
  themes: [oneDarkPro, vitesseLight],
);

// Switch themes per render by id.
final dark = codeToTextSpan(
  highlighter,
  code,
  lang: 'dart',
  theme: oneDarkPro.id,
);
final light = codeToTextSpan(
  highlighter,
  code,
  lang: 'dart',
  theme: vitesseLight.id,
);
```

> **Note:** Each theme is its own library, so importing one pulls in only that theme. The other 64 are tree-shaken away. Import `themes/all.dart` only for playgrounds that genuinely need every theme.

### Bring your own theme

Shiki doesn't own the themes. They're plain VS Code theme JSON. So any theme works: grab one from a VS Code marketplace extension, the textmate-grammars-themes source, or hand-write your own, and load it live. Four entry points take a theme and return its id:

| Method | Accepts | Use when |
| --- | --- | --- |
| `loadBundledTheme(t)` | `BundledTheme` | Using a theme that ships with the package. |
| `loadThemeFromJson(s)` | `String` | You have raw theme JSON (asset, network, a `.json` file). |
| `loadTheme(m)` | `Map<String, dynamic>` | You already decoded the JSON to a map. |
| `loadThemeRegistration(r)` | `ThemeRegistration` | You built a theme programmatically. |

**`byo_theme.dart`**

```dart
// A theme is just VS Code / TextMate theme JSON. Load one at runtime from an
// asset, the network, or a VS Code extension. No codegen, no rebuild.
final json = await rootBundle.loadString('assets/aurora.json');
// loadThemeFromJson returns the theme's id.
final themeId = highlighter.loadThemeFromJson(json);

final span = codeToTextSpan(
  highlighter,
  code,
  lang: 'dart',
  theme: themeId,
);
```

### Browse all 65 themes

Every bundled theme tokenizes the same Dart sample live in the interactive gallery on the docs page. The id shown is the exact value you pass as `theme:`. The 65 bundled theme ids:

```text
andromeeda, aurora-x, ayu-dark, ayu-light, ayu-mirage, catppuccin-frappe,
catppuccin-latte, catppuccin-macchiato, catppuccin-mocha, dark-plus, dracula,
dracula-soft, everforest-dark, everforest-light, github-dark, github-dark-default,
github-dark-dimmed, github-dark-high-contrast, github-light, github-light-default,
github-light-high-contrast, gruvbox-dark-hard, gruvbox-dark-medium, gruvbox-dark-soft,
gruvbox-light-hard, gruvbox-light-medium, gruvbox-light-soft, horizon, horizon-bright,
houston, kanagawa-dragon, kanagawa-lotus, kanagawa-wave, laserwave, light-plus,
material-theme, material-theme-darker, material-theme-lighter, material-theme-ocean,
material-theme-palenight, min-dark, min-light, monokai, night-owl, night-owl-light,
nord, one-dark-pro, one-light, plastic, poimandres, red, rose-pine, rose-pine-dawn,
rose-pine-moon, slack-dark, slack-ochin, snazzy-light, solarized-dark, solarized-light,
synthwave-84, tokyo-night, vesper, vitesse-black, vitesse-dark, vitesse-light
```

## Extra themes

Alongside the bundled VS Code themes, shiki_flutter ships the 10 custom **Pierre** themes from diffs.com (built by Pierre), the same set this site uses for its own code blocks. The collection spans light and dark, plus soft, vibrant, and color-blind-friendly variants:

- `pierre-dark` and `pierre-light`: the defaults.
- `pierre-dark-soft` and `pierre-light-soft`: gentler, lower contrast.
- `pierre-dark-vibrant` and `pierre-light-vibrant`: wide-gamut `display-p3` colors on supported displays.
- `pierre-dark-protanopia-deuteranopia` and `pierre-light-protanopia-deuteranopia`: tuned for red-green color blindness.
- `pierre-dark-tritanopia` and `pierre-light-tritanopia`: tuned for blue-yellow color blindness.

They live under `pierre_themes/` and behave like any other bundled theme. Import one (or the whole set) and pass it to `createHighlighter`:

**`pierre_themes.dart`**

```dart
// Pierre themes live under pierre_themes/. Import individual themes…
import 'package:shiki_flutter/pierre_themes/pierre_dark.dart';
import 'package:shiki_flutter/pierre_themes/pierre_light.dart';
// …or the whole set via the barrel, which exports a `pierreThemes` list.

final highlighter = createHighlighter(
  langs: [dart],
  themes: [pierreDark, pierreLight],
);

// Reference a theme by its id when you render.
final span = codeToTextSpan(
  highlighter,
  code,
  lang: 'dart',
  theme: pierreDark.id, // 'pierre-dark'
);
```

> **Note:** An opt-in collection: these are separate from the 65 bundled themes and not part of `themes/all.dart`, so they add nothing to your build unless you import them. The Pierre themes are MIT-licensed, © The Pierre Computer Company.

## Languages

Each bundled grammar is its own library exporting a single symbol (e.g. `dart`, `typescript`, `python`). Import the ones you use and list them in `createHighlighter`. The value you pass to `lang` is the language's id (shown in the list below).

### Embedded languages

Grammars that embed others load their dependencies automatically. Importing `html` also pulls in `css` and `javascript`, so `<style>` and `<script>` blocks are highlighted:

**`embedded.dart`**

```dart
// Importing html automatically pulls in css + javascript, so <style> and
// <script> blocks inside the HTML are highlighted too.
import 'package:shiki_flutter/langs/html.dart';

final highlighter = createHighlighter(
  langs: [html],
  themes: [githubDark],
);
```

Aliases work too: the `shellscript` grammar answers to `bash`, `sh`, `zsh`, and `shell`.

### Supported languages

shiki_flutter bundles grammars for **253 languages**. Pass any of these ids as `lang`:

```text
abap, actionscript-3, ada, angular-expression, angular-html, angular-inline-style,
angular-inline-template, angular-let-declaration, angular-template,
angular-template-blocks, angular-ts, apache, apex, apl, applescript, ara, asciidoc,
asm, astro, awk, ballerina, bat, beancount, berry, bibtex, bicep, bird2, blade, bsl,
c, c3, cadence, cairo, clarity, clojure, cmake, cobol, codeowners, codeql, coffee,
common-lisp, coq, cpp, cpp-macro, crystal, csharp, css, csv, cue, cypher, d, dart,
dax, desktop, diff, docker, dotenv, dream-maker, edge, elixir, elm, emacs-lisp, erb,
erlang, es-tag-css, es-tag-glsl, es-tag-html, es-tag-sql, es-tag-xml, fennel, fish,
fluent, fortran-fixed-form, fortran-free-form, fsharp, gdresource, gdscript, gdshader,
genie, gherkin, git-commit, git-rebase, gleam, glimmer-js, glimmer-ts, glsl, gn,
gnuplot, go, graphql, groovy, hack, haml, handlebars, haskell, haxe, hcl, hjson, hlsl,
html, html-derivative, http, hurl, hxml, hy, imba, ini, java, javascript, jinja,
jinja-html, jison, json, json5, jsonc, jsonl, jsonnet, jssm, jsx, julia, just, kdl,
kotlin, kusto, latex, lean, less, liquid, llvm, log, logo, lua, luau, make, markdown,
markdown-nix, markdown-vue, marko, matlab, mdc, mdx, mermaid, mipsasm, mojo, moonbit,
move, narrat, nextflow, nextflow-groovy, nginx, nim, nix, nushell, objective-c,
objective-cpp, ocaml, odin, openscad, pascal, perl, php, pkl, plsql, po, polar,
postcss, powerquery, powershell, prisma, prolog, proto, pug, puppet, purescript,
python, qml, qmldir, qss, r, racket, raku, razor, reg, regexp, rel, riscv, ron,
rosmsg, rst, ruby, rust, sas, sass, scala, scheme, scss, sdbl, shaderlab, shellscript,
shellsession, smalltalk, solidity, soy, sparql, splunk, sql, ssh-config, stata, stylus,
surrealql, svelte, swift, system-verilog, systemd, talonscript, tasl, tcl, templ,
terraform, tex, toml, ts-tags, tsv, tsx, turtle, twig, typescript, typespec, typst, v,
vala, vb, verilog, vhdl, viml, vue, vue-directives, vue-html, vue-interpolations,
vue-sfc-style-variable-injection, vue-vine, vyper, wasm, wenyan, wgsl, wikitext, wit,
wolfram, xml, xsl, yaml, zenscript, zig
```

## Async highlighting

Highlighting a file means compiling its grammar and running the regex engine over every line. The first time, that one-time compile can take long enough to drop a frame. Async highlighting moves that work off the UI thread so the app never freezes.

On native and desktop it is **on by default** (`asyncIO: true`). `ShikiCodeView` and `ShikiCodeListView` show your code immediately in the theme's base color, then swap in the fully highlighted result once the background isolate finishes. Results are cached (LRU) per `(code, lang, theme)`, so later rebuilds are instant and never flash a placeholder.

> **Note:** Web has no isolates, so async there is opt-in and runs in a browser Web Worker you install once. See **Web setup**. Everything below works the same on web once that worker is enabled.

### In the widgets

Both view widgets take an optional `async:` flag that overrides the global default for that one widget. Leave it unset to follow the platform default (on for IO, off for web):

**`async_widget.dart`**

```dart
// async is on by default on native/desktop (asyncIO). The widget shows the
// code in the theme's base color, then swaps in the highlighted result when
// the background isolate is done - the UI thread never freezes. Pass async:
// explicitly to override the global default for a single widget.
ShikiCodeView(
  highlighter: highlighter,
  code: sourceCode,
  lang: 'dart',
  theme: 'github-dark',
  async: true, // force off-thread; omit to follow the global default
)
```

### Imperatively

For raw tokens, `codeToTokensAsync` mirrors `codeToTokens` but returns a `Future`, tokenizing off the current isolate and caching the result. Identical in-flight requests are coalesced:

**`async_tokens.dart`**

```dart
// The imperative equivalent: tokenize off the current isolate and await the
// result. Cached (LRU) by (code, lang, theme), so repeat calls are instant.
final lines = await highlighter.codeToTokensAsync(
  sourceCode,
  const TokenizeOptions(lang: 'dart', theme: 'github-dark'),
);

final span = tokensToTextSpan(
  lines,
  baseStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
);
```

Call `highlighter.dispose()` when a highlighter is no longer needed to tear down its background worker and clear the token cache. The highlighter still works synchronously afterward; a later async call spawns a fresh worker.

## Engines

Tokenization runs through a pluggable regex engine, chosen per platform. **The defaults are pure Dart**, so there is nothing to install: the embedded engine on web, the Oniguruma-port engine on native / VM. Every engine produces identical tokens (verified against golden Shiki output); they differ only in speed and setup.

| Platform | Off-thread async | Default engine |
| --- | --- | --- |
| Android / iOS | Background isolate | Dart port |
| macOS / Windows / Linux | Background isolate | Dart port |
| Web | Web Worker (opt-in) | Embedded |

### The three engines

| Engine | Package | When to use |
| --- | --- | --- |
| `ShikiHighlighterEmbeddedEngine` | `shiki_flutter` (built in) | **Default on web.** Pure-Dart Oniguruma-subset engine with a native-`RegExp` fast path. Fastest on web, zero setup. |
| `ShikiHighlighterDartEngine` | `shiki_flutter_dart_engine` | **Default on IO.** A faithful pure-Dart Oniguruma port with full parity and no native build, so it runs everywhere. |
| `ShikiHighlighterNativeEngine` | `shiki_flutter_native_engine` | **Fastest on IO** (~2.4x the Dart port) via `dart:ffi`; full parity. Best for large files or heavy re-highlighting. |

### Switching engine

For the best native performance, add `shiki_flutter_native_engine` and point IO at it in `main` (the native library builds automatically on first run). Guard with `kIsWeb` so the web build keeps the embedded engine, which is faster there:

**`main.dart`**

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter_native_engine/shiki_flutter_native_engine.dart';

void main() {
  // The native Oniguruma engine (dart:ffi) is ~2.4x the pure-Dart port on IO.
  // The native library builds automatically on first run - nothing to install.
  if (!kIsWeb) {
    ShikiHighlighter.config = ShikiHighlighter.config.copyWith(
      ioEngine: const ShikiHighlighterNativeEngine(),
    );
  }
  runApp(const MyApp());
}
```

Or override the engine for a single highlighter:

**`per_highlighter.dart`**

```dart
// Override the engine for a single highlighter instead of globally.
final highlighter = createHighlighter(
  langs: [dart],
  themes: [githubDark],
  engine: const ShikiHighlighterNativeEngine(),
);
```

> **Note:** The native engine also runs on web as WebAssembly, but the embedded engine is ~2x faster there, so prefer embedded on web unless you specifically want the real Oniguruma engine everywhere.

## Web setup

The default web path needs no setup: the embedded pure-Dart engine runs on the main thread with no WebAssembly and no worker. That is fast enough for typical files. Two things are web-specific: moving the one-time compile off the main thread, and the release build.

### Off the main thread

Web has no isolates, so `asyncWeb` is **off by default**. To move the cold grammar compile off the UI thread (worth it for large documents), install the prebuilt Web Worker once, then turn `asyncWeb` on. The worker is grammar-free (~53 KB gzipped) and receives your grammars and themes at runtime, so the same prebuilt script serves any app.

```shellscript
# Copy the prebuilt Web Worker into your app's web/ folder. Run once
# (and again after upgrading shiki_flutter). The worker is grammar-free
# (~53 KB gzipped) and receives your grammars/themes at runtime.
dart run shiki_flutter:install
```

**`main.dart`**

```dart
import 'package:shiki_flutter/shiki_flutter.dart';

void main() {
  // Web has no isolates, so asyncWeb is off by default. After installing the
  // worker, turn it on to move the one-time grammar compile off the UI thread.
  ShikiHighlighter.config =
      ShikiHighlighter.config.copyWith(asyncWeb: true);
  runApp(const MyApp());
}
```

The default install command installs the worker for the embedded engine. If you set `webEngine` to another engine, install its matching worker with a flag:

| Web engine | Install command |
| --- | --- |
| `ShikiHighlighterEmbeddedEngine` (default) | `dart run shiki_flutter:install` |
| `ShikiHighlighterDartEngine` | `dart run shiki_flutter:install --dart` |
| `ShikiHighlighterNativeEngine` | `dart run shiki_flutter:install --native` |

> **Note:** If the worker is not installed (or a strict CSP blocks it), web async transparently falls back to inline tokenization, so nothing breaks. Re-run the install command after upgrading shiki_flutter to refresh the worker.

### Building for the web

The only shiki_flutter-specific web step is installing the worker. Everything else is a standard Flutter web build; the optional `--wasm` flag opts into the WasmGC runtime:

```shellscript
dart run shiki_flutter:install   # copy the Web Worker into web/ (once)
flutter build web                # standard build (add --wasm to opt into WasmGC)
```

## Configuration

Engine and async defaults live in a single `ShikiHighlighterConfig`, split by platform so IO and web are configured independently. Set it once (e.g. in `main`) via `ShikiHighlighter.config`, overriding only the fields you need with `copyWith`:

**`main.dart`**

```dart
// One config object, split by platform so IO and web are set independently.
// Set it once in main(); copyWith overrides only the fields you name.
void main() {
  ShikiHighlighter.config = ShikiHighlighter.config.copyWith(
    ioEngine: const ShikiHighlighterNativeEngine(), // faster on native/desktop
    asyncWeb: true,                                 // after installing the worker
  );
  runApp(const MyApp());
}
```

| Field | Type | Default | What it does |
| --- | --- | --- | --- |
| `ioEngine` | `ShikiHighlighterEngine` | `ShikiHighlighterDartEngine` | Engine used on native / VM (IO). |
| `webEngine` | `ShikiHighlighterEngine` | `ShikiHighlighterEmbeddedEngine` | Engine used on web. |
| `asyncIO` | `bool` | `true` | Highlight off the UI thread on IO (background isolate). |
| `asyncWeb` | `bool` | `false` | Highlight off the UI thread on web (Web Worker; opt-in). |

Two narrower overrides sit on top of the global config: `createHighlighter(engine: ...)` sets the engine for a single highlighter, and a widget's `async:` argument sets async for a single widget.

## Bundle size

Even though the whole catalog ships in the package, only the languages and themes you actually import end up in your app. Each grammar and theme is a separate Dart library referenced by symbol, so the compiler tree-shakes away everything unreferenced.

- **Do** import specific entries: `import 'package:shiki_flutter/langs/dart.dart';`.
- **Don't** import the `all.dart` barrels unless you truly want every grammar. They reference everything and defeat tree-shaking.

The barrels exist for tools and playgrounds that genuinely need everything:

**`everything.dart`**

```dart
// Only when you truly want EVERYTHING (playgrounds, tooling):
import 'package:shiki_flutter/langs/all.dart';
import 'package:shiki_flutter/themes/all.dart';

final highlighter = createHighlighter(
  langs: allLanguages,
  themes: allThemes,
);
```

> **Note:** Measured on a release web build: adding the package with one language + one theme grows the app download by ~55 KB gzipped (~180 KB uncompressed), while importing the entire catalog adds ~1.35 MB gzipped (~8.6 MB uncompressed). Everything you never import is tree-shaken out.

## Custom grammars

Beyond the bundled catalog, you can load any TextMate grammar or VS Code theme JSON at runtime:

**`custom.dart`**

```dart
// Load any TextMate grammar or VS Code theme JSON at runtime.
highlighter.loadLanguageFromJson(myGrammarJsonString);
final themeName = highlighter.loadThemeFromJson(myThemeJsonString);

final span = codeToTextSpan(
  highlighter,
  code,
  lang: 'my-lang',
  theme: themeName,
);
```

## Limitations

A couple of things worth knowing:

- A few very rare grammar constructs are unsupported. When one is hit it is skipped gracefully, and highlighting keeps going rather than failing, so at worst a small span is left uncolored.
- Unicode property classes (`\p{...}`) use pragmatic approximations (ASCII is exact); full Unicode category tables are not bundled, which can affect a handful of non-Latin edge cases.
