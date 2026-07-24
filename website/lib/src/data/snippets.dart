/// Curated code samples shown across the site. Every one of these is rendered
/// live by shiki_flutter (see `HighlighterService`).
///
/// Raw strings (`r'''...'''`) keep `$`, `\`, and quotes literal.
abstract final class Snippets {
  /// The hero snippet - the package's own three-line usage.
  static const String hero = r'''
import 'package:shiki_flutter/shiki_flutter.dart';

// Batteries included: a shared highlighter loads bundled languages and themes
// (referenced via the facades) on demand.
final highlighter = ShikiHighlighter();

// Source in, styled TextSpan out. Pure Dart, nothing to bundle.
final span = codeToTextSpan(
  highlighter,
  sourceCode,
  lang: CodeLanguages.dart,
  theme: ShikiThemes.githubDark,
);
''';

  /// Install command for the hero pill.
  static const String install = 'flutter pub add shiki_flutter';

  /// Per-language samples for the language switcher, keyed by language id.
  static const Map<String, String> byLanguage = {
    'dart': _dart,
    'typescript': _typescript,
    'python': _python,
    'rust': _rust,
    'go': _go,
  };

  static const String _dart = r'''
import 'dart:math' as math;

/// A 2-D point with a few conveniences.
class Point {
  const Point(this.x, this.y);
  final double x, y;

  double distanceTo(Point other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  String toString() => 'Point($x, $y)';
}

void main() {
  const origin = Point(0, 0);
  final points = [for (var i = 1; i <= 3; i++) Point(i * 1.0, i * 2.0)];
  final total = points.fold<double>(0, (sum, p) => sum + origin.distanceTo(p));
  print('Total distance: ${total.toStringAsFixed(2)}');
}
''';

  static const String _typescript = r'''
type Result<T> =
  | { ok: true; value: T }
  | { ok: false; error: string };

async function fetchUser(id: number): Promise<Result<User>> {
  const res = await fetch(`/api/users/${id}`);
  if (!res.ok) {
    return { ok: false, error: `HTTP ${res.status}` };
  }
  return { ok: true, value: (await res.json()) as User };
}

interface User {
  id: number;
  name: string;
  roles: readonly string[];
}
''';

  static const String _python = r'''
from dataclasses import dataclass
from functools import lru_cache


@dataclass(frozen=True)
class Vector:
    x: float
    y: float

    def __add__(self, other: "Vector") -> "Vector":
        return Vector(self.x + other.x, self.y + other.y)


@lru_cache(maxsize=None)
def fib(n: int) -> int:
    """Return the n-th Fibonacci number."""
    return n if n < 2 else fib(n - 1) + fib(n - 2)


if __name__ == "__main__":
    print([fib(n) for n in range(10)])
''';

  static const String _rust = r'''
use std::collections::HashMap;

/// Count word frequencies in a string slice.
fn word_counts(text: &str) -> HashMap<&str, usize> {
    let mut counts = HashMap::new();
    for word in text.split_whitespace() {
        *counts.entry(word).or_insert(0) += 1;
    }
    counts
}

fn main() {
    let text = "the quick brown fox the lazy dog the end";
    let mut pairs: Vec<_> = word_counts(text).into_iter().collect();
    pairs.sort_by(|a, b| b.1.cmp(&a.1));
    println!("{:?}", &pairs[..3]);
}
''';

  static const String _go = r'''
package main

import (
	"fmt"
	"sort"
)

// Top returns the n largest values, descending.
func Top(values []int, n int) []int {
	sorted := append([]int(nil), values...)
	sort.Sort(sort.Reverse(sort.IntSlice(sorted)))
	if n > len(sorted) {
		n = len(sorted)
	}
	return sorted[:n]
}

func main() {
	nums := []int{3, 1, 4, 1, 5, 9, 2, 6}
	fmt.Println(Top(nums, 3))
}
''';

  // ---- Docs samples -------------------------------------------------------

  static const String pubspec = r'''
dependencies:
  shiki_flutter: ^1.0.0
''';

  static const String quickStart = r'''
import 'package:flutter/material.dart';
import 'package:shiki_flutter/shiki_flutter.dart';

void main() {
  // Optional: an app-wide default theme so widgets can omit `theme:`.
  ShikiHighlighter.config = ShikiHighlighter.config.copyWith(
    defaultTheme: ShikiThemes.githubDark,
  );
  runApp(const MyApp());
}

class CodeCard extends StatelessWidget {
  const CodeCard({super.key, required this.source});
  final String source;

  @override
  Widget build(BuildContext context) {
    // No highlighter and no theme: the shared default and config.defaultTheme
    // supply them. Only the languages/themes you reference are bundled.
    return ShikiCodeView(
      code: source,
      lang: CodeLanguages.dart,
      textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
    );
  }
}
''';

  static const String renderTextSpan = r'''
final span = codeToTextSpan(
  highlighter,
  sourceCode,
  lang: CodeLanguages.dart,
  theme: ShikiThemes.githubDark,
  baseStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
);

// Drop the span into any Text.rich / RichText.
Text.rich(span);
''';

  static const String renderWidget = r'''
ShikiCodeView(
  code: sourceCode,
  lang: CodeLanguages.dart,
  theme: ShikiThemes.githubDark,
  textStyle: const TextStyle(fontFamily: 'FiraCode', fontSize: 14),
)
''';

  static const String codeListView = r'''
// Give it a bounded height, like any ListView (here, an Expanded parent).
Expanded(
  child: ShikiCodeListView(
    code: sourceCode,
    lang: CodeLanguages.dart,
    theme: ShikiThemes.githubDark,
    textStyle: const TextStyle(fontFamily: 'FiraCode', fontSize: 14),
  ),
)
''';

  static const String renderTokens = r'''
final lines = highlighter.codeToTokens(
  sourceCode,
  const TokenizeOptions(lang: 'dart', theme: 'github-dark'),
);

for (final line in lines) {
  for (final token in line) {
    print('${token.content} -> ${token.color} (${token.fontStyle})');
  }
}
''';

  static const String renderLineSpans = r'''
// codeToLineSpans groups the highlighting by line: a List<List<TextSpan>>,
// one inner list per line. Feed it to a ListView.builder so only the lines
// on screen are ever laid out.
final lines = codeToLineSpans(
  highlighter,
  sourceCode,
  lang: CodeLanguages.dart,
  theme: ShikiThemes.githubDark,
  baseStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
);

ListView.builder(
  itemCount: lines.length,
  itemBuilder: (context, i) => Text.rich(TextSpan(children: lines[i])),
);
''';

  static const String largeFileView = r'''
// A drop-in virtualized view: renders one line per row and only lays out
// the lines on screen. Give it a bounded height, like any ListView.
ShikiCodeListView(
  code: sourceCode,
  lang: CodeLanguages.dart,
  theme: ShikiThemes.githubDark,
  showLineNumbers: true,
  textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
)
''';

  static const String themesUsage = r'''
final highlighter = ShikiHighlighter();

// Switch themes per render by passing a different theme object; each is
// loaded on demand.
final dark = codeToTextSpan(
  highlighter,
  code,
  lang: CodeLanguages.dart,
  theme: ShikiThemes.oneDarkPro,
);
final light = codeToTextSpan(
  highlighter,
  code,
  lang: CodeLanguages.dart,
  theme: ShikiThemes.vitesseLight,
);
''';

  static const String themesLightDark = r'''
// One theme, always.
ShikiCodeView(
  code: source,
  lang: CodeLanguages.dart,
  theme: ShikiThemes.githubDark,
);

// A light/dark pair. The widget reads Theme.of(context).brightness and
// re-highlights when the app toggles light/dark. Override which side is
// picked with the widget's brightness: argument.
ShikiCodeView(
  code: source,
  lang: CodeLanguages.dart,
  theme: ShikiDualTheme(
    light: ShikiThemes.githubLight,
    dark: ShikiThemes.githubDark,
  ),
);
''';

  static const String defaultTheme = r'''
void main() {
  ShikiHighlighter.config = ShikiHighlighter.config.copyWith(
    defaultTheme: ShikiDualTheme(
      light: ShikiThemes.githubLight,
      dark: ShikiThemes.githubDark,
    ),
  );
  runApp(const MyApp());
}

// No theme: needed; it falls back to the default. A widget's own theme:
// overrides it, and if neither is set the widget throws a ShikiError.
ShikiCodeView(code: source, lang: CodeLanguages.dart);
''';

  static const String themesBringYourOwn = r'''
// A theme is just TextMate theme JSON, loaded at runtime from an
// asset, the network, or a VS Code extension. No codegen, no rebuild.
final json = await rootBundle.loadString('assets/aurora.json');
final aurora = ShikiTheme(id: 'aurora', type: 'dark', json: json);

final span = codeToTextSpan(
  highlighter,
  code,
  lang: CodeLanguages.dart,
  theme: aurora, // a ShikiTheme is a ShikiThemeBase, so widgets take it directly
);
''';

  static const String extraThemes = r'''
// Pierre themes are an opt-in set, exposed via the PierreThemes facade.
import 'package:shiki_flutter/langs.dart';
import 'package:shiki_flutter/pierre_themes.dart';

// Use a Pierre theme like any other bundled theme: pass it to a widget
// (or set it as the default). It is loaded on demand.
ShikiCodeView(code: code, lang: CodeLanguages.dart, theme: PierreThemes.pierreDark);
''';

  static const String embedded = r'''
// CodeLanguages.html automatically pulls in css + javascript, so <style> and
// <script> blocks inside the HTML are highlighted too.
ShikiCodeView(code: html, lang: CodeLanguages.html, theme: ShikiThemes.githubDark);
''';

  static const String treeShakeGood = r'''
// GOOD: reference only the languages/themes you use; the rest tree-shake away.
final highlighter = ShikiHighlighter()
  ..preload(langs: [CodeLanguages.dart], themes: [ShikiThemes.githubDark]);
''';

  static const String treeShakeAll = r'''
// Only when you truly want EVERYTHING (playgrounds, tooling). The `.all` lists
// reference the whole catalog, so nothing is tree-shaken away.
final highlighter = ShikiHighlighter()
  ..preload(langs: CodeLanguages.all, themes: ShikiThemes.all);
''';

  static const String customGrammar = r'''
// Wrap a TextMate grammar / theme JSON in a CodeLanguage / ShikiTheme
// and hand them straight to the renderer; the highlighter loads them on demand.
final myLang = CodeLanguage(
  id: 'my-lang',
  scopeName: 'source.my-lang', // the grammar's own scopeName
  displayName: 'My Language',
  json: myGrammarJsonString,
);
final myTheme = ShikiTheme(id: 'aurora', type: 'dark', json: myThemeJsonString);

final span = codeToTextSpan(
  highlighter,
  code,
  lang: myLang,
  theme: myTheme,
);
''';

  // ---- Async, engines, web setup, configuration ---------------------------

  static const String asyncWidget = r'''
// async is on by default on native/desktop (asyncIO). The widget shows the
// code in the theme's base color, then swaps in the highlighted result when
// the background isolate is done - the UI thread never freezes. Pass async:
// explicitly to override the global default for a single widget.
ShikiCodeView(
  code: sourceCode,
  lang: CodeLanguages.dart,
  theme: ShikiThemes.githubDark,
  async: true, // force off-thread; omit to follow the global default
)
''';

  static const String asyncTokens = r'''
// The imperative equivalent: tokenize off the current isolate and await the
// result. Cached (LRU) by (code, lang, theme), so repeat calls are instant.
final lines = await highlighter.codeToTokensAsync(
  sourceCode,
  const TokenizeOptions(lang: 'dart', theme: 'github-dark'),
);

final span = tokensToTextSpan(
  lines,
  baseStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
);
''';

  static const String preWarm = r'''
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Set your global defaults once: the theme every widget falls back to and
  //    a single shared highlighter to reuse across the whole app. Keep it alive
  //    for the app's lifetime; don't rebuild it per frame or per screen.
  final highlighter = ShikiHighlighter();
  ShikiHighlighter.config = ShikiHighlighter.config.copyWith(
    defaultTheme: ShikiThemes.githubDark,
    defaultHighlighter: highlighter,
  );

  // 2. Warm it up before the first real render. preload decodes each grammar's
  //    and theme's JSON and builds its model up front; warmAsync also spins up
  //    the background worker that async widgets use, so awaiting it means the
  //    first render pays no parse, isolate-spawn, or grammar-build cost.
  await highlighter.preload(
    langs: [CodeLanguages.dart, CodeLanguages.python],
    themes: [ShikiThemes.githubDark],
    warmAsync: true,
  );

  runApp(const MyApp());
}

// Widgets need no highlighter: or theme: now; they use the config defaults.
// ShikiCodeView(code: source, lang: CodeLanguages.dart)
''';

  static const String engineNative = r'''
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter_native_engine/shiki_flutter_native_engine.dart';

void main() {
  // The native Oniguruma engine (dart:ffi) is ~2.4x the pure-Dart port on IO.
  // The native library builds automatically on first run - nothing to install.
  if (!kIsWeb) {
    ShikiHighlighter.config = ShikiHighlighter.config.copyWith(
      ioEngine: const ShikiHighlighterNativeEngine(),
    );
  }
  runApp(const MyApp());
}
''';

  static const String enginePerHighlighter = r'''
// Override the engine for a single highlighter instead of globally.
final highlighter = ShikiHighlighter(
  engine: const ShikiHighlighterNativeEngine(),
);
''';

  static const String webInstall = r'''
# Copy the prebuilt Web Worker into your app's web/ folder. Run once
# (and again after upgrading shiki_flutter). The worker is grammar-free
# (~53 KB gzipped) and receives your grammars/themes at runtime.
dart run shiki_flutter:install
''';

  static const String webAsyncEnable = r'''
import 'package:shiki_flutter/shiki_flutter.dart';

void main() {
  // Web has no isolates, so asyncWeb is off by default. After installing the
  // worker, turn it on to move the one-time grammar compile off the UI thread.
  ShikiHighlighter.config =
      ShikiHighlighter.config.copyWith(asyncWeb: true);
  runApp(const MyApp());
}
''';

  static const String webBuild = r'''
dart run shiki_flutter:install   # copy the Web Worker into web/ (once)
flutter build web                # standard build (add --wasm to opt into WasmGC)
''';

  static const String configExample = r'''
// One config object, split by platform so IO and web are set independently.
// Set it once in main(); copyWith overrides only the fields you name.
void main() {
  ShikiHighlighter.config = ShikiHighlighter.config.copyWith(
    ioEngine: const ShikiHighlighterNativeEngine(), // faster on native/desktop
    asyncWeb: true,                                 // after installing the worker
  );
  runApp(const MyApp());
}
''';

  // ---- Best practices ----------------------------------------------------

  static const String recommendedSetup = r'''
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter_native_engine/shiki_flutter_native_engine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fastest engine per platform. The pure-Dart default works everywhere with
  // zero setup; on IO the native engine is ~2.4x faster (optional dependency).
  // Web keeps the embedded engine, which is the fastest engine there.
  if (!kIsWeb) {
    ShikiHighlighter.config = ShikiHighlighter.config.copyWith(
      ioEngine: const ShikiHighlighterNativeEngine(),
    );
  }

  // Off-thread highlighting plus app-wide defaults. asyncIO is on by default;
  // asyncWeb needs the installed worker (see Web setup). defaultHighlighter is
  // the shared instance every widget reuses; defaultTheme is its fallback.
  final highlighter = ShikiHighlighter();
  ShikiHighlighter.config = ShikiHighlighter.config.copyWith(
    asyncWeb: true,
    defaultTheme: ShikiThemes.githubDark,
    defaultHighlighter: highlighter,
  );

  // Warm exactly the languages and themes you render. Naming them here is also
  // what keeps everything else tree-shaken out of the build.
  await highlighter.preload(
    langs: [CodeLanguages.dart, CodeLanguages.python],
    themes: [ShikiThemes.githubDark],
    warmAsync: true,
  );

  runApp(const MyApp());
}
''';

  static const String tabularFigures = r'''
// A monospace font keeps columns aligned; tabular figures keep every digit the
// same width, so line numbers and the gutter never jitter while scrolling.
ShikiCodeView(
  code: source,
  lang: CodeLanguages.dart,
  textStyle: const TextStyle(
    fontFamily: 'JetBrains Mono',
    fontFeatures: [FontFeature.tabularFigures()],
    fontSize: 14,
    height: 1.5,
  ),
);
''';

  /// A small sample rendered live by the drop-in-widget demo.
  static const String widgetSample = r'''
Future<int> sum(Stream<int> values) async {
  var total = 0;
  await for (final value in values) {
    total += value; // fold the stream
  }
  return total;
}
''';
}
