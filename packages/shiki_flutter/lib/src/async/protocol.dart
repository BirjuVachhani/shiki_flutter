// Sendable value types shared by the worker implementations.
//
// This file must NOT import `dart:isolate`: it is reached from web builds (via
// `WorkerConfig`), where `dart:isolate` is unavailable. The `SendPort`-bearing
// bootstrap/handshake types live in `tokenize_worker_io.dart` instead.

import 'package:shiki_flutter_engine_interface/shiki_flutter_engine_interface.dart';

import '../core/highlighter.dart';
import '../core/themed_token.dart';
import 'lang_descriptor.dart';

/// A (lang, theme) pair to tokenize once at spawn so the expensive first-call
/// grammar/regex compile happens off the UI thread before any real request.
class WarmupSpec {
  /// Creates a [WarmupSpec] for the given [lang]/[theme] pair.
  const WarmupSpec(this.lang, this.theme);

  /// The language id to warm up, matching a bundled or loaded grammar.
  final String lang;

  /// The theme id to warm up, matching a bundled or loaded theme.
  final String theme;
}

/// Everything needed to build a warm highlighter inside a worker.
///
/// [engine] is passed as an instance rather than an identifier: the concrete
/// engines are `const` and stateless (they allocate native/scanner resources
/// lazily), so they copy across an isolate boundary and let the worker use the
/// exact engine the caller chose without this package depending on every engine
/// backend. When null the worker uses its own default.
class WorkerConfig {
  /// Creates a [WorkerConfig]; every field is optional and defaults to
  /// empty, so the worker falls back to its own defaults where unset.
  const WorkerConfig({
    this.engine,
    this.langs = const [],
    this.rawLangJsons = const [],
    this.themeJsons = const [],
    this.warmups = const [],
  });

  /// The tokenizer engine to build the worker's highlighter with, or
  /// `null` to use the worker's own default.
  final ShikiHighlighterEngine? engine;

  /// Bundled languages (with their embedded grammars and aliases).
  final List<LangDescriptor> langs;

  /// Languages loaded from a raw grammar JSON string (single grammar or an
  /// array), mirroring a direct `loadLanguageFromJson` on the main highlighter.
  final List<String> rawLangJsons;

  /// Raw theme JSON strings to load into the worker's highlighter.
  final List<String> themeJsons;

  /// (lang, theme) pairs to tokenize once at spawn to pre-warm the
  /// worker's grammar/regex compilation; see [WarmupSpec].
  final List<WarmupSpec> warmups;
}

/// A request to tokenize [code], correlated to its response by [id].
class TokenizeRequest {
  /// Creates a [TokenizeRequest] for [code] with the given [options],
  /// tagged with [id] so the matching response can be correlated back.
  const TokenizeRequest(this.id, this.code, this.options);

  /// Correlates this request to its [TokenizeResponse] or [TokenizeError].
  final int id;

  /// The source code to tokenize.
  final String code;

  /// The language/theme and tokenization limits to use.
  final TokenizeOptions options;
}

/// A successful tokenize result for request [id].
class TokenizeResponse {
  /// Creates a [TokenizeResponse] for request [id] carrying [tokens].
  const TokenizeResponse(this.id, this.tokens);

  /// Matches the originating [TokenizeRequest.id].
  final int id;

  /// The tokenized lines; one list of [ThemedToken]s per source line.
  final List<List<ThemedToken>> tokens;
}

/// A failed tokenize for request [id].
class TokenizeError {
  /// Creates a [TokenizeError] for request [id] with a [message] and
  /// [stackTrace] captured from the worker.
  const TokenizeError(this.id, this.message, this.stackTrace);

  /// Matches the originating [TokenizeRequest.id].
  final int id;

  /// A human-readable description of the failure.
  final String message;

  /// The stack trace from the worker, formatted as a string since
  /// [StackTrace] objects aren't guaranteed sendable across isolates.
  final String stackTrace;
}

/// Adds a bundled language to an already-running worker.
class LoadLangMessage {
  /// Creates a [LoadLangMessage] for [lang].
  const LoadLangMessage(this.lang);

  /// The bundled language to load into the worker.
  final LangDescriptor lang;
}

/// Adds a raw-JSON language to an already-running worker.
class LoadRawLangMessage {
  /// Creates a [LoadRawLangMessage] for the raw grammar [json].
  const LoadRawLangMessage(this.json);

  /// A raw grammar JSON string (single grammar or an array), matching
  /// [WorkerConfig.rawLangJsons].
  final String json;
}

/// Adds a theme to an already-running worker.
class LoadThemeMessage {
  /// Creates a [LoadThemeMessage] for the raw theme [themeJson].
  const LoadThemeMessage(this.themeJson);

  /// A raw theme JSON string, matching [WorkerConfig.themeJsons].
  final String themeJson;
}
