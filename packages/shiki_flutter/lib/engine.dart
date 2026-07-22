/// Flutter-free entrypoint: the TextMate tokenizer and the pluggable regex
/// engine seam, with no `dart:ui`/widget dependencies.
///
/// Import this (instead of `shiki_flutter.dart`) from non-Flutter contexts:
/// a native engine bridge, a CLI, or a `dart test` that must avoid `dart:ui`.
/// Flutter apps keep using `shiki_flutter.dart`, which exposes the same
/// tokenizer plus the rendering widgets.
library;

export 'src/async/token_cache.dart' show TokenCache;
export 'src/core/code_language.dart' show CodeLanguage, GrammarCategory;
export 'src/core/config.dart';
export 'src/core/highlighter.dart'
    show ShikiHighlighter, TokenizeOptions, ShikiError;
export 'src/core/themed_token.dart' show ThemedToken;
export 'src/onig/onig.dart'
    show
        ShikiHighlighterEngine,
        ShikiHighlighterEmbeddedEngine,
        OnigScanner,
        OnigString,
        OnigMatch,
        OnigCaptureIndex,
        kUnmatchedOffset;
