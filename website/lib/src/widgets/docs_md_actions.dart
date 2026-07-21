import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_button.dart';
import 'app_dropdown.dart';
import 'app_icon.dart';
import 'docs_md_loader.dart';

/// Top-of-docs actions: copy the whole page as Markdown (to paste into an LLM)
/// and download the same file. Both read the served `docs.md` (see
/// `web/docs.md`), which mirrors this docs page. Web-only: off web there is no
/// served file to fetch, so the control hides itself.
class DocsMarkdownActions extends StatefulWidget {
  const DocsMarkdownActions({super.key});

  @override
  State<DocsMarkdownActions> createState() => _DocsMarkdownActionsState();
}

class _DocsMarkdownActionsState extends State<DocsMarkdownActions> {
  /// The fetched Markdown, cached after the first successful load.
  String? _markdown;
  bool _copied = false;
  bool _busy = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Warm the cache so the first copy is instant. Failure is fine: _copy
    // retries the fetch on tap.
    if (kIsWeb) _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<String?> _load() async {
    if (_markdown != null) return _markdown;
    final md = await fetchDocsMarkdown();
    if (mounted && md != null) setState(() => _markdown = md);
    return md;
  }

  Future<void> _copy() async {
    if (_busy) return;
    setState(() => _busy = true);
    final md = await _load();
    if (!mounted) return;
    setState(() => _busy = false);
    if (md == null) return; // served file unreachable; leave the button as-is
    await Clipboard.setData(ClipboardData(text: md));
    if (!mounted) return;
    setState(() => _copied = true);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Fetch + download are browser-only; there is nothing to serve off web.
    if (!kIsWeb && !kDebugMode) return const SizedBox.shrink();

    // An "Actions" menu built on the shared AppDropdown (same shell as the theme
    // dropdown); the trigger is the site's AppButton so it matches other buttons.
    final dropdown = AppDropdown(
      // Anchor the menu to the trigger's right edge, since this sits right-aligned.
      targetAnchor: Alignment.bottomRight,
      followerAnchor: Alignment.topRight,
      panelAlignment: Alignment.topRight,
      scaleAlignment: Alignment.topRight,
      triggerBuilder: (context, open, toggle) => AppButton(
        label: _copied ? 'Copied!' : 'Actions',
        leadingDiffIcon: _copied ? DiffIcon.check : null,
        trailingDiffIcon: DiffIcon.chevronDown,
        variant: AppButtonVariant.secondary,
        size: AppButtonSize.sm,
        onPressed: toggle,
      ),
      overlayBuilder: (context, close) => AppMenuPanel(
        width: 210,
        children: [
          AppMenuItem(
            label: 'Copy as Markdown',
            leadingDiffIcon: DiffIcon.copy,
            onTap: _busy
                ? () {}
                : () {
                    close();
                    _copy();
                  },
          ),
          AppMenuItem(
            label: 'Download .md',
            leadingIcon: Icons.file_download_outlined,
            onTap: () {
              close();
              downloadDocsMarkdown('shiki_flutter-docs.md');
            },
          ),
        ],
      ),
    );

    // Right-aligned above the first section.
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: dropdown,
      ),
    );
  }
}
