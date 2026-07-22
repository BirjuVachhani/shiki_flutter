import 'package:shiki_flutter_dart_engine/shiki_flutter_dart_engine.dart';

import '../onig/onig.dart';
// Circular with highlighter.dart (which imports this file): legal in Dart since
// `defaultHighlighter` is a nullable field with no const-eval cycle.
import 'highlighter.dart';
import 'shiki_theme.dart';

/// Web vs. native without importing `package:flutter/foundation.dart`, whose
/// `kIsWeb` pulls in `dart:ui` and would break the Flutter-free `engine.dart`
/// entrypoint (which re-exports this file) under plain `dart` and
/// `dart compile js`. This is the same compile-time predicate Dart's own
/// conditional imports use.
const bool _kIsWeb = !bool.fromEnvironment('dart.library.io');

/// Global defaults for [ShikiHighlighter], split by platform so IO and web can
/// be configured independently.
///
/// Set it once (e.g. in `main`) via [ShikiHighlighter.config]. Every field has a
/// platform-appropriate default, so override only what you need, usually with
/// [copyWith]:
///
/// ```dart
/// void main() {
///   ShikiHighlighter.config = ShikiHighlighter.config.copyWith(
///     ioEngine: const ShikiHighlighterNativeEngine(), // faster on IO
///     asyncWeb: true, // after `dart run shiki_flutter:install`
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
    this.defaultTheme,
    this.defaultHighlighter,
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
  /// (`dart run shiki_flutter:install`) tokenization runs in that
  /// worker, otherwise it runs inline on the main thread. Defaults to `false`.
  final bool asyncWeb;

  /// The theme the rendering widgets use when their `theme:` argument is omitted.
  ///
  /// Either a single [ShikiTheme] or a light/dark pair ([ShikiDualTheme]),
  /// resolved from the ambient `Theme.of(context)` brightness. When null (the
  /// default), a widget with no `theme:` of its own throws a `ShikiError`.
  ///
  /// The widgets load the resolved theme (and language) on demand, so a global
  /// default works without pre-loading it into every highlighter.
  final ShikiThemeBase? defaultTheme;

  /// The highlighter the rendering widgets use when no `highlighter:` is passed.
  ///
  /// When null (the default), widgets fall back to a lazily-created shared
  /// instance (see [ShikiHighlighter.effectiveDefault]). Set one here (e.g. a
  /// [ShikiHighlighter] you have `preload`ed, or one with a custom engine) to
  /// make it the app-wide default without passing `highlighter:` everywhere.
  final ShikiHighlighter? defaultHighlighter;

  bool get async => _kIsWeb ? asyncWeb : asyncIO;

  ShikiHighlighterEngine get engine => _kIsWeb ? webEngine : ioEngine;

  /// Returns a copy with the given fields replaced.
  ShikiHighlighterConfig copyWith({
    ShikiHighlighterEngine? ioEngine,
    ShikiHighlighterEngine? webEngine,
    bool? asyncIO,
    bool? asyncWeb,
    ShikiThemeBase? defaultTheme,
    ShikiHighlighter? defaultHighlighter,
  }) => ShikiHighlighterConfig(
    ioEngine: ioEngine ?? this.ioEngine,
    webEngine: webEngine ?? this.webEngine,
    asyncIO: asyncIO ?? this.asyncIO,
    asyncWeb: asyncWeb ?? this.asyncWeb,
    defaultTheme: defaultTheme ?? this.defaultTheme,
    defaultHighlighter: defaultHighlighter ?? this.defaultHighlighter,
  );
}
