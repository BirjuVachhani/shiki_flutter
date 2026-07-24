/// A TextMate-grammar based syntax highlighter for Flutter, ported from Shiki.
///
/// Load a language grammar and a Shiki theme into a [ShikiHighlighter], then
/// either read the [ThemedToken]s directly via [ShikiHighlighter.codeToTokens]
/// or render them with [codeToTextSpan] / [ShikiCodeView].
///
/// ```dart
/// import 'package:shiki_flutter/shiki_flutter.dart';
/// import 'package:shiki_flutter/langs.dart';
/// import 'package:shiki_flutter/themes.dart';
///
/// final highlighter = ShikiHighlighter();
/// // lang/theme are objects and are loaded on demand.
/// final span = codeToTextSpan(highlighter, sourceCode,
///     lang: CodeLanguages.dart, theme: ShikiThemes.githubDark);
/// ```
library;

// Flutter-free core: the TextMate tokenizer and the pluggable regex-engine
// seam (ShikiHighlighter, ThemedToken, the OnigScanner types, CodeLanguage /
// ShikiTheme, and more). Set `ShikiHighlighter.config` (ioEngine / webEngine)
// or pass `ShikiHighlighter(engine: …)` to swap the pure-Dart default for a
// native backend such as `ShikiHighlighterNativeEngine` from
// `shiki_flutter_native_engine`.
export 'engine.dart';
// Bundled, tree-shakeable grammars and themes. Referencing a member (e.g.
// `CodeLanguages.dart` / `ShikiThemes.githubDark` / `PierreThemes.pierreDark`)
// pulls in only that grammar/theme; the rest are tree-shaken away.
export 'langs.dart' show CodeLanguages;
export 'pierre_themes.dart' show PierreThemes;
export 'src/core/code_language.dart';
// Flutter-only surface not provided by `engine.dart`.
export 'src/core/colors.dart' show applyColorReplacements, splitLines;
export 'src/core/config.dart';
export 'src/core/highlighter.dart';
export 'src/core/shiki_theme.dart';
export 'src/core/theme_registration.dart'
    show ThemeRegistration, normalizeTheme;
export 'src/flutter/code_list_view.dart';
export 'src/flutter/code_view.dart';
export 'src/flutter/gutter.dart' show GutterStyle;
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
export 'themes.dart' show ShikiThemes;
