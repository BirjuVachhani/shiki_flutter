// Copies the prebuilt Web Worker into your Flutter app's `web/` so async
// highlighting can run off the main thread on web.
//
// Run once from your app's root:
//
//   dart run shiki_flutter:install_web_worker
//
// Then enable it on web by setting `asyncWeb: true` in `ShikiHighlighter.config`
// (or `async: true` on a widget). Re-run after upgrading shiki_flutter to
// refresh the worker.
//
// Pure `dart:io`/`dart:isolate` (no Flutter): it reads the prebuilt shipped
// inside the shiki_flutter package and writes it next to your `index.html`.
import 'dart:io';
import 'dart:isolate';

const _packageAsset =
    'package:shiki_flutter/src/async/web/prebuilt/shiki_tokenize_worker.js';
const _destName = 'shiki_tokenize_worker.js';

Future<void> main() async {
  final resolved = await Isolate.resolvePackageUri(Uri.parse(_packageAsset));
  if (resolved == null || !File.fromUri(resolved).existsSync()) {
    stderr.writeln('Could not find the prebuilt worker inside the shiki_flutter '
        'package. Is shiki_flutter a dependency of this project?');
    exit(1);
  }

  final webDir = Directory('web');
  if (!webDir.existsSync()) {
    stderr.writeln('No "web/" directory here. Run this from your Flutter app '
        'root (a web-enabled project).');
    exit(1);
  }

  final dest = File('web/$_destName');
  File.fromUri(resolved).copySync(dest.path);
  final kb = (dest.lengthSync() / 1024).toStringAsFixed(0);

  stdout.writeln('✓ Installed ${dest.path} ($kb KB).');
  stdout.writeln('');
  stdout.writeln('Enable off-main-thread highlighting on web by setting, in main():');
  stdout.writeln('    ShikiHighlighter.config =');
  stdout.writeln('        ShikiHighlighter.config.copyWith(asyncWeb: true);');
  stdout.writeln('(or pass async: true to a ShikiCodeView / ShikiCodeListView).');
}
