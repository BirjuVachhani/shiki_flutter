// Per-widget memoization of build-time render work, shared by ShikiCodeView and
// ShikiCodeListView.
//
// Both widgets can rebuild many times with identical inputs (ancestor rebuilds,
// MediaQuery/textScaler changes on resize, the system-fonts and async setState
// signals). Regenerating every TextSpan/TextStyle for the whole file each time is
// wasted work that scales with file size, not the viewport. These tiny caches key
// on the *real* inputs of each derived value and recompute only when those change.
library;

import 'package:flutter/widgets.dart';

import '../core/themed_token.dart';

/// Memoizes the styled render artifact of a code widget (a single [TextSpan] for
/// [ShikiCodeView], or a `List<List<TextSpan>>` for [ShikiCodeListView]) so it is
/// rebuilt only when the tokens or the base style actually change.
///
/// The artifact depends on exactly two things: the resolved tokens and the base
/// [TextStyle] (which carries the theme foreground). It is deliberately
/// **independent of `textScaler`/viewport size**: spans carry an unscaled
/// `fontSize` and the scaler is applied by `Text.rich`/`TextPainter` at layout, so
/// a resize that only changes the scaler reuses the whole cached artifact.
///
/// Tokens are compared by identity (the token source keeps a stable reference
/// until its inputs change); the base style by value `==` (`TextStyle` has
/// reliable value equality). A blank line's or a pending build's placeholder is
/// held in a separate slot keyed on `(code, base)`, so the `tokens == null`
/// placeholder is never served by an `identical(null, null)` match.
class RenderMemo<T extends Object> {
  // Highlighted slot: the artifact built from resolved tokens.
  T? _value;
  Object? _tokens;
  TextStyle? _base;

  // Placeholder slot: the artifact built from plain code while tokens are pending.
  T? _placeholder;
  String? _placeholderCode;
  TextStyle? _placeholderBase;

  /// Returns the memoized artifact for [tokens]/[code]/[base].
  ///
  /// When [tokens] is null (async result pending) [placeholder] is used, memoized
  /// on `(code, base)`. Otherwise [render] is used, memoized on the identity of
  /// [tokens] and the value of [base].
  T resolve({
    required List<List<ThemedToken>>? tokens,
    required String code,
    required TextStyle base,
    required T Function(List<List<ThemedToken>> tokens, TextStyle base) render,
    required T Function(String code, TextStyle base) placeholder,
  }) {
    if (tokens == null) {
      if (_placeholder != null &&
          _placeholderCode == code &&
          _placeholderBase == base) {
        return _placeholder!;
      }
      _placeholderCode = code;
      _placeholderBase = base;
      return _placeholder = placeholder(code, base);
    }
    if (_value != null && identical(tokens, _tokens) && base == _base) {
      return _value!;
    }
    _tokens = tokens;
    _base = base;
    return _value = render(tokens, base);
  }
}

/// A single-slot memo: caches the result of [of]'s `compute` and reuses it while
/// the key is unchanged (by value `==`). Used for cheap-but-repeated scalars such
/// as a line count or the widest line length, which depend only on the code.
class Memoized<K, V extends Object> {
  K? _key;
  V? _value;

  V of(K key, V Function() compute) {
    if (_value != null && _key == key) return _value!;
    _key = key;
    return _value = compute();
  }
}
