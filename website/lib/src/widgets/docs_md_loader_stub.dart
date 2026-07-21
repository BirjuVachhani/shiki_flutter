// Non-web stub: there is no served `docs.md` to fetch or download off the web,
// so both operations are no-ops. The docs control hides itself off web, so
// these are never reached in practice; they exist only to satisfy the
// conditional import on the IO/desktop build.

/// Returns the served docs Markdown, or null when unavailable (always null
/// off web).
Future<String?> fetchDocsMarkdown() async => null;

/// Triggers a browser download of the docs Markdown (no-op off web).
void downloadDocsMarkdown(String filename) {}
