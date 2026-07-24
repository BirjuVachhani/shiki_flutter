# Regenerating bundled languages & themes (maintainer guide)

The bundled grammars, themes, and Pierre themes are **generated**, never hand-written.
This doc explains how to regenerate them and how to bump the upstream sources.

> Audience: package maintainers. This is not part of the published package docs.

## What is generated

| Output | Contents | Public? |
|---|---|---|
| `lib/src/langs/*.dart` | one `const CodeLanguage` per grammar (incl. injection grammars) | internal (`src/`) |
| `lib/src/themes/*.dart` | one `const ShikiTheme` per theme | internal |
| `lib/src/pierre_themes/*.dart` | one `const ShikiTheme` per Pierre theme | internal |
| `lib/langs.dart` | `CodeLanguages` facade (`static const` per language + `all`) | exposed |
| `lib/themes.dart` | `ShikiThemes` facade | exposed |
| `lib/pierre_themes.dart` | `PierreThemes` facade (opt-in Pierre set) | exposed |
| `THIRD_PARTY_NOTICES.md` (package root) | upstream license/NOTICE text | shipped |

Consumers reference a member (e.g. `CodeLanguages.dart`, `ShikiThemes.githubDark`,
`PierreThemes.pierreDark`); because every symbol is `const`, the `static const`
facade members are pure compile-time aliases, so unused languages/themes are
tree-shaken out of the build.

## Sources (pinned)

All sources are npm packages, pinned in [`tm/package.json`](tm/package.json):

| Package | Provides | Upstream |
|---|---|---|
| `tm-grammars` | TextMate grammars (`.json`) + `index.js` metadata | github.com/shikijs/textmate-grammars-themes |
| `tm-themes` | TextMate themes (`.json`) + metadata | (same repo) |
| `@pierre/theme` | the 10 opt-in Pierre themes (`.json`) | github.com/pierrecomputer/pierre (packages/theme) |

`tool/tm/node_modules`, `tool/tm/package-lock.json`, and `tool/tm/meta.json` are
git-ignored: they are build-time only.

## Prerequisites

- Node + npm (to fetch sources and dump metadata)
- The Dart/Flutter SDK

## Regenerate (two steps)

Run step 1 once, or any time you bump a version in `tm/package.json`:

```sh
cd tool/tm
npm ci              # installs the pinned sources into node_modules/
node dump_meta.mjs  # writes meta.json (grammar/theme metadata)
```

Then, from the **package root** (`packages/shiki_flutter`):

```sh
dart run tool/generate_bundled.dart
```

The generator wipes and rewrites `lib/src/{langs,themes,pierre_themes}`, the three
facades, and `THIRD_PARTY_NOTICES.md`. It prints a summary like
`Generated 235 languages (+18 injections), 65 themes, and 10 Pierre themes.`

### Why the metadata dump?

The raw grammar/theme `.json` files carry the payload (`scopeName`, `patterns`,
`colors`, `tokenColors`) but not the `aliases` or `embedded`-language relationships,
which live in each package's `index.js`. `dump_meta.mjs` reads `tm-grammars` and
`tm-themes` and writes those relationships to `meta.json` for the Dart generator.
(Pierre themes need no metadata dump: the generator reads
`node_modules/@pierre/theme/themes/*.json` directly.)

## Bumping to a newer upstream version

1. Edit the version(s) in [`tm/package.json`](tm/package.json).
2. Re-run both steps above.
3. `git diff` the result: new languages/themes appear automatically (the generator
   enumerates whatever is installed), and grammar/theme content updates in place.
4. Verify (below), then commit. Update `CHANGELOG.md` if the language/theme set changed.

## Verify after regenerating

- **Analyze:** `dart analyze` (from the package root). The generated dirs are
  intentionally *not* excluded, so a bad generated `const` shows up here.
- **Tests:** `flutter test`. Watch especially:
  - `test/theme_goldens_test.dart` — if a theme's colors changed upstream, its golden
    will fail; regenerate with `flutter test --update-goldens test/theme_goldens_test.dart`
    after eyeballing the diff.
  - `test/bundled_test.dart` — includes the `ruby <-> haml` embed-cycle regression.
- **Tree-shaking (optional):** compile a probe that references one member vs `.all`
  and compare sizes; see `tool/measure_size.dart`. A single lang+theme should produce
  a tiny artifact; `.all` a large one.

## Rules and gotchas

- **Never hand-edit generated files** (`lib/src/langs`, `lib/src/themes`,
  `lib/src/pierre_themes`, `lib/langs.dart`, `lib/themes.dart`, `lib/pierre_themes.dart`).
  Change the generator and regenerate. Every generated file starts with a
  `// GENERATED ... Do not edit.` banner.
- **Keep everything `const`.** The tree-shaking guarantee depends on it. Do not switch
  the symbols to `final`, an `enum`, or a `Map`, and do not add an eager aggregate. The
  `all` list is the only aggregate and is opt-in (referencing it pulls in everything).
- **Embedded languages use a named `_embedded()` thunk**, not an inline closure, so the
  `const` stays valid. Reference cycles (e.g. `ruby` embeds `haml`, `haml` embeds `ruby`)
  are handled at load time by the highlighter's in-flight guard, not here.
- **Renaming the public types/facades touches two places.** The names live in the
  generated output *and* in the generator's emit strings plus the type files
  (`lib/src/core/code_language.dart`, `lib/src/core/shiki_theme.dart`). If you rename a
  type/facade, update the generator's emitted strings too, or the next regeneration will
  revert your rename.

## Naming reference

| Concept | Value type | Facade (file) |
|---|---|---|
| Language | `CodeLanguage` | `CodeLanguages` (`lib/langs.dart`) |
| Theme | `ShikiTheme` | `ShikiThemes` (`lib/themes.dart`) |
| Pierre theme | `ShikiTheme` | `PierreThemes` (`lib/pierre_themes.dart`) |
