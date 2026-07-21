// Loads and downloads the served `web/docs.md` for the docs "Copy as Markdown"
// control. Split by platform with the same conditional-import idiom used by the
// highlighter engine config: `dart.library.js_interop` is defined only on web,
// so the VM resolves to the stub (no served file to reach) and web resolves to
// the `package:web` implementation.
export 'docs_md_loader_stub.dart'
    if (dart.library.js_interop) 'docs_md_loader_web.dart';
