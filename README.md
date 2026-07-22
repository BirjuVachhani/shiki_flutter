![shiki_flutter](https://raw.githubusercontent.com/BirjuVachhani/shiki_flutter/main/website/assets/banner.webp)

# shiki_flutter

A TextMate-grammar based syntax highlighter for Flutter, ported from
[Shiki](https://shiki.style). It tokenizes source code with real VS Code
grammars and themes and renders it as styled `TextSpan`s in pure, idiomatic
Dart, so the output colors match VS Code exactly. The token output is verified
against real Shiki output, token-for-token.

- **Docs and live demo:** https://shiki.birju.dev
- **Package on pub.dev:** https://pub.dev/packages/shiki_flutter
- **Full usage guide:** [packages/shiki_flutter/README.md](packages/shiki_flutter/README.md)

This repository is the monorepo (a [pub workspace](https://dart.dev/tools/pub/workspaces))
for the package and its engine backends, plus the showcase site and supporting
tooling.

## Highlights

- **~250 languages and ~65 VS Code themes** ship inside the package. You import
  only the ones you use; the rest tree-shake away.
- **Pure-Dart regex engine** by default: no native build, no WebAssembly, so it
  runs on every platform Flutter supports (mobile, web, desktop).
- **Faithful tokenizer**: a Dart port of `vscode-textmate` (begin/end/while
  rules, captures, injections, embedded languages, cross-line state).
- **Light/dark themes** that follow the app's brightness, and **off-main-thread
  async** (a background isolate on native, an optional Web Worker on web) so the
  UI never freezes on the one-time grammar compile.

See the [package README](packages/shiki_flutter/README.md) for installation and
the full API, or browse the [docs site](https://shiki.birju.dev).

```dart
import 'package:shiki_flutter/shiki_flutter.dart';

// Drop-in widget. Theme comes from ShikiHighlighter.config.defaultTheme when
// `theme:` is omitted.
ShikiCodeView(
  code: source,
  lang: CodeLanguages.dart,
  theme: ShikiThemes.githubDark,
);
```

## Packages

The published packages live under [`packages/`](packages/). Most apps depend
only on `shiki_flutter`; the two default engines (embedded on web, the Dart port
on native) need zero setup.

| Package | Description |
| ------- | ----------- |
| [`shiki_flutter`](packages/shiki_flutter) | The highlighter and Flutter widgets (`ShikiCodeView`, `ShikiCodeListView`). **Start here.** |
| [`shiki_flutter_engine_interface`](packages/shiki_flutter_engine_interface) | The regex-engine seam every backend implements: the `ShikiHighlighterEngine` factory plus the `OnigScanner` / `OnigString` / `OnigMatch` contract. Pure Dart, no dependencies. |
| [`shiki_flutter_dart_engine`](packages/shiki_flutter_dart_engine) | Pure-Dart Oniguruma engine (via the `oniguruma_dart` port): no FFI, no native build, runs everywhere. The default engine on native/VM. |
| [`shiki_flutter_native_engine`](packages/shiki_flutter_native_engine) | Native Oniguruma via `dart:ffi` (IO) and WebAssembly (web). Optional, ~2.4x faster on IO; opt in via `ShikiHighlighter.config`. |

## Repository layout

| Path | What it is |
| ---- | ---------- |
| [`packages/`](packages/) | The published packages listed above. |
| [`website/`](website/) | The showcase and documentation site behind [shiki.birju.dev](https://shiki.birju.dev). It dogfoods the package. |
| [`storyboard/`](storyboard/) | The Pierre component storyboard (the diffs.com / shadcn "neutral" design system) the site is built from, locked with golden tests. |
| `shiki-main/` | Vendored upstream [Shiki](https://github.com/shikijs/shiki), used as the reference for golden generation. |
| [`docs/`](docs/) | Design notes and implementation plans. |
| `.github/workflows/` | CI: website deploy and the Oniguruma prebuild. |

## Development

Requires Flutter (Dart SDK `^3.12`). Resolve the whole workspace once from the
repository root:

```sh
flutter pub get
```

Run the package's test suite (analyzer output, golden comparisons, widget
tests):

```sh
cd packages/shiki_flutter
flutter test
```

Run the showcase site locally:

```sh
cd website
flutter run -d chrome
```

## License

MIT, Copyright (c) 2026 Birju Vachhani. Each package carries its own `LICENSE`.
Bundled grammars and themes keep their upstream licenses (see
[THIRD_PARTY_NOTICES.md](packages/shiki_flutter/THIRD_PARTY_NOTICES.md)); the
vendored `shiki-main/` is MIT.
