// Maintainer tool: compiles the Web Worker entry points into the committed
// prebuilt bundles that `dart run shiki_flutter:install` copies into
// an app's `web/`.
//
// There is one single-purpose worker per WASM-free engine — embedded (the
// default) and the `oniguruma_dart` port — so each artifact tree-shakes to just
// the one engine it runs and the default worker stays small. (The native engine's
// worker is built separately, from `shiki_flutter_native_engine`.)
//
// Run from the package root after changing anything the workers tokenize with:
//
//   dart run tool/build_web_worker.dart
//
// The outputs are checked in, so a plain `pub get` gives apps ready-to-install
// workers with no compile step. CI should re-run this and fail if a committed
// file changes, so the artifacts can't drift from source.
import 'dart:io';

const _targets = <(String entry, String output)>[
  (
    'lib/src/async/web/tokenize_worker_entry.dart',
    'lib/src/async/web/prebuilt/shiki_tokenize_worker.js',
  ),
  (
    'lib/src/async/web/tokenize_worker_entry_dart.dart',
    'lib/src/async/web/prebuilt/shiki_tokenize_worker_dart.js',
  ),
];

Future<void> main() async {
  for (final (entry, output) in _targets) {
    if (!File(entry).existsSync()) {
      stderr.writeln('Run this from the shiki_flutter package root '
          '(cannot find $entry).');
      exit(1);
    }
    Directory(output).parent.createSync(recursive: true);

    stdout.writeln('Compiling $entry -> $output ...');
    final result = await Process.run('dart', [
      'compile',
      'js',
      '-O2',
      '--no-source-maps',
      entry,
      '-o',
      output,
    ]);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    if (result.exitCode != 0) exit(result.exitCode);

    // `dart compile js` also drops a `.deps` sidecar we don't ship.
    final deps = File('$output.deps');
    if (deps.existsSync()) deps.deleteSync();

    final kb = (File(output).lengthSync() / 1024).toStringAsFixed(0);
    stdout.writeln('Wrote $output ($kb KB).');
  }
}
