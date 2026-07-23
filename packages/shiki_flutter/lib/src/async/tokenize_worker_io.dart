// Real `dart:isolate` worker: holds a warm highlighter on a background isolate
// and answers tokenize requests, so the UI thread never blocks on the expensive
// first-call grammar/regex compile.

import 'dart:async';
import 'dart:isolate';

import 'package:shiki_flutter_engine_interface/shiki_flutter_engine_interface.dart';

import '../core/highlighter.dart';
import '../core/themed_token.dart';
import 'lang_descriptor.dart';
import 'protocol.dart';
import 'tokenize_worker.dart';
import 'tokenize_worker_inline.dart' as inline;

/// The single message handed to the spawned isolate: a port to reply on plus the
/// config to build the warm highlighter from.
class _Bootstrap {
  const _Bootstrap(this.mainSendPort, this.config);
  final SendPort mainSendPort;
  final WorkerConfig config;
}

/// A small, generic snippet used to warm a grammar: it exercises more rules
/// (identifiers, numbers, punctuation, a comment) than an empty line, so more
/// regexes compile off the UI thread before the first real request.
const String _warmupSnippet = 'a 1 = ( ) { } ; // x\n"s"';

/// Entry point that runs inside the spawned isolate.
void _workerMain(_Bootstrap bootstrap) {
  final rx = ReceivePort();
  // Handshake: hand our command port back to the main isolate first.
  bootstrap.mainSendPort.send(rx.sendPort);

  final config = bootstrap.config;
  final highlighter = ShikiHighlighter(engine: config.engine);
  for (final themeJson in config.themeJsons) {
    highlighter.loadThemeFromJson(themeJson);
  }
  for (final lang in config.langs) {
    highlighter.loadBundledLanguage(rebuildBundledLanguage(lang));
  }
  for (final json in config.rawLangJsons) {
    highlighter.loadLanguageFromJson(json);
  }
  // Warm up: force the first-call rule-tree build and regex compile now, on this
  // background isolate, so the first real request returns quickly.
  for (final w in config.warmups) {
    try {
      highlighter.codeToTokens(
        _warmupSnippet,
        TokenizeOptions(lang: w.lang, theme: w.theme),
      );
    } catch (_) {
      // A warm-up failure (e.g. unknown lang/theme) must not kill the worker.
    }
  }

  rx.listen((message) {
    if (message is TokenizeRequest) {
      try {
        final tokens = highlighter.codeToTokens(message.code, message.options);
        bootstrap.mainSendPort.send(TokenizeResponse(message.id, tokens));
      } catch (e, st) {
        bootstrap.mainSendPort.send(
          TokenizeError(message.id, e.toString(), st.toString()),
        );
      }
    } else if (message is LoadLangMessage) {
      highlighter.loadBundledLanguage(rebuildBundledLanguage(message.lang));
    } else if (message is LoadRawLangMessage) {
      highlighter.loadLanguageFromJson(message.json);
    } else if (message is LoadThemeMessage) {
      highlighter.loadThemeFromJson(message.themeJson);
    }
  });
}

/// A [TokenizeWorker] backed by a real `dart:isolate`, holding a warm
/// highlighter on a background isolate and transparently respawning it
/// after a crash (retaining the languages/themes/warmups loaded so far).
class IsolateTokenizeWorker implements TokenizeWorker {
  IsolateTokenizeWorker._(
    this._engine,
    this._langs,
    this._rawLangJsons,
    this._themeJsons,
    this._warmups,
  );

  // Retained so the worker can be transparently respawned after a crash.
  final ShikiHighlighterEngine? _engine;
  final List<LangDescriptor> _langs;
  final List<String> _rawLangJsons;
  final List<String> _themeJsons;
  final List<WarmupSpec> _warmups;

  Isolate? _isolate;
  SendPort? _workerSendPort;
  ReceivePort? _fromWorker;
  ReceivePort? _onError;
  ReceivePort? _onExit;

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
    warmups: _warmups,
  );

  /// Creates and starts an [IsolateTokenizeWorker] configured with
  /// [config], waiting for the spawned isolate's handshake before
  /// returning.
  static Future<TokenizeWorker> spawn(WorkerConfig config) async {
    final worker = IsolateTokenizeWorker._(
      config.engine,
      List.of(config.langs),
      List.of(config.rawLangJsons),
      List.of(config.themeJsons),
      List.of(config.warmups),
    );
    await worker._start();
    return worker;
  }

  Future<void> _start() async {
    final fromWorker = ReceivePort();
    final onError = ReceivePort();
    final onExit = ReceivePort();
    _fromWorker = fromWorker;
    _onError = onError;
    _onExit = onExit;

    fromWorker.listen(_handleWorkerMessage);
    onError.listen(_handleWorkerError);
    onExit.listen((_) => _handleWorkerDown('isolate exited'));

    _isolate = await Isolate.spawn(
      _workerMain,
      _Bootstrap(fromWorker.sendPort, _config),
      onError: onError.sendPort,
      onExit: onExit.sendPort,
      errorsAreFatal: false,
      debugName: 'shiki-tokenizer',
    );
    await _ready.future;
  }

  void _handleWorkerMessage(dynamic message) {
    if (message is SendPort) {
      _workerSendPort = message;
      _alive = true;
      if (!_ready.isCompleted) _ready.complete();
    } else if (message is TokenizeResponse) {
      _pending.remove(message.id)?.complete(message.tokens);
    } else if (message is TokenizeError) {
      _pending.remove(message.id)?.completeError(ShikiError(message.message));
    }
  }

  void _handleWorkerError(dynamic message) {
    // onError delivers [errorString, stackString].
    final detail = message is List && message.isNotEmpty
        ? message.first.toString()
        : message.toString();
    _handleWorkerDown('worker error: $detail');
  }

  void _handleWorkerDown(String reason) {
    if (_disposed) return;
    _alive = false;
    _workerSendPort = null;
    // Fail everything in flight; callers can retry (a retry respawns).
    final pending = List.of(_pending.values);
    _pending.clear();
    for (final completer in pending) {
      if (!completer.isCompleted) completer.completeError(ShikiError(reason));
    }
  }

  Future<void> _respawn() async {
    _isolate?.kill(priority: Isolate.immediate);
    _fromWorker?.close();
    _onError?.close();
    _onExit?.close();
    _ready = Completer<void>();
    await _start();
  }

  @override
  Future<List<List<ThemedToken>>> tokenize(
    String code,
    TokenizeOptions options,
  ) async {
    if (_disposed) throw ShikiError('tokenize on a disposed worker');
    await _ready.future;
    if (!_alive) await _respawn();
    final id = _nextId++;
    final completer = Completer<List<List<ThemedToken>>>();
    _pending[id] = completer;
    _workerSendPort!.send(TokenizeRequest(id, code, options));
    return completer.future;
  }

  @override
  void loadLanguage(LangDescriptor lang) {
    _langs.add(lang);
    _workerSendPort?.send(LoadLangMessage(lang));
  }

  @override
  void loadRawLanguage(String json) {
    _rawLangJsons.add(json);
    _workerSendPort?.send(LoadRawLangMessage(json));
  }

  @override
  void loadTheme(String themeJson) {
    _themeJsons.add(themeJson);
    _workerSendPort?.send(LoadThemeMessage(themeJson));
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _alive = false;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _fromWorker?.close();
    _onError?.close();
    _onExit?.close();
    _handleWorkerDown('worker disposed');
  }
}

/// Spawns an isolate-backed worker, falling back to inline tokenization on the
/// current isolate if the spawn fails for any reason.
Future<TokenizeWorker> spawnTokenizeWorker(WorkerConfig config) async {
  try {
    return await IsolateTokenizeWorker.spawn(config);
  } catch (_) {
    return inline.spawnTokenizeWorker(config);
  }
}
