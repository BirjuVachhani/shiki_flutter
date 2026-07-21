// Browser Web Worker transport: runs tokenization off the main thread on web,
// where `dart:isolate` is unavailable. It drives a separately-compiled worker
// script (`shiki_tokenize_worker.js`, installed into the app's `web/` by
// `dart run shiki_flutter:install`) over `postMessage`.
//
// Mirrors `tokenize_worker_io.dart`: a ready handshake, id/Completer request
// correlation, crash handling that fails in-flight requests and respawns from
// the retained config. Messages cross the worker boundary as JSON strings
// (see `protocol_codec.dart`), since `postMessage` can't carry live Dart objects.
//
// If the worker script is missing (not installed), 404s, or is blocked (e.g. a
// strict `blob:`/`worker-src` CSP), spawning falls back to inline tokenization
// on the current isolate, the same graceful degradation the isolate worker uses.

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:shiki_flutter_engine_interface/shiki_flutter_engine_interface.dart';
import 'package:web/web.dart' as web;

import '../core/highlighter.dart';
import '../core/themed_token.dart';
import 'lang_descriptor.dart';
import 'protocol.dart';
import 'protocol_codec.dart';
import 'tokenize_worker.dart';
import 'tokenize_worker_inline.dart' as inline;

/// The compiled worker script for the embedded engine (the default), resolved
/// against the document base href. `dart run shiki_flutter:install`
/// copies it next to `index.html`.
const String _kWorkerScript = 'shiki_tokenize_worker.js';

/// The compiled worker script for the pure-Dart (`oniguruma_dart`) port engine,
/// installed by `dart run shiki_flutter:install --dart`. A
/// separate artifact so the default worker isn't bloated by the port's engine.
const String _kDartWorkerScript = 'shiki_tokenize_worker_dart.js';

/// The compiled worker script for the native (WebAssembly) engine, installed by
/// `dart run shiki_flutter:install --native`. Selected when the
/// configured engine is the native one.
const String _kNativeWorkerScript = 'shiki_tokenize_worker_native.js';

/// How long to wait for the worker's `ready` handshake before giving up and
/// falling back to inline (covers a 404 script or a CSP that blocks the worker).
const Duration _kHandshakeTimeout = Duration(seconds: 8);

/// A more generous handshake budget for the native worker: it must fetch and
/// instantiate the ~650 KB Oniguruma WebAssembly module before replying `ready`.
const Duration _kNativeHandshakeTimeout = Duration(seconds: 20);

class WebTokenizeWorker implements TokenizeWorker {
  WebTokenizeWorker._(
    this._url,
    this._handshakeTimeout,
    this._engine,
    this._langs,
    this._rawLangJsons,
    this._themeJsons,
  );

  final String _url;
  final Duration _handshakeTimeout;

  // Retained so the worker can be transparently respawned after a crash.
  final ShikiHighlighterEngine? _engine;
  final List<LangDescriptor> _langs;
  final List<String> _rawLangJsons;
  final List<String> _themeJsons;

  web.Worker? _worker;
  final Map<int, Completer<List<List<ThemedToken>>>> _pending = {};
  int _nextId = 0;
  Completer<void> _ready = Completer<void>();
  bool _alive = false;
  bool _disposed = false;

  @override
  bool get isRemote => true;

  @override
  Future<void> get ready => _ready.future;

  WorkerConfig get _config => WorkerConfig(
    engine: _engine,
    langs: _langs,
    rawLangJsons: _rawLangJsons,
    themeJsons: _themeJsons,
  );

  static Future<TokenizeWorker> spawn(
    String url,
    Duration handshakeTimeout,
    WorkerConfig config,
  ) async {
    final worker = WebTokenizeWorker._(
      url,
      handshakeTimeout,
      config.engine,
      List.of(config.langs),
      List.of(config.rawLangJsons),
      List.of(config.themeJsons),
    );
    await worker._start();
    return worker;
  }

  Future<void> _start() async {
    final w = web.Worker(_url.toJS);
    _worker = w;
    w.onmessage = _onMessage.toJS;
    w.onerror = _onError.toJS;
    // Ship the config; the worker builds a warm highlighter and replies 'ready'.
    w.postMessage(
      jsonEncode({
        'type': 'config',
        'config': workerConfigToJson(_config),
      }).toJS,
    );
    await _ready.future.timeout(
      _handshakeTimeout,
      onTimeout: () => throw ShikiError('web worker handshake timed out'),
    );
  }

  void _onMessage(web.MessageEvent event) {
    final data = event.data;
    if (data == null || !data.isA<JSString>()) return;
    final msg = (jsonDecode((data as JSString).toDart) as Map)
        .cast<String, dynamic>();
    switch (msg['type']) {
      case 'ready':
        _alive = true;
        if (!_ready.isCompleted) _ready.complete();
      case 'result':
        _pending
            .remove(msg['id'] as int)
            ?.complete(tokensFromJson(msg['tokens'] as List));
      case 'error':
        _pending
            .remove(msg['id'] as int)
            ?.completeError(
              ShikiError(msg['message'] as String? ?? 'web worker error'),
            );
    }
  }

  void _onError(web.Event event) => _handleWorkerDown('web worker error');

  void _handleWorkerDown(String reason) {
    if (_disposed) return;
    _alive = false;
    if (!_ready.isCompleted) _ready.completeError(ShikiError(reason));
    // Fail everything in flight; callers can retry (a retry respawns).
    final pending = List.of(_pending.values);
    _pending.clear();
    for (final completer in pending) {
      if (!completer.isCompleted) completer.completeError(ShikiError(reason));
    }
  }

  Future<void> _respawn() async {
    _worker?.terminate();
    _ready = Completer<void>();
    _alive = false;
    await _start();
  }

  @override
  Future<List<List<ThemedToken>>> tokenize(
    String code,
    TokenizeOptions options,
  ) async {
    if (_disposed) throw ShikiError('tokenize on a disposed worker');
    if (!_alive) await _respawn();
    final id = _nextId++;
    final completer = Completer<List<List<ThemedToken>>>();
    _pending[id] = completer;
    _worker!.postMessage(
      jsonEncode({
        'type': 'tokenize',
        'id': id,
        'code': code,
        'options': tokenizeOptionsToJson(options),
      }).toJS,
    );
    return completer.future;
  }

  @override
  void loadLanguage(LangDescriptor lang) {
    _langs.add(lang);
    _worker?.postMessage(
      jsonEncode({'type': 'loadLang', 'lang': langDescriptorToJson(lang)}).toJS,
    );
  }

  @override
  void loadRawLanguage(String json) {
    _rawLangJsons.add(json);
    _worker?.postMessage(
      jsonEncode({'type': 'loadRawLang', 'json': json}).toJS,
    );
  }

  @override
  void loadTheme(String themeJson) {
    _themeJsons.add(themeJson);
    _worker?.postMessage(
      jsonEncode({'type': 'loadTheme', 'themeJson': themeJson}).toJS,
    );
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _alive = false;
    _worker?.terminate();
    _worker = null;
    _handleWorkerDown('worker disposed');
  }
}

/// Resolves [script] against the document base href, so it works under
/// `--base-href` and subpath deployments (not just the site root).
String _resolveWorkerUrl(String script) =>
    Uri.parse(web.document.baseURI).resolve(script).toString();

/// Spawns a Web-Worker-backed worker, falling back to inline tokenization on the
/// current isolate if the worker script is missing/blocked or the handshake
/// fails for any reason.
///
/// The script (and its handshake budget) is chosen from the configured engine's
/// [engineTag]: each engine has its own single-purpose prebuilt worker. The
/// native worker fetches a WebAssembly module, so it gets a longer handshake
/// budget; the embedded/port workers are pure Dart.
Future<TokenizeWorker> spawnTokenizeWorker(WorkerConfig config) async {
  final (script, timeout) = switch (engineTag(config.engine)) {
    'native' => (_kNativeWorkerScript, _kNativeHandshakeTimeout),
    'dart' => (_kDartWorkerScript, _kHandshakeTimeout),
    _ => (_kWorkerScript, _kHandshakeTimeout),
  };
  try {
    return await WebTokenizeWorker.spawn(
      _resolveWorkerUrl(script),
      timeout,
      config,
    );
  } catch (_) {
    return inline.spawnTokenizeWorker(config);
  }
}
