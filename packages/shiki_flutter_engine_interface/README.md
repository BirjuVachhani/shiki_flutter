# shiki_flutter_engine_interface

The regex-engine seam shared by [`shiki_flutter`](../shiki_flutter) and its
engine backends. It is a tiny, **dependency-free** package holding only the
contract the TextMate tokenizer runs on:

- `ShikiHighlighterEngine`: the factory that builds scanners and strings.
- `OnigScanner`: finds the earliest match among a set of patterns on a line.
- `OnigString`, `OnigMatch`, `OnigCaptureIndex`, `kUnmatchedOffset`: the value
  types passed across that seam.

It mirrors `vscode-textmate`'s `IOnigLib` / `onigLib.ts` and Shiki's JavaScript
`scanner.ts`.

## Why it exists

`shiki_flutter`'s regex engine is pluggable. Extracting the contract into its
own package means every implementation depends on the **same** types and can be
swapped in interchangeably:

| Package | Engine | Backend |
|---------|--------|---------|
| `shiki_flutter` | `ShikiHighlighterEmbeddedEngine` (web default) | shiki_flutter's own pure-Dart engine |
| `shiki_flutter_dart_engine` | `ShikiHighlighterDartEngine` (native/VM default) | `oniguruma_dart` port (pure Dart, web included) |
| `shiki_flutter_native_engine` | `ShikiHighlighterNativeEngine` | native Oniguruma C via `dart:ffi` (IO only) |

Because this package pulls in nothing (not even Flutter), a backend can
implement the seam without depending on all of `shiki_flutter`.

## Implementing an engine

```dart
import 'package:shiki_flutter_engine_interface/shiki_flutter_engine_interface.dart';

class MyEngine implements ShikiHighlighterEngine {
  const MyEngine();

  // A stable literal (not derived from runtimeType, which minifies on web).
  @override
  String get id => 'my-engine';

  @override
  OnigScanner createScanner(List<String> sources) => MyScanner(sources);

  @override
  OnigString createString(String str) => OnigString(str);
}
```

Then point the highlighter at it, e.g. on IO:
`ShikiHighlighter.config = ShikiHighlighter.config.copyWith(ioEngine: const MyEngine());`.
