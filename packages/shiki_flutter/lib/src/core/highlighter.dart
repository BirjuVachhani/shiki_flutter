import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';

import '../async/lang_descriptor.dart';
import '../async/protocol.dart';
import '../async/token_cache.dart';
import '../async/tokenize_worker.dart';
import '../onig/onig.dart';
import '../textmate/encoded_token_metadata.dart';
import '../textmate/grammar.dart';
import '../textmate/raw_grammar.dart';
import '../textmate/registry.dart';
import '../textmate/theme.dart';
import 'code_language.dart';
import 'colors.dart';
import 'config.dart';
import 'shiki_theme.dart';
import 'theme_registration.dart';
import 'themed_token.dart';

/// Web vs. native without importing `package:flutter/foundation.dart`, whose
/// `kIsWeb` pulls in `dart:ui` and would break the Flutter-free `engine.dart`
/// entrypoint under plain `dart` and `dart compile js`. This is the same
/// compile-time predicate Dart's own conditional imports use.
const bool _kIsWeb = !bool.fromEnvironment('dart.library.io');

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
    this.tokenizeTimeLimit = 0,
    this.colorReplacements,
  });

  final String? lang;
  final String? theme;

  /// When true, each token carries its TextMate [ThemedToken.scopes].
  final bool includeExplanation;

  /// Lines at or beyond this length are emitted as a single un-tokenized token
  /// (0 disables the limit).
  final int tokenizeMaxLineLength;

  /// Per-line time budget in milliseconds. Defaults to `0` (unlimited), so
  /// tokenization is a pure function of the input and stays byte-identical to
  /// Shiki regardless of machine load. Set a positive value only to opt into a
  /// main-thread safety budget: when a single line exceeds it, tokenization of
  /// that line stops early and the remainder is emitted as one coarse token,
  /// which makes output depend on wall-clock time (and thus non-deterministic
  /// under load). Async highlighting keeps this work off the UI thread anyway,
  /// so the limit is rarely needed; for pathological lines prefer
  /// [tokenizeMaxLineLength].
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
  /// Global defaults for the highlighter engine and async behavior, split by
  /// platform (see [ShikiHighlighterConfig]). Set it once, e.g. in `main`:
  ///
  /// ```dart
  /// ShikiHighlighter.config = ShikiHighlighter.config.copyWith(
  ///   ioEngine: const ShikiHighlighterNativeEngine(),
  /// );
  /// ```
  ///
  /// A `ShikiHighlighter(engine: …)` argument overrides the engine per
  /// highlighter; a widget's `async:` argument overrides async per widget.
  static ShikiHighlighterConfig config = const ShikiHighlighterConfig();

  static ShikiHighlighter? _lazyDefault;

  /// The highlighter the rendering widgets use when none is passed to them: the
  /// one set on [ShikiHighlighterConfig.defaultHighlighter], or a lazily-created
  /// shared instance. Set `ShikiHighlighter.config.defaultHighlighter` (e.g. a
  /// [preload]ed highlighter) to control it.
  static ShikiHighlighter get effectiveDefault =>
      config.defaultHighlighter ?? (_lazyDefault ??= ShikiHighlighter());

  /// Creates a highlighter. [engine] overrides the global engine default
  /// (`ShikiHighlighter.config.engine`) for this instance only.
  /// [cache] overrides the token cache used for async highlighting.
  ShikiHighlighter({ShikiHighlighterEngine? engine, TokenCache? cache})
    : _engine = engine ?? ShikiHighlighter.config.engine,
      _tokenCache = cache ?? TokenCache(),
      _registry = SyncRegistry(
        Theme.createFromRawTheme(RawTheme(settings: [])),
        engine ?? ShikiHighlighter.config.engine,
      );

  final ShikiHighlighterEngine _engine;
  final SyncRegistry _registry;
  final Map<String, ThemeRegistration> _themes = {};
  final Map<String, _ResolvedTheme> _resolvedThemes = {};

  /// Ids of [ShikiTheme]s loaded via [loadShikiTheme]/[ensureShikiTheme], so the
  /// latter can skip re-parsing a theme's JSON on repeat calls (a theme's `id`
  /// need not equal its registration name, which is what [_themes] keys on).
  final Set<String> _loadedShikiThemeIds = {};

  /// language name / alias -> scope name.
  final Map<String, String> _langToScope = {};
  final Set<String> _loadedScopes = {};

  /// Bundled scopes currently being loaded, so a cyclic `embeddedLanguages`
  /// graph (e.g. `markdown` -> `html` -> ... -> `markdown`) doesn't recurse
  /// forever: the scope is only added to [_loadedScopes] after its JSON is
  /// registered, which happens *after* the embedded recursion below.
  final Set<String> _loadingBundledScopes = {};

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
  @internal
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
  @internal
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
  @internal
  void addLanguageAlias(String alias, String target) {
    final scope = _langToScope[target.toLowerCase()] ?? target;
    _langToScope[alias.toLowerCase()] = scope;
  }

  /// Loads a bundled language (from `package:shiki_flutter/langs/<id>.dart`),
  /// including any grammars it embeds and its aliases. Idempotent.
  @internal
  void loadBundledLanguage(CodeLanguage lang) {
    if (_loadedScopes.contains(lang.scopeName)) return;
    // Break embed cycles: skip a scope already being loaded further up the
    // recursion (its JSON is registered below, after the embedded loop).
    if (!_loadingBundledScopes.add(lang.scopeName)) return;
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
      _loadingBundledScopes.remove(lang.scopeName);
    }
  }

  /// Loads a bundled theme (from `package:shiki_flutter/themes/<id>.dart`).
  @internal
  String loadShikiTheme(ShikiTheme theme) {
    _loadedShikiThemeIds.add(theme.id);
    return loadThemeFromJson(theme.json);
  }

  /// Loads [theme] only if a [ShikiTheme] with the same id has not been loaded
  /// yet. Idempotent, so the widgets can call it on every build without
  /// re-parsing the theme JSON.
  void ensureShikiTheme(ShikiTheme theme) {
    if (!_loadedShikiThemeIds.contains(theme.id)) loadShikiTheme(theme);
  }

  /// Loads [lang]'s grammar only if its scope is not already loaded. Idempotent,
  /// so the widgets can call it on every build without re-parsing the grammar.
  void ensureLanguage(CodeLanguage lang) {
    if (!_loadedScopes.contains(lang.scopeName)) loadBundledLanguage(lang);
  }

  /// Eagerly loads [langs] and [themes] so the first render (or [codeToTokens]
  /// call) that uses them pays no grammar/theme parse cost. Optional warm-up:
  /// the rendering widgets and render helpers load their content on demand
  /// anyway. A [ShikiDualTheme] warms both its light and dark sides.
  ///
  /// The synchronous parse runs before the returned future first suspends, so a
  /// highlighter used synchronously right after `..preload(...)` is already warm
  /// without awaiting.
  ///
  /// Pass [warmAsync] to also spawn and warm the background worker that backs
  /// `async` widgets and [codeToTokensAsync] (a background isolate on native, a
  /// Web Worker on web when installed). Then `await`ing the result waits for
  /// that worker to finish loading the same grammars and themes, so the first
  /// async render pays no isolate-spawn or grammar-build cost either.
  Future<void> preload({
    List<CodeLanguage> langs = const [],
    List<ShikiThemeBase> themes = const [],
    bool warmAsync = false,
  }) async {
    for (final lang in langs) {
      ensureLanguage(lang);
    }
    for (final theme in themes) {
      for (final concrete in theme.themes) {
        ensureShikiTheme(concrete);
      }
    }
    if (warmAsync) await _ensureWorker();
  }

  /// Loads a theme from a decoded JSON map and returns its resolved name.
  @internal
  String loadTheme(Map<String, dynamic> themeJson) {
    final outermost = _themeLoadDepth == 0;
    _themeLoadDepth++;
    try {
      if (outermost) _captureTheme(jsonEncode(themeJson));
      final registration = normalizeTheme(
        ThemeRegistration.fromJson(themeJson),
      );
      _themes[registration.name] = registration;
      _lastLoadedTheme = registration.name;
      return registration.name;
    } finally {
      _themeLoadDepth--;
    }
  }

  /// Loads a theme from a JSON string and returns its resolved name.
  @internal
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
  ///
  /// The normalized theme is also serialized and forwarded to the async worker
  /// (see [_captureTheme]), so a theme registered as a Dart object works with
  /// [codeToTokensAsync] and `async` widgets just like [loadThemeFromJson].
  @internal
  String loadThemeRegistration(ThemeRegistration registration) {
    final normalized = normalizeTheme(registration);
    // Normalizing is idempotent (colors already hex, leading default present),
    // so the worker re-parsing this JSON resolves to the same theme.
    _captureTheme(jsonEncode(normalized.toJson()));
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
      RawTheme(name: registration.name, settings: registration.settings),
    );
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
          [ThemedToken(content: line.content, offset: line.offset)],
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
  /// (via `ShikiHighlighter(cache: …)`) or clear it.
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
    if (_isTrivial(options.lang, options.theme)) {
      return codeToTokens(code, options);
    }
    return _tokenCache.get(TokenCache.keyFor(code, options));
  }

  /// Tokenizes [code] off the current isolate (on native/VM), caching the result.
  ///
  /// Returns cached tokens immediately when present; otherwise spawns a warm
  /// worker on first use and reuses it for every later call. Identical in-flight
  /// requests are coalesced. On native/VM the worker is a background isolate; on
  /// web it is a browser Web Worker when one is installed (see
  /// `dart run shiki_flutter:install`), otherwise it runs inline.
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
        // highlighter instead (reusing its already-loaded grammars rather than
        // the fallback's second copy) deferred one event-loop turn so a
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

  Future<TokenizeWorker> _ensureWorker() =>
      _workerFuture ??= spawnTokenizeWorker(
        WorkerConfig(
          engine: _engine,
          langs: List.of(_asyncLangDescriptors),
          rawLangJsons: List.of(_asyncRawLangJsons),
          themeJsons: List.of(_asyncThemeJsons),
        ),
      );

  void _captureLangDescriptor(CodeLanguage lang) {
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

      if (options.tokenizeMaxLineLength > 0 &&
          line.length >= options.tokenizeMaxLineLength) {
        result.add([
          ThemedToken(
            content: line,
            offset: lineOffset,
            color: '',
            fontStyle: 0,
          ),
        ]);
        continue;
      }

      TokenizeLineResult? withScopes;
      var scopeTokenIndex = 0;
      if (options.includeExplanation) {
        withScopes = grammar.tokenizeLine(
          line,
          stateStack,
          options.tokenizeTimeLimit,
        );
      }

      final tokenized = grammar.tokenizeLine2(
        line,
        stateStack,
        options.tokenizeTimeLimit,
      );
      final tokensLength = tokenized.tokens.length ~/ 2;
      final actual = <ThemedToken>[];

      for (var j = 0; j < tokensLength; j++) {
        final startIndex = tokenized.tokens[2 * j];
        final nextStartIndex = j + 1 < tokensLength
            ? tokenized.tokens[2 * j + 2]
            : line.length;
        if (startIndex == nextStartIndex) continue;

        final metadata = tokenized.tokens[2 * j + 1];
        final color = applyColorReplacements(
          colorMap[EncodedTokenMetadata.getForeground(metadata)],
          colorReplacements,
        );
        // Deliberately no per-token background. Shiki's base tokenizer only
        // emits a foreground/fontStyle per token; the theme's background is
        // painted once on the container, never behind each token. Deriving a
        // background from the encoded metadata just re-surfaces the theme's
        // default editor background (or the textmate `#ffffff` fallback for
        // themes whose global setting omits a background, e.g. gruvbox), which
        // would render every token as a filled box.
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

        actual.add(
          ThemedToken(
            content: line.substring(startIndex, nextStartIndex),
            offset: lineOffset + startIndex,
            color: color,
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
