// The high-level highlighter, mirroring Shiki's `codeToTokens` pipeline.
library;

import 'dart:convert';

import '../bundled/bundled_language.dart';
import '../bundled/bundled_theme.dart';
import '../onig/onig.dart';
import '../textmate/encoded_token_metadata.dart';
import '../textmate/grammar.dart';
import '../textmate/raw_grammar.dart';
import '../textmate/registry.dart';
import '../textmate/theme.dart';
import 'colors.dart';
import 'theme_registration.dart';
import 'themed_token.dart';

/// Creates a highlighter with the given bundled [langs] and [themes] loaded.
///
/// Because [langs]/[themes] are passed by symbol (e.g. `dart`, `githubDark`
/// imported from `package:shiki_flutter/langs/dart.dart`), any bundled grammar
/// or theme your app never references is tree-shaken out of the final build.
///
/// ```dart
/// import 'package:shiki_flutter/shiki_flutter.dart';
/// import 'package:shiki_flutter/langs/dart.dart';
/// import 'package:shiki_flutter/themes/github_dark.dart';
///
/// final hl = createHighlighter(langs: [dart], themes: [githubDark]);
/// ```
ShikiHighlighter createHighlighter({
  List<BundledLanguage> langs = const [],
  List<BundledTheme> themes = const [],
  ShikiHighlighterEngine? engine,
}) {
  final hl = ShikiHighlighter(engine: engine);
  for (final lang in langs) {
    hl.loadBundledLanguage(lang);
  }
  for (final theme in themes) {
    hl.loadBundledTheme(theme);
  }
  return hl;
}

/// Thrown for highlighter usage errors (unknown language/theme, etc.).
class ShikiError implements Exception {
  ShikiError(this.message);
  final String message;
  @override
  String toString() => 'ShikiError: $message';
}

/// Options for [ShikiHighlighter.codeToTokens].
class TokenizeOptions {
  const TokenizeOptions({
    this.lang,
    this.theme,
    this.includeExplanation = false,
    this.tokenizeMaxLineLength = 0,
    this.tokenizeTimeLimit = 500,
    this.colorReplacements,
  });

  final String? lang;
  final String? theme;

  /// When true, each token carries its TextMate [ThemedToken.scopes].
  final bool includeExplanation;

  /// Lines at or beyond this length are emitted as a single un-tokenized token
  /// (0 disables the limit).
  final int tokenizeMaxLineLength;

  /// Per-line time budget in milliseconds (0 disables the limit).
  final int tokenizeTimeLimit;

  final Map<String, dynamic>? colorReplacements;
}

class _ResolvedTheme {
  _ResolvedTheme(this.registration, this.textmateTheme, this.colorMap);
  final ThemeRegistration registration;
  final Theme textmateTheme;
  final List<String> colorMap;
}

/// A synchronous, TextMate-grammar based syntax highlighter.
///
/// Load one or more languages and themes, then call [codeToTokens].
class ShikiHighlighter {
  /// The regex engine used by every highlighter that doesn't specify its own.
  ///
  /// Defaults to the pure-Dart [ShikiHighlighterDartEngine] (works on all
  /// platforms, fastest on web). Set this once — e.g. in `main` — to switch the
  /// default backend for the whole app:
  ///
  /// ```dart
  /// void main() {
  ///   if (!kIsWeb) ShikiHighlighter.engine = ShikiHighlighterFFIEngine();
  ///   runApp(const MyApp());
  /// }
  /// ```
  ///
  /// A per-highlighter `createHighlighter(engine: …)` argument overrides it.
  static ShikiHighlighterEngine engine = const ShikiHighlighterDartEngine();

  /// Creates a highlighter. [engine] overrides the global [engine] default for
  /// this instance only; when null the current [ShikiHighlighter.engine] is used.
  ShikiHighlighter({ShikiHighlighterEngine? engine})
      : _registry = SyncRegistry(
            Theme.createFromRawTheme(RawTheme(settings: [])),
            engine ?? ShikiHighlighter.engine);

  final SyncRegistry _registry;
  final Map<String, ThemeRegistration> _themes = {};
  final Map<String, _ResolvedTheme> _resolvedThemes = {};

  /// language name / alias -> scope name.
  final Map<String, String> _langToScope = {};
  final Set<String> _loadedScopes = {};

  String? _lastLoadedTheme;

  /// Loads a language grammar from a decoded JSON map.
  void loadLanguage(Map<String, dynamic> grammarJson) {
    final grammar = RawGrammar.fromJson(grammarJson);
    _registry.addGrammar(grammar);
    _loadedScopes.add(grammar.scopeName);
    _langToScope[grammar.scopeName] = grammar.scopeName;
    final name = grammar.name;
    if (name != null) {
      _langToScope[name.toLowerCase()] = grammar.scopeName;
    }
  }

  /// Loads a language grammar from a JSON string.
  ///
  /// Accepts either a single grammar object or a JSON array of grammars (the
  /// format used by Shiki's bundled language modules, where the array contains
  /// the main grammar plus any embedded grammars).
  void loadLanguageFromJson(String json) {
    final decoded = jsonDecode(json);
    if (decoded is List) {
      for (final grammar in decoded) {
        loadLanguage((grammar as Map).cast<String, dynamic>());
      }
    } else {
      loadLanguage((decoded as Map).cast<String, dynamic>());
    }
  }

  /// Registers an alias (e.g. `js` -> `javascript`).
  void addLanguageAlias(String alias, String target) {
    final scope = _langToScope[target.toLowerCase()] ?? target;
    _langToScope[alias.toLowerCase()] = scope;
  }

  /// Loads a bundled language (from `package:shiki_flutter/langs/<id>.dart`),
  /// including any grammars it embeds and its aliases. Idempotent.
  void loadBundledLanguage(BundledLanguage lang) {
    if (_loadedScopes.contains(lang.scopeName)) return;
    for (final embedded in lang.embeddedLanguages()) {
      loadBundledLanguage(embedded);
    }
    loadLanguageFromJson(lang.json);
    _langToScope[lang.id.toLowerCase()] = lang.scopeName;
    for (final alias in lang.aliases) {
      _langToScope[alias.toLowerCase()] = lang.scopeName;
    }
  }

  /// Loads a bundled theme (from `package:shiki_flutter/themes/<id>.dart`).
  String loadBundledTheme(BundledTheme theme) => loadThemeFromJson(theme.json);

  /// Loads a theme from a decoded JSON map and returns its resolved name.
  String loadTheme(Map<String, dynamic> themeJson) {
    final registration = normalizeTheme(ThemeRegistration.fromJson(themeJson));
    _themes[registration.name] = registration;
    _lastLoadedTheme = registration.name;
    return registration.name;
  }

  /// Loads a theme from a JSON string and returns its resolved name.
  String loadThemeFromJson(String json) =>
      loadTheme(jsonDecode(json) as Map<String, dynamic>);

  /// Registers an already-built [ThemeRegistration] (e.g. a built-in theme).
  String loadThemeRegistration(ThemeRegistration registration) {
    final normalized = normalizeTheme(registration);
    _themes[normalized.name] = normalized;
    _lastLoadedTheme = normalized.name;
    return normalized.name;
  }

  List<String> get loadedThemes => _themes.keys.toList();
  List<String> get loadedLanguages => _loadedScopes.toList();

  _ResolvedTheme _resolveTheme(String themeName) {
    final cached = _resolvedThemes[themeName];
    if (cached != null) return cached;

    final registration = _themes[themeName];
    if (registration == null) {
      throw ShikiError('Theme "$themeName" is not loaded');
    }
    final textmateTheme = Theme.createFromRawTheme(
        RawTheme(name: registration.name, settings: registration.settings));
    final colorMap = textmateTheme.getColorMap();
    final resolved = _ResolvedTheme(registration, textmateTheme, colorMap);
    _resolvedThemes[themeName] = resolved;
    return resolved;
  }

  Grammar _resolveGrammar(String lang) {
    final scope = _langToScope[lang.toLowerCase()] ?? lang;
    final grammar =
        _registry.grammarForScopeName(scope, 0, null, null, null);
    if (grammar == null) {
      throw ShikiError('Language "$lang" is not loaded');
    }
    return grammar;
  }

  /// The resolved theme registration (for background/foreground defaults).
  ThemeRegistration getThemeRegistration(String themeName) =>
      _resolveTheme(themeName).registration;

  /// Tokenizes [code] and returns a list of lines, each a list of themed
  /// tokens.
  List<List<ThemedToken>> codeToTokens(String code, TokenizeOptions options) {
    final themeName = options.theme ?? _lastLoadedTheme;
    final lang = options.lang ?? 'text';

    if (isPlainLang(lang) || isNoneTheme(themeName)) {
      return [
        for (final line in splitLines(code))
          [ThemedToken(content: line.content, offset: line.offset)]
      ];
    }

    if (themeName == null) {
      throw ShikiError('No theme specified and no theme has been loaded');
    }

    final resolved = _resolveTheme(themeName);
    _registry.setTheme(resolved.textmateTheme);
    final grammar = _resolveGrammar(lang);

    return _tokenizeWithTheme(code, grammar, resolved, options);
  }

  List<List<ThemedToken>> _tokenizeWithTheme(
    String code,
    Grammar grammar,
    _ResolvedTheme resolved,
    TokenizeOptions options,
  ) {
    final colorReplacements = resolveColorReplacements(
      resolved.registration.name,
      resolved.registration.colorReplacements,
      options.colorReplacements,
    );
    final colorMap = resolved.colorMap;

    final lines = splitLines(code);
    StateStack? stateStack;
    final result = <List<ThemedToken>>[];

    for (final entry in lines) {
      final line = entry.content;
      final lineOffset = entry.offset;

      if (line == '') {
        result.add([]);
        continue;
      }

      if (options.tokenizeMaxLineLength > 0 &&
          line.length >= options.tokenizeMaxLineLength) {
        result.add([
          ThemedToken(content: line, offset: lineOffset, color: '', fontStyle: 0)
        ]);
        continue;
      }

      TokenizeLineResult? withScopes;
      var scopeTokenIndex = 0;
      if (options.includeExplanation) {
        withScopes =
            grammar.tokenizeLine(line, stateStack, options.tokenizeTimeLimit);
      }

      final tokenized =
          grammar.tokenizeLine2(line, stateStack, options.tokenizeTimeLimit);
      final tokensLength = tokenized.tokens.length ~/ 2;
      final actual = <ThemedToken>[];

      for (var j = 0; j < tokensLength; j++) {
        final startIndex = tokenized.tokens[2 * j];
        final nextStartIndex =
            j + 1 < tokensLength ? tokenized.tokens[2 * j + 2] : line.length;
        if (startIndex == nextStartIndex) continue;

        final metadata = tokenized.tokens[2 * j + 1];
        final color = applyColorReplacements(
          colorMap[EncodedTokenMetadata.getForeground(metadata)],
          colorReplacements,
        );
        final bgId = EncodedTokenMetadata.getBackground(metadata);
        var bgColor = bgId == 0
            ? null
            : applyColorReplacements(colorMap[bgId], colorReplacements);
        // Drop the background when it is just the theme's default editor
        // background. Shiki paints that once on the container; keeping it on
        // every token would render each token as a filled box. Only genuine
        // per-scope background overrides survive.
        final defaultBg = resolved.registration.bg;
        if (bgColor != null &&
            defaultBg != null &&
            bgColor.toLowerCase() == defaultBg.toLowerCase()) {
          bgColor = null;
        }
        final fontStyle = EncodedTokenMetadata.getFontStyle(metadata);

        List<String>? scopes;
        if (withScopes != null) {
          scopes = [];
          var offset = 0;
          while (startIndex + offset < nextStartIndex &&
              scopeTokenIndex < withScopes.tokens.length) {
            final scopeToken = withScopes.tokens[scopeTokenIndex];
            offset += scopeToken.endIndex - scopeToken.startIndex;
            scopes.addAll(scopeToken.scopes);
            scopeTokenIndex += 1;
          }
        }

        actual.add(ThemedToken(
          content: line.substring(startIndex, nextStartIndex),
          offset: lineOffset + startIndex,
          color: color,
          bgColor: bgColor,
          fontStyle: fontStyle == FontStyle.notSet ? 0 : fontStyle,
          scopes: scopes,
        ));
      }

      result.add(actual);
      stateStack = tokenized.ruleStack;
    }

    return result;
  }
}
