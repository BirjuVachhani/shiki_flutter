# Pierre themes

A set of **10 custom Shiki themes** used by [diffs.com](https://diffs.com) and
built by [Pierre](https://pierre.co). They are standard VS Code / TextMate theme
JSON (an `editor.*` `colors` block plus 248 `tokenColors` scope rules), taken
from Pierre's published, MIT-licensed theme package
([`@pierre/theme`](https://github.com/pierrecomputer/pierre/tree/main/packages/theme)) —
not reconstructed from rendered output, so they are lossless.

## License / attribution

These themes are **MIT licensed**, © The Pierre Computer Company. The full
notice ships alongside them in [`LICENSE`](./LICENSE) — keep it with any copy you
redistribute. `shiki_flutter` itself is a separate work; this folder only
re-distributes Pierre's themes under their own MIT terms.

## Opt-in collection

This is a **separate, opt-in** collection: the Pierre themes are **not** part of
`themes/all.dart` and are not counted among the package's bundled Shiki themes.
Import only what you use — everything you don't import is tree-shaken out.

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

- `*.dart` — one `BundledTheme` per theme, same shape as the package's own
  `lib/themes/*.dart`, ready to pass to `createHighlighter(themes: [...])`. All
  ten embed their source JSON byte-for-byte.
- `pierre_themes.dart` — barrel that re-exports every theme plus a
  `pierreThemes` list.
- `json/` — the **faithful** verbatim originals. Kept in the repository as
  reference/source-of-truth; excluded from the published pub.dev archive (via
  `.pubignore`) since the `.dart` files already carry the same JSON.

## display-p3 (wide gamut)

`pierre-dark-vibrant` / `pierre-light-vibrant` define every color as
`color(display-p3 …)`. These values are preserved **verbatim** — `shiki_flutter`'s
`parseColor` renders them natively via `Color.from` + `ColorSpace.displayP3`
(wide-gamut where the platform/display supports it, gamut-mapped to sRGB
elsewhere). The other eight themes are already `#hex`.

## Using them

```dart
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter/langs/dart.dart';
// A single theme…
import 'package:shiki_flutter/pierre_themes/pierre_dark.dart';
// …or the whole collection via the barrel:
// import 'package:shiki_flutter/pierre_themes/pierre_themes.dart';

final highlighter = createHighlighter(
  langs: [dart],
  themes: [pierreDark], // or [...pierreThemes] for the whole set
);
```

For non-Dart use (JS Shiki, VS Code, etc.), copy the `json/` files directly.
