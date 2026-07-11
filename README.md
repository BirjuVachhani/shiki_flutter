# shiki_flutter

A TextMate-grammar based syntax highlighter for Flutter, ported from
[Shiki](https://shiki.style). It tokenizes source code with real VS Code
TextMate grammars and themes and renders it as styled `TextSpan`s — the same
tokenization pipeline Shiki uses, reimplemented in pure, idiomatic Dart.

Because it uses the same grammars and themes as VS Code and Shiki, the output
colors match VS Code exactly. This package's test suite verifies token output
against real Shiki output token-for-token.

## Features

- **Faithful TextMate tokenizer** — a Dart port of `vscode-textmate`: rules,
  repositories, `begin`/`end`/`while` rules, captures, injections, embedded
  languages, and cross-line state.
- **Built-in regex engine** — a from-scratch Oniguruma-subset backtracking
  regex engine with capture-group offsets, `\A`/`\G`/`\z`/`\Z` anchors,
  possessive quantifiers, atomic groups, look-around, POSIX classes, nested
  character classes, `\p{...}` properties, and inline flags. No native code or
  WASM, so it runs everywhere Flutter runs (mobile, web, desktop).
- **VS Code themes** — load any VS Code / TextMate theme JSON; foreground,
  background, and font styles (bold / italic / underline / strikethrough) are
  resolved via scope-selector specificity, exactly like Shiki.
- **Flutter rendering** — turn code straight into a `TextSpan`, or drop in the
  `ShikiCodeView` widget.

## Getting started

Add the dependency:

```yaml
dependencies:
  shiki_flutter: ^0.1.0
```

**Batteries included:** ~250 languages and ~65 VS Code themes ship inside the
package. You don't bundle any JSON assets — you import the ones you use.

## Usage

Import the specific bundled languages and themes you need, then create a
highlighter:

```dart
import 'package:flutter/material.dart';
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter/langs/dart.dart';        // the Dart grammar
import 'package:shiki_flutter/themes/github_dark.dart'; // the GitHub Dark theme

final highlighter = createHighlighter(
  langs: [dart],
  themes: [githubDark],
);
```

Render with the widget:

```dart
ShikiCodeView(
  highlighter: highlighter,
  code: "void main() => print('Hello');",
  lang: dart.id,          // 'dart'
  theme: githubDark.id,   // 'github-dark'
  textStyle: const TextStyle(fontFamily: 'FiraCode', fontSize: 14),
)
```

Or build a `TextSpan` yourself:

```dart
final span = codeToTextSpan(highlighter, sourceCode,
    lang: 'dart', theme: 'github-dark');
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

## Bundle size & tree-shaking

Even though the whole catalog ships in the package, **only the languages and
themes you actually import end up in your app.** Each grammar/theme is a
separate Dart library referenced by symbol, so the Dart compiler tree-shakes
away everything unreferenced. In a measured build, importing one language +
one theme produced a ~6 MB binary, while importing *all* of them produced
~15 MB — the difference (~9 MB of grammar data) is dropped when unused.

To keep this working:

- **Do** import specific languages/themes: `import '.../langs/dart.dart';`.
- **Don't** import `package:shiki_flutter/langs/all.dart` unless you truly want
  every grammar — that barrel intentionally references all of them (no
  tree-shaking). It exists for tools/playgrounds that need everything:

  ```dart
  import 'package:shiki_flutter/langs/all.dart';   // pulls in EVERYTHING
  import 'package:shiki_flutter/themes/all.dart';
  final hl = createHighlighter(langs: allLanguages, themes: allThemes);
  ```

Embedded languages load automatically: importing `langs/html.dart` also pulls
in `css` and `javascript` so `<style>`/`<script>` blocks are highlighted.

### Custom grammars/themes

You can also load any TextMate grammar or VS Code theme JSON at runtime:

```dart
highlighter.loadLanguageFromJson(myGrammarJsonString);
highlighter.loadThemeFromJson(myThemeJsonString);
```

### Pierre themes (opt-in)

The package also bundles the 10 custom **Pierre** themes from
[diffs.com](https://diffs.com) — including two wide-gamut `display-p3` variants
and colorblind-friendly (protanopia/deuteranopia, tritanopia) sets. They are a
separate, opt-in collection (not part of `themes/all.dart` or the ~65 count):

```dart
import 'package:shiki_flutter/pierre_themes/pierre_dark.dart';
// or the whole set: package:shiki_flutter/pierre_themes/pierre_themes.dart

final hl = createHighlighter(langs: [dart], themes: [pierreDark]);
```

Pierre's themes are MIT licensed, © The Pierre Computer Company; the notice
ships in [`lib/pierre_themes/LICENSE`](lib/pierre_themes/LICENSE). See
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
