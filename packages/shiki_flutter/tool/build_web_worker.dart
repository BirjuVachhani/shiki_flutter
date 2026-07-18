// Maintainer tool: compiles the Web Worker entry point into the committed
// prebuilt bundle that `dart run shiki_flutter:install_web_worker` copies into
// an app's `web/`.
//
// Run from the package root after changing anything the worker tokenizes with:
//
//   dart run tool/build_web_worker.dart
//
// The output (`lib/src/async/web/prebuilt/shiki_tokenize_worker.js`) is checked
// in, so a plain `pub get` gives apps a ready-to-install worker with no compile
// step. CI should re-run this and fail if the committed file changes, so the
// artifact can't drift from source.
import 'dart:io';

const _entry = 'lib/src/async/web/tokenize_worker_entry.dart';
const _output = 'lib/src/async/web/prebuilt/shiki_tokenize_worker.js';

Future<void> main() async {
  if (!File(_entry).existsSync()) {
    stderr.writeln('Run this from the shiki_flutter package root '
        '(cannot find $_entry).');
    exit(1);
  }
  Directory(_output).parent.createSync(recursive: true);

  stdout.writeln('Compiling $_entry -> $_output ...');
  final result = await Process.run('dart', [
    'compile',
    'js',
    '-O2',
    '--no-source-maps',
    _entry,
    '-o',
    _output,
  ]);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) exit(result.exitCode);

  // `dart compile js` also drops a `.deps` sidecar we don't ship.
  final deps = File('$_output.deps');
  if (deps.existsSync()) deps.deleteSync();

  final kb = (File(_output).lengthSync() / 1024).toStringAsFixed(0);
  stdout.writeln('Wrote $_output ($kb KB).');
}
