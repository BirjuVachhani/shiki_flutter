// Non-web stub: there is no document to mutate off the web, so updating the
// page title and meta tags is a no-op. Exists only to satisfy the conditional
// import on the IO/desktop build (and under the VM in widget tests).

/// Updates the live document metadata (no-op off web).
void setDocumentMeta({
  required String title,
  required String description,
  required String canonical,
}) {}
