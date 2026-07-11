# Pierre themes

A self-contained set of **10 custom Shiki themes** used by
[diffs.com](https://diffs.com) (built by [Pierre](https://pierre.co)). They are
standard VS Code / TextMate theme JSON (an `editor.*` `colors` block plus 248
`tokenColors` scope rules) and were extracted from the site's published theme
chunks — not reconstructed from rendered output, so they are lossless.

> These are Pierre's themes. This folder is here for personal use / dogfooding
> the `shiki_flutter` port. Don't redistribute or publish them as your own.

## Contents

| File | Theme id | Type |
|------|----------|------|
| `pierre_dark.dart` | `pierre-dark` | dark |
| `pierre_light.dart` | `pierre-light` | light |
| `pierre_dark_soft.dart` | `pierre-dark-soft` | dark |
| `pierre_light_soft.dart` | `pierre-light-soft` | light |
| `pierre_dark_vibrant.dart` | `pierre-dark-vibrant` | dark |
| `pierre_light_vibrant.dart` | `pierre-light-vibrant` | light |
| `pierre_dark_protanopia_deuteranopia.dart` | `pierre-dark-protanopia-deuteranopia` | dark |
| `pierre_light_protanopia_deuteranopia.dart` | `pierre-light-protanopia-deuteranopia` | light |
| `pierre_dark_tritanopia.dart` | `pierre-dark-tritanopia` | dark |
| `pierre_light_tritanopia.dart` | `pierre-light-tritanopia` | light |

- `json/` — the **faithful** originals (verbatim theme JSON). The two vibrant
  themes here use wide-gamut `color(display-p3 …)` values, exactly as shipped.
- `*.dart` — one `BundledTheme` per theme, same shape as the package's own
  `lib/themes/*.dart`, ready to pass to `createHighlighter(themes: [...])`.
- `pierre_themes.dart` — barrel that re-exports every theme plus a
  `pierreThemes` list.

## display-p3 (wide gamut)

`pierre-dark-vibrant` / `pierre-light-vibrant` define every color as
`color(display-p3 …)`. These values are preserved **verbatim** in both `json/`
and the `.dart` copies — `shiki_flutter`'s `parseColor` renders them natively
via `Color.from` + `ColorSpace.displayP3` (wide-gamut where the platform/display
supports it, gamut-mapped to sRGB elsewhere). The other eight themes are already
`#hex`. All ten `.dart` files embed their source JSON byte-for-byte.

## Using them

The website uses `pierre-dark` / `pierre-light` as the **default** theme for all
code blocks (via `HighlighterService.themeForBrightness`); the theme-switcher
showcase overrides this to demo the real bundled package themes. Only the two
defaults are registered on the shared highlighter — the other eight variants
stay here as reusable source and are tree-shaken out of the build until you
register them.

```dart
import 'pierre_themes/pierre_themes.dart';

final highlighter = createHighlighter(
  langs: [...],
  themes: [pierreDark, pierreLight], // or [...pierreThemes] for the whole set
);
```

## Reusing / bundling later

The `.dart` files match `tool/generate_bundled.dart`'s output, so to fold them
into the package you can copy them into `lib/themes/` and add the exports to
`lib/themes/all.dart`. For non-Dart use (JS Shiki, etc.), copy the `json/`
files directly.
