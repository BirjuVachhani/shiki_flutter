// Drives token acquisition for a widget: the single memoized token source for
// both the synchronous and the async (placeholder->highlight) paths. On the async
// path it resolves from the cache synchronously when possible, otherwise tokenizes
// off-thread and notifies when the result lands. On the sync path it tokenizes
// lazily on first read and memoizes until the inputs change. Flutter-free (no
// dart:ui) so the seam stays testable, but designed to be owned by a widget's
// State.
library;

import '../core/highlighter.dart';
import '../core/themed_token.dart';
import 'token_cache.dart';

/// Holds the current tokens for one widget and keeps them in sync with its
/// (highlighter, code, lang, theme) inputs.
///
/// Call [resolve] from `initState`/`didUpdateWidget`; read [tokens] in `build`
/// (null means "not ready: show a plain placeholder"); call [dispose] from the
/// State's `dispose`. When an async result for the current inputs arrives, the
/// `onChanged` callback fires so the State can `setState`.
///
/// **Token validity** depends only on the tokenize inputs — the
/// [TokenCache.keyFor] key and the highlighter identity. The `async` flag passed
/// to [resolve] is *not* part of validity: it only selects how a miss is filled
/// (synchronously in the [tokens] getter, or off-thread). Flipping `async` with
/// unchanged inputs keeps already-resolved tokens and recomputes nothing.
class AsyncTokenResolver {
  AsyncTokenResolver(this._onChanged);

  final void Function() _onChanged;

  /// The tokens to render now, or null while an async result is pending. On the
  /// sync path this is computed lazily by the [tokens] getter.
  List<List<ThemedToken>>? _tokens;

  // Inputs for the current key, retained so the sync path can tokenize lazily and
  // the async completion can check it is still current.
  String? _key;
  ShikiHighlighter? _highlighter;
  String? _code;
  TokenizeOptions? _options;
  bool _async = true;

  // Sync path only: tokens are stale and must be (re)computed on next read.
  bool _syncDirty = false;

  bool _disposed = false;

  /// The tokens to render now, or null while an async result is pending.
  ///
  /// On the sync path, tokenizes lazily on first read after an input change (kept
  /// at build time so tokenize errors surface where they always did) and memoizes
  /// the result until the inputs change again.
  List<List<ThemedToken>>? get tokens {
    if (_syncDirty) {
      _syncDirty = false;
      _tokens = _highlighter!.codeToTokens(_code!, _options!);
    }
    return _tokens;
  }

  /// Ensures [tokens] reflects (highlighter, code, options).
  ///
  /// Recomputes only when the tokenize inputs change (the [TokenCache.keyFor] key
  /// or the highlighter identity). When [async] is false, a change marks the sync
  /// path dirty (the [tokens] getter tokenizes on next read). When [async] is
  /// true, a cache hit (or trivial plain/`none` input) sets [tokens]
  /// synchronously; a miss clears [tokens] (placeholder) and fires `onChanged`
  /// later with the computed result.
  ///
  /// Safe to call on every `initState`/`didUpdateWidget`: unchanged inputs with
  /// the same highlighter do nothing (existing tokens are kept), regardless of the
  /// [async] flag.
  void resolve(
    ShikiHighlighter highlighter,
    String code,
    TokenizeOptions options, {
    required bool async,
  }) {
    final key = TokenCache.keyFor(code, options);
    final inputsUnchanged = key == _key && identical(highlighter, _highlighter);
    _async = async;
    if (inputsUnchanged) return;

    _key = key;
    _highlighter = highlighter;
    _code = code;
    _options = options;

    if (!async) {
      // Defer sync tokenization to the next `tokens` read (build time).
      _tokens = null;
      _syncDirty = true;
      return;
    }

    _syncDirty = false;
    final hit = highlighter.peekTokens(code, options);
    if (hit != null) {
      _tokens = hit;
      return;
    }

    _tokens = null; // show the placeholder until the async result arrives
    highlighter.codeToTokensAsync(code, options).then((result) {
      // Ignore the result if the widget is gone, the inputs/highlighter changed,
      // or we flipped to the sync path (which fills tokens itself) in the meantime.
      if (_disposed ||
          !_async ||
          key != _key ||
          !identical(highlighter, _highlighter)) {
        return;
      }
      _tokens = result;
      _onChanged();
    }).catchError((_) {
      // Leave the placeholder; a later rebuild (new key) retries.
    });
  }

  void dispose() => _disposed = true;
}
