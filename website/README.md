# shiki_flutter website

The showcase site for [`shiki_flutter`](../) — a landing page and docs, styled
after [diffs.com](https://diffs.com) (the shadcn "neutral" palette: monochrome,
dark-forward, subtle borders).

Every code sample on the site is tokenized **live by shiki_flutter itself** via
`lib/src/highlight/highlighter_service.dart`, so the site doubles as a working
integration test of the package.

## Run it

```sh
cd website
flutter pub get
flutter run -d chrome
```

## Build for the web

```sh
flutter build web --release
```

The output is written to `build/web/`.

## Structure

```
lib/
  main.dart                     # entry: MaterialApp.router + ThemeController
  src/
    theme/                      # design tokens, ThemeData, dark/light controller
    router/app_router.dart      # go_router: / and /docs
    highlight/                  # the shared ShikiHighlighter + memoized spans
    data/                       # code snippets + external links
    widgets/                    # nav, footer, code block, buttons, switchers…
    pages/                      # home_page, docs_page
assets/fonts/                   # Inter + JetBrains Mono (OFL)
```

## Notes

- **Fonts** (Inter, JetBrains Mono) are vendored as OFL `.ttf` files under
  `assets/fonts/`, so the site needs no network at runtime.
- **Routing** uses clean URLs via `usePathUrlStrategy()`. When hosting on a
  static host, add an SPA fallback that serves `index.html` for unknown paths,
  and if serving from a sub-path, pass `--base-href /your-path/` to
  `flutter build web`.
- **Theme** defaults to dark; the nav toggle switches the whole site (and the
  code blocks pick GitHub Dark / GitHub Light to match).
