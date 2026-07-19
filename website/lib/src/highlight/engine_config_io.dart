import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter_native_engine/shiki_flutter_native_engine.dart';

/// IO (desktop/mobile) engine config: tokenize with the real Oniguruma C library
/// via `dart:ffi` (the native engine), on a background isolate (`asyncIO`) so the
/// one-time grammar/regex compile never blocks the UI thread.
///
/// Native runs need native assets enabled
/// (`flutter config --enable-native-assets`); this variant is never part of the
/// web build (see [engine_config.dart]).
ShikiHighlighterConfig siteHighlighterConfig() => const ShikiHighlighterConfig(
      ioEngine: ShikiHighlighterNativeEngine(),
      asyncIO: true,
    );
