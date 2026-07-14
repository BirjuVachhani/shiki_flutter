/// Flutter-free entrypoint: the TextMate tokenizer and the pluggable regex
/// engine seam, with no `dart:ui`/widget dependencies.
///
/// Import this (instead of `shiki_flutter.dart`) from non-Flutter contexts —
/// a native engine bridge, a CLI, or a `dart test` that must avoid `dart:ui`.
/// Flutter apps keep using `shiki_flutter.dart`, which exposes the same
/// tokenizer plus the rendering widgets.
library;

export 'src/bundled/bundled_language.dart' show BundledLanguage;
export 'src/bundled/bundled_theme.dart' show BundledTheme;
export 'src/core/highlighter.dart'
    show ShikiHighlighter, TokenizeOptions, ShikiError, createHighlighter;
export 'src/core/themed_token.dart' show ThemedToken;
export 'src/onig/onig.dart'
    show
        ShikiHighlighterEngine,
        ShikiHighlighterDartEngine,
        OnigScanner,
        OnigString,
        OnigMatch,
        OnigCaptureIndex,
        kUnmatchedOffset;
