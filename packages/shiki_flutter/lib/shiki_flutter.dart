/// A TextMate-grammar based syntax highlighter for Flutter, ported from Shiki.
///
/// Load a language grammar and a VS Code theme into a [ShikiHighlighter], then
/// either read the [ThemedToken]s directly via [ShikiHighlighter.codeToTokens]
/// or render them with [codeToTextSpan] / [ShikiCodeView].
///
/// ```dart
/// final highlighter = ShikiHighlighter();
/// highlighter.loadLanguage(jsonDecode(grammarJson));
/// final themeName = highlighter.loadTheme(jsonDecode(themeJson));
/// final span = codeToTextSpan(highlighter, sourceCode,
///     lang: 'dart', theme: themeName);
/// ```
library;

export 'src/bundled/bundled_language.dart' show BundledLanguage;
export 'src/bundled/bundled_theme.dart' show BundledTheme;
export 'src/core/colors.dart' show applyColorReplacements, splitLines;
export 'src/core/highlighter.dart'
    show ShikiHighlighter, TokenizeOptions, ShikiError, createHighlighter;
export 'src/core/theme_registration.dart'
    show ThemeRegistration, normalizeTheme;
export 'src/core/themed_token.dart' show ThemedToken;
// The pluggable regex-engine seam. Set `ShikiHighlighter.engine` (or pass
// `createHighlighter(engine: …)`) to swap the pure-Dart default for a native
// backend such as `ShikiHighlighterFFIEngine` from `shiki_flutter_ffi_engine`.
export 'src/onig/onig.dart'
    show
        ShikiHighlighterEngine,
        ShikiHighlighterDartEngine,
        OnigScanner,
        OnigString,
        OnigMatch,
        OnigCaptureIndex;
export 'src/flutter/code_list_view.dart' show ShikiCodeListView;
export 'src/flutter/code_view.dart' show ShikiCodeView;
export 'src/flutter/render.dart'
    show
        codeToTextSpan,
        tokensToTextSpan,
        codeToLineSpans,
        tokensToLineSpans,
        lineToTextSpan,
        themedTokenStyle,
        parseColor,
        parseHexColor;
export 'src/textmate/theme.dart' show FontStyle;
