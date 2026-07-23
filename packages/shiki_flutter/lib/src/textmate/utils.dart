// Small utilities ported from `vscode-textmate`'s `utils.ts`.
//
// The regular expressions in this file are ordinary Dart [RegExp]s: they are
// fixed helper patterns (not grammar patterns), so the built-in engine is fine.

import '../onig/onig.dart';

/// Compares [a] and [b] lexicographically, returning `-1`, `0`, or `1`.
int strcmp(String a, String b) {
  if (a == b) return 0;
  return a.compareTo(b) < 0 ? -1 : 1;
}

/// Compares two nullable string lists element-by-element with [strcmp],
/// then by length; `null` sorts before any non-null list. Used to order
/// theme rules by their `parentScopes` specificity.
int strArrCmp(List<String>? a, List<String>? b) {
  if (a == null && b == null) return 0;
  if (a == null) return -1;
  if (b == null) return 1;
  final len1 = a.length;
  final len2 = b.length;
  if (len1 == len2) {
    for (var i = 0; i < len1; i++) {
      final res = strcmp(a[i], b[i]);
      if (res != 0) return res;
    }
    return 0;
  }
  return len1 - len2;
}

final RegExp _hex6 = RegExp(r'^#[0-9a-f]{6}$', caseSensitive: false);
final RegExp _hex8 = RegExp(r'^#[0-9a-f]{8}$', caseSensitive: false);
final RegExp _hex3 = RegExp(r'^#[0-9a-f]{3}$', caseSensitive: false);
final RegExp _hex4 = RegExp(r'^#[0-9a-f]{4}$', caseSensitive: false);

/// Whether [hex] is a `#`-prefixed hex color in 3, 4, 6, or 8 digit form
/// (e.g. `#fff`, `#fff0`, `#ffffff`, `#ffffff00`).
bool isValidHexColor(String hex) {
  return _hex6.hasMatch(hex) ||
      _hex8.hasMatch(hex) ||
      _hex3.hasMatch(hex) ||
      _hex4.hasMatch(hex);
}

final RegExp _escapeRegExp = RegExp(r'[\-\\\{\}\*\+\?\|\^\$\.\,\[\]\(\)\#\s]');

/// Escapes regular-expression characters in a given string.
String escapeRegExpCharacters(String value) {
  return value.replaceAllMapped(_escapeRegExp, (m) => '\\${m[0]}');
}

/// Returns the last path segment of [path], accepting both `/` and `\`
/// separators and ignoring a trailing separator.
String basename(String path) {
  var idx = path.lastIndexOf('/');
  if (idx == -1) idx = path.lastIndexOf('\\');
  if (idx == -1) return path;
  if (idx == path.length - 1) {
    return basename(path.substring(0, path.length - 1));
  }
  return path.substring(idx + 1);
}

/// A memoising wrapper around a single-argument function.
class CachedFn<K, V> {
  /// Creates a [CachedFn] wrapping [_fn]; results are memoised per input.
  CachedFn(this._fn);

  final V Function(K) _fn;
  final Map<K, V> _cache = {};

  /// Returns the cached result for [key], computing and storing it via the
  /// wrapped function on first access.
  V get(K key) {
    final existing = _cache[key];
    if (existing != null || _cache.containsKey(key)) {
      return existing as V;
    }
    final value = _fn(key);
    _cache[key] = value;
    return value;
  }
}

final RegExp _capturingRegexSource = RegExp(
  r'\$(\d+)|\$\{(\d+):/(downcase|upcase)\}',
);

/// Helpers for grammar `name`/`contentName`/`end` templates that reference
/// captured text via `$1`, `${1:/downcase}`, etc.
class RegexSource {
  /// Whether [regexSource] contains a `$n` or `${n:/command}` capture
  /// reference.
  static bool hasCaptures(String? regexSource) {
    if (regexSource == null) return false;
    return _capturingRegexSource.hasMatch(regexSource);
  }

  /// Substitutes `$n`/`${n:/downcase}`/`${n:/upcase}` references in
  /// [regexSource] with the corresponding capture's text, sliced from
  /// [captureSource] using [captureIndices]. Leading dots in the
  /// substituted text are stripped so the result stays a valid scope name.
  static String replaceCaptures(
    String regexSource,
    String captureSource,
    List<OnigCaptureIndex> captureIndices,
  ) {
    return regexSource.replaceAllMapped(_capturingRegexSource, (m) {
      final indexStr = m[1] ?? m[2];
      final command = m[3];
      final index = int.parse(indexStr!);
      if (index < captureIndices.length) {
        final capture = captureIndices[index];
        var result = captureSource.substring(capture.start, capture.end);
        // Remove leading dots that would make the selector invalid.
        while (result.isNotEmpty && result[0] == '.') {
          result = result.substring(1);
        }
        switch (command) {
          case 'downcase':
            return result.toLowerCase();
          case 'upcase':
            return result.toUpperCase();
          default:
            return result;
        }
      }
      return m[0]!;
    });
  }
}

/// Milliseconds since epoch, used for tokenization time limits.
int performanceNow() => DateTime.now().millisecondsSinceEpoch;
