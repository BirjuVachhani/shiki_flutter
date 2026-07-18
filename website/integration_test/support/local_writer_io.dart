// Native (dart:io) implementation of the best-effort local result writer.
library;

import 'dart:io';

/// Writes [json] to [path], creating parent directories. Best-effort: silently
/// ignores failures (sandbox / read-only FS). Selected on native via the
/// conditional export in `local_writer.dart`.
void writeLocalJson(String path, String json) {
  try {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(json);
  } catch (_) {
    // Metrics still flow through reportData + console prints.
  }
}
