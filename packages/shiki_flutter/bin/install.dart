// Installs the prebuilt Web Worker(s) for off-main-thread async highlighting on
// web into your app's `web/` folder. There is one worker per engine. Install
// the one matching your `webEngine`:
//
//   dart run shiki_flutter:install             # embedded engine (default)
//   dart run shiki_flutter:install --default   # embedded engine
//   dart run shiki_flutter:install --dart      # oniguruma_dart port
//   dart run shiki_flutter:install --native    # native (WebAssembly) engine
//
// Flags can be combined (e.g. `--default --dart`). Then enable it on web by
// setting `asyncWeb: true`. Re-run after upgrading to refresh the worker(s).
//
// Pure `dart:io`/`dart:isolate` (no Flutter). The `--native` worker and its wasm
// live in `shiki_flutter_native_engine` / `oniguruma_native`; they are resolved
// by name at runtime, so this command never adds a native dependency to the core
// package (add `shiki_flutter_native_engine` yourself to use `--native`).
import 'dart:io';
import 'dart:isolate';

/// (package asset, destination filename) for the two core-hosted workers.
const _coreWorkers = <String, (String, String)>{
  'default': (
    'package:shiki_flutter/src/async/web/prebuilt/shiki_tokenize_worker.js',
    'shiki_tokenize_worker.js',
  ),
  'dart': (
    'package:shiki_flutter/src/async/web/prebuilt/shiki_tokenize_worker_dart.js',
    'shiki_tokenize_worker_dart.js',
  ),
};

const _nativeAsset =
    'package:shiki_flutter_native_engine/src/prebuilt/shiki_tokenize_worker_native.js';
const _nativeDest = 'shiki_tokenize_worker_native.js';

Future<void> main(List<String> args) async {
  final engines = _parseEngines(args);
  if (engines == null) {
    stderr.writeln('Usage: dart run shiki_flutter:install '
        '[--default] [--dart] [--native]');
    exit(64);
  }

  if (!Directory('web').existsSync()) {
    stderr.writeln('No "web/" directory here. Run this from your Flutter app '
        'root (a web-enabled project).');
    exit(1);
  }

  for (final engine in engines) {
    if (engine == 'native') {
      await _installNative();
    } else {
      await _installCore(engine);
    }
  }

  _printEnableHint(engines);
}

Future<void> _installCore(String engine) async {
  final (asset, destName) = _coreWorkers[engine]!;
  final resolved = await Isolate.resolvePackageUri(Uri.parse(asset));
  if (resolved == null || !File.fromUri(resolved).existsSync()) {
    stderr.writeln('Could not find the prebuilt "$engine" worker inside the '
        'shiki_flutter package. Is shiki_flutter a dependency of this project?');
    exit(1);
  }
  final dest = File('web/$destName');
  File.fromUri(resolved).copySync(dest.path);
  final kb = (dest.lengthSync() / 1024).toStringAsFixed(0);
  stdout.writeln('✓ Installed ${dest.path} ($kb KB), $engine engine.');
}

Future<void> _installNative() async {
  final resolved = await Isolate.resolvePackageUri(Uri.parse(_nativeAsset));
  if (resolved == null || !File.fromUri(resolved).existsSync()) {
    stderr.writeln('Could not find the native worker. Add '
        '`shiki_flutter_native_engine` to your dependencies to use --native.');
    exit(1);
  }
  final dest = File('web/$_nativeDest');
  File.fromUri(resolved).copySync(dest.path);
  final kb = (dest.lengthSync() / 1024).toStringAsFixed(0);
  stdout.writeln('✓ Installed ${dest.path} ($kb KB), native engine.');

  // Fetch the Oniguruma wasm module into web/ (verified download, with retries).
  stdout.writeln('Fetching the Oniguruma WebAssembly module '
      '(oniguruma_native:setup)...');
  final setup = await Process.run(
      'dart', ['run', 'oniguruma_native:setup'], runInShell: true);
  stdout.write(setup.stdout);
  stderr.write(setup.stderr);
  if (setup.exitCode != 0) {
    stderr.writeln('! Could not fetch the wasm automatically. Run it yourself:');
    stderr.writeln('    dart run oniguruma_native:setup');
    stderr.writeln('  (loadWasm() also falls back to the GitHub Release at '
        'runtime, so the app still works online without it.)');
  }
}

/// Returns the engines to install (`default`|`dart`|`native`), preserving order
/// and de-duplicated, or null on an unknown flag. No flags → just the default
/// (embedded) worker, so `dart run shiki_flutter:install` stays zero-config.
List<String>? _parseEngines(List<String> args) {
  const known = {'--default': 'default', '--dart': 'dart', '--native': 'native'};
  if (args.isEmpty) return ['default'];
  final out = <String>[];
  for (final a in args) {
    final engine = known[a];
    if (engine == null) return null;
    if (!out.contains(engine)) out.add(engine);
  }
  return out;
}

void _printEnableHint(List<String> engines) {
  stdout.writeln('');
  stdout.writeln('Enable off-main-thread highlighting on web in main():');
  if (engines.contains('native')) {
    stdout.writeln('    await loadWasm(); // instantiate the wasm before highlighting');
    stdout.writeln('    ShikiHighlighter.config = ShikiHighlighter.config.copyWith(');
    stdout.writeln('      webEngine: const ShikiHighlighterNativeEngine(),');
    stdout.writeln('      asyncWeb: true,');
    stdout.writeln('    );');
  } else {
    stdout.writeln('    ShikiHighlighter.config =');
    stdout.writeln('        ShikiHighlighter.config.copyWith(asyncWeb: true);');
  }
  stdout.writeln('(or pass async: true to a ShikiCodeView / ShikiCodeListView).');
}
