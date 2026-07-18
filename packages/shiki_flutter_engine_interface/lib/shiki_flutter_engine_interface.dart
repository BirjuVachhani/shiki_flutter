/// The pluggable regex-engine seam shared by `shiki_flutter` and its engine
/// backends, mirroring `vscode-textmate`'s `onigLib.ts` / `IOnigLib` and Shiki's
/// JavaScript `scanner.ts`.
///
/// An engine is anything that can build an [OnigScanner] and an [OnigString] —
/// that pair is the entire contract the TextMate tokenizer runs on.
/// `shiki_flutter` ships a pure-Dart implementation; other packages plug in a
/// native (FFI Oniguruma) or ported (`oniguruma_dart`) backend by implementing
/// [ShikiHighlighterEngine]. Keeping the contract in this tiny, dependency-free
/// package lets every implementation share one set of types and interoperate.
library;

/// A captured range within a match. Mirrors `IOnigCaptureIndex`.
class OnigCaptureIndex {
  const OnigCaptureIndex(this.start, this.end, this.length);

  final int start;
  final int end;
  final int length;
}

/// The result of [OnigScanner.findNextMatch]. Mirrors `IOnigMatch`.
class OnigMatch {
  const OnigMatch(this.index, this.captureIndices);

  /// Index of the pattern (within the scanner) that matched.
  final int index;
  final List<OnigCaptureIndex> captureIndices;
}

/// Wraps a string being scanned. Mirrors `OnigString`.
///
/// Because both the pure-Dart engine and Dart strings work in UTF-16 code
/// units, no offset conversion is required. A native engine may subclass this to
/// cache an encoded copy of [content].
class OnigString {
  OnigString(this.content);

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

/// Factory for scanners and strings — the pluggable engine seam. Mirrors
/// `vscode-textmate`'s `IOnigLib`.
///
/// Set the global `ShikiHighlighter.config` once (e.g. in `main`, via its
/// `ioEngine` / `webEngine` fields), or pass one per call via
/// `createHighlighter(engine: …)`, to choose which implementation the tokenizer
/// uses.
abstract interface class ShikiHighlighterEngine {
  OnigScanner createScanner(List<String> sources);
  OnigString createString(String str);
}
