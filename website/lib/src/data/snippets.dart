/// Curated code samples shown across the site. Every one of these is rendered
/// live by shiki_flutter (see `HighlighterService`).
///
/// Raw strings (`r'''...'''`) keep `$`, `\`, and quotes literal.
abstract final class Snippets {
  /// The hero snippet - the package's own three-line usage.
  static const String hero = r'''
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter/langs/dart.dart';
import 'package:shiki_flutter/themes/github_dark.dart';

// Batteries included: pass bundled languages and themes by symbol.
final highlighter = createHighlighter(
  langs: [dart],
  themes: [githubDark],
);

// Source in, styled TextSpan out. Pure Dart, nothing to bundle.
final span = codeToTextSpan(
  highlighter,
  sourceCode,
  lang: 'dart',
  theme: 'github-dark',
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

// Import ONLY what you use. The rest is tree-shaken away.
import 'package:shiki_flutter/langs/dart.dart';
import 'package:shiki_flutter/themes/github_dark.dart';

final highlighter = createHighlighter(
  langs: [dart],
  themes: [githubDark],
);

class CodeCard extends StatelessWidget {
  const CodeCard({super.key, required this.source});
  final String source;

  @override
  Widget build(BuildContext context) {
    return ShikiCodeView(
      highlighter: highlighter,
      code: source,
      lang: dart.id,        // 'dart'
      theme: githubDark.id, // 'github-dark'
      textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
    );
  }
}
''';

  static const String renderTextSpan = r'''
final span = codeToTextSpan(
  highlighter,
  sourceCode,
  lang: 'dart',
  theme: 'github-dark',
  baseStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
);

// Drop the span into any Text.rich / RichText.
Text.rich(span);
''';

  static const String renderWidget = r'''
ShikiCodeView(
  highlighter: highlighter,
  code: sourceCode,
  lang: 'dart',
  theme: 'github-dark',
  textStyle: const TextStyle(fontFamily: 'FiraCode', fontSize: 14),
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
  lang: 'dart',
  theme: 'github-dark',
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
  highlighter: highlighter,
  code: sourceCode,
  lang: 'dart',
  theme: 'github-dark',
  showLineNumbers: true,
  textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
)
''';

  static const String themesUsage = r'''
import 'package:shiki_flutter/themes/one_dark_pro.dart';
import 'package:shiki_flutter/themes/vitesse_light.dart';

final highlighter = createHighlighter(
  langs: [dart],
  themes: [oneDarkPro, vitesseLight],
);

// Switch themes per render by id.
final dark = codeToTextSpan(
  highlighter,
  code,
  lang: 'dart',
  theme: oneDarkPro.id,
);
final light = codeToTextSpan(
  highlighter,
  code,
  lang: 'dart',
  theme: vitesseLight.id,
);
''';

  static const String themesBringYourOwn = r'''
// A theme is just VS Code / TextMate theme JSON. Load one at runtime from an
// asset, the network, or a VS Code extension. No codegen, no rebuild.
final json = await rootBundle.loadString('assets/aurora.json');
// loadThemeFromJson returns the theme's id.
final themeId = highlighter.loadThemeFromJson(json);

final span = codeToTextSpan(
  highlighter,
  code,
  lang: 'dart',
  theme: themeId,
);
''';

  static const String extraThemes = r'''
// Pierre themes live under pierre_themes/. Import individual themes…
import 'package:shiki_flutter/pierre_themes/pierre_dark.dart';
import 'package:shiki_flutter/pierre_themes/pierre_light.dart';
// …or the whole set via the barrel, which exports a `pierreThemes` list.

final highlighter = createHighlighter(
  langs: [dart],
  themes: [pierreDark, pierreLight],
);

// Reference a theme by its id when you render.
final span = codeToTextSpan(
  highlighter,
  code,
  lang: 'dart',
  theme: pierreDark.id, // 'pierre-dark'
);
''';

  static const String embedded = r'''
// Importing html automatically pulls in css + javascript, so <style> and
// <script> blocks inside the HTML are highlighted too.
import 'package:shiki_flutter/langs/html.dart';

final highlighter = createHighlighter(
  langs: [html],
  themes: [githubDark],
);
''';

  static const String treeShakeGood = r'''
// GOOD: import the specific languages/themes you need.
import 'package:shiki_flutter/langs/dart.dart';
import 'package:shiki_flutter/themes/github_dark.dart';

final highlighter = createHighlighter(
  langs: [dart],
  themes: [githubDark],
);
''';

  static const String treeShakeAll = r'''
// Only when you truly want EVERYTHING (playgrounds, tooling):
import 'package:shiki_flutter/langs/all.dart';
import 'package:shiki_flutter/themes/all.dart';

final highlighter = createHighlighter(
  langs: allLanguages,
  themes: allThemes,
);
''';

  static const String customGrammar = r'''
// Load any TextMate grammar or VS Code theme JSON at runtime.
highlighter.loadLanguageFromJson(myGrammarJsonString);
final themeName = highlighter.loadThemeFromJson(myThemeJsonString);

final span = codeToTextSpan(
  highlighter,
  code,
  lang: 'my-lang',
  theme: themeName,
);
''';

  // ---- Async, engines, web setup, configuration ---------------------------

  static const String asyncWidget = r'''
// async is on by default on native/desktop (asyncIO). The widget shows the
// code in the theme's base color, then swaps in the highlighted result when
// the background isolate is done - the UI thread never freezes. Pass async:
// explicitly to override the global default for a single widget.
ShikiCodeView(
  highlighter: highlighter,
  code: sourceCode,
  lang: 'dart',
  theme: 'github-dark',
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
final highlighter = createHighlighter(
  langs: [dart],
  themes: [githubDark],
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
