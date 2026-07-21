// Web implementation: fetch the served `docs.md` (emitted from web/docs.md,
// served at the site root alongside index.html) and trigger a file download of
// it. Both URLs are relative, so they resolve against the app's <base href>.
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Fetches the served `docs.md` and returns its text, or null on any failure
/// (missing file, network error, non-2xx). Same-origin, so no CORS.
Future<String?> fetchDocsMarkdown() async {
  try {
    final response = await web.window.fetch('docs.md'.toJS).toDart;
    if (!response.ok) return null;
    final text = await response.text().toDart;
    return text.toDart;
  } catch (_) {
    return null;
  }
}

/// Triggers a browser download of the served `docs.md`, saved as [filename].
void downloadDocsMarkdown(String filename) {
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = 'docs.md'
    ..download = filename
    ..style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
}
