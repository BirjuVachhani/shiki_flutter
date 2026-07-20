// Measures the *isolated* download-size impact of adding `shiki_flutter` to a
// Flutter web app, independent of any host app's baseline.
//
// How it works: it scaffolds a throwaway Flutter web app, adds this package as
// a path dependency, then builds it several times as `--release`, each build
// identical except for how much of Shiki it uses. Because the bundled grammars
// and themes are `const` strings compiled into `main.dart.js`, and dart2js
// tree-shakes by symbol, the *delta* in `main.dart.js` between the no-Shiki
// baseline and a variant is exactly what the package costs. The host app
// cancels out.
//
// Usage (from the package root):
//   dart run tool/measure_size.dart          # measure, then clean up
//   dart run tool/measure_size.dart --keep    # leave the temp app on disk
//
// Numbers reported: uncompressed `main.dart.js` and gzip (level 9, ~= what a
// server sends over the wire). Grammar JSON compresses heavily, so gzip is the
// figure that matters for real downloads.

import 'dart:io';

/// Each variant is an identical app that differs only in Shiki usage.
const _variants = <String, String>{
  'baseline': '''
import 'package:flutter/material.dart';
const _code = 'void main() => print("hello");';
void main() => runApp(const MaterialApp(
    home: Scaffold(body: Center(child: Text(_code)))));
''',
  'one_small': '''
import 'package:flutter/material.dart';
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter/langs/dart.dart';
import 'package:shiki_flutter/themes/github_dark.dart';
const _code = 'void main() => print("hello");';
void main() {
  final h = createHighlighter(langs: [dart], themes: [githubDark]);
  runApp(MaterialApp(home: Scaffold(body: Center(
      child: ShikiCodeView(
          highlighter: h, code: _code, lang: dart.id, theme: githubDark.id)))));
}
''',
  'one_large': '''
import 'package:flutter/material.dart';
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter/langs/javascript.dart';
import 'package:shiki_flutter/themes/github_dark.dart';
const _code = 'const x = 1;';
void main() {
  final h = createHighlighter(langs: [javascript], themes: [githubDark]);
  runApp(MaterialApp(home: Scaffold(body: Center(
      child: ShikiCodeView(
          highlighter: h, code: _code, lang: javascript.id,
          theme: githubDark.id)))));
}
''',
  'catalog': '''
import 'package:flutter/material.dart';
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter/langs/all.dart';
import 'package:shiki_flutter/themes/all.dart';
const _code = 'void main() => print("hello");';
void main() {
  // Reference every bundled symbol so none are tree-shaken.
  final h = createHighlighter(langs: allLanguages, themes: allThemes);
  runApp(MaterialApp(home: Scaffold(body: Center(
      child: ShikiCodeView(
          highlighter: h, code: _code, lang: 'dart', theme: 'github-dark')))));
}
''',
};

/// Human-readable labels for the delta report, in display order.
const _deltaLabels = <String, String>{
  'one_small': '1 language + 1 theme (small grammar, e.g. dart)',
  'one_large': '1 language + 1 theme (large grammar, e.g. javascript)',
  'catalog': 'Entire catalog (all languages + themes)',
};

Future<void> main(List<String> args) async {
  final keep = args.contains('--keep');
  final pkgRoot = Directory.current.absolute.path;

  final pubspec = File('$pkgRoot/pubspec.yaml');
  if (!pubspec.existsSync() ||
      !pubspec.readAsStringSync().contains('name: shiki_flutter')) {
    stderr.writeln(
      'Run this from the shiki_flutter package root '
      '(could not find its pubspec.yaml in ${Directory.current.path}).',
    );
    exit(1);
  }

  final tmp = await Directory.systemTemp.createTemp('shiki_size_');
  final appDir = '${tmp.path}/probe';
  try {
    stdout.writeln('› scaffolding probe app in $appDir');
    await _run('flutter', [
      'create',
      '--platforms=web',
      '--project-name',
      'shiki_size_probe',
      appDir,
    ]);

    // Add shiki_flutter as a path dependency.
    final probePubspec = File('$appDir/pubspec.yaml');
    probePubspec.writeAsStringSync(
      probePubspec.readAsStringSync().replaceFirst(
        RegExp(r'^dependencies:\s*$', multiLine: true),
        'dependencies:\n  shiki_flutter:\n    path: $pkgRoot',
      ),
    );
    await _run('flutter', ['pub', 'get'], cwd: appDir);

    // Build every variant and record its main.dart.js size.
    final raw = <String, int>{};
    final gz = <String, int>{};
    for (final entry in _variants.entries) {
      final name = entry.key;
      File('$appDir/lib/main_$name.dart').writeAsStringSync(entry.value);
      stdout.writeln('› building "$name" (flutter build web --release) …');
      await _run('flutter', [
        'build',
        'web',
        '--release',
        '-t',
        'lib/main_$name.dart',
      ], cwd: appDir);
      final bytes = File('$appDir/build/web/main.dart.js').readAsBytesSync();
      raw[name] = bytes.length;
      gz[name] = GZipCodec(level: 9).encode(bytes).length;
    }

    _report(raw, gz);
  } finally {
    if (keep) {
      stdout.writeln('\n(kept temp app at $appDir)');
    } else {
      await tmp.delete(recursive: true);
    }
  }
}

void _report(Map<String, int> raw, Map<String, int> gz) {
  final base = raw['baseline']!;
  final baseGz = gz['baseline']!;

  stdout.writeln('\n${'=' * 72}');
  stdout.writeln('Absolute main.dart.js size (release web build)');
  stdout.writeln('=' * 72);
  stdout.writeln(
    '${'variant'.padRight(38)}'
    '${'uncompressed'.padLeft(16)}${'gzip -9'.padLeft(18)}',
  );
  for (final name in _variants.keys) {
    stdout.writeln(
      '${name.padRight(38)}'
      '${_bytes(raw[name]!).padLeft(16)}${_bytes(gz[name]!).padLeft(18)}',
    );
  }

  stdout.writeln('\n${'=' * 72}');
  stdout.writeln('Isolated package impact (delta over the no-Shiki baseline)');
  stdout.writeln('=' * 72);
  stdout.writeln(
    '${'what you add'.padRight(50)}'
    '${'uncompressed'.padLeft(14)}${'gzip'.padLeft(8)}',
  );
  _deltaLabels.forEach((name, label) {
    final dRaw = raw[name]! - base;
    final dGz = gz[name]! - baseGz;
    stdout.writeln(
      '${label.padRight(50)}'
      '${_bytes(dRaw).padLeft(14)}${_bytes(dGz).padLeft(8)}',
    );
  });
  stdout.writeln(
    '\nBaseline (Flutter app with no Shiki): '
    '${_bytes(base)} uncompressed / ${_bytes(baseGz)} gzip, not counted '
    'above.',
  );
}

String _bytes(int n) {
  if (n >= 1024 * 1024) return '${(n / (1024 * 1024)).toStringAsFixed(2)} MB';
  if (n >= 1024) return '${(n / 1024).toStringAsFixed(0)} KB';
  return '$n B';
}

Future<void> _run(String exe, List<String> args, {String? cwd}) async {
  final result = await Process.run(exe, args, workingDirectory: cwd);
  if (result.exitCode != 0) {
    stderr.writeln('command failed: $exe ${args.join(' ')}');
    stderr.writeln(result.stdout);
    stderr.writeln(result.stderr);
    exit(result.exitCode);
  }
}
