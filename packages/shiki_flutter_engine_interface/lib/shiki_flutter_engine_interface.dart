/// The pluggable regex-engine seam shared by `shiki_flutter` and its engine
/// backends, mirroring `vscode-textmate`'s `onigLib.ts` / `IOnigLib` and Shiki's
/// JavaScript `scanner.ts`.
///
/// An engine is anything that can build an [OnigScanner] and an [OnigString]:
/// that pair is the entire contract the TextMate tokenizer runs on.
/// `shiki_flutter` ships a pure-Dart implementation; other packages plug in a
/// native (FFI Oniguruma) or ported (`oniguruma_dart`) backend by implementing
/// [ShikiHighlighterEngine]. Keeping the contract in this tiny, dependency-free
/// package lets every implementation share one set of types and interoperate.
library;

/// A captured range within a match. Mirrors `IOnigCaptureIndex`.
class OnigCaptureIndex {
  /// Creates a capture index spanning [start] to [end], with [length] equal
  /// to `end - start`, all in UTF-16 code units.
  const OnigCaptureIndex(this.start, this.end, this.length);

  /// The offset, in UTF-16 code units, where the captured range starts.
  final int start;

  /// The offset, in UTF-16 code units, where the captured range ends.
  final int end;

  /// The length of the captured range, in UTF-16 code units.
  final int length;
}

/// The result of [OnigScanner.findNextMatch]. Mirrors `IOnigMatch`.
class OnigMatch {
  /// Creates a match for pattern [index] with the given [captureIndices].
  const OnigMatch(this.index, this.captureIndices);

  /// Index of the pattern (within the scanner) that matched.
  final int index;

  /// The capture ranges for this match, one per group, with the whole
  /// match's range as group 0.
  final List<OnigCaptureIndex> captureIndices;
}

/// Wraps a string being scanned. Mirrors `OnigString`.
///
/// Because both the pure-Dart engine and Dart strings work in UTF-16 code
/// units, no offset conversion is required. A native engine may subclass this to
/// cache an encoded copy of [content].
class OnigString {
  /// Wraps [content] so it can be scanned by an [OnigScanner].
  OnigString(this.content);

  /// The wrapped string being scanned.
  final String content;
}

/// Sentinel used for capture groups that did not participate in a match.
const int kUnmatchedOffset = 0xFFFFFFFF;

/// Scans a line for the earliest match among a set of patterns.
///
/// This is the contract the TextMate tokenizer depends on; each engine backend
/// provides its own implementation.
abstract interface class OnigScanner {
  /// Finds the earliest match at or after [startPosition]; a match exactly at
  /// [startPosition] wins immediately. Returns null when nothing matches.
  ///
  /// [string] is an [OnigString] (or a plain [String]); offsets are UTF-16
  /// code units.
  OnigMatch? findNextMatch(Object string, int startPosition);
}

/// Factory for scanners and strings: the pluggable engine seam. Mirrors
/// `vscode-textmate`'s `IOnigLib`.
///
/// Set the global `ShikiHighlighter.config` once (e.g. in `main`, via its
/// `ioEngine` / `webEngine` fields), or pass one per call via
/// `createHighlighter(engine: …)`, to choose which implementation the tokenizer
/// uses.
abstract interface class ShikiHighlighterEngine {
  /// A short, stable identifier for this engine: e.g. `'embedded'`, `'dart'`,
  /// `'native'`. On web it selects the matching prebuilt Web Worker for async
  /// highlighting, so it **must be a literal constant**: never derive it from
  /// `runtimeType`, whose name is minified in release (`dart2js`/`dart2wasm`)
  /// builds. A custom engine returns its own id; the async-web transport falls
  /// back to the default worker for an id it has no dedicated worker for.
  String get id;

  /// Creates an [OnigScanner] that finds the earliest match among [sources],
  /// a list of regex pattern strings.
  OnigScanner createScanner(List<String> sources);

  /// Wraps [str] in an [OnigString] for this engine to scan.
  OnigString createString(String str);
}
