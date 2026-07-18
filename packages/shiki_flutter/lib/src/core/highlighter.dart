// The high-level highlighter, mirroring Shiki's `codeToTokens` pipeline.
library;

import 'dart:async';
import 'dart:convert';

import 'package:shiki_flutter_dart_engine/shiki_flutter_dart_engine.dart';

import '../async/lang_descriptor.dart';
import '../async/protocol.dart';
import '../async/token_cache.dart';
import '../async/tokenize_worker.dart';
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

/// Web vs. native without importing `package:flutter/foundation.dart` — whose
/// `kIsWeb` pulls in `dart:ui` and would break the Flutter-free `engine.dart`
/// entrypoint under plain `dart` and `dart compile js`. This is the same
/// compile-time predicate Dart's own conditional imports use.
const bool _kIsWeb = !bool.fromEnvironment('dart.library.io');

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
  TokenCache? cache,
}) {
  final hl = ShikiHighlighter(engine: engine, cache: cache);
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

/// Global defaults for [ShikiHighlighter], split by platform so IO and web can
/// be configured independently.
///
/// Set it once (e.g. in `main`) via [ShikiHighlighter.config]. Every field has a
/// platform-appropriate default, so override only what you need — usually with
/// [copyWith]:
///
/// ```dart
/// void main() {
///   ShikiHighlighter.config = ShikiHighlighter.config.copyWith(
///     ioEngine: const ShikiHighlighterNativeEngine(), // faster on IO
///     asyncWeb: true, // after `dart run shiki_flutter:install_web_worker`
///   );
///   runApp(const MyApp());
/// }
/// ```
class ShikiHighlighterConfig {
  const ShikiHighlighterConfig({
    this.ioEngine = const ShikiHighlighterDartEngine(),
    this.webEngine = const ShikiHighlighterEmbeddedEngine(),
    this.asyncIO = true,
    this.asyncWeb = false,
  });

  /// The regex engine used on native/VM (IO). Defaults to the pure-Dart
  /// [ShikiHighlighterDartEngine] (full parity, zero setup, works everywhere).
  /// Set it to `const ShikiHighlighterNativeEngine()` (from
  /// `shiki_flutter_native_engine`, after `flutter config --enable-native-assets`)
  /// for ~2.4x faster tokenization.
  final ShikiHighlighterEngine ioEngine;

  /// The regex engine used on web. Defaults to the built-in pure-Dart
  /// [ShikiHighlighterEmbeddedEngine], the fastest engine on web (no WASM).
  final ShikiHighlighterEngine webEngine;

  /// Whether the rendering widgets highlight asynchronously on native/VM,
  /// tokenizing on a background isolate so the UI thread never blocks on the
  /// one-time grammar compile. Defaults to `true`.
  final bool asyncIO;

  /// Whether the rendering widgets highlight asynchronously on web. Web has no
  /// isolates; when `true` and the Web Worker is installed
  /// (`dart run shiki_flutter:install_web_worker`) tokenization runs in that
  /// worker, otherwise it runs inline on the main thread. Defaults to `false`.
  final bool asyncWeb;

  /// Returns a copy with the given fields replaced.
  ShikiHighlighterConfig copyWith({
    ShikiHighlighterEngine? ioEngine,
    ShikiHighlighterEngine? webEngine,
    bool? asyncIO,
    bool? asyncWeb,
  }) =>
      ShikiHighlighterConfig(
        ioEngine: ioEngine ?? this.ioEngine,
        webEngine: webEngine ?? this.webEngine,
        asyncIO: asyncIO ?? this.asyncIO,
        asyncWeb: asyncWeb ?? this.asyncWeb,
      );
}

/// A synchronous, TextMate-grammar based syntax highlighter.
///
/// Load one or more languages and themes, then call [codeToTokens].
class ShikiHighlighter {
  /// Global defaults for the highlighter engine and async behavior, split by
  /// platform (see [ShikiHighlighterConfig]). Set it once, e.g. in `main`:
  ///
  /// ```dart
  /// ShikiHighlighter.config = ShikiHighlighter.config.copyWith(
  ///   ioEngine: const ShikiHighlighterNativeEngine(),
  /// );
  /// ```
  ///
  /// A `createHighlighter(engine: …)` argument overrides the engine per
  /// highlighter; a widget's `async:` argument overrides async per widget.
  static ShikiHighlighterConfig config = const ShikiHighlighterConfig();

  /// The engine [config] resolves to for the current platform:
  /// [ShikiHighlighterConfig.webEngine] on web, else
  /// [ShikiHighlighterConfig.ioEngine].
  static ShikiHighlighterEngine get engineDefault =>
      _kIsWeb ? config.webEngine : config.ioEngine;

  /// Whether async highlighting is on by default for the current platform:
  /// [ShikiHighlighterConfig.asyncWeb] on web, else
  /// [ShikiHighlighterConfig.asyncIO]. A widget's `async:` argument overrides it.
  static bool get asyncDefault => _kIsWeb ? config.asyncWeb : config.asyncIO;

  /// Creates a highlighter. [engine] overrides the global [engine] default for
  /// this instance only; when null [ShikiHighlighter.engineDefault] is used.
  /// [cache] overrides the token cache used for async highlighting.
  ShikiHighlighter({ShikiHighlighterEngine? engine, TokenCache? cache})
      : this._(engine ?? ShikiHighlighter.engineDefault, cache ?? TokenCache());

  ShikiHighlighter._(this._engine, this._tokenCache)
      : _registry = SyncRegistry(
          Theme.createFromRawTheme(RawTheme(settings: [])),
          _engine,
        );

  final ShikiHighlighterEngine _engine;
  final SyncRegistry _registry;
  final Map<String, ThemeRegistration> _themes = {};
  final Map<String, _ResolvedTheme> _resolvedThemes = {};

  /// language name / alias -> scope name.
  final Map<String, String> _langToScope = {};
  final Set<String> _loadedScopes = {};

  String? _lastLoadedTheme;

  // --- Async offloading state ------------------------------------------------
  //
  // What was loaded is captured (as sendable descriptors / raw JSON) so a worker
  // isolate can build an identical warm highlighter. Capture happens only at the
  // outermost public load call; the depth counters suppress the internal nested
  // calls (e.g. loadBundledLanguage -> loadLanguageFromJson -> loadLanguage).
  final TokenCache _tokenCache;
  final List<LangDescriptor> _asyncLangDescriptors = [];
  final List<String> _asyncRawLangJsons = [];
  final List<String> _asyncThemeJsons = [];
  int _langLoadDepth = 0;
  int _themeLoadDepth = 0;
  Future<TokenizeWorker>? _workerFuture;
  final Map<String, Future<List<List<ThemedToken>>>> _inflight = {};

  /// Loads a language grammar from a decoded JSON map.
  void loadLanguage(Map<String, dynamic> grammarJson) {
    final outermost = _langLoadDepth == 0;
    _langLoadDepth++;
    try {
      if (outermost) _captureRawLang(jsonEncode(grammarJson));
      final grammar = RawGrammar.fromJson(grammarJson);
      _registry.addGrammar(grammar);
      _loadedScopes.add(grammar.scopeName);
      _langToScope[grammar.scopeName] = grammar.scopeName;
      final name = grammar.name;
      if (name != null) {
        _langToScope[name.toLowerCase()] = grammar.scopeName;
      }
    } finally {
      _langLoadDepth--;
    }
  }

  /// Loads a language grammar from a JSON string.
  ///
  /// Accepts either a single grammar object or a JSON array of grammars (the
  /// format used by Shiki's bundled language modules, where the array contains
  /// the main grammar plus any embedded grammars).
  void loadLanguageFromJson(String json) {
    final outermost = _langLoadDepth == 0;
    _langLoadDepth++;
    try {
      if (outermost) _captureRawLang(json);
      final decoded = jsonDecode(json);
      if (decoded is List) {
        for (final grammar in decoded) {
          loadLanguage((grammar as Map).cast<String, dynamic>());
        }
      } else {
        loadLanguage((decoded as Map).cast<String, dynamic>());
      }
    } finally {
      _langLoadDepth--;
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
    final outermost = _langLoadDepth == 0;
    _langLoadDepth++;
    try {
      if (outermost) _captureLangDescriptor(lang);
      for (final embedded in lang.embeddedLanguages()) {
        loadBundledLanguage(embedded);
      }
      loadLanguageFromJson(lang.json);
      _langToScope[lang.id.toLowerCase()] = lang.scopeName;
      for (final alias in lang.aliases) {
        _langToScope[alias.toLowerCase()] = lang.scopeName;
      }
    } finally {
      _langLoadDepth--;
    }
  }

  /// Loads a bundled theme (from `package:shiki_flutter/themes/<id>.dart`).
  String loadBundledTheme(BundledTheme theme) => loadThemeFromJson(theme.json);

  /// Loads a theme from a decoded JSON map and returns its resolved name.
  String loadTheme(Map<String, dynamic> themeJson) {
    final outermost = _themeLoadDepth == 0;
    _themeLoadDepth++;
    try {
      if (outermost) _captureTheme(jsonEncode(themeJson));
      final registration = normalizeTheme(ThemeRegistration.fromJson(themeJson));
      _themes[registration.name] = registration;
      _lastLoadedTheme = registration.name;
      return registration.name;
    } finally {
      _themeLoadDepth--;
    }
  }

  /// Loads a theme from a JSON string and returns its resolved name.
  String loadThemeFromJson(String json) {
    final outermost = _themeLoadDepth == 0;
    _themeLoadDepth++;
    try {
      if (outermost) _captureTheme(json);
      return loadTheme(jsonDecode(json) as Map<String, dynamic>);
    } finally {
      _themeLoadDepth--;
    }
  }

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
    final textmateTheme = Theme.createFromRawTheme(RawTheme(name: registration.name, settings: registration.settings));
    final colorMap = textmateTheme.getColorMap();
    final resolved = _ResolvedTheme(registration, textmateTheme, colorMap);
    _resolvedThemes[themeName] = resolved;
    return resolved;
  }

  Grammar _resolveGrammar(String lang) {
    final scope = _langToScope[lang.toLowerCase()] ?? lang;
    final grammar = _registry.grammarForScopeName(scope, 0, null, null, null);
    if (grammar == null) {
      throw ShikiError('Language "$lang" is not loaded');
    }
    return grammar;
  }

  /// The resolved theme registration (for background/foreground defaults).
  ThemeRegistration getThemeRegistration(String themeName) => _resolveTheme(themeName).registration;

  /// Tokenizes [code] and returns a list of lines, each a list of themed
  /// tokens.
  List<List<ThemedToken>> codeToTokens(String code, TokenizeOptions options) {
    final themeName = options.theme ?? _lastLoadedTheme;
    final lang = options.lang ?? 'text';

    if (isPlainLang(lang) || isNoneTheme(themeName)) {
      return [
        for (final line in splitLines(code)) [ThemedToken(content: line.content, offset: line.offset)],
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

  // --- Async offloading API --------------------------------------------------

  /// The token cache backing [codeToTokensAsync]. Exposed so callers can size it
  /// (via `createHighlighter(cache: …)`) or clear it.
  TokenCache get tokenCache => _tokenCache;

  /// Whether a plain, un-highlighted result can be produced synchronously with no
  /// worker round trip (the plain/`none` short-circuit that [codeToTokens] takes).
  bool _isTrivial(String? lang, String? theme) =>
      isPlainLang(lang ?? 'text') || isNoneTheme(theme ?? _lastLoadedTheme);

  /// Returns already-cached tokens for these inputs synchronously, or null if
  /// they must be computed. Trivial (plain/`none`) inputs are produced inline.
  ///
  /// A widget uses this to render highlighted output on the very first frame when
  /// the result is cached (no placeholder flash).
  List<List<ThemedToken>>? peekTokens(String code, TokenizeOptions options) {
    if (_isTrivial(options.lang, options.theme)) return codeToTokens(code, options);
    return _tokenCache.get(TokenCache.keyFor(code, options));
  }

  /// Tokenizes [code] off the current isolate (on native/VM), caching the result.
  ///
  /// Returns cached tokens immediately when present; otherwise spawns a warm
  /// worker on first use and reuses it for every later call. Identical in-flight
  /// requests are coalesced. On native/VM the worker is a background isolate; on
  /// web it is a browser Web Worker when one is installed (see
  /// `dart run shiki_flutter:install_web_worker`), otherwise it runs inline.
  Future<List<List<ThemedToken>>> codeToTokensAsync(
    String code,
    TokenizeOptions options,
  ) {
    if (_isTrivial(options.lang, options.theme)) {
      return Future.value(codeToTokens(code, options));
    }
    final key = TokenCache.keyFor(code, options);
    final cached = _tokenCache.get(key);
    if (cached != null) return Future.value(cached);
    return _inflight[key] ??= _runTokenize(key, code, options);
  }

  Future<List<List<ThemedToken>>> _runTokenize(
    String key,
    String code,
    TokenizeOptions options,
  ) async {
    try {
      final worker = await _ensureWorker();
      final List<List<ThemedToken>> tokens;
      if (_kIsWeb && !worker.isRemote) {
        // On web the worker is a browser Web Worker. When one isn't available
        // (the worker script isn't installed, or a CSP blocks it) the seam
        // falls back to an inline worker; in that case tokenize on THIS
        // highlighter instead — reusing its already-loaded grammars rather than
        // the fallback's second copy — deferred one event-loop turn so a
        // placeholder frame can paint before the (blocking) tokenize.
        tokens = await Future(() => codeToTokens(code, options));
      } else {
        tokens = await worker.tokenize(code, options);
      }
      _tokenCache.put(key, tokens, code.length);
      return tokens;
    } finally {
      _inflight.remove(key);
    }
  }

  Future<TokenizeWorker> _ensureWorker() => _workerFuture ??= spawnTokenizeWorker(
        WorkerConfig(
          engine: _engine,
          langs: List.of(_asyncLangDescriptors),
          rawLangJsons: List.of(_asyncRawLangJsons),
          themeJsons: List.of(_asyncThemeJsons),
        ),
      );

  void _captureLangDescriptor(BundledLanguage lang) {
    final descriptor = flattenBundledLanguage(lang);
    _asyncLangDescriptors.add(descriptor);
    _workerFuture?.then((w) => w.loadLanguage(descriptor));
  }

  void _captureRawLang(String json) {
    _asyncRawLangJsons.add(json);
    _workerFuture?.then((w) => w.loadRawLanguage(json));
  }

  void _captureTheme(String json) {
    _asyncThemeJsons.add(json);
    _workerFuture?.then((w) => w.loadTheme(json));
  }

  /// Tears down the background worker (if any) and clears the token cache.
  ///
  /// Call when a highlighter is no longer needed. The highlighter can still be
  /// used synchronously afterward; a later async call spawns a fresh worker.
  ///
  /// Returns immediately: if a worker spawn is still in flight it is killed once
  /// it lands, so disposing never blocks on a pending spawn.
  Future<void> dispose() async {
    final worker = _workerFuture;
    _workerFuture = null;
    _tokenCache.clear();
    if (worker != null) {
      unawaited(worker.then((w) => w.dispose()).catchError((_) {}));
    }
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

      if (options.tokenizeMaxLineLength > 0 && line.length >= options.tokenizeMaxLineLength) {
        result.add([ThemedToken(content: line, offset: lineOffset, color: '', fontStyle: 0)]);
        continue;
      }

      TokenizeLineResult? withScopes;
      var scopeTokenIndex = 0;
      if (options.includeExplanation) {
        withScopes = grammar.tokenizeLine(line, stateStack, options.tokenizeTimeLimit);
      }

      final tokenized = grammar.tokenizeLine2(line, stateStack, options.tokenizeTimeLimit);
      final tokensLength = tokenized.tokens.length ~/ 2;
      final actual = <ThemedToken>[];

      for (var j = 0; j < tokensLength; j++) {
        final startIndex = tokenized.tokens[2 * j];
        final nextStartIndex = j + 1 < tokensLength ? tokenized.tokens[2 * j + 2] : line.length;
        if (startIndex == nextStartIndex) continue;

        final metadata = tokenized.tokens[2 * j + 1];
        final color = applyColorReplacements(colorMap[EncodedTokenMetadata.getForeground(metadata)], colorReplacements);
        final bgId = EncodedTokenMetadata.getBackground(metadata);
        var bgColor = bgId == 0 ? null : applyColorReplacements(colorMap[bgId], colorReplacements);
        // Drop the background when it is just the theme's default editor
        // background. Shiki paints that once on the container; keeping it on
        // every token would render each token as a filled box. Only genuine
        // per-scope background overrides survive.
        final defaultBg = resolved.registration.bg;
        if (bgColor != null && defaultBg != null && bgColor.toLowerCase() == defaultBg.toLowerCase()) {
          bgColor = null;
        }
        final fontStyle = EncodedTokenMetadata.getFontStyle(metadata);

        List<String>? scopes;
        if (withScopes != null) {
          scopes = [];
          var offset = 0;
          while (startIndex + offset < nextStartIndex && scopeTokenIndex < withScopes.tokens.length) {
            final scopeToken = withScopes.tokens[scopeTokenIndex];
            offset += scopeToken.endIndex - scopeToken.startIndex;
            scopes.addAll(scopeToken.scopes);
            scopeTokenIndex += 1;
          }
        }

        actual.add(
          ThemedToken(
            content: line.substring(startIndex, nextStartIndex),
            offset: lineOffset + startIndex,
            color: color,
            bgColor: bgColor,
            fontStyle: fontStyle == FontStyle.notSet ? 0 : fontStyle,
            scopes: scopes,
          ),
        );
      }

      result.add(actual);
      stateStack = tokenized.ruleStack;
    }

    return result;
  }
}
