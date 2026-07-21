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
  const WarmupSpec(this.lang, this.theme);
  final String lang;
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
  const WorkerConfig({
    this.engine,
    this.langs = const [],
    this.rawLangJsons = const [],
    this.themeJsons = const [],
    this.warmups = const [],
  });

  final ShikiHighlighterEngine? engine;

  /// Bundled languages (with their embedded grammars and aliases).
  final List<LangDescriptor> langs;

  /// Languages loaded from a raw grammar JSON string (single grammar or an
  /// array), mirroring a direct `loadLanguageFromJson` on the main highlighter.
  final List<String> rawLangJsons;

  final List<String> themeJsons;
  final List<WarmupSpec> warmups;
}

/// A request to tokenize [code], correlated to its response by [id].
class TokenizeRequest {
  const TokenizeRequest(this.id, this.code, this.options);
  final int id;
  final String code;
  final TokenizeOptions options;
}

/// A successful tokenize result for request [id].
class TokenizeResponse {
  const TokenizeResponse(this.id, this.tokens);
  final int id;
  final List<List<ThemedToken>> tokens;
}

/// A failed tokenize for request [id].
class TokenizeError {
  const TokenizeError(this.id, this.message, this.stackTrace);
  final int id;
  final String message;
  final String stackTrace;
}

/// Adds a bundled language to an already-running worker.
class LoadLangMessage {
  const LoadLangMessage(this.lang);
  final LangDescriptor lang;
}

/// Adds a raw-JSON language to an already-running worker.
class LoadRawLangMessage {
  const LoadRawLangMessage(this.json);
  final String json;
}

/// Adds a theme to an already-running worker.
class LoadThemeMessage {
  const LoadThemeMessage(this.themeJson);
  final String themeJson;
}
