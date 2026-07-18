// Drives the placeholder->highlight lifecycle for a widget: resolve tokens from
// the cache synchronously when possible, otherwise tokenize off-thread and
// notify when the result lands. Flutter-free (no dart:ui) so the seam stays
// testable, but designed to be owned by a widget's State.
library;

import '../core/highlighter.dart';
import '../core/themed_token.dart';
import 'token_cache.dart';

/// Holds the current tokens for one widget and keeps them in sync with its
/// (code, lang, theme) inputs via a highlighter's async API.
///
/// Call [resolve] from `initState`/`didUpdateWidget`; read [tokens] in `build`
/// (null means "not ready — show a plain placeholder"); call [dispose] from the
/// State's `dispose`. When an async result for the current inputs arrives, the
/// `onChanged` callback fires so the State can `setState`.
class AsyncTokenResolver {
  AsyncTokenResolver(this._onChanged);

  final void Function() _onChanged;

  /// The tokens to render now, or null while an async result is pending.
  List<List<ThemedToken>>? tokens;

  String? _key;
  bool _disposed = false;

  /// Ensures [tokens] reflects (code, options). A cache hit (or a trivial
  /// plain/`none` input) sets [tokens] synchronously; a miss clears [tokens]
  /// (placeholder) and fires `onChanged` later with the computed result.
  ///
  /// Does nothing when the inputs are unchanged, so it is safe to call on every
  /// `didUpdateWidget`.
  void resolve(
    ShikiHighlighter highlighter,
    String code,
    TokenizeOptions options,
  ) {
    final key = TokenCache.keyFor(code, options);
    if (key == _key) return;
    _key = key;

    final hit = highlighter.peekTokens(code, options);
    if (hit != null) {
      tokens = hit;
      return;
    }

    tokens = null; // show the placeholder until the async result arrives
    highlighter.codeToTokensAsync(code, options).then((result) {
      if (_disposed || key != _key) return; // widget gone or inputs changed
      tokens = result;
      _onChanged();
    }).catchError((_) {
      // Leave the placeholder; a later rebuild (new key) retries.
    });
  }

  void dispose() => _disposed = true;
}
