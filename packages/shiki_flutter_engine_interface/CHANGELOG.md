## 1.0.0

Initial release: the regex-engine seam shared by `shiki_flutter` and its engine
backends. Pure Dart, no dependencies.

* `ShikiHighlighterEngine`: the factory seam (`createScanner` / `createString`).
* `OnigScanner`: the `findNextMatch` contract the TextMate tokenizer runs on.
* `OnigString`, `OnigMatch`, `OnigCaptureIndex`: the value types passed across
  the seam, plus the `kUnmatchedOffset` sentinel for unmatched capture groups.
