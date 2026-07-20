import 'package:shiki_flutter/shiki_flutter.dart';

/// Web engine config: tokenize with the built-in pure-Dart embedded engine (the
/// default web engine, no WASM), off the main thread in the installed browser
/// Web Worker (`web/shiki_tokenize_worker.js`, from `dart run shiki_flutter:install`).
///
/// Web has no isolates, so `asyncWeb` + that worker are what keep the UI thread
/// free during the cold grammar/regex compile.
ShikiHighlighterConfig siteHighlighterConfig() => const ShikiHighlighterConfig(
  // webEngine defaults to ShikiHighlighterEmbeddedEngine (no WASM).
  asyncWeb: true,
);
