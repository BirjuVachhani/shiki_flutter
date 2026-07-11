/// Curated code samples shown across the site. Every one of these is rendered
/// live by shiki_flutter (see `HighlighterService`).
///
/// Raw strings (`r'''...'''`) keep `$`, `\`, and quotes literal.
abstract final class Snippets {
  /// The hero snippet — the package's own three-line usage.
  static const String hero = r'''
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter/langs/dart.dart';
import 'package:shiki_flutter/themes/github_dark.dart';

// Batteries included: pass bundled languages and themes by symbol.
final highlighter = createHighlighter(
  langs: [dart],
  themes: [githubDark],
);

// Turn source straight into a styled TextSpan: no assets, no WASM.
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
  shiki_flutter: ^0.2.0
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
